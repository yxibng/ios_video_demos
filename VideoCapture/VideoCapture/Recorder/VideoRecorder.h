//
//  VideoRecorder.h
//  VideoCapture
//
//  Created by yxibng on 2019/10/15.
//  Copyright © 2019 yxibng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, VideoPixelFormat) {
    VideoPixelFormat_BGRA,
    VideoPixelFormat_YUV
};


@class VideoRecorder;
@protocol VideoRecorderDelegate <NSObject>
@optional
- (void)videoRecorder:(VideoRecorder *)videoRecorder didStartWithSession:(AVCaptureSession *)session;
- (void)videoRecorder:(VideoRecorder *)videoRecorder didRecievePixelBuffer:(CVPixelBufferRef)pixelBuffer;
@end


@interface VideoRecorder : NSObject

@property (nonatomic, assign) VideoPixelFormat pixelFormat;
@property (nonatomic, weak) id<VideoRecorderDelegate>delegate;
@property (nonatomic, assign) int32_t fps;
@property (nonatomic, assign) AVCaptureSessionPreset preset;
@property (nonatomic, assign) AVCaptureDevicePosition currentPosition;

- (instancetype)initWithPixelFormat:(VideoPixelFormat)pixelFormat
                                fps:(int32_t)fps
                             preset:(AVCaptureSessionPreset)preset
                           delegate:(id<VideoRecorderDelegate>)delegate
                     cameraPosition:(AVCaptureDevicePosition)cameraPosition;


- (void)startRecord;
- (void)stopRecord;
- (void)switchCamera;

@end

NS_ASSUME_NONNULL_END
