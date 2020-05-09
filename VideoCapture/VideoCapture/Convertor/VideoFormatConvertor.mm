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
    
    assert(result == 0);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVPixelBufferRelease(pixelBuffer);
    
    if (result != 0) {
        free(i420_y);
        free(i420_u);
        free(i420_v);
        
        NSLog(@"convertToI420Raw from nv12 pixelBuffer, error code = %d", result);
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
    
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVPixelBufferRelease(pixelBuffer);
    
    if (result != 0) {
        free(i420_y);
        free(i420_u);
        free(i420_v);
        
        NSLog(@"convertToI420Raw from rgba pixelBuffer, error code = %d", result);
        
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
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVPixelBufferRelease(pixelBuffer);
    
    CVPixelBufferUnlockBaseAddress(dstPixelBuffer, 0);
    
    if (result != 0) {
        CVPixelBufferRelease(dstPixelBuffer);
        return result;
    }
    
    *i420Buffer = dstPixelBuffer;
    return result;
}

+ (int)convertToI420PixelBuffer:(CVPixelBufferRef *)i420Buffer nv12PixelBuffer:(CVPixelBufferRef)pixelBuffer mirrored:(BOOL)mirrored
{
    if (!mirrored) {
        return [self convertToI420PixelBuffer:i420Buffer nv12PixelBuffer:pixelBuffer];
    }
    
    RawData_i420 middleData;
    
    int ret = [self convertToI420Raw:&middleData nv12PixelBuffer:pixelBuffer];
    if (ret != 0) {
        return ret;
    }
    
    PixelBufferPoolDesc poolDesc = {0};
    poolDesc.width = middleData.width;
    poolDesc.height = middleData.height;
    poolDesc.format = PixelBufferFormat_I420;
    
    PixelBufferDesc desc = {
        .poolDesc = poolDesc,
        .threshold = kPixelBufferPoolThreshold};
    
    CVPixelBufferRef dstPixelBuffer = [[PixelBufferPool sharedPool] createPixelBufferFromPoolWithDesc:desc];
    if (!dstPixelBuffer) {
        [VideoFormatConvertor freeRawI420:&middleData];
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
    
    
    int result = libyuv::I420Mirror(middleData.y_frame, middleData.stride_y,
                                    middleData.u_frame, middleData.stride_u,
                                    middleData.v_frame, middleData.stride_v,
                                    i420_y, dst_stride_y,
                                    i420_u, dst_stride_u,
                                    i420_v, dst_stride_v,
                                    middleData.width, middleData.height);
    
    CVPixelBufferUnlockBaseAddress(dstPixelBuffer, 0);
    
    if (result != 0) {
        CVPixelBufferRelease(dstPixelBuffer);
        [VideoFormatConvertor freeRawI420:&middleData];
        return result;
    }
    
    [VideoFormatConvertor freeRawI420:&middleData];
    *i420Buffer = dstPixelBuffer;
    
    return 0;
}

+ (int)rotateI420PixelBuffer:(CVPixelBufferRef)pixelBuffer dstPixelBuffer:(CVPixelBufferRef *)dstPixelBuffer rotationType:(RotaitonType)rotationType
{
    if (!pixelBuffer || !dstPixelBuffer) {
        return -1;
    }
    
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    int src_width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int src_height = (int)CVPixelBufferGetHeight(pixelBuffer);
    
    int src_stride_y = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    int src_stride_u = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    int src_stride_v = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 2);
    
    uint8_t *src_y = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    uint8_t *src_u = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    uint8_t *src_v = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2);
    
    
    //确定旋转后的宽高
    int dstWidth = (rotationType == Rotate0 || rotationType == Rotate180) ? src_width : src_height;
    int dstHeight = (rotationType == Rotate0 || rotationType == Rotate180) ? src_height : src_width;
    
    
    PixelBufferPoolDesc poolDesc = {
        .width = dstWidth,
        .height = dstHeight,
        .format = PixelBufferFormat_I420};
    
    PixelBufferDesc desc = {
        .poolDesc = poolDesc,
        .threshold = kPixelBufferPoolThreshold};
    
    CVPixelBufferRef i420Buffer = [[PixelBufferPool sharedPool] createPixelBufferFromPoolWithDesc:desc];
    assert(i420Buffer != NULL);
    if (!i420Buffer) {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return -1;
    }
    
    CVPixelBufferLockBaseAddress(i420Buffer, 0);
    
    int dst_stride_y = (int)CVPixelBufferGetBytesPerRowOfPlane(i420Buffer, 0);
    int dst_stride_u = (int)CVPixelBufferGetBytesPerRowOfPlane(i420Buffer, 1);
    int dst_stride_v = (int)CVPixelBufferGetBytesPerRowOfPlane(i420Buffer, 2);
    
    uint8_t *dst_y = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(i420Buffer, 0);
    uint8_t *dst_u = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(i420Buffer, 1);
    uint8_t *dst_v = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(i420Buffer, 2);
    
    libyuv::RotationMode mode = (libyuv::RotationMode)rotationType;
    //i420 copy
    int result = libyuv::I420Rotate(src_y, src_stride_y,
                                    src_u, src_stride_u,
                                    src_v, src_stride_v,
                                    dst_y, dst_stride_y,
                                    dst_u, dst_stride_u,
                                    dst_v, dst_stride_v,
                                    src_width, src_height,
                                    mode);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVPixelBufferUnlockBaseAddress(i420Buffer, 0);
    
    if (result != 0) {
        CVPixelBufferRelease(i420Buffer);
        return result;
    }
    
    *dstPixelBuffer = i420Buffer;
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
    
    int pixelWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int pixelHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    
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
    int dst_stride_v = (int)CVPixelBufferGetBytesPerRowOfPlane(i420Buffer, 2);
    
    
    int cropped_src_width = fmin(pixelWidth, dstWidth * pixelHeight / dstHeight);
    int cropped_src_height = fmin(pixelHeight, dstHeight * pixelWidth / dstWidth);
    
    
    //~是取反操作符, 为了让src_offset_x,src_offset_y是偶数
    /*
     例如 a = 5;  a & ~1 = 4;
     具体 a = 5, 二进制表示为 101 , 和 001(~1) 按位与
     结果为二进制 100, 十进制 = 4
     */
    
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




+ (int)scaleI420:(RawData_i420 *)i420Buffer dstI420Buffer:(RawData_i420 *)dstI420Buffer dstWidth:(int)dstWidth dstHeight:(int)dstHeight
{
    if (!i420Buffer || !dstI420Buffer) {
        return -1;
    }
    
    
    int pixelWidth = i420Buffer->width;
    int pixelHeight = i420Buffer->height;
    
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
    
    uint8_t *y_frame = i420Buffer->y_frame;
    uint8_t *u_frame = i420Buffer->u_frame;
    uint8_t *v_frame = i420Buffer->v_frame;
    
    int src_stride_y = i420Buffer->stride_y;
    int src_stride_u = i420Buffer->stride_u;
    int src_stride_v = i420Buffer->stride_v;
    
    
    RawData_i420 buffer;
    buffer.width = dstWidth;
    buffer.height = dstHeight;
    buffer.stride_y = dstWidth;
    buffer.stride_u = dstWidth / 2;
    buffer.stride_v = dstWidth / 2;
    
    buffer.y_frame = (uint8_t *)malloc(sizeof(dstWidth * dstHeight));
    buffer.u_frame = (uint8_t *)malloc(sizeof(dstWidth * dstHeight / 4));
    buffer.v_frame = (uint8_t *)malloc(sizeof(dstWidth * dstHeight / 4));
    
    
    uint8_t *dst_y_frame = buffer.y_frame;
    uint8_t *dst_u_frame = buffer.u_frame;
    uint8_t *dst_v_frame = buffer.v_frame;
    
    int dst_stride_y = buffer.stride_y;
    int dst_stride_u = buffer.stride_u;
    int dst_stride_v = buffer.stride_v;
    
    
    int cropped_src_width = fmin(pixelWidth, dstWidth * pixelHeight / dstHeight);
    int cropped_src_height = fmin(pixelHeight, dstHeight * pixelWidth / dstWidth);
    
    
    //~是取反操作符, 为了让src_offset_x,src_offset_y是偶数
    /*
     例如 a = 5;  a & ~1 = 4;
     具体 a = 5, 二进制表示为 101 , 和 001(~1) 按位与
     结果为二进制 100, 十进制 = 4
     */
    
    int src_offset_x = ((pixelWidth - cropped_src_width) / 2) & ~1;
    int src_offset_y = ((pixelHeight - cropped_src_height) / 2) & ~1;
    
    uint8_t *y_ptr = y_frame + src_offset_y * src_stride_y + src_offset_x;
    uint8_t *u_ptr = u_frame + src_offset_y / 2 * src_stride_u + src_offset_x / 2;
    uint8_t *v_ptr = v_frame + src_offset_y / 2 * src_stride_v + src_offset_x / 2;
    
    int ret =  libyuv::I420Scale(y_ptr, src_stride_y,
                                 u_ptr, src_stride_u,
                                 v_ptr, src_stride_v,
                                 cropped_src_width, cropped_src_height,
                                 dst_y_frame, dst_stride_y,
                                 dst_u_frame, dst_stride_u,
                                 dst_v_frame, dst_stride_v,
                                 dstWidth, dstHeight,
                                 libyuv::kFilterBox);
    
    if (ret != 0) {
        [self freeRawI420:&buffer];
        return ret;
    }
    
    *dstI420Buffer = buffer;
    
    return 0;
}

+ (int)rotateI420:(RawData_i420 *)i420Buffer dstI420Buffer:(RawData_i420 *)dstI420Buffer rotationType:(RotaitonType)rotationType
{
    
    
    if (!i420Buffer || dstI420Buffer) {
        return -1;
    }
    
    int src_width = i420Buffer->width;
    int src_height = i420Buffer->height;
    
    uint8_t *src_y = i420Buffer->y_frame;
    uint8_t *src_u = i420Buffer->u_frame;
    uint8_t *src_v = i420Buffer->v_frame;
    
    int src_stride_y = i420Buffer->stride_y;
    int src_stride_u = i420Buffer->stride_u;
    int src_stride_v = i420Buffer->stride_v;
    
    //确定旋转后的宽高
    int dstWidth = (rotationType == Rotate0 || rotationType == Rotate180) ? src_width : src_height;
    int dstHeight = (rotationType == Rotate0 || rotationType == Rotate180) ? src_height : src_width;
    
    
    RawData_i420 buffer;
    buffer.width = dstWidth;
    buffer.height = dstHeight;
    buffer.stride_y = dstWidth;
    buffer.stride_u = dstWidth / 2;
    buffer.stride_v = dstWidth / 2;
    
    buffer.y_frame = (uint8_t *)malloc(sizeof(dstWidth * dstHeight));
    buffer.u_frame = (uint8_t *)malloc(sizeof(dstWidth * dstHeight / 4));
    buffer.v_frame = (uint8_t *)malloc(sizeof(dstWidth * dstHeight / 4));
    
    
    uint8_t *dst_y = buffer.y_frame;
    uint8_t *dst_u = buffer.u_frame;
    uint8_t *dst_v = buffer.v_frame;
    
    int dst_stride_y = buffer.stride_y;
    int dst_stride_u = buffer.stride_u;
    int dst_stride_v = buffer.stride_v;
    
    
    libyuv::RotationMode mode = (libyuv::RotationMode)rotationType;
    //i420 copy
    int result = libyuv::I420Rotate(src_y, src_stride_y,
                                    src_u, src_stride_u,
                                    src_v, src_stride_v,
                                    dst_y, dst_stride_y,
                                    dst_u, dst_stride_u,
                                    dst_v, dst_stride_v,
                                    src_width, src_height,
                                    mode);
    
    if (result != 0) {
        [self freeRawI420:&buffer];
        return result;
    }
    
    *dstI420Buffer = buffer;
    return 0;
}

+ (int)mirrorI420:(RawData_i420 *)i420Buffer dstI420Buffer:(RawData_i420 *)dstI420Buffer
{
    
    
    if (!i420Buffer || dstI420Buffer) {
        return -1;
    }
    
    int src_width = i420Buffer->width;
    int src_height = i420Buffer->height;
    
    uint8_t *src_y = i420Buffer->y_frame;
    uint8_t *src_u = i420Buffer->u_frame;
    uint8_t *src_v = i420Buffer->v_frame;
    
    int src_stride_y = i420Buffer->stride_y;
    int src_stride_u = i420Buffer->stride_u;
    int src_stride_v = i420Buffer->stride_v;
    
    
    RawData_i420 buffer;
    buffer.width = src_width;
    buffer.height = src_height;
    buffer.stride_y = src_width;
    buffer.stride_u = src_width / 2;
    buffer.stride_v = src_width / 2;
    
    buffer.y_frame = (uint8_t *)malloc(sizeof(src_width * src_width));
    buffer.u_frame = (uint8_t *)malloc(sizeof(src_width * src_width / 4));
    buffer.v_frame = (uint8_t *)malloc(sizeof(src_width * src_width / 4));
    
    
    uint8_t *dst_y = buffer.y_frame;
    uint8_t *dst_u = buffer.u_frame;
    uint8_t *dst_v = buffer.v_frame;
    
    int dst_stride_y = buffer.stride_y;
    int dst_stride_u = buffer.stride_u;
    int dst_stride_v = buffer.stride_v;

    //i420 mirror
    int result = libyuv::I420Mirror(src_y, src_stride_y,
                                    src_u, src_stride_u,
                                    src_v, src_stride_v,
                                    dst_y, dst_stride_y,
                                    dst_u, dst_stride_u,
                                    dst_v, dst_stride_v,
                                    src_width, src_height);
    
    
    if (result != 0) {
        [self freeRawI420:&buffer];
        return result;
    }
    
    *dstI420Buffer = buffer;
    return  0;
}




@end
