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


#define kPixelBufferPoolThreshold 50


@implementation VideoFormatConvertor

using namespace std;

+ (void)freeRawI420:(RawData_i420 *)i420Buffer
{
    if (!i420Buffer) {
        return;
    }

    if (i420Buffer->y_frame) {
        free(i420Buffer->y_frame);
        i420Buffer->y_frame = NULL;
    }

    if (i420Buffer->u_frame) {
        free(i420Buffer->u_frame);
        i420Buffer->u_frame = NULL;
    }

    if (i420Buffer->v_frame) {
        free(i420Buffer->v_frame);
        i420Buffer->v_frame = NULL;
    }
}


+ (int)convertToI420Raw:(RawData_i420 *)i420Buffer nv12PixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (!i420Buffer || !pixelBuffer) {
        return -1;
    }

    CVPixelBufferRetain(pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    int pixelWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int pixelHeight = (int)CVPixelBufferGetHeight(pixelBuffer);

    uint8_t *y_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    uint8_t *uv_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);

    int src_stride_y = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    int src_stride_uv = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);


    uint8_t *i420_y = (uint8_t *)malloc(pixelWidth * pixelHeight);
    uint8_t *i420_u = (uint8_t *)malloc(pixelWidth * pixelHeight / 4);
    uint8_t *i420_v = (uint8_t *)malloc(pixelWidth * pixelHeight / 4);

    int dst_stride_y = (int)pixelWidth;
    int dst_stride_u = (int)pixelWidth / 2;
    int dst_stride_v = (int)pixelWidth / 2;

    int result = libyuv::NV12ToI420(y_frame, src_stride_y,
                                    uv_frame, src_stride_uv,
                                    i420_y, dst_stride_y,
                                    i420_u, dst_stride_u,
                                    i420_v, dst_stride_v,
                                    pixelWidth, pixelHeight);
    NSLog(@"convertToI420Raw from nv12 pixelBuffer, error code = %d", result);
    assert(result == 0);

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVPixelBufferRelease(pixelBuffer);

    if (result != 0) {
        free(i420_y);
        free(i420_u);
        free(i420_v);
        return result;
    }

    RawData_i420 buffer = {0};
    buffer.y_frame = i420_y;
    buffer.u_frame = i420_u;
    buffer.v_frame = i420_v;

    buffer.stride_y = dst_stride_y;
    buffer.stride_u = dst_stride_u;
    buffer.stride_v = dst_stride_v;

    buffer.width = pixelWidth;
    buffer.height = pixelHeight;

    *i420Buffer = buffer;
    return result;
}


+ (int)convertToI420Raw:(RawData_i420 *)i420Buffer rgbaPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (!i420Buffer || !pixelBuffer) {
        return -1;
    }

    CVPixelBufferRetain(pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    int pixelWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int pixelHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    uint8_t *src_bgra = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer);
    int src_stride_bgra = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);

    uint8_t *i420_y = (uint8_t *)malloc(pixelWidth * pixelHeight);
    uint8_t *i420_u = (uint8_t *)malloc(pixelWidth * pixelHeight / 4);
    uint8_t *i420_v = (uint8_t *)malloc(pixelWidth * pixelHeight / 4);

    int dst_stride_y = pixelWidth;
    int dst_stride_u = pixelWidth / 2;
    int dst_stride_v = pixelWidth / 2;

    int result = libyuv::BGRAToI420(src_bgra, src_stride_bgra,
                                    i420_y, dst_stride_y,
                                    i420_u, dst_stride_u,
                                    i420_v, dst_stride_v,
                                    pixelWidth, pixelHeight);

    assert(result == 0);
    NSLog(@"convertToI420Raw from rgba pixelBuffer, error code = %d", result);

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVPixelBufferRelease(pixelBuffer);

    if (result != 0) {
        free(i420_y);
        free(i420_u);
        free(i420_v);

        return result;
    }

    RawData_i420 buffer = {0};
    buffer.y_frame = i420_y;
    buffer.u_frame = i420_u;
    buffer.v_frame = i420_v;

    buffer.stride_y = dst_stride_y;
    buffer.stride_u = dst_stride_u;
    buffer.stride_v = dst_stride_v;

    buffer.width = pixelWidth;
    buffer.height = pixelHeight;

    *i420Buffer = buffer;
    return result;
}

+ (int)convertToI420PixelBuffer:(CVPixelBufferRef *)i420Buffer nv12PixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (!i420Buffer || !pixelBuffer) {
        return -1;
    }
    CVPixelBufferRetain(pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    int pixelWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int pixelHeight = (int)CVPixelBufferGetHeight(pixelBuffer);

    uint8_t *y_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    uint8_t *uv_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);

    int src_stride_y = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    int src_stride_uv = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);


    PixelBufferPoolDesc poolDesc = {0};
    poolDesc.width = pixelWidth;
    poolDesc.height = pixelHeight;
    poolDesc.format = PixelBufferFormat_I420;

    PixelBufferDesc desc = {
        .poolDesc = poolDesc,
        .threshold = kPixelBufferPoolThreshold};

    CVPixelBufferRef dstPixelBuffer = [[PixelBufferPool sharedPool] createPixelBufferFromPoolWithDesc:desc];
    if (!dstPixelBuffer) {
        CVPixelBufferUnlockBaseAddress(dstPixelBuffer, 0);
        CVPixelBufferRelease(dstPixelBuffer);
        return -1;
    }


    CVPixelBufferLockBaseAddress(dstPixelBuffer, 0);
    //kCVPixelFormatType_420YpCbCr8Planar 是三平面
    int dst_stride_y = (int)CVPixelBufferGetBytesPerRowOfPlane(dstPixelBuffer, 0);
    int dst_stride_u = (int)CVPixelBufferGetBytesPerRowOfPlane(dstPixelBuffer, 1);
    int dst_stride_v = (int)CVPixelBufferGetBytesPerRowOfPlane(dstPixelBuffer, 2);

    uint8_t *i420_y = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(dstPixelBuffer, 0);
    uint8_t *i420_u = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(dstPixelBuffer, 1);
    uint8_t *i420_v = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(dstPixelBuffer, 2);


    int result = libyuv::NV12ToI420(y_frame, src_stride_y,
                                    uv_frame, src_stride_uv,
                                    i420_y, dst_stride_y,
                                    i420_u, dst_stride_u,
                                    i420_v, dst_stride_v,
                                    (int)pixelWidth, (int)pixelHeight);

    if (result != 0) {
        CVPixelBufferUnlockBaseAddress(dstPixelBuffer, 0);
        CVPixelBufferRelease(dstPixelBuffer);

        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        CVPixelBufferRelease(pixelBuffer);

        return result;
    }

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVPixelBufferRelease(pixelBuffer);

    CVPixelBufferUnlockBaseAddress(dstPixelBuffer, 0);

    *i420Buffer = dstPixelBuffer;
    return result;
}

+ (int)convertToI420PixelBuffer:(CVPixelBufferRef *)i420Buffer rgbaPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (!i420Buffer || !pixelBuffer) {
        return -1;
    }
    CVPixelBufferRetain(pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    int pixelWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int pixelHeight = (int)CVPixelBufferGetHeight(pixelBuffer);

    uint8_t *frame = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer);
    int src_stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);

    PixelBufferPoolDesc poolDesc = {0};
    poolDesc.width = pixelWidth;
    poolDesc.height = pixelHeight;
    poolDesc.format = PixelBufferFormat_I420;

    PixelBufferDesc desc = {
        .poolDesc = poolDesc,
        .threshold = kPixelBufferPoolThreshold};

    CVPixelBufferRef dstPixelBuffer = [[PixelBufferPool sharedPool] createPixelBufferFromPoolWithDesc:desc];
    if (!dstPixelBuffer) {
        CVPixelBufferUnlockBaseAddress(dstPixelBuffer, 0);
        CVPixelBufferRelease(dstPixelBuffer);
        return -1;
    }


    CVPixelBufferLockBaseAddress(dstPixelBuffer, 0);
    //kCVPixelFormatType_420YpCbCr8Planar 是三平面
    int dst_stride_y = (int)CVPixelBufferGetBytesPerRowOfPlane(dstPixelBuffer, 0);
    int dst_stride_u = (int)CVPixelBufferGetBytesPerRowOfPlane(dstPixelBuffer, 1);
    int dst_stride_v = (int)CVPixelBufferGetBytesPerRowOfPlane(dstPixelBuffer, 2);

    uint8_t *i420_y = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(dstPixelBuffer, 0);
    uint8_t *i420_u = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(dstPixelBuffer, 1);
    uint8_t *i420_v = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(dstPixelBuffer, 2);


    int result = libyuv::ARGBToI420(frame, src_stride,
                                    i420_y, dst_stride_y,
                                    i420_u, dst_stride_u,
                                    i420_v, dst_stride_v,
                                    pixelWidth, pixelHeight);

    if (result != 0) {
        CVPixelBufferUnlockBaseAddress(dstPixelBuffer, 0);
        CVPixelBufferRelease(dstPixelBuffer);

        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        CVPixelBufferRelease(pixelBuffer);
        return result;
    }

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVPixelBufferRelease(pixelBuffer);

    CVPixelBufferUnlockBaseAddress(dstPixelBuffer, 0);

    *i420Buffer = dstPixelBuffer;
    return result;
}


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
    NSDictionary *att = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey : @{} };

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


    int src_offset_x = ((pixelWidth - cropped_src_width) / 2) & ~1;
    int src_offset_y = ((pixelHeight - cropped_src_height) / 2) & ~1;


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


//+ (CVPixelBufferRef)convertToI420FromNv12:(CVPixelBufferRef)pixelBuffer
//{
//    if (!pixelBuffer) {
//        return NULL;
//    }
//    CVPixelBufferRetain(pixelBuffer);
//    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
//
//    size_t pixelWidth = CVPixelBufferGetWidth(pixelBuffer);
//    size_t pixelHeight = CVPixelBufferGetHeight(pixelBuffer);
//
//    uint8_t *y_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
//    uint8_t *uv_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
//
//    int src_stride_y = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
//    int src_stride_uv = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
//
//
//    //create i420 buffer
//    NSDictionary *att = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey : @{}};
//
//    CVPixelBufferRef i420Buffer;
//    CVPixelBufferCreate(kCFAllocatorDefault, pixelWidth, pixelHeight, kCVPixelFormatType_420YpCbCr8Planar, (__bridge CFDictionaryRef _Nullable)att, &i420Buffer);
//    if (!i420Buffer) {
//        //create error
//        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
//        CVPixelBufferRelease(pixelBuffer);
//        return NULL;
//    }
//
//    CVPixelBufferLockBaseAddress(i420Buffer, 0);
//    //kCVPixelFormatType_420YpCbCr8Planar 是三平面
//    int dst_stride_y = (int)CVPixelBufferGetBytesPerRowOfPlane(i420Buffer, 0);
//    int dst_stride_u = (int)CVPixelBufferGetBytesPerRowOfPlane(i420Buffer, 1);
//    int dst_stride_v = (int)CVPixelBufferGetBytesPerRowOfPlane(i420Buffer, 2);
//
//    uint8_t *i420_y = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(i420Buffer, 0);
//    uint8_t *i420_u = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(i420Buffer, 1);
//    uint8_t *i420_v = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(i420Buffer, 2);
//
//
//    int ret = libyuv::NV12ToI420(y_frame, src_stride_y,
//                         uv_frame, src_stride_uv,
//                         i420_y, dst_stride_y,
//                         i420_u, dst_stride_u,
//                         i420_v, dst_stride_v,
//                         (int)pixelWidth, (int)pixelHeight);
//
//    if (ret != 0) {
//        CVPixelBufferUnlockBaseAddress(i420Buffer, 0);
//        CVPixelBufferRelease(i420Buffer);
//
//        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
//        CVPixelBufferRelease(pixelBuffer);
//        return NULL;
//    }
//
//
//    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
//    CVPixelBufferRelease(pixelBuffer);
//
//    CVPixelBufferUnlockBaseAddress(i420Buffer, 0);
//    return (CVPixelBufferRef)CFAutorelease(i420Buffer);
//}
//
//
//
//+ (CVPixelBufferRef)convertToNv12FromI420:(CVPixelBufferRef)pixelBuffer
//{
//    if (!pixelBuffer) {
//        return NULL;
//    }
//    CVPixelBufferRetain(pixelBuffer);
//    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
//
//    size_t pixelWidth = CVPixelBufferGetWidth(pixelBuffer);
//    size_t pixelHeight = CVPixelBufferGetHeight(pixelBuffer);
//
//    uint8_t *y_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
//    uint8_t *u_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
//    uint8_t *v_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2);
//
//    int src_stride_y = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
//    int src_stride_u = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
//    int src_stride_v = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 2);
//
//    //create rgb buffer
//    NSDictionary *att = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey : @{}};
//
//    CVPixelBufferRef nv12Buffer;
//    CVPixelBufferCreate(kCFAllocatorDefault, pixelWidth, pixelHeight, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, (__bridge CFDictionaryRef _Nullable)att, &nv12Buffer);
//    if (!nv12Buffer) {
//        //create error
//        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
//        CVPixelBufferRelease(pixelBuffer);
//        return NULL;
//    }
//
//    CVPixelBufferLockBaseAddress(nv12Buffer, 0);
//
//    int dst_stride_y = (int)CVPixelBufferGetBytesPerRowOfPlane(nv12Buffer, 0);
//    int dst_stride_uv = (int)CVPixelBufferGetBytesPerRowOfPlane(nv12Buffer, 1);
//
//    uint8_t *dst_y = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(nv12Buffer, 0);
//    uint8_t *dst_uv = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(nv12Buffer, 1);
//
//
//
//    int ret = libyuv::I420ToNV12(y_frame, src_stride_y,
//                                 u_frame, src_stride_u,
//                                 v_frame, src_stride_v,
//                                 dst_y, dst_stride_y,
//                                 dst_uv, dst_stride_uv,
//                                 pixelWidth, pixelHeight);
//
//    if (ret != 0) {
//        CVPixelBufferUnlockBaseAddress(nv12Buffer, 0);
//        CVPixelBufferRelease(nv12Buffer);
//
//        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
//        CVPixelBufferRelease(pixelBuffer);
//        return NULL;
//    }
//
//
//    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
//    CVPixelBufferRelease(pixelBuffer);
//
//    CVPixelBufferUnlockBaseAddress(nv12Buffer, 0);
//    return (CVPixelBufferRef)CFAutorelease(nv12Buffer);
//}
//
//
//
//+ (CVPixelBufferRef)convertToBGRAFromNv12:(CVPixelBufferRef)pixelBuffer
//{
//    if (!pixelBuffer) {
//        return NULL;
//    }
//    CVPixelBufferRetain(pixelBuffer);
//    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
//
//    size_t pixelWidth = CVPixelBufferGetWidth(pixelBuffer);
//    size_t pixelHeight = CVPixelBufferGetHeight(pixelBuffer);
//    uint8_t *y_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
//    uint8_t *uv_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
//    int src_stride_y = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
//    int src_stride_uv = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
//
//
//    //create rgb buffer
//    uint8_t *abgr_data = (uint8_t *)malloc(pixelWidth * pixelHeight * 4);
//    int abgr_stride = pixelWidth * 4;
//    int ret = libyuv::NV12ToABGR(y_frame, src_stride_y,
//                         uv_frame, src_stride_uv,
//                         abgr_data, abgr_stride,
//                         (int)pixelWidth, (int)pixelHeight);
//    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
//    CVPixelBufferRelease(pixelBuffer);
//    if (ret) {
//        free(abgr_data);
//        return NULL;
//    }
//
//
//    CVPixelBufferRef dstBuffer = [[PixelBufferPool sharedPool] createPixelBufferWithWidth:(int)pixelWidth height:(int)pixelHeight pixelFormat:PixelBufferFormat_BGRA];
//    if (!dstBuffer) {
//        //create error
//        free(abgr_data);
//        return NULL;
//    }
//
//    CVPixelBufferLockBaseAddress(dstBuffer, 0);
//
//
//    uint8_t *dst_data = (uint8_t *)CVPixelBufferGetBaseAddress(dstBuffer);
//    int dst_stride = (int)CVPixelBufferGetBytesPerRow(dstBuffer);
//
//    ret = libyuv::ARGBToBGRA(abgr_data, abgr_stride,
//                       dst_data, dst_stride,
//                       (int)pixelWidth, (int)pixelHeight);
//    CVPixelBufferUnlockBaseAddress(dstBuffer, 0);
//
//    if (ret != 0) {
//        free(abgr_data);
//        return NULL;
//    }
//
//    return (CVPixelBufferRef)CFAutorelease(dstBuffer);
//}
//
//
//
//+ (CVPixelBufferRef)convertToNV12PixelBufferWithI420Buffer:(I420Buffer)i420Buffer
//{
//    if (!i420Buffer.y_frame) {
//        return NULL;
//    }
//
//    //create rgb buffer
//    NSDictionary *att = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey : @{}};
//
//    CVPixelBufferRef nv12Buffer;
//    CVPixelBufferCreate(kCFAllocatorDefault, i420Buffer.width, i420Buffer.height, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, (__bridge CFDictionaryRef _Nullable)att, &nv12Buffer);
//    if (!nv12Buffer) {
//        //create error
//        NSLog(@"%s, create error,  line = %d", __func__, __LINE__);
//        return NULL;
//    }
//
//    CVPixelBufferLockBaseAddress(nv12Buffer, 0);
//
//    int dst_stride_y      = (int)CVPixelBufferGetBytesPerRowOfPlane(nv12Buffer, 0);
//    int dst_stride_uv     = (int)CVPixelBufferGetBytesPerRowOfPlane(nv12Buffer, 1);
//
//    uint8_t *dst_y        = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(nv12Buffer, 0);
//    uint8_t *dst_uv       = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(nv12Buffer, 1);
//
//    int ret               = libyuv::I420ToNV12(i420Buffer.y_frame, i420Buffer.stride_y,
//                                 i420Buffer.u_frame, i420Buffer.stride_u,
//                                 i420Buffer.v_frame, i420Buffer.stride_v,
//                                 dst_y, dst_stride_y,
//                                 dst_uv, dst_stride_uv,
//                                 i420Buffer.width, i420Buffer.height);
//    assert(ret == 0);
//
//    CVPixelBufferUnlockBaseAddress(nv12Buffer, 0);
//    return (CVPixelBufferRef)CFAutorelease(nv12Buffer);
//}
//
//+ (CVPixelBufferRef)convertToBGRAPixelBufferWithI420Buffer:(I420Buffer)i420Buffer
//{
//    if (!i420Buffer.y_frame) {
//        return NULL;
//    }
//
//    //create rgb buffer
//    NSDictionary *att = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey : @{}};
//
//    CVPixelBufferRef bgraBuffer;
//    CVPixelBufferCreate(kCFAllocatorDefault,
//                        (size_t)i420Buffer.width,
//                        (size_t)i420Buffer.height,
//                        kCVPixelFormatType_32BGRA,
//                        (__bridge CFDictionaryRef _Nullable)att,
//                        &bgraBuffer);
//    if (!bgraBuffer) {
//        //create error
//        NSLog(@"%s, create error,  line = %d", __func__, __LINE__);
//        return NULL;
//    }
//
//    CVPixelBufferLockBaseAddress(bgraBuffer, 0);
//
//    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(bgraBuffer);
//    int bytesPerRow = (int)CVPixelBufferGetBytesPerRow(bgraBuffer);
//
//    int ret =  libyuv::I420ToARGB(i420Buffer.y_frame, i420Buffer.stride_y,
//                       i420Buffer.u_frame, i420Buffer.stride_u,
//                       i420Buffer.v_frame, i420Buffer.stride_v,
//                       baseAddress, bytesPerRow,
//                       i420Buffer.width, i420Buffer.height);
//
//    assert(ret == 0);
//    CVPixelBufferUnlockBaseAddress(bgraBuffer, 0);
//    return (CVPixelBufferRef)CFAutorelease(bgraBuffer);
//}
//
//
//
//
//
//+ (void)convertToI420Buffer:(I420Buffer *)i420Buffer nv12PixelBuffer:(CVPixelBufferRef)pixelBuffer
//{
//    if (!i420Buffer || !pixelBuffer) {
//        return;
//    }
//
//    CVPixelBufferRetain(pixelBuffer);
//    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
//
//    size_t pixelWidth = CVPixelBufferGetWidth(pixelBuffer);
//    size_t pixelHeight = CVPixelBufferGetHeight(pixelBuffer);
//
//    uint8_t *y_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
//    uint8_t *uv_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
//    int src_stride_y = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
//    int src_stride_uv = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
//
//
//    uint8_t *i420_y = (uint8_t *)malloc(pixelWidth * pixelHeight * 1.5);
//    uint8_t *i420_u = i420_y + pixelWidth * pixelHeight;
//    uint8_t *i420_v = i420_u + pixelWidth * pixelHeight / 4;
//
//    int dst_stride_y = (int)pixelWidth;
//    int dst_stride_u = (int)pixelWidth / 2;
//    int dst_stride_v = (int)pixelWidth / 2;
//
//
//   int ret = libyuv::NV12ToI420(y_frame,src_stride_y,
//                       uv_frame, src_stride_uv,
//                       i420_y, dst_stride_y,
//                       i420_u, dst_stride_u,
//                       i420_v, dst_stride_v,
//                       (int)pixelWidth, (int)pixelHeight);
//
//    assert(ret == 0);
//
//    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
//    CVPixelBufferRelease(pixelBuffer);
//
//    I420Buffer buffer = {0};
//    buffer.y_frame = i420_y;
//    buffer.u_frame = i420_u;
//    buffer.v_frame = i420_v;
//
//    buffer.stride_y = dst_stride_y;
//    buffer.stride_u = dst_stride_u;
//    buffer.stride_v = dst_stride_v;
//
//    buffer.width = pixelWidth;
//    buffer.height = pixelHeight;
//
//    *i420Buffer = buffer;
//}
//
//
//+ (void)convertToI420Buffer:(I420Buffer *)i420Buffer bgraPixelBuffer:(CVPixelBufferRef)pixelBuffer
//{
//    if (!i420Buffer || !pixelBuffer) {
//        return;
//    }
//
//    CVPixelBufferRetain(pixelBuffer);
//    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
//
//    size_t pixelWidth = CVPixelBufferGetWidth(pixelBuffer);
//    size_t pixelHeight = CVPixelBufferGetHeight(pixelBuffer);
//    uint8_t *src_bgra = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer);
//    int src_stride_bgra = CVPixelBufferGetBytesPerRow(pixelBuffer);
//
//
//    uint8_t *i420_y = (uint8_t *)malloc(pixelWidth * pixelHeight * 1.5);
//    uint8_t *i420_u = i420_y + pixelWidth * pixelHeight;
//    uint8_t *i420_v = i420_u + pixelWidth * pixelHeight / 4;
//
//    int dst_stride_y = pixelWidth;
//    int dst_stride_u = pixelWidth / 2;
//    int dst_stride_v = pixelWidth / 2;
//
//    int ret = libyuv::BGRAToI420(src_bgra, src_stride_bgra,
//                       i420_y, dst_stride_y,
//                       i420_u, dst_stride_u,
//                       i420_v, dst_stride_v,
//                       pixelWidth, pixelHeight);
//
//    assert(ret == 0);
//
//    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
//    CVPixelBufferRelease(pixelBuffer);
//
//    I420Buffer buffer = {0};
//    buffer.y_frame = i420_y;
//    buffer.u_frame = i420_u;
//    buffer.v_frame = i420_v;
//
//    buffer.stride_y = dst_stride_y;
//    buffer.stride_u = dst_stride_u;
//    buffer.stride_v = dst_stride_v;
//
//    buffer.width = pixelWidth;
//    buffer.height = pixelHeight;
//
//    *i420Buffer = buffer;
//}
//
//


@end
