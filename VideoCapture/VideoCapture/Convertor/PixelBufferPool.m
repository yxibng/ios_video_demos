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
@property (nonatomic, strong) NSMutableDictionary *poolMaps;
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
        _poolMaps = @{}.mutableCopy;
        _lock = [[NSLock alloc] init];
    }
    return self;
}

//need release returned CVPixelBufferRef
- (CVPixelBufferRef)createPixelBufferWithWidth:(int)width height:(int)height pixelFormat:(PixelBufferFormat)pixelFormat
{
    OSType type;
    switch (pixelFormat) {
        case PixelBufferFormat_I420:
            /*
             kCVPixelFormatType_420YpCbCr8PlanarFullRange 在 iOS13上面有问题
             */
            type = kCVPixelFormatType_420YpCbCr8Planar;
            break;
        case PixelBufferFormat_BGRA:
            type = kCVPixelFormatType_32BGRA;
            break;
        case PixelBufferFormat_NV12:
            type = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
            break;
    }
    return [self _createPixelBufferWithWidth:width height:height pixelFormat:type];
}


//need release returned CVPixelBufferRef
- (CVPixelBufferRef)_createPixelBufferWithWidth:(int)width height:(int)height pixelFormat:(OSType)pixelFormat
{
    //get pool
    CVPixelBufferPoolRef pool = [self getPoolWithWidth:width height:height pixelFormat:pixelFormat];
    if (!pool) {
        return NULL;
    }
    
    //create pixel buffer from pool
    CVPixelBufferRef pixelBuffer = nil;
    CVReturn status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer);
    if (status != kCVReturnSuccess) {
        return NULL;
    }
    return pixelBuffer;
}


- (CVPixelBufferPoolRef)getPoolWithWidth:(int)width height:(int)height pixelFormat:(OSType)pixelFormat
{
    
    NSString *key = [NSString stringWithFormat:@"%d_%d_%u",width,height,(unsigned int)pixelFormat];
    [self.lock lock];
    CVPixelBufferPoolRef pool = (CVPixelBufferPoolRef)CFDictionaryGetValue(self.pools, (__bridge const void *)(key));
    [self.lock unlock];
    
    if (pool) {
        [self flushPool:pool];
        return pool;
    }
    pool = [self createPixelBufferPoolWithWidth:width height:height pixelFormat:pixelFormat];
    
    if (!pool) {
        return NULL;
    }
    [self.lock lock];
    CFDictionarySetValue(self.pools, (__bridge const void *)(key), pool);
    [self.lock unlock];
    return pool;
}



// create pool
- (CVPixelBufferPoolRef)createPixelBufferPoolWithWidth:(int)width height:(int)height pixelFormat:(OSType)pixelFormat
{
    CVPixelBufferPoolRef pool = nil;
    NSDictionary *att = @{
        (NSString *)kCVPixelBufferPixelFormatTypeKey : @(pixelFormat),
        (NSString *)kCVPixelBufferWidthKey : @(width),
        (NSString *)kCVPixelBufferHeightKey : @(height),
        (NSString *)kCVPixelBufferIOSurfacePropertiesKey : @{},
    };
    
    int status = CVPixelBufferPoolCreate(kCFAllocatorDefault, (__bridge CFDictionaryRef _Nullable)att, (__bridge CFDictionaryRef _Nullable)att, &pool);
    if (status != kCVReturnSuccess) {
        return NULL;
    }
    return (CVPixelBufferPoolRef)CFAutorelease(pool);
}

// flush pool free memory
- (void)flushPool:(CVPixelBufferPoolRef)pool
{
    if (!pool) {
        return;
    }
    CVPixelBufferPoolFlush(pool, kCVPixelBufferPoolFlushExcessBuffers);
}

@end
