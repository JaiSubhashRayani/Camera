//
//  LUTLoader.swift
//  Camera
//
//  Created by Jai Subhash Rayani on 17/05/26.
//


import Foundation
import CoreImage

/// Translates standard Adobe .cube Look Up Table text tokens into byte streams.
final class LUTLoader {
    
    /// WARNING: Add target .cube resource profiles inside your Xcode App Bundle resources bundle map.
    static func convertCubeFileToNSData(bundleResourceName: String, dimension: Int = 64) -> NSData? {
        guard let path = Bundle.main.path(forResource: bundleResourceName, ofType: "cube") else {
            print("CRITICAL: .cube asset file configuration profile missing from app bundle target mapping.")
            return nil
        }
        
        guard let dataString = try? String(contentsOfFile: path, encoding: .utf8) else { return nil }
        
        let expectedByteLength = dimension * dimension * dimension * 4
        var floatArray = [Float]()
        floatArray.reserveCapacity(expectedByteLength)
        
        let lines = dataString.components(separatedBy: .newlines)
        
        for line in lines {
            let components = line.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespaces)
            let parsedFloats = components.compactMap { Float($0) }
            
            // Valid data rows contain exactly three RGB floats
            if parsedFloats.count == 3 {
                floatArray.append(parsedFloats[0]) // Red Channel
                floatArray.append(parsedFloats[1]) // Green Channel
                floatArray.append(parsedFloats[2]) // Blue Channel
                floatArray.append(1.0)             // Alpha Channel Alignment
            }
        }
        
        guard floatArray.count == expectedByteLength else {
            print("LUT Parser payload validation length tracking error: Mismatched size matrix bounds.")
            return nil
        }
        
        return NSData(bytes: floatArray, length: floatArray.count * MemoryLayout<Float>.size)
    }
}