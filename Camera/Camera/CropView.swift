//
//  CropView.swift
//  Camera
//
//  Created by Jai Subhash Rayani on 17/05/26.
//


import SwiftUI

struct CropView: View {
    @ObservedObject var model: PhotoEditorViewModel
    
    let aspectsList = ["Free", "1:1", "4:3", "16:9", "3:2"]
    
    var body: some View {
        VStack(spacing: 12) {
            // Precise Angular Micro Rotations Slider Block
            VStack(spacing: 2) {
                Text(String(format: "ROTATION: %.1f°", model.activeState.rotationAngle))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.yellow)
                Slider(value: $model.activeState.rotationAngle, in: -45.0...45.0, step: 0.5)
                    .accentColor(.yellow)
                    .onChange(of: model.activeState.rotationAngle) { newValue in // <--- FIXED
                        if abs(newValue) < 2.0 { model.activeState.rotationAngle = 0.0 }
                    }
                    .simultaneousGesture(TapGesture().onEnded { model.commitStateDeltaChange() })
            }
            .padding(.horizontal, 32)
            
            // Mirror Flips and Orientation Matrix Modifiers
            HStack(spacing: 40) {
                Button(action: {
                    model.activeState.isFlippedHorizontal.toggle()
                    model.commitStateDeltaChange()
                }) {
                    Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right.fill").font(.body)
                }
                
                Button(action: {
                    model.activeState.isFlippedVertical.toggle()
                    model.commitStateDeltaChange()
                }) {
                    Image(systemName: "arrow.up.and.down.righttriangle.up.righttriangle.down.fill").font(.body)
                }
            }
            .foregroundColor(.white)
            
            // Crop Aspect Ratio Profile Selectors Row
            HStack(spacing: 16) {
                ForEach(aspectsList, id: \.self) { aspect in
                    Text(aspect)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(model.activeState.selectedAspectRatio == aspect ? Color.yellow : Color.white.opacity(0.1))
                        .foregroundColor(model.activeState.selectedAspectRatio == aspect ? .black : .white)
                        .cornerRadius(4)
                        .onTapGesture {
                            model.activeState.selectedAspectRatio = aspect
                            model.commitStateDeltaChange()
                        }
                }
            }
        }
    }
}
