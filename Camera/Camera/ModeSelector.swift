//
//  ModeSelector.swift
//  Camera
//
//  Created by Jai Subhash Rayani on 17/05/26.
//


import SwiftUI

struct ModeSelector: View {
    @ObservedObject var model: CameraViewModel
    
    var body: some View {
        HStack {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 22) { // Increased slightly for clean tracking look
                        ForEach(CameraViewModel.CameraMode.allCases) { mode in
                            Text(mode.rawValue)
                                .font(.system(size: model.currentMode == mode ? 13.5 : 12, weight: .semibold))
                                .tracking(2.0)
                                .foregroundColor(model.currentMode == mode ? .yellow : .white.opacity(0.6))
                                .id(mode)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        model.currentMode = mode
                                    }
                                }
                        }
                    }
                    // Provides the perfect starting and ending offset padding
                    // so the outer text elements can center perfectly
                    .padding(.horizontal, UIScreen.main.bounds.width / 2 - 35)
                }
                .scrollDisabled(model.isRecording)
                // --- THE EDGES FADE MASK ---
                .mask(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0.0),       // Faded completely at the far left edge
                            .init(color: .black, location: 0.25),      // Solid black crisp focus zone starts
                            .init(color: .black, location: 0.75),      // Solid black crisp focus zone ends
                            .init(color: .clear, location: 1.0)        // Faded completely at the far right edge
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                // ----------------------------
                .onChange(of: model.currentMode) { newMode in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        proxy.scrollTo(newMode, anchor: .center)
                    }
                }
                .onAppear { proxy.scrollTo(model.currentMode, anchor: .center) }
            }
        }
        .frame(height: 32)
    }
}
