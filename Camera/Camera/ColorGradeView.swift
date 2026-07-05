//
//  ColorGradeView.swift
//  Camera
//
//  Created by Jai Subhash Rayani on 17/05/26.
//


import SwiftUI

struct ColorGradeView: View {
    @ObservedObject var model: PhotoEditorViewModel
    @State private var currentSubTab = 0 // 0 = LUT Profiles, 1 = Wheels Matrix
    
    let lutsArray = ["Cinematic", "Fade", "Chrome", "Matte", "Cool Blue", "Golden Hour", "Noir", "Vivid", "Faded Green", "Warm Film"]
    
    var body: some View {
        VStack(spacing: 8) {
            Picker("", selection: $currentSubTab) {
                Text("FILTERS").tag(0)
                Text("COLOR WHEELS").tag(1)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            .padding(.top, 4)
            
            if currentSubTab == 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(lutsArray, id: \.self) { lutName in
                            VStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(model.activeState.activeLUTName == lutName ? Color.yellow.opacity(0.3) : Color.white.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(String(lutName.prefix(2))).font(.headline.bold()).foregroundColor(.white)
                                    )
                                    .border(model.activeState.activeLUTName == lutName ? Color.yellow : Color.clear, width: 2)
                                Text(lutName)
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(model.activeState.activeLUTName == lutName ? .yellow : .white)
                            }
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                if model.activeState.activeLUTName == lutName {
                                    model.activeState.activeLUTName = nil
                                } else {
                                    model.activeState.activeLUTName = lutName
                                }
                                model.commitStateDeltaChange()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            } else {
                HStack(spacing: 24) {
                    MiniColorWheelHUD(label: "SHADOWS", vector: $model.activeState.shadowColorVector, model: model)
                    MiniColorWheelHUD(label: "MIDTONES", vector: $model.activeState.midtoneColorVector, model: model)
                    MiniColorWheelHUD(label: "HIGHLIGHTS", vector: $model.activeState.highlightColorVector, model: model)
                }
            }
        }
    }
}

struct MiniColorWheelHUD: View {
    let label: String
    @Binding var vector: [Float]
    @ObservedObject var model: PhotoEditorViewModel
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label).font(.system(size: 8, weight: .bold)).foregroundColor(.white.opacity(0.5))
            Circle()
                .fill(AngularGradient(gradient: Gradient(colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red]), center: .center))
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 8, height: 8)
                        .offset(x: CGFloat(vector[0] * 10 - 10), y: CGFloat(vector[1] * 10 - 10))
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { val in
                            let rad = min(22.0, sqrt(pow(val.location.x - 22, 2) + pow(val.location.y - 22, 2)))
                            vector[0] = Float(rad / 22.0)
                            vector[1] = Float(rad / 22.0)
                        }
                        .onEnded { _ in model.commitStateDeltaChange() }
                )
        }
    }
}
