//
//  CameraViewModel.swift
//  Camera
//
//  Created by Jai Subhash Rayani on 17/05/26.
//

import Foundation
import AVFoundation
import Photos
import CoreMotion
import Combine
import UIKit
import SwiftUI

@MainActor
class CameraViewModel: NSObject, ObservableObject {
    @Published var isPermissionGranted = false
    @Published var showPermissionPrompt = false
    @Published var isSessionInterrupted = false
    @Published var lastThumbnail: UIImage? = nil
    @Published var animateThumbnailFlyIn = false
    
    // Core Parameters - Re-mapped to focus on your core production requirements
    @Published var currentMode: CameraMode = .photo {
        didSet { changeCameraMode(from: oldValue, to: currentMode) }
    }
    @Published var zoomFactor: CGFloat = 1.0 {
        didSet { applyZoom() }
    }
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var isLivePhotoActive = false
    @Published var isHDRActive = false
    @Published var timerState: TimerState = .off
    @Published var aspectRatio: AspectRatioSetting = .ratio4x3
    @Published var isGridVisible = false
    
    // UI Interaction States
    @Published var focusPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
    @Published var showFocusReticle = false
    @Published var exposureBias: Float = 0.0 {
        didSet { applyExposureBias() }
    }
    @Published var showEVSlider = false
    
    // Motion / Level State
    @Published var deviceRoll: Double = 0.0
    @Published var isLevelActive = false
    
    // Portrait Mode States
    @Published var selectedLightingEffect: LightingEffect = .natural
    @Published var depthAperture: Float = 4.0
    @Published var detectedFaceRect: CGRect? = nil
    
    // Video Capture States
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var recordingTimerString = "00:00"
    
    // Countdown State
    @Published var countdownRemaining: Int = 0
    @Published var isCountingDown = false
    
    // Session State Dependencies
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session", qos: .userInitiated)
    
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private let movieFileOutput = AVCaptureMovieFileOutput()
    private let metadataOutput = AVCaptureMetadataOutput()
    
    private let motionManager = CMMotionManager()
    private var videoTimer: AnyCancellable?
    private var focusTimer: Task<Void, Never>?
    private var evTimer: Task<Void, Never>?
    
    // Cleaned 3-Tier Mode Matrix Array Configuration
    enum CameraMode: String, CaseIterable, Identifiable {
        case video = "VIDEO"
        case photo = "PHOTO"
        case portrait = "PORTRAIT"
        var id: String { self.rawValue }
    }
    
    enum TimerState: String, CaseIterable {
        case off = "Off", threeSec = "3s", tenSec = "10s"
    }
    
    enum AspectRatioSetting: String, CaseIterable {
        case ratio1x1 = "1:1", ratio4x3 = "4:3", ratio16x9 = "16:9"
    }
    
    enum LightingEffect: String, CaseIterable, Identifiable {
        case natural = "NATURAL", studio = "STUDIO", contour = "CONTOUR", stage = "STAGE", stageMono = "STAGE MONO", highKeyMono = "HIGH-KEY MONO"
        var id: String { self.rawValue }
    }
    
    override init() {
        super.init()
        loadPersistedSettings()
        checkSystemPermissions()
        // Hardware sensor monitoring is commented out to save battery cycles since UI element is removed
        // initializeMotionMonitoring()
    }
    
    private func loadPersistedSettings() {
        let savedFlashRawValue = UserDefaults.standard.integer(forKey: "cam_flashMode")
        if let mode = AVCaptureDevice.FlashMode(rawValue: savedFlashRawValue) {
            self.flashMode = mode
        }
        self.isHDRActive = UserDefaults.standard.bool(forKey: "cam_hdrActive")
    }
    
    private func checkSystemPermissions() {
        let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        if videoStatus == .authorized && audioStatus == .authorized {
            self.isPermissionGranted = true
            setupCaptureSession()
        } else if videoStatus == .denied || audioStatus == .denied {
            self.isPermissionGranted = false
            self.showPermissionPrompt = true
        } else {
            self.showPermissionPrompt = true
        }
    }
    
    func requestSystemAccess() {
        Task {
            let videoGranted = await AVCaptureDevice.requestAccess(for: .video)
            let audioGranted = await AVCaptureDevice.requestAccess(for: .audio)
            if videoGranted && audioGranted {
                self.isPermissionGranted = true
                self.showPermissionPrompt = false
                setupCaptureSession()
            } else {
                self.isPermissionGranted = false
            }
        }
    }
    
    private func setupCaptureSession() {
        sessionQueue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
            
            if self.session.canAddInput(videoInput) {
                self.session.addInput(videoInput)
                self.videoDeviceInput = videoInput
            }
            
            guard let audioDevice = AVCaptureDevice.default(for: .audio),
                  let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else { return }
            if self.session.canAddInput(audioInput) { self.session.addInput(audioInput) }
            
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
                self.photoOutput.isHighResolutionCaptureEnabled = true
            }
            
            if self.session.canAddOutput(self.movieFileOutput) { self.session.addOutput(self.movieFileOutput) }
            
            if self.session.canAddOutput(self.metadataOutput) {
                self.session.addOutput(self.metadataOutput)
                self.metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                if self.metadataOutput.availableMetadataObjectTypes.contains(.face) {
                    self.metadataOutput.metadataObjectTypes = [.face]
                }
            }
            
            self.session.commitConfiguration()
            self.registerNotificationObservers()
            self.session.startRunning()
            
            Task { await self.fetchLatestLibraryAsset() }
        }
    }
    
    private func registerNotificationObservers() {
        NotificationCenter.default.addObserver(forName: .AVCaptureSessionWasInterrupted, object: session, queue: .main) { _ in
            self.isSessionInterrupted = true
        }
        NotificationCenter.default.addObserver(forName: .AVCaptureSessionInterruptionEnded, object: session, queue: .main) { _ in
            self.isSessionInterrupted = false
        }
    }
    
    // Streamlined Transition Logic: Tailored to your active configuration pass
    private func changeCameraMode(from oldMode: CameraMode, to newMode: CameraMode) {
        UISelectionFeedbackGenerator().selectionChanged()
        sessionQueue.async {
            self.session.beginConfiguration()
            switch newMode {
            case .photo, .portrait:
                self.session.sessionPreset = .photo
            case .video:
                self.session.sessionPreset = .hd1920x1080
            }
            self.session.commitConfiguration()
        }
    }
    
    private func applyZoom() {
        guard let device = videoDeviceInput?.device else { return }
        let clamped = max(device.minAvailableVideoZoomFactor, min(zoomFactor, device.maxAvailableVideoZoomFactor))
        try? device.lockForConfiguration()
        device.videoZoomFactor = clamped
        device.unlockForConfiguration()
    }
    
    func switchLensDevice() {
        guard !isRecording else { return }
        sessionQueue.async {
            guard let currentInput = self.videoDeviceInput else { return }
            self.session.beginConfiguration()
            self.session.removeInput(currentInput)
            
            let newPosition: AVCaptureDevice.Position = (currentInput.device.position == .back) ? .front : .back
            guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                  let newInput = try? AVCaptureDeviceInput(device: newDevice) else {
                self.session.addInput(currentInput)
                self.session.commitConfiguration()
                return
            }
            
            if self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.videoDeviceInput = newInput
            } else {
                self.session.addInput(currentInput)
            }
            self.session.commitConfiguration()
        }
    }
    
    func tapToFocusAndExpose(at relativePoint: CGPoint) {
        guard let device = videoDeviceInput?.device else { return }
        focusPoint = relativePoint
        showFocusReticle = true
        showEVSlider = false
        
        focusTimer?.cancel()
        focusTimer = Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if !showEVSlider { self.showFocusReticle = false }
        }
        
        sessionQueue.async {
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                    device.focusPointOfInterest = relativePoint
                    device.focusMode = .autoFocus
                }
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                    device.exposurePointOfInterest = relativePoint
                    device.exposureMode = .autoExpose
                }
                device.unlockForConfiguration()
            } catch { print("Configuration failure in Focus operations: \(error)") }
        }
    }
    
    func activateEVSlider() {
        guard showFocusReticle else { return }
        showEVSlider = true
        resetEVTimeout()
    }
    
    func resetEVTimeout() {
        evTimer?.cancel()
        evTimer = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            self.showEVSlider = false
            self.showFocusReticle = false
        }
    }
    
    private func applyExposureBias() {
        guard let device = videoDeviceInput?.device else { return }
        sessionQueue.async {
            try? device.lockForConfiguration()
            device.setExposureTargetBias(self.exposureBias)
            device.unlockForConfiguration()
        }
    }
    
    func capture() {
        if timerState != .off {
            startCountdownCapture()
        } else {
            executeActualCapturePipeline()
        }
    }
    
    private func startCountdownCapture() {
        isCountingDown = true
        countdownRemaining = (timerState == .threeSec) ? 3 : 10
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            self.countdownRemaining -= 1
            if self.countdownRemaining <= 0 {
                timer.invalidate()
                self.isCountingDown = false
                self.executeActualCapturePipeline()
            }
        }
    }
    
    // Cleaned Action Pipeline Execution node
    private func executeActualCapturePipeline() {
        switch currentMode {
        case .photo, .portrait:
            let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            if photoOutput.supportedFlashModes.contains(flashMode) { settings.flashMode = flashMode }
            settings.photoQualityPrioritization = .speed
            photoOutput.capturePhoto(with: settings, delegate: self)
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .video:
            if movieFileOutput.isRecording {
                movieFileOutput.stopRecording()
            } else {
                let path = NSTemporaryDirectory() + "capture_\(UUID().uuidString).mov"
                let url = URL(fileURLWithPath: path)
                movieFileOutput.startRecording(to: url, recordingDelegate: self)
            }
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }
    
    private func initializeMotionMonitoring() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
                guard let self = self, let motion = motion else { return }
                self.deviceRoll = motion.attitude.roll * (180.0 / .pi)
                let isTargetAligned = abs(self.deviceRoll) <= 1.0 || abs(self.deviceRoll - 180.0) <= 1.0 || abs(self.deviceRoll + 180.0) <= 1.0
                if isTargetAligned != self.isLevelActive { self.isLevelActive = isTargetAligned }
            }
        }
    }
    
    private func fetchLatestLibraryAsset() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else { return }
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = 1
        
        let assets = PHAsset.fetchAssets(with: .image, options: options)
        if let firstAsset = assets.firstObject {
            let manager = PHImageManager.default()
            let size = CGSize(width: 120, height: 120)
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = false
            requestOptions.deliveryMode = .highQualityFormat
            
            manager.requestImage(for: firstAsset, targetSize: size, contentMode: .aspectFill, options: requestOptions) { image, _ in
                DispatchQueue.main.async { self.lastThumbnail = image }
            }
        }
    }
    
    func registerPhotoAssetToSystemLibrary(url: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
        }) { _, _ in
            Task { await self.fetchLatestLibraryAsset() }
        }
    }
    
    func registerVideoAssetToSystemLibrary(url: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { _, _ in
            Task { await self.fetchLatestLibraryAsset() }
        }
    }
}

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let data = photo.fileDataRepresentation() else { return }
        let tempUrl = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + ".jpg")
        try? data.write(to: tempUrl)
        
        if let img = UIImage(data: data) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                self.lastThumbnail = img
                self.animateThumbnailFlyIn = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.animateThumbnailFlyIn = false }
        }
        registerPhotoAssetToSystemLibrary(url: tempUrl)
    }
}

extension CameraViewModel: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        isRecording = true
        recordingDuration = 0
        videoTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self else { return }
            self.recordingDuration += 1
            let mins = Int(self.recordingDuration) / 60
            let secs = Int(self.recordingDuration) % 60
            self.recordingTimerString = String(format: "%02d:%02d", mins, secs)
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        isRecording = false
        videoTimer?.cancel()
        recordingTimerString = "00:00"
        guard error == nil else { return }
        registerVideoAssetToSystemLibrary(url: outputFileURL)
    }
}

extension CameraViewModel: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard currentMode == .portrait else {
            self.detectedFaceRect = nil
            return
        }
        if let face = metadataObjects.first as? AVMetadataFaceObject {
            self.detectedFaceRect = face.bounds
        } else {
            self.detectedFaceRect = nil
        }
    }
}
