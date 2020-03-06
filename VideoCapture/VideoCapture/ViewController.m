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
#import "DBYOpenGLView.h"


@interface ViewController () <VideoRecorderDelegate>
@property (weak, nonatomic) IBOutlet VideoPreview *preview;
@property (nonatomic, strong) VideoRecorder *recorder;
@property (weak, nonatomic) IBOutlet DBYOpenGLView *openglView;

@property (nonatomic, assign) VideoPixelFormat pixelFormat;


@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _pixelFormat = VideoPixelFormat_BGRA;

    self.recorder = [[VideoRecorder alloc] initWithPixelFormat:_pixelFormat
                                                           fps:30
                                                        preset:AVCaptureSessionPreset1280x720
                                                      delegate:self
                                                cameraPosition:AVCaptureDevicePositionFront];

    [self.recorder startRecord];
    // Do any additional setup after loading the view.
}


- (void)videoRecorder:(VideoRecorder *)videoRecorder didStartWithSession:(AVCaptureSession *)session
{
}

- (void)videoRecorder:(VideoRecorder *)videoRecorder didRecievePixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    [self displayAsI420With:pixelBuffer pixelBufferType:_pixelFormat];
}

- (void)displayAsI420With:(CVPixelBufferRef)pixelBuffer pixelBufferType:(VideoPixelFormat)format
{
    if (format == VideoPixelFormat_YUV) {
        // source is nv12
        CVPixelBufferRef dstBuffer;
        int ret = [VideoFormatConvertor convertToI420PixelBuffer:&dstBuffer nv12PixelBuffer:pixelBuffer];
        if (ret != 0) {
            return;
        }
        [self.preview displayPixelBuffer:dstBuffer];
        CVPixelBufferRelease(dstBuffer);

    } else {
        // source is rgba
        CVPixelBufferRef dstBuffer;
        int ret = [VideoFormatConvertor convertToI420PixelBuffer:&dstBuffer rgbaPixelBuffer:pixelBuffer];
        if (ret != 0) {
            return;
        }
        [self.preview displayPixelBuffer:dstBuffer];
        CVPixelBufferRelease(dstBuffer);
    }
}

@end
