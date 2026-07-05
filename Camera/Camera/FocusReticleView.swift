//
//  FocusReticleView.swift
//  Camera
//
//  Created by Jai Subhash Rayani on 17/05/26.
//


import SwiftUI

struct FocusReticleView: View {
    @ObservedObject var model: CameraViewModel
    @State private var scaleIndicator: CGFloat = 1.3
    
    var body: some View {
        if model.showFocusReticle {
            GeometryReader { geo in
                let targetX = model.focusPoint.x * geo.size.width
                let targetY = model.focusPoint.y * geo.size.height
                
                ZStack {
                    // Central Tracking Frame Bounding Box
                    Rectangle()
                        .stroke(Color.yellow, lineWidth: 1.5)
                        .frame(width: 70, height: 70)
                        .scaleEffect(scaleIndicator)
                        .onAppear {
                            scaleIndicator = 1.3
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.65)) {
                                scaleIndicator = 1.0
                            }
                        }
                    
                    // Exposure Management Interactive Slider Strip
                    if model.showEVSlider {
                        VStack(spacing: 4) {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.yellow)
                            
                            // Visual EV Scale Track
                            Rectangle()
                                .fill(Color.yellow.opacity(0.4))
                                .frame(width: 2, height: 80)
                                .overlay(
                                    Circle()
                                        .fill(Color.yellow)
                                        .frame(width: 10, height: 10)
                                        .offset(y: CGFloat(-model.exposureBias * 20))
                                )
                        }
                        .offset(x: 52)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    model.activateEVSlider()
                                    let conversionRate = Float(gesture.translation.height / 40.0)
                                    model.exposureBias = max(-2.0, min(model.exposureBias - conversionRate, 2.0))
                                }
                                .onEnded { _ in model.resetEVTimeout() }
                        )
                    }
                }
                .position(x: targetX, y: targetY)
                .gesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in model.activateEVSlider() })
            }
        }
    }
}