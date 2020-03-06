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

typedef struct {
    uint8_t *y_frame;
    uint8_t *u_frame;
    uint8_t *v_frame;

    int width;
    int height;

    int stride_y;
    int stride_u;
    int stride_v;
} RawData_i420;

typedef struct {
    uint8_t *y_frame;
    uint8_t *uv_frame;

    uint8_t width;
    uint8_t height;

    uint8_t stride_y;
    uint8_t stride_uv;

} RawData_nv12;

typedef struct {
    uint8_t *frame;

    uint8_t width;
    uint8_t height;
} RawData_bgra;


@interface VideoFormatConvertor : NSObject

//释放对应的y,u,v分量对应的内存空降
+ (void)freeRawI420:(RawData_i420 *)i420Buffer;

/// nv12 to i420 raw
/// @param i420Buffer 转换结果RawData_i420类型的指针,内部会为y,u,v分配内存, 使用结束,需要调用 freeRawI420 方法
/// @param pixelBuffer 源pixelBuffer
/// @return 0 成功, 其他失败
+ (int)convertToI420Raw:(RawData_i420 *)i420Buffer nv12PixelBuffer:(CVPixelBufferRef)pixelBuffer;

/// rgba to i420 raw
/// @param i420Buffer 转换结果RawData_i420类型的指针,内部会为y,u,v分配内存, 使用结束,需要调用 freeRawI420 方法
/// @param pixelBuffer 源pixelBuffer
/// @return 0 成功, 其他失败
+ (int)convertToI420Raw:(RawData_i420 *)i420Buffer rgbaPixelBuffer:(CVPixelBufferRef)pixelBuffer;

/// nv12 to i420 pixel buffer
/// @param i420Buffer 转换结果, 需要调用CVPixelBufferRelease进行释放
/// @param pixelBuffer 源pixelBuffer, nv12 类型
/// @return 0 成功, 其他失败
+ (int)convertToI420PixelBuffer:(CVPixelBufferRef *)i420Buffer nv12PixelBuffer:(CVPixelBufferRef)pixelBuffer;

/// rgba to i420 pixel buffer
/// @param i420Buffer 转换结果, 需要调用CVPixelBufferRelease进行释放
/// @param pixelBuffer 源pixelBuffer, rgba 类型
/// @return 0 成功, 其他失败
+ (int)convertToI420PixelBuffer:(CVPixelBufferRef *)i420Buffer rgbaPixelBuffer:(CVPixelBufferRef)pixelBuffer;


+ (CVPixelBufferRef)sacleI420:(CVPixelBufferRef)pixelBuffer dstWidth:(int)dstWidth dstHeight:(int)dstHeight;


//+ (void)convertToI420Buffer:(I420RawData *)i420Buffer nv12PixelBuffer:(CVPixelBufferRef)pixelBuffer;
//+ (void)convertToI420Buffer:(I420RawData *)i420Buffer bgraPixelBuffer:(CVPixelBufferRef)pixelBuffer;
//
//+ (CVPixelBufferRef)convertToNV12PixelBufferWithI420Buffer:(I420Buffer)i420Buffer;
//+ (CVPixelBufferRef)convertToBGRAPixelBufferWithI420Buffer:(I420Buffer)i420Buffer;
//
//+ (CVPixelBufferRef)convertToI420FromNv12:(CVPixelBufferRef)pixelBuffer;
//
//+ (CVPixelBufferRef)convertToBGRAFromNv12:(CVPixelBufferRef)pixelBuffer;
//
//
//
//+(CVPixelBufferRef)convertToNv12FromI420:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
