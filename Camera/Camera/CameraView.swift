//
//  CameraView.swift
//  Camera
//
//  Created by Jai Subhash Rayani on 17/05/26.
//


import SwiftUI

struct CameraView: View {
    @StateObject private var model = CameraViewModel()
    @StateObject private var orientationModel = OrientationObserver()
    @State private var initFadeIn = false
    
    var body: some View {
        NavigationStack { // Manages the smooth right-to-left editor navigation push
            ZStack {
                Color.black.ignoresSafeArea()
                
                if model.isPermissionGranted {
                    ZStack {
                        // Viewfinder Background Layer
                        CameraPreviewView(session: model.session)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .ignoresSafeArea()
                            .opacity(initFadeIn ? 1.0 : 0.0)
                            .onAppear {
                                withAnimation(.easeIn(duration: 0.35)) { self.initFadeIn = true }
                            }
                            .onTapGesture { location in
                                let targetPoint = CGPoint(x: location.x / UIScreen.main.bounds.width, y: location.y / UIScreen.main.bounds.height)
                                model.tapToFocusAndExpose(at: targetPoint)
                            }
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { val in
                                        let rate: CGFloat = 0.08
                                        model.zoomFactor = max(1.0, model.zoomFactor + (val - 1.0) * rate)
                                    }
                            )

                        if model.isGridVisible { GridOverlayView() }
                        
                        FocusReticleView(model: model)
                        
                        if model.currentMode == .portrait { PortraitLightingView(model: model) }
                        
                        // Immersive UI Layer Interface Layout
                        VStack {
                            TopControlsBar(model: model)
                                .environmentObject(orientationModel)
                            
                            if model.isRecording {
                                Text(model.recordingTimerString)
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.black.opacity(0.5).cornerRadius(6))
                                    .foregroundColor(.white)
                                    .padding(.top, 8)
                            }
                            
                            Spacer()
                            
                           
                            VStack(spacing: 16) {
                                // 1. Lens / Zoom Selection Capsule
                                ZoomControl(model: model)
                                
                                // 2. Center-Locked Primary Controls Bar (Gallery | Shutter | Flip)
                                BottomControlsBar(model: model)
                                    .environmentObject(orientationModel)
                                
                                // 3. Liquid Glass Interactive Slidable Mode Selector
                                GeometryReader { geo in
                                    let screenWidth = geo.size.width
                                    let modeCount = CameraViewModel.CameraMode.allCases.count
                                    let stepWidth: CGFloat = 110 // Total layout block width allocated per text element
                                    
                                    // Match the structural index array to compute precise spatial translation matrices
                                    let activeIndex = CGFloat(CameraViewModel.CameraMode.allCases.firstIndex(of: model.currentMode) ?? 0)
                                    
                                    // Symmetrical layout math calculation coordinates
                                    let baseCenterOffset = (screenWidth / 2) - (stepWidth / 2)
                                    let dynamicScrollTranslation = baseCenterOffset - (activeIndex * stepWidth)
                                    
                                    ZStack(alignment: .leading) {
                                        // Liquid Glass Background Pill Indicator
                                        Capsule()
                                            .fill(.ultraThinMaterial)
                                            .environment(\.colorScheme, .dark)
                                            .frame(width: stepWidth - 20, height: 36)
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                                            )
                                            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                                            .position(x: screenWidth / 2, y: 16) // Quantized directly down the center axis
                                        
                                        // The Sliding Text Track Container
                                        HStack(spacing: 0) {
                                            ForEach(CameraViewModel.CameraMode.allCases) { mode in
                                                Text(mode.rawValue)
                                                    .font(.system(size: model.currentMode == mode ? 13.5 : 12, weight: .bold))
                                                    .tracking(2.0)
                                                    .foregroundColor(model.currentMode == mode ? .yellow : .white.opacity(0.4))
                                                    .frame(width: stepWidth, height: 32)
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                        UISelectionFeedbackGenerator().selectionChanged()
                                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                                            model.currentMode = mode
                                                        }
                                                    }
                                            }
                                        }
                                        .offset(x: dynamicScrollTranslation) // Translates layout smoothly matching state index shifts
                                    }
                                    .frame(height: 32)
                                    .contentShape(Rectangle())
                                    // Global interactive Drag Gesture engine overriding raw structural scroll blocks
                                    .gesture(
                                        DragGesture()
                                            .onEnded { gesture in
                                                let horizontalSwipeVelocity = gesture.predictedEndTranslation.width
                                                let activeIndexInt = CameraViewModel.CameraMode.allCases.firstIndex(of: model.currentMode) ?? 0
                                                
                                                // Left Swipe Gesture execution loop pipeline
                                                if horizontalSwipeVelocity < -50 && activeIndexInt < modeCount - 1 {
                                                    UISelectionFeedbackGenerator().selectionChanged()
                                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                                        model.currentMode = CameraViewModel.CameraMode.allCases[activeIndexInt + 1]
                                                    }
                                                }
                                                // Right Swipe Gesture execution loop pipeline
                                                else if horizontalSwipeVelocity > 50 && activeIndexInt > 0 {
                                                    UISelectionFeedbackGenerator().selectionChanged()
                                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                                        model.currentMode = CameraViewModel.CameraMode.allCases[activeIndexInt - 1]
                                                    }
                                                }
                                            }
                                    )
                                }
                                .frame(height: 32)
                                .padding(.bottom, 24)
                            }
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.black.opacity(0.0),
                                        Color.black.opacity(0.55),
                                        Color.black.opacity(0.96)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .ignoresSafeArea(edges: .bottom) // Forces the container matrix down to the physical edge of the panel
                        
                        if model.isCountingDown {
                            Text("\(model.countdownRemaining)")
                                .font(.system(size: 84, weight: .light, design: .rounded))
                                .foregroundColor(.yellow)
                                .transition(.scale.combined(with: .opacity))
                                .animation(.easeInOut(duration: 0.2), value: model.countdownRemaining)
                        }
                        
                        if model.isSessionInterrupted {
                            VisualBlurOverlay(message: "Camera Unavailable")
                        }
                    }
                } else if model.showPermissionPrompt {
                    PermissionView(model: model)
                }
            }
            .statusBarHidden(true)
            .persistentSystemOverlays(.hidden)
        }
    }
    
    // MARK: - Embedded Component Nodes
    
    struct GridOverlayView: View {
        var body: some View {
            GeometryReader { geo in
                Path { p in
                    // Horizontal guides
                    p.move(to: CGPoint(x: 0, y: geo.size.height / 3))
                    p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 3))
                    p.move(to: CGPoint(x: 0, y: 2 * geo.size.height / 3))
                    p.addLine(to: CGPoint(x: geo.size.width, y: 2 * geo.size.height / 3))
                    
                    // Vertical guides
                    p.move(to: CGPoint(x: geo.size.width / 3, y: 0))
                    p.addLine(to: CGPoint(x: geo.size.width / 3, y: geo.size.height))
                    p.move(to: CGPoint(x: 2 * geo.size.width / 3, y: 0))
                    p.addLine(to: CGPoint(x: 2 * geo.size.width / 3, y: geo.size.height))
                }
                .stroke(Color.white.opacity(0.2), lineWidth: 1.0)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
    
    struct VisualBlurOverlay: View {
        let message: String
        var body: some View {
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .ignoresSafeArea()
                .overlay {
                    Text(message)
                        .font(.headline)
                        .foregroundColor(.white)
                }
        }
    }
}
