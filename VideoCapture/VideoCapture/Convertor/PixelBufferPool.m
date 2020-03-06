//
//  PixelBufferPool.m
//  VideoCapture
//
//  Created by yxibng on 2019/10/15.
//  Copyright © 2019 yxibng. All rights reserved.
//

#import "PixelBufferPool.h"
#include <libyuv/libyuv.h>

#define kCVPixelBufferPoolAllocationThreshold 30


@interface PixelBufferPool ()
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


- (CVPixelBufferPoolRef)pixelBufferPoolWithDesc:(PixelBufferPoolDesc)poolDesc
{
    OSType type;
    NSString *suffix;
    switch (poolDesc.format) {
        case PixelBufferFormat_I420:
            /*kCVPixelFormatType_420YpCbCr8PlanarFullRange 在iOS11上面显示不出来*/
            type = kCVPixelFormatType_420YpCbCr8Planar;
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

    NSString *key = [NSString stringWithFormat:@"%d_%d_%@", poolDesc.width, poolDesc.height, suffix];

    [self.lock lock];
    CVPixelBufferPoolRef pool = (CVPixelBufferPoolRef)CFDictionaryGetValue(self.pools, (__bridge const void *)(key));
    if (pool == NULL) {
        NSDictionary *att = @{
            (NSString *)kCVPixelBufferPixelFormatTypeKey : @(type),
            (NSString *)kCVPixelBufferWidthKey : @(poolDesc.width),
            (NSString *)kCVPixelBufferHeightKey : @(poolDesc.height),
            (NSString *)kCVPixelBufferIOSurfacePropertiesKey : @{},
        };

        int status = CVPixelBufferPoolCreate(NULL, NULL, (__bridge CFDictionaryRef _Nullable)att, &pool);
        if (status != kCVReturnSuccess) {
            [self.lock unlock];
            return NULL;
        }
        CFDictionarySetValue(self.pools, (__bridge const void *)(key), pool);
        CVPixelBufferPoolRelease(pool);
    }
    [self.lock unlock];
    return pool;
}


- (CVPixelBufferRef)createPixelBufferFromPoolWithDesc:(PixelBufferDesc)bufferDesc
{
    CVPixelBufferPoolRef pool = [self pixelBufferPoolWithDesc:bufferDesc.poolDesc];
    assert(pool != nil);
    if (!pool) {
        return NULL;
    }

    //create pixel buffer
    CVPixelBufferRef pixelBuffer = nil;
    NSDictionary *option = @{(NSString *)kCVPixelBufferPoolAllocationThresholdKey : @(bufferDesc.threshold) };
    CVReturn status = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(NULL, pool, (__bridge CFDictionaryRef _Nullable)(option), &pixelBuffer);

    if (status == kCVReturnWouldExceedAllocationThreshold) {
        CVPixelBufferPoolFlush(pool, kCVPixelBufferPoolFlushExcessBuffers);
        return NULL;
    }
    if (status != kCVReturnSuccess) {
        return NULL;
    }
    return pixelBuffer;
}


- (void)cleanup
{
    [self.lock lock];
    CFDictionaryRemoveAllValues(self.pools);
    [self.lock unlock];
}

- (void)flush
{
    [self.lock lock];
    CFDictionaryApplyFunction(self.pools, applyFunction, (__bridge void *)(self));
    [self.lock unlock];
}


void applyFunction(const void *key, const void *value, void *context)
{
    CVPixelBufferPoolRef pool = (CVPixelBufferPoolRef)value;
    CVPixelBufferPoolFlush(pool, kCVPixelBufferPoolFlushExcessBuffers);
}


@end
