//
//  PixelBufferPool.h
//  VideoCapture
//
//  Created by yxibng on 2019/10/15.
//  Copyright © 2019 yxibng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PixelBufferFormat) {
    PixelBufferFormat_NV12,
    PixelBufferFormat_I420,
    PixelBufferFormat_BGRA
};


@interface PixelBufferPool : NSObject
+ (instancetype)sharedPool;

- (CVPixelBufferRef)pixelBufferWithWidth:(int)width height:(int)height pixelFormat:(PixelBufferFormat)pixelFormat;
@end

NS_ASSUME_NONNULL_END
