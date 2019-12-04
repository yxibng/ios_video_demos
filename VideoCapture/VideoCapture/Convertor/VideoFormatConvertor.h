//
//  VideoFormatConvertor.h
//  VideoCapture
//
//  Created by yxibng on 2019/10/15.
//  Copyright © 2019 yxibng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoFormatConvertor : NSObject

+ (CVPixelBufferRef)convertToI420FromNv12:(CVPixelBufferRef)pixelBuffer;

+ (CVPixelBufferRef)convertToBGRAFromNv12:(CVPixelBufferRef)pixelBuffer;

+ (CVPixelBufferRef)sacleI420:(CVPixelBufferRef)pixelBuffer dstWidth:(int)dstWidth dstHeight:(int)dstHeight;
@end

NS_ASSUME_NONNULL_END
