//
//  OCRHelper.swift
//  OpenCV-iOS
//
//  Created by Joshua Colley on 01/11/2018.
//  Copyright © 2018 Joshua Colley. All rights reserved.
//

import Foundation
import TesseractOCR

typealias OCRDetection = (text: String, rows: [String])
typealias LineBounds = (top: CGFloat, bottom: CGFloat)

class OCRHelper {
    static let shared = OCRHelper()

    var tesseract: G8Tesseract = G8Tesseract(language: "eng")

    fileprivate func configureTesseract() {
        tesseract.engineMode = .tesseractOnly
        tesseract.pageSegmentationMode = .auto
    }

    func processImage(image: UIImage, frame: CGRect) -> OCRDetection {
        self.configureTesseract()
        tesseract.image = image
        tesseract.recognize()

        var lines: [LineBounds] = []
        var rows: [String] = []
        tesseract.characterChoices.forEach { (blockCol) in
            let col = blockCol as! [G8RecognizedBlock]
            col.forEach({ (block) in
                let box = block.boundingBox.scaled(to: image.size)
                let intersection = self.doesIntersect(box: box, lines: lines)
                guard intersection.doesIntersect else {
                    // Doesn't Intersect
                    lines.append((top: box.minY, bottom: box.maxY))
                    rows.append(block.text)
                    return
                }
                // Does Intersect
                rows[intersection.index] = rows[intersection.index] + block.text
            })
        }
        return (text: tesseract.recognizedText, rows: rows)
    }

    fileprivate func doesIntersect(box: CGRect, lines: [LineBounds]) -> (doesIntersect: Bool, index: Int) {
        guard lines.count != 0 else { return (doesIntersect: false, index: -1) }
        var doesIntersect: Bool = false
        var intersection: Int = -1
        lines.enumerated().forEach({ (index, line) in
            if line.top < box.midY && box.midY < line.bottom {
                doesIntersect = true
                intersection = index
            }
        })
        return (doesIntersect: doesIntersect, index: intersection)
    }
}
