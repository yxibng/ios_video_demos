//
//  PixelBufferPool.m
//  VideoCapture
//
//  Created by yxibng on 2019/10/15.
//  Copyright © 2019 yxibng. All rights reserved.
//

#import "PixelBufferPool.h"
#include <libyuv/libyuv.h>


@interface PixelBufferPool()
@property (nonatomic) CFMutableDictionaryRef pools;
@property (nonatomic) NSLock *lock;
@end



@implementation PixelBufferPool
- (void)dealloc
{
    [self.lock lock];
    if (_pools) {
        CFDictionaryRemoveAllValues(_pools);
        CFRelease(_pools);
    }
    [self.lock unlock];
}

+ (instancetype)sharedPool
{
    static PixelBufferPool *pool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pool = [PixelBufferPool new];
    });
    return pool;
}

- (instancetype)init
{
    if (self = [super init]) {
        _pools = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        _lock = [[NSLock alloc] init];
    }
    return self;
}


- (CVPixelBufferRef)pixelBufferWithWidth:(int)width height:(int)height pixelFormat:(PixelBufferFormat)pixelFormat
{
    CVPixelBufferPoolRef pixBufferPool = [self pixelBufferPoolWithWidth:width height:height pixelFormat:pixelFormat];
    if (!pixBufferPool) {
        return NULL;
    }
    //create pixel buffer
    CVPixelBufferRef pixelBuffer = nil;
    CVReturn status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixBufferPool, &pixelBuffer);
    if (status != kCVReturnSuccess) {
        return NULL;
    }
    return pixelBuffer;
}


- (CVPixelBufferPoolRef)pixelBufferPoolWithWidth:(int)width height:(int)height pixelFormat:(PixelBufferFormat)pixelFormat
{
    OSType type;
    NSString *suffix;
    switch (pixelFormat) {
        case PixelBufferFormat_I420:
            type = kCVPixelFormatType_420YpCbCr8PlanarFullRange;
            suffix = @"i420";
            break;
        case PixelBufferFormat_BGRA:
            type = kCVPixelFormatType_32BGRA;
            suffix = @"bgra";
            break;
        case PixelBufferFormat_NV12:
            type = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
            suffix = @"nv12";
            break;
    }

    NSString *key = [NSString stringWithFormat:@"%d_%d_%@", width, height, suffix];

    [self.lock lock];
    CVPixelBufferPoolRef pool = (CVPixelBufferPoolRef)CFDictionaryGetValue(self.pools, (__bridge const void *)(key));
    if (pool == NULL) {
        NSDictionary *att = @{
            (NSString *)kCVPixelBufferPixelFormatTypeKey : @(type),
            (NSString *)kCVPixelBufferWidthKey : @(width),
            (NSString *)kCVPixelBufferHeightKey : @(height),
            (NSString *)kCVPixelBufferIOSurfacePropertiesKey : @{},
        };

        int status = CVPixelBufferPoolCreate(NULL, (__bridge CFDictionaryRef _Nullable)att, (__bridge CFDictionaryRef _Nullable)att, &pool);
        if (status != kCVReturnSuccess) {
            [self.lock unlock];
            return NULL;
        }
        CFDictionarySetValue(self.pools, (__bridge const void *)(key), pool);
        CVPixelBufferPoolRelease(pool);
    }
    CVPixelBufferPoolFlush(pool, kCVPixelBufferPoolFlushExcessBuffers);
    [self.lock unlock];
    return pool;
}





@end
