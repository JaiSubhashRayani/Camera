//
//  PermissionView.swift
//  Camera
//
//  Created by Jai Subhash Rayani on 17/05/26.
//


import SwiftUI

struct PermissionView: View {
    @ObservedObject var model: CameraViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.macro")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundColor(.yellow)
            
            Text("Camera Access Required")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("To capture cinematic 4K video and high-resolution media, access to the device camera and microphone array is required.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                model.requestSystemAccess()
            } label: {
                Text("Allow Access")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.yellow)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}