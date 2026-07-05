//
//  BottomControlsBar.swift
//  Camera
//
//  Created by Jai Subhash Rayani on 17/05/26.
//

import SwiftUI
import Photos

struct BottomControlsBar: View {
    @ObservedObject var model: CameraViewModel
    @EnvironmentObject var orientation: OrientationObserver
    
    var body: some View {
        HStack {
            // Left Column Group: Gallery Media Preview Link
            ZStack {
                if let image = model.lastThumbnail {
                    NavigationLink(destination: PhotoViewerView(targetAsset: PHAsset()).environmentObject(PhotoLibraryViewModel())) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 50, height: 50)
                }
            }
            .frame(width: 50, height: 50) // Fixes structural dimensions
            .offset(model.animateThumbnailFlyIn ? CGSize(width: UIScreen.main.bounds.width / 3, height: 0) : CGSize.zero)
            .scaleEffect(model.animateThumbnailFlyIn ? 2.0 : 1.0)
            .rotationEffect(.degrees(-orientation.rotationAngle))
            
            // Equal space multiplier 1
            Spacer()
            
            // Center Column Group: High-Priority Shutter Core
            ShutterButton(model: model)
                .frame(width: 80, height: 80) // Fixes core container box constraints
            
            // Equal space multiplier 2
            Spacer()
            
            // Right Column Group: Active Camera Core Switcher Block
            Button {
                guard !model.isRecording else { return }
                model.switchLensDevice()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
            .disabled(model.isRecording)
            .frame(width: 50, height: 50) // Symmetrical bounding footprint matching left item
            .rotationEffect(.degrees(-orientation.rotationAngle))
        }
        .padding(.horizontal, 32) // Comfortable edge inset away from screen boundaries
        .frame(maxWidth: .infinity) // Pulls layout wide edge-to-edge
        .frame(height: 84) // Slightly reduced height to look tight and proportional above the tabs
    }
}
