//
//  ZoomControl.swift
//  Camera
//
//  Created by Jai Subhash Rayani on 17/05/26.
//


import SwiftUI

struct ZoomControl: View {
    @ObservedObject var model: CameraViewModel
    @State private var visibleTimeout = false
    @State private var dynamicFadeTask: Task<Void, Never>?
    
    private var zoomArray: [CGFloat] { [0.5, 1.0, 2.0, 3.0] }
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(zoomArray, id: \.self) { step in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        model.zoomFactor = step
                    }
                    triggerVisibleLifecycle()
                } label: {
                    Text(step == 0.5 ? ".5" : "\(Int(step))×")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(model.zoomFactor == step ? .yellow : .white.opacity(0.6))
                        .frame(width: 32, height: 32)
                        .background(model.zoomFactor == step ? Color.white.opacity(0.15) : Color.clear)
                        .clipShape(Circle())
                }
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .clipShape(Capsule())
        .opacity(visibleTimeout ? 1.0 : 0.0)
        .onChange(of: model.zoomFactor) { _ in triggerVisibleLifecycle() }
        .onAppear { triggerVisibleLifecycle() }
    }
    
    private func triggerVisibleLifecycle() {
        withAnimation(.easeIn(duration: 0.2)) { visibleTimeout = true }
        dynamicFadeTask?.cancel()
        dynamicFadeTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation(.easeOut(duration: 0.25)) { self.visibleTimeout = false }
        }
    }
}