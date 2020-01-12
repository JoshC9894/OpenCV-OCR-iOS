//
//  OpenCVWrapper.h
//  OpenCV-iOS
//
//  Created by Joshua Colley on 22/10/2018.
//  Copyright © 2018 Joshua Colley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Vision/Vision.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject
+ (UIImage *)processImage:(UIImage *)image withDetection:(VNRectangleObservation *)rect;
@end

NS_ASSUME_NONNULL_END
