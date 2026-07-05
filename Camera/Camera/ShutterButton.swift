//
//  ShutterButton.swift
//  Camera
//
//  Created by Jai Subhash Rayani on 17/05/26.
//


import SwiftUI

struct ShutterButton: View {
    @ObservedObject var model: CameraViewModel
    @State private var innerScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {}) {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                if model.currentMode == .video {
                    // Video Layout Morph Matrix Engine
                    RoundedRectangle(cornerRadius: model.isRecording ? 4 : 16, style: .continuous)
                        .fill(Color.red)
                        .frame(width: model.isRecording ? 28 : 64, height: model.isRecording ? 28 : 64)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: model.isRecording)
                } else {
                    // Photo Pipeline Core Execution Matrix
                    Circle()
                        .fill(Color.white)
                        .frame(width: 64, height: 64)
                        .scaleEffect(innerScale)
                }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if model.currentMode == .photo { innerScale = 0.88 }
                }
                .onEnded { _ in
                    innerScale = 1.0
                    model.capture()
                }
        )
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    if model.currentMode == .photo {
                        model.currentMode = .video
                        model.capture()
                    }
                }
        )
    }
}
