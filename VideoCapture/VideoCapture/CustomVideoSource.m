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

@interface CustomVideoSource ()<VideoRecorderDelegate>

@property (nonatomic, strong) VideoRecorder *recorder;

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
        self.recorder = [[VideoRecorder alloc] initWithPixelFormat:format
                                                               fps:30
                                                            preset:AVCaptureSessionPreset1280x720
                                                          delegate:self
                                                    cameraPosition:AVCaptureDevicePositionFront];
        [self.recorder startRecord];
    }
    return self;
}


- (NSArray<NSString *> *)identifiers {
    return @[@"s1",@"s2"];
}


- (void)shouldStart:(NSString *)identifier
{
    NSLog(@"%s, %@",__FUNCTION__, identifier);
}

- (void)shouldStop:(NSString *)identifier
{
    NSLog(@"%s, %@",__FUNCTION__, identifier);
}

- (void)videoRecorder:(VideoRecorder *)videoRecorder didStartWithSession:(AVCaptureSession *)session
{
}

- (void)videoRecorder:(VideoRecorder *)videoRecorder didRecievePixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    for (NSString *identifier  in self.identifiers) {
        [self.consumer consumePixelBuffer:pixelBuffer sourceIdentifier:identifier];
    }
    
}




@end
