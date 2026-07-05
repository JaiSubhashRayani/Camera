//
//  PhotoGridView.swift
//  Camera
//
//  Created by Jai Subhash Rayani on 17/05/26.
//


import SwiftUI
import Photos

struct PhotoGridView: View {
    @StateObject private var model = PhotoLibraryViewModel()
    @Environment(\.dismiss) var dismissSheet
    
    private let dynamicLayoutColumns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: dynamicLayoutColumns, spacing: 2) {
                        ForEach(model.libraryAssets, id: \.localIdentifier) { asset in
                            GridTileItem(model: model, asset: asset)
                        }
                    }
                }
            }
            .navigationTitle(model.activeAlbumName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if model.multiSelectModeActive {
                        Button("Select All") { model.selectAllAvailableAssets() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(model.multiSelectModeActive ? "Cancel" : "Select") {
                        model.multiSelectModeActive.toggle()
                        if !model.multiSelectModeActive { model.selectedAssets.removeAll() }
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    if model.multiSelectModeActive {
                        HStack {
                            Button(action: { model.purgeSelectedAssets() }) {
                                Image(systemName: "trash").foregroundColor(.red)
                            }
                            Spacer()
                            Button("Share") { /* System Share Presentation Sheet Call */ }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

struct GridTileItem: View {
    @ObservedObject var model: PhotoLibraryViewModel
    let asset: PHAsset
    @State private var texture: UIImage? = nil
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                if let img = texture {
                    NavigationLink(destination: PhotoViewerView(targetAsset: asset).environmentObject(model)) {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipShape(Rectangle())
                    }
                    .disabled(model.multiSelectModeActive)
                    .simultaneousGesture(TapGesture().onEnded {
                        if model.multiSelectModeActive { model.toggleAssetSelection(asset: asset) }
                    })
                } else {
                    Rectangle().fill(Color.white.opacity(0.05))
                }
                
                if model.multiSelectModeActive {
                    Image(systemName: model.selectedAssets.contains(asset) ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(model.selectedAssets.contains(asset) ? .yellow : .white)
                        .padding(6)
                        .shadow(radius: 2)
                }
            }
            .onAppear {
                model.requestThumbnail(for: asset, size: CGSize(width: geo.size.width * 2, height: geo.size.height * 2)) { uiImage in
                    self.texture = uiImage
                }
            }
        }
        .aspectRatio(1.0, contentMode: .fit)
        .onLongPressGesture {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            model.multiSelectModeActive = true
            model.toggleAssetSelection(asset: asset)
        }
    }
}