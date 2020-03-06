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


typedef struct {
    int width;
    int height;
    PixelBufferFormat format;
} PixelBufferPoolDesc;


typedef struct {
    PixelBufferPoolDesc poolDesc;
    int threshold;
} PixelBufferDesc;


@interface PixelBufferPool : NSObject

+ (instancetype)sharedPool;

/**
 获取pixel buffer pool , 不存在会创建一个
 */
- (CVPixelBufferPoolRef)pixelBufferPoolWithDesc:(PixelBufferPoolDesc)poolDesc;
/**
 针对创建出来的pixel buffer 需要调用CVPixelBufferRelease进行释放
 */
- (CVPixelBufferRef)createPixelBufferFromPoolWithDesc:(PixelBufferDesc)bufferDesc;

///  清空所有的pool
- (void)cleanup;
///  对所有的pool 调用 flush 方法
- (void)flush;

@end

NS_ASSUME_NONNULL_END
