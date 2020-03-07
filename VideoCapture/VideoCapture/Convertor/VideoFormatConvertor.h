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

typedef NS_ENUM(NSUInteger, RotaitonType) {
    Rotate0 = 0,     // No rotation.
    Rotate90 = 90,   // Rotate 90 degrees clockwise.
    Rotate180 = 180, // Rotate 180 degrees.
    Rotate270 = 270, // Rotate 270 degrees clockwise.,
};

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


/// nv12 to i420 pixel buffer
/// @param i420Buffer 转换结果, 需要调用CVPixelBufferRelease进行释放
/// @param pixelBuffer 源pixelBuffer, nv12 类型
/// @param mirrored 是否是镜像模式
/// @return 0 成功, 其他失败
+ (int)convertToI420PixelBuffer:(CVPixelBufferRef *)i420Buffer nv12PixelBuffer:(CVPixelBufferRef)pixelBuffer mirrored:(BOOL)mirrored;


/// rgba to i420 pixel buffer
/// @param i420Buffer 转换结果, 需要调用CVPixelBufferRelease进行释放
/// @param pixelBuffer 源pixelBuffer, rgba 类型
/// @return 0 成功, 其他失败
+ (int)convertToI420PixelBuffer:(CVPixelBufferRef *)i420Buffer rgbaPixelBuffer:(CVPixelBufferRef)pixelBuffer;


///  旋转i420
/// @param pixelBuffer 待旋转的pixel buffer
/// @param dstPixelBuffer 旋转后的pixel buffer, 需要调用CVPixelBufferRelease进行释放
/// @param rotationType  0, 90, 180, 270
+ (int)rotateI420PixelBuffer:(CVPixelBufferRef)pixelBuffer dstPixelBuffer:(CVPixelBufferRef *)dstPixelBuffer rotationType:(RotaitonType)rotationType;


/*
 实现对 i420 的裁切和缩放.
 截取中间的一块.
 */
+ (CVPixelBufferRef)sacleI420:(CVPixelBufferRef)pixelBuffer dstWidth:(int)dstWidth dstHeight:(int)dstHeight;

@end

NS_ASSUME_NONNULL_END
