//
//  ViewController.m
//  VideoCapture
//
//  Created by yxibng on 2019/10/15.
//  Copyright © 2019 yxibng. All rights reserved.
//

#import "ViewController.h"
#import "VideoPreview.h"
#import "VideoFormatConvertor.h"
#import "VideoRecorder.h"

@interface ViewController ()<VideoRecorderDelegate>
@property (weak, nonatomic) IBOutlet VideoPreview *preview;
@property (nonatomic, strong) VideoRecorder *recorder;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.recorder = [[VideoRecorder alloc] initWithPixelFormat:VideoPixelFormat_YUV fps:15 preset:AVOutputSettingsPreset640x480 delegate:self cameraPosition:AVCaptureDevicePositionFront];
    [self.recorder startRecord];
    // Do any additional setup after loading the view.
}


- (void)videoRecorder:(VideoRecorder *)videoRecorder didStartWithSession:(AVCaptureSession *)session
{
    
}

- (void)videoRecorder:(VideoRecorder *)videoRecorder didRecievePixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    //nv12
//    [self showNV12:pixelBuffer];
    
    //i420
    [self showI420:pixelBuffer];
    
    
    //bgra
    //[self showBGRA:pixelBuffer];
}

- (void)showNV12:(CVPixelBufferRef)pixelBuffer
{
    if (!pixelBuffer) {
        return;
    }
    
    CVPixelBufferRetain(pixelBuffer);
    [self.preview displayPixelBuffer:pixelBuffer];
    CVBufferRelease(pixelBuffer);
}

- (void)showI420:(CVPixelBufferRef)pixelBuffer
{
    if (!pixelBuffer) {
        return;
    }
    CVPixelBufferRetain(pixelBuffer);
    
    CVPixelBufferRef i420Buffer = [VideoFormatConvertor convertToI420FromNv12:pixelBuffer];
    if (i420Buffer) {
        CVPixelBufferRetain(i420Buffer);
        [self.preview displayPixelBuffer:i420Buffer];
        CVPixelBufferRelease(i420Buffer);
    }
    
    CVBufferRelease(pixelBuffer);
}

- (void)showBGRA:(CVPixelBufferRef)pixelBuffer
{
    if (!pixelBuffer) {
        return;
    }
    CVPixelBufferRetain(pixelBuffer);
    
    CVPixelBufferRef rgbBuffer = [VideoFormatConvertor convertToBGRAFromNv12:pixelBuffer];
    if (rgbBuffer) {
        CVPixelBufferRetain(rgbBuffer);
        [self.preview displayPixelBuffer:rgbBuffer];
        CVPixelBufferRelease(rgbBuffer);
    }
    
    CVBufferRelease(pixelBuffer);
}





@end
