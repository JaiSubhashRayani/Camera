//
//  EditState.swift
//  Camera
//
//  Created by Jai Subhash Rayani on 17/05/26.
//


import SwiftUI
import CoreImage

/// Encapsulates all non-destructive adjustment parameters for the filter pipeline.
struct EditState: Equatable, Codable {
    // Basic Adjustments
    var brightness: Float = 0.0         // Range: -1.0 to 1.0
    var contrast: Float = 1.0           // Range:  0.0 to 2.0
    var saturation: Float = 1.0         // Range:  0.0 to 2.0
    var sharpness: Float = 0.0          // Range:  0.0 to 2.0
    var highlights: Float = 1.0         // Range:  0.0 to 2.0
    var shadows: Float = 0.0            // Range: -1.0 to 1.0
    var vignetteIntensity: Float = 0.0   // Range:  0.0 to 1.0
    var vignetteRadius: Float = 1.0      // Range:  0.0 to 2.0
    var noiseReduction: Float = 0.0     // Range:  0.0 to 0.1
    var temperature: Float = 5000.0     // Range: 2000.0 to 10000.0
    var tint: Float = 0.0               // Range: -100.0 to 100.0
    
    // Color Grading
    var activeLUTName: String? = nil
    var lutIntensity: Float = 1.0       // Range:  0.0 to 1.0
    
    // HSL Matrix Tuning (Vector components: [H, S, L, Offset])
    var shadowColorVector: [Float] = [1.0, 1.0, 1.0, 0.0]
    var midtoneColorVector: [Float] = [1.0, 1.0, 1.0, 0.0]
    var highlightColorVector: [Float] = [1.0, 1.0, 1.0, 0.0]
    
    // Transform parameters
    var cropRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1) // Normalized values
    var rotationAngle: Double = 0.0     // Degrees: -45 to 45
    var isFlippedHorizontal: Bool = false
    var isFlippedVertical: Bool = false
    var selectedAspectRatio: String = "Free"
}