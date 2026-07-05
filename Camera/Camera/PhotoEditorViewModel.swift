//
//  PhotoEditorViewModel.swift
//  Camera
//
//  Created by Jai Subhash Rayani on 17/05/26.
//


import SwiftUI
import CoreImage
import Photos
import Combine
import Foundation

@MainActor
final class PhotoEditorViewModel: ObservableObject {
    @Published var activeState = EditState()
    @Published var workingImage: UIImage? = nil
    @Published var isProcessingExport = false
    @Published var exportProgress: Float = 0.0
    @Published var currentUtilityTab: EditorTab = .adjust
    @Published var presentRevertAlert = false
    
    private var undoMatrixStack = [EditState]()
    private var redoMatrixStack = [EditState]()
    
    let renderingEngineContext: CIContext
    private var nativeSourceCIImage: CIImage?
    private var rawAssetReference: PHAsset?
    
    enum EditorTab: String, CaseIterable {
        case adjust = "ADJUST", grade = "GRADE", transform = "CROP"
    }
    
    init(ciContext: CIContext = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)) {
        self.renderingEngineContext = ciContext
    }
    
    func injectActiveTargetAsset(_ asset: PHAsset) {
        self.rawAssetReference = asset
        self.undoMatrixStack.removeAll()
        self.redoMatrixStack.removeAll()
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { [weak self] data, _, _, _ in
            guard let data = data, let ciImage = CIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.nativeSourceCIImage = ciImage
                self?.workingImage = UIImage(data: data)
                self?.activeState = EditState()
            }
        }
    }
    
    func commitStateDeltaChange() {
        if let currentTop = undoMatrixStack.last, currentTop == activeState { return }
        undoMatrixStack.append(activeState)
        redoMatrixStack.removeAll()
    }
    
    func triggerUndoStep() {
        guard !undoMatrixStack.isEmpty else { return }
        let current = activeState
        redoMatrixStack.append(current)
        activeState = undoMatrixStack.removeLast()
    }
    
    func triggerRedoStep() {
        guard !redoMatrixStack.isEmpty else { return }
        let next = redoMatrixStack.removeLast()
        undoMatrixStack.append(activeState)
        activeState = next
    }
    
    func resetToOriginalState() {
        activeState = EditState()
        undoMatrixStack.removeAll()
        redoMatrixStack.removeAll()
    }
    
    func computePipelineOutputImage() -> CIImage? {
        guard let input = nativeSourceCIImage else { return nil }
        
        var lutDataBuffer: NSData? = nil
        if let lutName = activeState.activeLUTName {
            lutDataBuffer = LUTLoader.convertCubeFileToNSData(bundleResourceName: lutName)
        }
        
        return CIFilterChain.process(inputImage: input, state: activeState, lutData: lutDataBuffer, lutSize: 64)
    }
    
    func saveRenderedAssetToLibrary() {
        guard let outputCI = computePipelineOutputImage() else { return }
        isProcessingExport = true
        exportProgress = 0.2
        
        // Explicitly typing Task parameters clears the 'Success' and context inference errors
        Task(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            
            // Generate the JPEG Representation payload safely
            guard let jpegData = self.renderingEngineContext.jpegRepresentation(
                of: outputCI,
                colorSpace: colorSpace,
                options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.92]
            ) else {
                await MainActor.run { self.isProcessingExport = false }
                return
            }
            
            let targetUrl = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + ".jpg")
            try? jpegData.write(to: targetUrl)
            
            // UI updates must remain isolated explicitly on the Main Actor
            await MainActor.run {
                self.exportProgress = 0.7
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: targetUrl)
            }) { success, _ in
                // Re-route closure updates safely back to the MainActor closure context
                Task { @MainActor in
                    self.isProcessingExport = false
                    self.exportProgress = 1.0
                }
            }
        }
    }
}
