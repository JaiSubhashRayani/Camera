//
//  PhotoViewerView.swift
//  Camera
//
//  Created by Jai Subhash Rayani on 17/05/26.
//


import SwiftUI
import Photos

struct PhotoViewerView: View {
    let targetAsset: PHAsset
    @EnvironmentObject var libraryModel: PhotoLibraryViewModel
    @StateObject private var editorModel = PhotoEditorViewModel()
    @State private var showControlsOverlay = true
    @State private var currentZoomScale: CGFloat = 1.0
    @State private var animateEntry = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Core Page View Slider
            TabView(selection: $editorModel.workingImage) {
                if let rawImg = editorModel.workingImage {
                    Image(uiImage: rawImg)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .ignoresSafeArea()
                        .scaleEffect(currentZoomScale)
                        .opacity(animateEntry ? 1.0 : 0.0)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { scale in self.currentZoomScale = scale.magnitude }
                                .onEnded { _ in withAnimation(.spring()) { self.currentZoomScale = 1.0 } }
                        )
                        .simultaneousGesture(
                            TapGesture(count: 2).onEnded {
                                withAnimation(.spring()) { currentZoomScale = currentZoomScale == 1.0 ? 2.5 : 1.0 }
                            }
                        )
                        .simultaneousGesture(
                            TapGesture(count: 1).onEnded { showControlsOverlay.toggle() }
                        )
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Translucent Top Bar Overlay
            if showControlsOverlay {
                VStack {
                    HStack {
                        Text(targetAsset.creationDate?.formatted(date: .abbreviated, time: .shortened) ?? "")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    
                    Spacer()
                    
                    // Translucent Bottom Navigation Utility Bar
                    HStack {
                        NavigationLink(destination: PhotoEditorView(model: editorModel)) {
                            Text("Edit").foregroundColor(.yellow).fontWeight(.semibold)
                        }
                        Spacer()
                        Image(systemName: "heart").foregroundColor(.white)
                        Spacer()
                        Image(systemName: "ellipsis.circle").foregroundColor(.white)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(showControlsOverlay ? .visible : .hidden, for: .navigationBar)
        .onAppear {
            editorModel.injectActiveTargetAsset(targetAsset)
            withAnimation(.easeIn(duration: 0.3)) { self.animateEntry = true }
        }
    }
}