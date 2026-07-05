//
//  TopControlsBar.swift
//  Camera
//
//  Created by Jai Subhash Rayani on 17/05/26.
//


import SwiftUI
import AVFoundation

struct TopControlsBar: View {
    @ObservedObject var model: CameraViewModel
    @EnvironmentObject var orientation: OrientationObserver
    
    var body: some View {
        HStack {
            // Flash Action Button
            Button { pulseAction {
                switch model.flashMode {
                case .off: model.flashMode = .on
                case .on: model.flashMode = .auto
                case .auto: model.flashMode = .off
                @unknown default: model.flashMode = .off
                }
                UserDefaults.standard.set(model.flashMode.rawValue, forKey: "cam_flashMode")
            }} label: {
                Image(systemName: model.flashMode == .off ? "bolt.slash.fill" : (model.flashMode == .on ? "bolt.fill" : "bolt.badge.a.fill"))
                    .foregroundColor(model.flashMode == .off ? .white : .yellow)
            }
            
            Spacer()
            
            // Live Photo Action Button
            Button { pulseAction { model.isLivePhotoActive.toggle() }} label: {
                Image(systemName: model.isLivePhotoActive ? "livephoto" : "livephoto.slash")
                    .foregroundColor(model.isLivePhotoActive ? .yellow : .white)
            }
            
            Spacer()
            
            // HDR Toggle Button
            Button { pulseAction {
                model.isHDRActive.toggle()
                UserDefaults.standard.set(model.isHDRActive, forKey: "cam_hdrActive")
            }} label: {
                Text("HDR")
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(model.isHDRActive ? Color.yellow : Color.clear)
                    .cornerRadius(4)
                    .foregroundColor(model.isHDRActive ? .black : .white)
                    .border(model.isHDRActive ? Color.clear : Color.white, width: 1)
            }
            
            Spacer()
            
            // Timer Action Button
            Button { pulseAction {
                switch model.timerState {
                case .off: model.timerState = .threeSec
                case .threeSec: model.timerState = .tenSec
                case .tenSec: model.timerState = .off
                }
            }} label: {
                Image(systemName: model.timerState == .off ? "timer" : "timer.circle.fill")
                    .foregroundColor(model.timerState == .off ? .white : .yellow)
            }
            
            Spacer()
            
            // Composition Grid System Switcher
            Button { pulseAction { model.isGridVisible.toggle() }} label: {
                Image(systemName: "grid")
                    .foregroundColor(model.isGridVisible ? .yellow : .white)
            }
        }
        .font(.system(size: 20, weight: .medium))
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .rotationEffect(.degrees(-orientation.rotationAngle))
        .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
    }
    
    private func pulseAction(_ step: @escaping () -> Void) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        step()
    }
}
