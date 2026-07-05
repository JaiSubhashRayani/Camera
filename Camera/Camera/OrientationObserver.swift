//
//  OrientationObserver.swift
//  Camera
//
//  Created by Jai Subhash Rayani on 17/05/26.
//


import SwiftUI
import Combine

class OrientationObserver: ObservableObject {
    @Published var currentOrientation: UIDeviceOrientation = .portrait
    @Published var rotationAngle: Double = 0.0
    private var cancellable: AnyCancellable?

    init() {
        self.currentOrientation = UIDevice.current.orientation
        self.cancellable = NotificationCenter.default
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .sink { [weak self] _ in self?.updateOrientation() }
    }

    private func updateOrientation() {
        let deviceOrientation = UIDevice.current.orientation
        guard deviceOrientation.isValidInterfaceOrientation else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            self.currentOrientation = deviceOrientation
            switch deviceOrientation {
            case .portrait: self.rotationAngle = 0.0
            case .landscapeLeft: self.rotationAngle = 90.0
            case .landscapeRight: self.rotationAngle = -90.0
            case .portraitUpsideDown: self.rotationAngle = 180.0
            default: break
            }
        }
    }
}