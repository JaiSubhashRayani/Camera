//
//  PortraitLightingView.swift
//  Camera
//
//  Created by Jai Subhash Rayani on 17/05/26.
//


import SwiftUI

struct PortraitLightingView: View {
    @ObservedObject var model: CameraViewModel
    
    var body: some View {
        ZStack {
            // Live Object Target Tracking HUD Frame Block
            if let targetBox = model.detectedFaceRect {
                GeometryReader { geo in
                    Rectangle()
                        .stroke(Color.yellow, lineWidth: 1.5)
                        .frame(width: targetBox.width * geo.size.width, height: targetBox.height * geo.size.height)
                        .position(x: targetBox.midX * geo.size.width, y: targetBox.midY * geo.size.height)
                }
            }
            
            // Right-Aligned Focal Depth Aperture Adjustment Track Slider
            HStack {
                Spacer()
                VStack {
                    Text(String(format: "f/%.1f", model.depthAperture))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow)
                        .padding(4)
                        .background(Color.black.opacity(0.6).cornerRadius(4))
                    
                    Slider(value: $model.depthAperture, in: 1.4...16.0, step: 0.1)
                        .accentColor(.yellow)
                        .labelsHidden()
                        .frame(width: 120)
                        .rotationEffect(.degrees(-90))
                        .frame(height: 140)
                }
                .padding(.trailing, 8)
            }
            
            // Bottom Lighting Array Selector
            VStack {
                Spacer()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(CameraViewModel.LightingEffect.allCases) { effect in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(model.selectedLightingEffect == effect ? Color.yellow : Color.white.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Text(String(effect.rawValue.prefix(1)))
                                            .font(.caption2.bold())
                                            .foregroundColor(.black)
                                    )
                                    .background(
                                        Circle()
                                            .stroke(Color.yellow, lineWidth: model.selectedLightingEffect == effect ? 2 : 0)
                                            .frame(width: 42, height: 42)
                                    )
                                
                                Text(effect.rawValue)
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(model.selectedLightingEffect == effect ? .yellow : .white)
                            }
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                model.selectedLightingEffect = effect
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 70)
                .padding(.bottom, 160)
            }
        }
    }
}