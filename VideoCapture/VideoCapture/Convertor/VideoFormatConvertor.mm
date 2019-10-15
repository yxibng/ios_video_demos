//
//  VideoFormatConvertor.m
//  VideoCapture
//
//  Created by yxibng on 2019/10/15.
//  Copyright © 2019 yxibng. All rights reserved.
//

#import "VideoFormatConvertor.h"
#include <libyuv/libyuv.h>
#import "PixelBufferPool.h"

@implementation VideoFormatConvertor

+ (CVPixelBufferRef)convertToI420FromNv12:(CVPixelBufferRef)pixelBuffer
{
    if (!pixelBuffer) {
        return NULL;
    }
    CVPixelBufferRetain(pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    size_t pixelWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t pixelHeight = CVPixelBufferGetHeight(pixelBuffer);

    uint8_t *y_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    uint8_t *uv_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);

    int src_stride_y = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    int src_stride_uv = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);


    //create rgb buffer
    CVPixelBufferRef i420Buffer = [[PixelBufferPool sharedPool] pixelBufferWithWidth:(int)pixelWidth height:(int)pixelHeight pixelFormat:PixelBufferFormat_I420];
    if (!i420Buffer) {
        //create error
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        CVPixelBufferRelease(pixelBuffer);
        return NULL;
    }

    CVPixelBufferLockBaseAddress(i420Buffer, 0);
    //kCVPixelFormatType_420YpCbCr8Planar 是三平面
    int dst_stride_y = (int)CVPixelBufferGetBytesPerRowOfPlane(i420Buffer, 0);
    int dst_stride_u = (int)CVPixelBufferGetBytesPerRowOfPlane(i420Buffer, 1);
    int dst_stride_v = (int)CVPixelBufferGetBytesPerRowOfPlane(i420Buffer, 2);
    
    uint8_t *i420_y = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(i420Buffer, 0);
    uint8_t *i420_u = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(i420Buffer, 1);
    uint8_t *i420_v = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(i420Buffer, 2);


    int ret = libyuv::NV12ToI420(y_frame, src_stride_y,
                         uv_frame, src_stride_uv,
                         i420_y, dst_stride_y,
                         i420_u, dst_stride_u,
                         i420_v, dst_stride_v,
                         (int)pixelWidth, (int)pixelHeight);

    if (ret != 0) {
        CVPixelBufferUnlockBaseAddress(i420Buffer, 0);
        CVPixelBufferRelease(i420Buffer);

        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        CVPixelBufferRelease(pixelBuffer);
        return NULL;
    }


    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVPixelBufferRelease(pixelBuffer);

    CVPixelBufferUnlockBaseAddress(i420Buffer, 0);
    return (CVPixelBufferRef)CFAutorelease(i420Buffer);
}




@end
