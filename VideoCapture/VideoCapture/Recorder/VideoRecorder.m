//
//  VideoRecorder.m
//  VideoCapture
//
//  Created by yxibng on 2019/10/15.
//  Copyright © 2019 yxibng. All rights reserved.
//

#import "VideoRecorder.h"
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, AVCamSetupResult) {
    AVCamSetupResultSuccess,
    AVCamSetupResultCameraNotAuthorized,
    AVCamSetupResultSessionConfigurationFailed
};


@interface VideoRecorder() <AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic) AVCamSetupResult setupResult;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (nonatomic, assign) AVCaptureVideoOrientation captureVideoOrientation;

@property (nonatomic) dispatch_queue_t sessionQueue;

@property (nonatomic) dispatch_queue_t sampleBufferCallbackQueue;


@end


@implementation VideoRecorder

- (instancetype)initWithPixelFormat:(VideoPixelFormat)pixelFormat
                                fps:(int32_t)fps
                             preset:(AVOutputSettingsPreset)preset
                           delegate:(nonnull id<VideoRecorderDelegate>)delegate
                     cameraPosition:(AVCaptureDevicePosition)cameraPosition
{
    if (self = [super init]) {
        
        _pixelFormat = pixelFormat;
        _fps = fps;
        _preset = preset;
        _delegate = delegate;
        _currentPosition = cameraPosition;
        
        [self setup];
    }
    return self;
}

- (void)startRecord
{
    dispatch_async(self.sessionQueue, ^{
        if (self.setupResult == AVCamSetupResultSuccess) {
            [self.session startRunning];
        }
    });
}

- (void)stopRecord
{
    dispatch_async(self.sessionQueue, ^{
        if (self.setupResult == AVCamSetupResultSuccess) {
            [self.session stopRunning];
        }
    });
}

- (void)switchCamera
{
    
    dispatch_async(self.sessionQueue, ^{

        AVCaptureDevice *currentVideoDevice = self.videoInput.device;
        AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
        AVCaptureDevicePosition preferredPosition;
        switch (currentPosition) {
            case AVCaptureDevicePositionFront:
                preferredPosition = AVCaptureDevicePositionBack;
                break;
            case AVCaptureDevicePositionUnspecified:
            case AVCaptureDevicePositionBack:
                preferredPosition = AVCaptureDevicePositionFront;
                break;
        }


        AVCaptureDevice *captureDevice = [self captureDeviceWitchPosition:preferredPosition];
        NSError *error;
        AVCaptureDeviceInput *nextDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];

        if (!nextDeviceInput) {
            return;
        }

        [self.session beginConfiguration];
        //remove the existing device input
        [self.session removeInput:self.videoInput];
        //add next input
        if ([self.session canAddInput:nextDeviceInput]) {
            [self.session addInput:nextDeviceInput];

            self.videoInput = nextDeviceInput;
            self.currentPosition = preferredPosition;
        } else {
            [self.session addInput:self.videoInput];
        }

        //设置帧率
        [captureDevice lockForConfiguration:NULL];
        [captureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, self.fps)];
        [captureDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, self.fps)];
        [captureDevice unlockForConfiguration];

        //设置视频的方向
        AVCaptureConnection *connect = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
        connect.videoOrientation = self.captureVideoOrientation;

        [self.session commitConfiguration];
    });
    
}

#pragma mark - delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    //回调 pixBuffer
    if ([self.delegate respondsToSelector:@selector(videoRecorder:didRecievePixelBuffer:)]) {
        [self.delegate videoRecorder:self didRecievePixelBuffer:pixelBuffer];
    }
}




- (void)setup
{
    _setupResult = AVCamSetupResultSuccess;
    _currentPosition = AVCaptureDevicePositionFront;
    _sessionQueue = dispatch_queue_create("videoRecorder.session.config.queue", DISPATCH_QUEUE_SERIAL);
    _sampleBufferCallbackQueue = dispatch_queue_create("videoRecorder.session.sampleBufferCallback.queue", DISPATCH_QUEUE_SERIAL);
    _session = [[AVCaptureSession alloc] init];

     
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterruptionEnd:) name:AVCaptureSessionInterruptionEndedNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarOrientationDidChange:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    
    
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized: {
            break;
        }
        case AVAuthorizationStatusNotDetermined: {
            dispatch_suspend(self.sessionQueue);
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (!granted) {
                    self.setupResult = AVCamSetupResultCameraNotAuthorized;
                }
                dispatch_resume(self.sessionQueue);
            }];
            break;
        }
        default: {
            // The user has previously denied access.
            self.setupResult = AVCamSetupResultCameraNotAuthorized;
            break;
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.captureVideoOrientation = [self videoOrientation];
        dispatch_async(self.sessionQueue, ^{
            [self configureSession];
        });
    });
}

#pragma mark - config

// Call this on the session queue.
- (void)configureSession
{
    if (self.setupResult != AVCamSetupResultSuccess) {
        return;
    }

    [self.session beginConfiguration];
    //设置分辨率
    AVCaptureSessionPreset preset = self.preset;
    if ([self.session canSetSessionPreset:preset]) {
        self.session.sessionPreset = preset;
    }
    // find video input device
    NSError *error = nil;
    AVCaptureDevice *captureDevice = [self captureDeviceWitchPosition:self.currentPosition];
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!videoDeviceInput) {
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.session commitConfiguration];
        return;
    }

    //add video input device
    if ([self.session canAddInput:videoDeviceInput]) {
        [self.session addInput:videoDeviceInput];
        self.videoInput = videoDeviceInput;
    } else {
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.session commitConfiguration];
        return;
    }

    //设置帧率
    [captureDevice lockForConfiguration:NULL];
    [captureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, self.fps)];
    [captureDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, self.fps)];
    [captureDevice unlockForConfiguration];

    
    OSType type;
    if (self.pixelFormat == VideoPixelFormat_YUV) {
        type = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    } else {
        type = kCVPixelFormatType_32BGRA;
    }
    
    //add video data output
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:type], kCVPixelBufferPixelFormatTypeKey, nil];
    output.videoSettings = settings;

    if ([self.session canAddOutput:output]) {
        [self.session addOutput:output];
        [output setSampleBufferDelegate:self queue:self.sampleBufferCallbackQueue];
        self.videoOutput = output;
    } else {
        self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        [self.session commitConfiguration];
        return;
    }
    //设置视频的方向
    AVCaptureConnection *connect = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    connect.videoOrientation = self.captureVideoOrientation;
    self.setupResult = AVCamSetupResultSuccess;
    [self.session commitConfiguration];
}


- (void)setFps:(int32_t)fps
{
    _fps = fps;
    
    if (fps > 30) {
        return;
    }
    
    dispatch_async(self.sessionQueue, ^{
        AVCaptureDevice *captureDevice = [self captureDeviceWitchPosition:self.currentPosition];
        //设置帧率
        [captureDevice lockForConfiguration:NULL];
        [captureDevice setActiveVideoMinFrameDuration:CMTimeMake(1, self.fps)];
        [captureDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, self.fps)];
        [captureDevice unlockForConfiguration];
    });
    
}


#pragma mark - Notification
- (void)sessionWasInterrupted:(NSNotification *)notification
{
    NSLog(@"--------sessionWaInterrupted,%@", notification);
}

- (void)sessionInterruptionEnd:(NSNotification *)notification
{
    NSLog(@"--------sessionInterruptionEnd,%@", notification);
    [self startRecord];
}

- (void)sessionRuntimeError:(NSNotification *)notification
{
    NSLog(@"--------sessionRuntimeError,%@", notification);
}

- (void)statusBarOrientationDidChange:(NSNotification *)notification
{
    AVCaptureConnection *connection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    dispatch_async(dispatch_get_main_queue(), ^{
        AVCaptureVideoOrientation orientation = [self videoOrientation];
        self.captureVideoOrientation = orientation;
        if (connection.videoOrientation != orientation) {
            connection.videoOrientation = orientation;
        }
    });
}


- (AVCaptureDevice *)captureDeviceWitchPosition:(AVCaptureDevicePosition)position
{
    AVCaptureDevice *videoDevice;

    if (@available(iOS 11.1, *)) {
        NSArray<AVCaptureDeviceType> *deviceTypes = @[ AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInDualCamera, AVCaptureDeviceTypeBuiltInTrueDepthCamera ];
        AVCaptureDeviceDiscoverySession *session = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes mediaType:AVMediaTypeVideo position:position];
        for (AVCaptureDevice *device in session.devices) {
            if (device.position == position) {
                videoDevice = device;
            }
        }
    } else if (@available(iOS 10.0, *)) {
        videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:position];
    } else {
        NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in cameras) {
            if (device.position == position) {
                videoDevice = device;
            }
        }
    }

    return videoDevice;
}

- (AVCaptureVideoOrientation)videoOrientation
{
    UIInterfaceOrientation statusBarOrientation = UIApplication.sharedApplication.statusBarOrientation;

    if (statusBarOrientation == UIInterfaceOrientationUnknown) {
        return AVCaptureVideoOrientationPortrait;
    }
    return (AVCaptureVideoOrientation)statusBarOrientation;
}





@end
