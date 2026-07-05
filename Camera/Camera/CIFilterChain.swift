//
//  CIFilterChain.swift
//  Camera
//
//  Created by Jai Subhash Rayani on 17/05/26.
//


import CoreImage
import CoreGraphics
import UIKit

/// High-throughput composable processing engine running on top of a unified pipeline.
final class CIFilterChain {
    
    static func process(inputImage: CIImage, state: EditState, lutData: NSData?, lutSize: Int) -> CIImage {
        var outputImage = inputImage
        
        // 1. Temperature & Tint adjustment via Linear Vector maps
        if let tempTintFilter = CIFilter(name: "CITemperatureAndTint") {
            tempTintFilter.setValue(outputImage, forKey: kCIInputImageKey)
            // Neutral point: 6500K
            tempTintFilter.setValue(CIVector(x: CGFloat(state.temperature), y: CGFloat(state.tint)), forKey: "inputTargetNeutral")
            tempTintFilter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            if let result = tempTintFilter.outputImage { outputImage = result }
        }
        
        // 2. Core Color Controls (Brightness, Contrast, Saturation)
        if let colorControls = CIFilter(name: "CIColorControls") {
            colorControls.setValue(outputImage, forKey: kCIInputImageKey)
            colorControls.setValue(state.brightness, forKey: kCIInputBrightnessKey)
            colorControls.setValue(state.contrast, forKey: kCIInputContrastKey)
            colorControls.setValue(state.saturation, forKey: kCIInputSaturationKey)
            if let result = colorControls.outputImage { outputImage = result }
        }
        
        // 3. Highlights & Shadows Adjustments
        if let highShadowFilter = CIFilter(name: "CIHighlightShadowAdjust") {
            highShadowFilter.setValue(outputImage, forKey: kCIInputImageKey)
            highShadowFilter.setValue(state.highlights, forKey: "inputHighlightAmount")
            highShadowFilter.setValue(state.shadows, forKey: "inputShadowAmount")
            if let result = highShadowFilter.outputImage { outputImage = result }
        }
        
        // 4. Sharpness Extraction Channel
        if let sharpenFilter = CIFilter(name: "CISharpenLuminance") {
            sharpenFilter.setValue(outputImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue(state.sharpness, forKey: kCIInputSharpnessKey)
            if let result = sharpenFilter.outputImage { outputImage = result }
        }
        
        // 5. Hardware Noise Reduction
        if let noiseFilter = CIFilter(name: "CINoiseReduction") {
            noiseFilter.setValue(outputImage, forKey: kCIInputImageKey)
            noiseFilter.setValue(state.noiseReduction, forKey: "inputNoiseLevel")
            if let result = noiseFilter.outputImage { outputImage = result }
        }
        
        // 6. Look Up Table Cube Insertion Node
        if let lutData = lutData, let cubeFilter = CIFilter(name: "CIColorCube") {
            cubeFilter.setValue(outputImage, forKey: kCIInputImageKey)
            cubeFilter.setValue(lutSize, forKey: "inputCubeDimension")
            cubeFilter.setValue(lutData, forKey: "inputCubeData")
            if let cubeOutput = cubeFilter.outputImage {
                // Perform alpha blend according to the intensity slider
                if let blendFilter = CIFilter(name: "CIMix") {
                    blendFilter.setValue(outputImage, forKey: kCIInputBackgroundImageKey)
                    blendFilter.setValue(cubeOutput, forKey: kCIInputImageKey)
                    blendFilter.setValue(state.lutIntensity, forKey: kCIInputAmountKey)
                    if let blendedResult = blendFilter.outputImage { outputImage = blendedResult }
                }
            }
        }
        
        // 7. Manual Three-Way Wheels HSL Tuning (CIColorMatrix Mapping)
        if let matrixFilter = CIFilter(name: "CIColorMatrix") {
            matrixFilter.setValue(outputImage, forKey: kCIInputImageKey)
            
            // Shadows, midtones, and highlights maps blend directly into the translation matrices
            let rVector = CIVector(x: CGFloat(state.highlightColorVector[0]), y: 0, z: 0)
            let gVector = CIVector(x: 0, y: CGFloat(state.midtoneColorVector[1]), z: 0)
            let bVector = CIVector(x: 0, y: 0, z: CGFloat(state.shadowColorVector[2]))
            
            matrixFilter.setValue(rVector, forKey: "inputRVector")
            matrixFilter.setValue(gVector, forKey: "inputGVector")
            matrixFilter.setValue(bVector, forKey: "inputBVector")
            if let result = matrixFilter.outputImage { outputImage = result }
        }
        
        // 8. Geometric Vignetting
        if let vignetteFilter = CIFilter(name: "CIVignette") {
            vignetteFilter.setValue(outputImage, forKey: kCIInputImageKey)
            vignetteFilter.setValue(state.vignetteIntensity, forKey: kCIInputIntensityKey)
            vignetteFilter.setValue(state.vignetteRadius, forKey: kCIInputRadiusKey)
            if let result = vignetteFilter.outputImage { outputImage = result }
        }
        
        // 9. Rigid Multi-Axis Structural Rotations & Flips
        outputImage = applyTransformations(to: outputImage, state: state)
        
        return outputImage
    }
    
    private static func applyTransformations(to image: CIImage, state: EditState) -> CIImage {
        var result = image
        
        if state.isFlippedHorizontal { result = result.oriented(.upMirrored) }
        if state.isFlippedVertical { result = result.oriented(.downMirrored) }
        
        if state.rotationAngle != 0 {
            let radians = CGFloat(state.rotationAngle * .pi / 180.0)
            let transform = CGAffineTransform(rotationAngle: radians)
            result = result.transformed(by: transform)
        }
        
        if state.cropRect != CGRect(x: 0, y: 0, width: 1, height: 1) {
            let imageSize = result.extent.size
            let absoluteCropRect = CGRect(
                x: state.cropRect.origin.x * imageSize.width,
                y: state.cropRect.origin.y * imageSize.height,
                width: state.cropRect.size.width * imageSize.width,
                height: state.cropRect.size.height * imageSize.height
            )
            result = result.cropped(to: absoluteCropRect)
        }
        
        return result
    }
}