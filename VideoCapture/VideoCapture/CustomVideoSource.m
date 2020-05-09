//
//  CustomVideoSource.m
//  VideoCapture
//
//  Created by yxibng on 2020/5/8.
//  Copyright © 2020 yxibng. All rights reserved.
//

#import "CustomVideoSource.h"
#import "VideoRecorder.h"
#import "VideoFormatConvertor.h"


@interface _VideoSource: NSObject
@property (nonatomic, copy) NSString *identifer;
@property (nonatomic, assign) BOOL running;

@end

@implementation _VideoSource
- (instancetype)initWithIdentifier:(NSString *)identifier {
    if (self = [super init]) {
        _identifer = identifier;
        _running = NO;
    }
    return self;
}

@end



@interface CustomVideoSource ()<VideoRecorderDelegate>

@property (nonatomic, strong) VideoRecorder *recorder;
@property (nonatomic, strong) NSDictionary< NSString *, _VideoSource *> *sources;

@end


@implementation CustomVideoSource

- (void)dealloc
{
    [self.recorder stopRecord];
}



- (instancetype)init
{
    self = [super init];
    if (self) {
        VideoPixelFormat format = VideoPixelFormat_YUV;
        _recorder = [[VideoRecorder alloc] initWithPixelFormat:format
                                                               fps:30
                                                            preset:AVCaptureSessionPreset1280x720
                                                          delegate:self
                                                    cameraPosition:AVCaptureDevicePositionFront];
        [_recorder startRecord];
        _sources = @{
            @"s1": [[_VideoSource alloc] initWithIdentifier:@"s1"],
            @"s2": [[_VideoSource alloc] initWithIdentifier:@"s2"]
            };
        
        
    }
    return self;
}

- (NSArray<NSString *> *)identifiers {
    return self.sources.allKeys;
}


- (void)shouldStart:(NSString *)identifier
{
    NSLog(@"%s, %@",__FUNCTION__, identifier);
    //可以开始推流
    
    assert(identifier != nil);
    
    _VideoSource *source = self.sources[identifier];
    source.running = YES;
    
    
    
}

- (void)shouldStop:(NSString *)identifier
{
    NSLog(@"%s, %@",__FUNCTION__, identifier);
    assert(identifier != nil);
    
    //停止推流
    _VideoSource *source = self.sources[identifier];
    source.running = NO;
    
}

- (void)videoRecorder:(VideoRecorder *)videoRecorder didStartWithSession:(AVCaptureSession *)session
{
    
}

- (void)videoRecorder:(VideoRecorder *)videoRecorder didRecievePixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    for (NSString *identifier  in self.identifiers) {
        
        _VideoSource *source = self.sources[identifier];
        
        if (!source.running) {
            //推流没有准备好，不可以推流
            continue;
        }
        
        if ([identifier isEqualToString:@"s1"]) {
            //对视频数据处理之后，推送出去
            [self processPixelBuffer:pixelBuffer identifier:identifier];
        } else {
            //直接推送 nv12 pixBuffer
            [self.consumer consumePixelBuffer:pixelBuffer sourceIdentifier:identifier];
        }
    }
    
}

- (void)processPixelBuffer:(CVPixelBufferRef)pixelBuffer identifier:(NSString *)identifier
{
    
    RawData_i420 i420Raw;
    
    int ret = [VideoFormatConvertor convertToI420Raw:&i420Raw nv12PixelBuffer:pixelBuffer];
    if (ret != 0) {
        return;
    }
    
    void *y_frame = malloc(sizeof(i420Raw.width * i420Raw.height * 1.5));
    void *u_frame = y_frame + i420Raw.width * i420Raw.height;
    void *v_frame = u_frame + i420Raw.width * i420Raw.height / 4;
    memcpy(y_frame, i420Raw.y_frame, i420Raw.width * i420Raw.height);
    memcpy(u_frame, i420Raw.u_frame, i420Raw.width * i420Raw.height /4);
    memcpy(v_frame, i420Raw.v_frame, i420Raw.width * i420Raw.height /4);
    
    [VideoFormatConvertor freeRawI420:&i420Raw];
    
    [self.consumer consumeRawData:y_frame frameSize:CGSizeMake(i420Raw.width, i420Raw.height) sourceIdentifier:identifier];
    
    free(y_frame);
    
    /*
     
     可以调用 VideoFormatConvertor 进行
     scale， rotate, mirror
     处理之后，将处理后的 buffer 发送出去
     */
}






@end
