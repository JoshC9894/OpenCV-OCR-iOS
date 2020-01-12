//
//  OpenCVWrapper.m
//  OpenCV-iOS
//
//  Created by Joshua Colley on 22/10/2018.
//  Copyright © 2018 Joshua Colley. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import "OpenCVWrapper.h"
#import <Vision/Vision.h>
#import <UIKit/UIKit.h>
#import <opencv2/imgcodecs/ios.h>

using namespace std;
using namespace cv;

@implementation OpenCVWrapper

+ (UIImage *)processImage:(UIImage *)image withDetection:(VNRectangleObservation *)rect; {
    // Setup Input - Source
    cv::Point2f in_tr = cv::Point2f(rect.topRight.x * image.size.width, rect.topRight.y * image.size.height);
    cv::Point2f in_tl = cv::Point2f(rect.topLeft.x * image.size.width, rect.topLeft.y * image.size.height);
    cv::Point2f in_br = cv::Point2f(rect.bottomRight.x * image.size.width, rect.bottomRight.y * image.size.height);
    cv::Point2f in_bl = cv::Point2f(rect.bottomLeft.x * image.size.width, rect.bottomLeft.y * image.size.height);

    std::vector<cv::Point2f> input;
    input.push_back(in_tl);
    input.push_back(in_tr);
    input.push_back(in_br);
    input.push_back(in_bl);

    // Setup Output - Target
    CGFloat maxWidth = rect.boundingBox.size.width * image.size.width;
    CGFloat maxHeight = rect.boundingBox.size.height * image.size.height;

    cv::Point2f out_tl = cv::Point2f(0, 0);
    cv::Point2f out_tr = cv::Point2f(maxWidth - 1, 0);
    cv::Point2f out_br = cv::Point2f(maxWidth - 1, maxHeight - 1);
    cv::Point2f out_bl = cv::Point2f(0, maxHeight - 1);

    std::vector<cv::Point2f> output;
    output.push_back(out_tl);
    output.push_back(out_tr);
    output.push_back(out_br);
    output.push_back(out_bl);

    cv::Mat imgMat;
    UIImageToMat(image, imgMat);

    // Warp Perspective
    cv::Mat warpedMat = cv::Mat(cvSize(maxWidth, maxHeight), CV_8UC1);
    cv::Mat perspective = cv::getPerspectiveTransform(input, output);
    cv::warpPerspective(imgMat, warpedMat, perspective, cvSize(maxWidth, maxHeight));
    cv::flip(warpedMat, warpedMat, ROTATE_90_CLOCKWISE);

    // Resize Image
    cv::resize(warpedMat, warpedMat, cvSize(maxWidth * 2, maxHeight * 2));

    // Change Image to Grayscale
    cv::Mat grayScaled;
    cv::cvtColor(warpedMat, grayScaled, cv::COLOR_BGR2GRAY);

    // Colour Binarization
    cv::Mat binarized;
    cv::adaptiveThreshold(grayScaled, binarized, 255, CV_ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY_INV, 9, 5);

    // Blur
    cv::Mat blurred;
    cv::medianBlur(binarized, blurred, 9);

    // Blend Lines Together
    cv::Mat morphed;
    cv::morphologyEx(blurred, morphed, MORPH_CLOSE, cv::getStructuringElement(MORPH_RECT, cvSize(150, 8))); // High value to find chuncks of text

    // Normal Output Image
    cv::Mat outputImg = warpedMat;

    // Find Contours
    cv::Mat contoured = morphed;
    cv::medianBlur(contoured, contoured, 11);
    vector<vector<cv::Point>> contours;
    cv::findContours(contoured, contours, -1, 2);

    // Draw Detected Boxes on Original Image
    for (int i = 0; i < contours.size(); i++) {
        cv::Rect rect = boundingRect(contours[i]);
        rect.height = rect.height + 20;
        rect.width = rect.width + 20;
        rect.x = rect.x - 10;
        rect.y = rect.y - 10;

        if ((rect.height < 20 || rect.width < 50)) { continue; }
        rectangle(outputImg, rect, Scalar(255, 0, 0), 5);
    }

    return MatToUIImage(morphed);
}
@end
