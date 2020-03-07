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


@property (nonatomic, assign) BOOL mirrored;

@property (nonatomic, assign) RotaitonType rotationType;


@end


@implementation ViewController
- (IBAction)onChangeMirrored:(UISwitch *)sender
{
    self.mirrored = sender.isOn;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.mirrored = YES;

    self.rotationType = Rotate0;

    _pixelFormat = VideoPixelFormat_YUV;

    self.recorder = [[VideoRecorder alloc] initWithPixelFormat:_pixelFormat
                                                           fps:30
                                                        preset:AVCaptureSessionPreset1280x720
                                                      delegate:self
                                                cameraPosition:AVCaptureDevicePositionFront];

    [self.recorder startRecord];
    // Do any additional setup after loading the view.
}
- (IBAction)rotateToLeft:(id)sender
{
    int degree = ((int)self.rotationType - 90 + 360) % 360;
    self.rotationType = (RotaitonType)degree;
}

- (IBAction)rotateToRight:(id)sender
{
    int degree = ((int)self.rotationType + 90) % 360;
    self.rotationType = (RotaitonType)degree;
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
        int ret = [VideoFormatConvertor convertToI420PixelBuffer:&dstBuffer nv12PixelBuffer:pixelBuffer mirrored:self.mirrored];
        if (ret != 0) {
            return;
        }

        CVPixelBufferRef rotationBuffer;
        ret = [VideoFormatConvertor rotateI420PixelBuffer:dstBuffer dstPixelBuffer:&rotationBuffer rotationType:self.rotationType];
        CVPixelBufferRelease(dstBuffer);
        if (ret != 0) {
            return;
        }
        [self.preview displayPixelBuffer:rotationBuffer];
        CVPixelBufferRelease(rotationBuffer);

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
