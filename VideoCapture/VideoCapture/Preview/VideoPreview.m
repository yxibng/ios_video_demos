//
//  VideoPreview.m
//  VideoCapture
//
//  Created by yxibng on 2019/10/15.
//  Copyright © 2019 yxibng. All rights reserved.
//

#import "VideoPreview.h"


@interface VideoPreview ()

@property (nonatomic, strong) AVSampleBufferDisplayLayer *displayLayer;

@end


@implementation VideoPreview

+ (Class)layerClass
{
    return [AVSampleBufferDisplayLayer class];
}

- (AVSampleBufferDisplayLayer *)displayLayer
{
    return (AVSampleBufferDisplayLayer *)self.layer;
}

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (!pixelBuffer) {
        return;
    }

    CVPixelBufferRetain(pixelBuffer);

    //不设置具体时间信息
    CMSampleTimingInfo timing = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
    //获取视频信息
    CMVideoFormatDescriptionRef videoInfo = NULL;
    OSStatus result = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
    NSParameterAssert(result == 0 && videoInfo != NULL);
    if (result != 0) {
        CVPixelBufferRelease(pixelBuffer);
        return;
    }

    CMSampleBufferRef sampleBuffer = NULL;
    result = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, videoInfo, &timing, &sampleBuffer);

    CVPixelBufferRelease(pixelBuffer);
    CFRelease(videoInfo);

    NSParameterAssert(result == 0 && sampleBuffer != NULL);
    if (result != 0) {
        return;
    }
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
    [self displaySampleBuffer:sampleBuffer];
    CFRelease(sampleBuffer);
}

- (void)displaySampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (sampleBuffer == NULL) {
        return;
    }
    CFRetain(sampleBuffer);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.displayLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
            [self.displayLayer flush];
        }
        if (!self.window) {
            //如果当前视图不再window上，就不要显示了
            CFRelease(sampleBuffer);
            return;
        }
        [self.displayLayer enqueueSampleBuffer:sampleBuffer];
        CFRelease(sampleBuffer);
    });
}


@end
