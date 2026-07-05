//
//  PhotoLibraryViewModel.swift
//  Camera
//
//  Created by Jai Subhash Rayani on 17/05/26.
//


import SwiftUI
import Photos
import PhotosUI
import Combine

@MainActor
final class PhotoLibraryViewModel: ObservableObject {
    @Published var libraryAssets: [PHAsset] = []
    @Published var selectedAssets: Set<PHAsset> = []
    @Published var multiSelectModeActive = false
    @Published var activeAlbumName = "Recents"
    @Published var syncStatusMessage: String? = nil
    
    private let cacheImageManager = PHCachingImageManager()
    
    init() {
        verifyPermissionsAndLoadLibrary()
    }
    
    func verifyPermissionsAndLoadLibrary() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .authorized || status == .limited {
            loadSystemAssets()
        } else {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] nextStatus in
                if nextStatus == .authorized || nextStatus == .limited {
                    DispatchQueue.main.async { self?.loadSystemAssets() }
                }
            }
        }
    }
    
    private func loadSystemAssets() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResults = PHAsset.fetchAssets(with: .image, options: options)
        
        var localizedAssets = [PHAsset]()
        fetchResults.enumerateObjects { asset, _, _ in
            localizedAssets.append(asset)
        }
        self.libraryAssets = localizedAssets
    }
    
    func requestThumbnail(for asset: PHAsset, size: CGSize, complete: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        
        cacheImageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, _ in
            complete(image)
        }
    }
    
    func toggleAssetSelection(asset: PHAsset) {
        if selectedAssets.contains(asset) {
            selectedAssets.remove(asset)
        } else {
            selectedAssets.insert(asset)
        }
    }
    
    func selectAllAvailableAssets() {
        selectedAssets = Set(libraryAssets)
    }
    
    func purgeSelectedAssets() {
        let assetsArray = Array(selectedAssets)
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assetsArray as NSArray)
        }) { [weak self] success, _ in
            if success {
                DispatchQueue.main.async {
                    self?.selectedAssets.removeAll()
                    self?.multiSelectModeActive = false
                    self?.loadSystemAssets()
                }
            }
        }
    }
}
