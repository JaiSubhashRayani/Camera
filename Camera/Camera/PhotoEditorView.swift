//
//  PhotoEditorView.swift
//  Camera
//
//  Created by Jai Subhash Rayani on 17/05/26.
//


import SwiftUI

struct PhotoEditorView: View {
    @ObservedObject var model: PhotoEditorViewModel
    @Environment(\.dismiss) var dismissView
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Main Image Viewport Monitor
                ZStack {
                    if let renderedUI = model.workingImage {
                        Image(uiImage: renderedUI)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding()
                    } else {
                        ProgressView().tint(.white)
                    }
                    
                    if model.isProcessingExport {
                        ZStack {
                            Color.black.opacity(0.7).ignoresSafeArea()
                            VStack(spacing: 12) {
                                ProgressView(value: model.exportProgress)
                                    .progressViewStyle(.linear)
                                    .frame(width: 140)
                                Text("Flattening core filter matrix...")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Context Sensitive Sub-Utility Adjusters Board Control Tower
                VStack {
                    switch model.currentUtilityTab {
                    case .adjust:
                        AdjustmentSlidersBlock(model: model)
                    case .grade:
                        ColorGradeView(model: model)
                    case .transform:
                        CropView(model: model)
                    }
                }
                .transition(.opacity)
                .frame(height: 180)
                
                // Segmented Command Deck
                HStack {
                    ForEach(PhotoEditorViewModel.EditorTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.25)) { model.currentUtilityTab = tab }
                        }) {
                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(model.currentUtilityTab == tab ? .yellow : .white.opacity(0.4))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismissView() }.foregroundColor(.white)
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: { model.triggerUndoStep() }) { Image(systemName: "arrow.uturn.backward") }
                    Button(action: { model.triggerRedoStep() }) { Image(systemName: "arrow.uturn.forward") }
                    Button("Save") { model.saveRenderedAssetToLibrary() }.foregroundColor(.yellow)
                }
            }
        }
    }
}

struct AdjustmentSlidersBlock: View {
    @ObservedObject var model: PhotoEditorViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                TuneSlider(title: "BRIGHTNESS", binding: $model.activeState.brightness, bounds: -1.0...1.0, baseline: 0.0, model: model)
                TuneSlider(title: "CONTRAST", binding: $model.activeState.contrast, bounds: 0.0...2.0, baseline: 1.0, model: model)
                TuneSlider(title: "SATURATION", binding: $model.activeState.saturation, bounds: 0.0...2.0, baseline: 1.0, model: model)
                TuneSlider(title: "SHARPNESS", binding: $model.activeState.sharpness, bounds: 0.0...2.0, baseline: 0.0, model: model)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
        }
    }
}

struct TuneSlider: View {
    let title: String
    @Binding var binding: Float
    let bounds: ClosedRange<Float>
    let baseline: Float
    @ObservedObject var model: PhotoEditorViewModel
    
    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(title).font(.system(size: 9, weight: .bold)).foregroundColor(.white.opacity(0.6))
                Spacer()
                Text(String(format: "%.2f", binding)).font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundColor(.yellow)
            }
            Slider(value: $binding, in: bounds) { _ in model.commitStateDeltaChange() }
                .accentColor(.yellow)
                .simultaneousGesture(TapGesture(count: 2).onEnded {
                    withAnimation { binding = baseline }
                    model.commitStateDeltaChange()
                })
        }
    }
}