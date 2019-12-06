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

using namespace std;


+ (CVPixelBufferRef)sacleI420:(CVPixelBufferRef)pixelBuffer dstWidth:(int)dstWidth dstHeight:(int)dstHeight
{
    if (!pixelBuffer) {
        return NULL;
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    size_t pixelWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t pixelHeight = CVPixelBufferGetHeight(pixelBuffer);
    
    int width;
    int height;
    if (pixelWidth >= pixelHeight) {
        width = fmax(dstWidth, dstHeight);
        height = fmin(dstWidth, dstHeight);
    } else {
        width = fmin(dstWidth, dstHeight);
        height = fmax(dstWidth, dstHeight);
    }
    
    dstWidth = width;
    dstHeight = height;

    uint8_t *y_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    uint8_t *u_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    uint8_t *v_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2);
    
    int src_stride_y = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    int src_stride_u = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    int src_stride_v = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    
    
    //create rgb buffer
    NSDictionary *att = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey : @{}};

    CVPixelBufferRef i420Buffer;
    CVPixelBufferCreate(kCFAllocatorDefault, dstWidth, dstHeight, kCVPixelFormatType_420YpCbCr8Planar, (__bridge CFDictionaryRef _Nullable)att, &i420Buffer);

    CVPixelBufferLockBaseAddress(i420Buffer, 0);
    uint8_t *dst_y_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(i420Buffer, 0);
    uint8_t *dst_u_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(i420Buffer, 1);
    uint8_t *dst_v_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(i420Buffer, 2);

    int dst_stride_y = (int)CVPixelBufferGetBytesPerRowOfPlane(i420Buffer, 0);
    int dst_stride_u = (int)CVPixelBufferGetBytesPerRowOfPlane(i420Buffer, 1);
    int dst_stride_v = (int)CVPixelBufferGetBytesPerRowOfPlane(i420Buffer, 1);


    int cropped_src_width = fmin(pixelWidth, dstWidth * pixelHeight / dstHeight);
    int cropped_src_height = fmin(pixelHeight, dstHeight * pixelWidth / dstWidth);

    
    int src_offset_x =  ((pixelWidth - cropped_src_width) / 2) & ~1;
    int src_offset_y =  ((pixelHeight - cropped_src_height) / 2) & ~1;


    uint8_t *y_ptr = y_frame + src_offset_y * src_stride_y + src_offset_x;
    uint8_t *u_ptr = u_frame + src_offset_y / 2 * src_stride_u + src_offset_x / 2;
    uint8_t *v_ptr = v_frame + src_offset_y / 2 * src_stride_v + src_offset_x / 2;

    libyuv::I420Scale(y_ptr, src_stride_y,
                      u_ptr, src_stride_u,
                      v_ptr, src_stride_v,
                      cropped_src_width, cropped_src_height,
                      dst_y_frame, dst_stride_y,
                      dst_u_frame, dst_stride_u,
                      dst_v_frame, dst_stride_v,
                      dstWidth, dstHeight,
                      libyuv::kFilterBox);

        
    CVPixelBufferUnlockBaseAddress(i420Buffer, 0);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
          
    return (CVPixelBufferRef)CFAutorelease(i420Buffer);
}


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
    NSDictionary *att = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey : @{}};

    CVPixelBufferRef i420Buffer;
    CVPixelBufferCreate(kCFAllocatorDefault, pixelWidth, pixelHeight, kCVPixelFormatType_420YpCbCr8Planar, (__bridge CFDictionaryRef _Nullable)att, &i420Buffer);
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





+ (CVPixelBufferRef)convertToBGRAFromNv12:(CVPixelBufferRef)pixelBuffer
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
    uint8_t *abgr_data = (uint8_t *)malloc(pixelWidth * pixelHeight * 4);
    int abgr_stride = pixelWidth * 4;
    int ret = libyuv::NV12ToABGR(y_frame, src_stride_y,
                         uv_frame, src_stride_uv,
                         abgr_data, abgr_stride,
                         (int)pixelWidth, (int)pixelHeight);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVPixelBufferRelease(pixelBuffer);
    if (ret) {
        free(abgr_data);
        return NULL;
    }
    
    
    CVPixelBufferRef dstBuffer = [[PixelBufferPool sharedPool] createPixelBufferWithWidth:(int)pixelWidth height:(int)pixelHeight pixelFormat:PixelBufferFormat_BGRA];
    if (!dstBuffer) {
        //create error
        free(abgr_data);
        return NULL;
    }
    
    CVPixelBufferLockBaseAddress(dstBuffer, 0);
    

    uint8_t *dst_data = (uint8_t *)CVPixelBufferGetBaseAddress(dstBuffer);
    int dst_stride = (int)CVPixelBufferGetBytesPerRow(dstBuffer);
    
    ret = libyuv::ARGBToBGRA(abgr_data, abgr_stride,
                       dst_data, dst_stride,
                       (int)pixelWidth, (int)pixelHeight);
    CVPixelBufferUnlockBaseAddress(dstBuffer, 0);
    
    if (ret != 0) {
        free(abgr_data);
        return NULL;
    }
    
    return (CVPixelBufferRef)CFAutorelease(dstBuffer);
}




@end
