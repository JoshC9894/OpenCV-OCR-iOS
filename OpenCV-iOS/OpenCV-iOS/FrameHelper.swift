//
//  FrameHelper.swift
//  OpenCV-iOS
//
//  Created by Joshua Colley on 26/10/2018.
//  Copyright © 2018 Joshua Colley. All rights reserved.
//

import Foundation
import Vision
import UIKit

class FrameHelper {

    static func drawBox(rect: CGRect) -> CAShapeLayer {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.close()

        let shape = CAShapeLayer()
        shape.lineWidth = 2
        shape.lineJoin = CAShapeLayerLineJoin.miter
        shape.strokeColor = UIColor(red: 0.0, green: 0.906, blue: 0.392, alpha: 1.0).cgColor
        shape.fillColor = UIColor(red: 0.0, green: 0.906, blue: 0.392, alpha: 1.0).cgColor
        shape.opacity = 0.5
        shape.path = path.cgPath

        return shape
    }
    
    static func getShape(rect: VNRectangleObservation, frame: CGRect) -> CAShapeLayer {
        let path = UIBezierPath()
        path.move(to: rect.topLeft.scaled(to: frame.size))
        path.addLine(to: rect.topRight.scaled(to: frame.size))
        path.addLine(to: rect.bottomRight.scaled(to: frame.size))
        path.addLine(to: rect.bottomLeft.scaled(to: frame.size))
        path.close()
        
        let shape = CAShapeLayer()
        shape.lineWidth = 2
        shape.lineJoin = CAShapeLayerLineJoin.miter
        shape.strokeColor = UIColor(red: 0.0, green: 0.906, blue: 0.392, alpha: 1.0).cgColor
        shape.fillColor = UIColor(red: 0.0, green: 0.906, blue: 0.392, alpha: 0.5).cgColor
        shape.opacity = 0.5
        shape.path = path.cgPath
        
        return shape
    }
    
    static func maskView(shape: CAShapeLayer) -> CAShapeLayer {
        let maskShape = shape
        maskShape.fillColor = UIColor.orange.cgColor
        maskShape.strokeColor = UIColor.orange.cgColor
        maskShape.opacity = 1.0
        
        return shape
    }
    
    static func uiImageFromBuffer(buffer: CVPixelBuffer, frame: CGRect) -> UIImage? {
        let ciImage = CIImage(cvImageBuffer: buffer)
        if let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) {
            return UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
        }
        return nil
    }
    
    static func straightenImage(rect: VNRectangleObservation, image: CIImage, frame: CGRect) -> UIImage? {
        let ciImage = image.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: rect.topLeft.scaled(to: frame.size)),
            "inputTopRight": CIVector(cgPoint: rect.topRight.scaled(to: frame.size)),
            "inputBottomLeft": CIVector(cgPoint: rect.bottomLeft.scaled(to: frame.size)),
            "inputBottomRight": CIVector(cgPoint: rect.bottomRight.scaled(to: frame.size))
            ])
        
        UIGraphicsBeginImageContext(CGSize(width: ciImage.extent.size.width,
                                           height: ciImage.extent.size.height))
        UIImage(ciImage: ciImage, scale: 1.0, orientation: .down).draw(in: CGRect(x: 0,
                                                                                  y: 0,
                                                                                  width: ciImage.extent.size.width,
                                                                                  height: ciImage.extent.size.height))
        let uiImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return uiImage
    }
}

// MARK: - Extensions
extension CGRect {
    func scaled(to size: CGSize) -> CGRect {
        return CGRect(x: self.origin.x * size.width,
                      y: self.origin.y * size.height,
                      width: self.size.width * size.width,
                      height: self.size.height * size.height)
    }
}

extension CGPoint {
    func scaled(to size: CGSize) -> CGPoint {
        return CGPoint(x: self.x * size.width,
                       y: self.y * size.height)
    }
}
