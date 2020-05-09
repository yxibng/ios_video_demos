//
//  ChatController.m
//  VideoCapture
//
//  Created by yxibng on 2020/5/8.
//  Copyright © 2020 yxibng. All rights reserved.
//

#import "ChatController.h"
#import "CustomVideoSource.h"

@import DbyPaas_iOS;

@interface ChatController ()<DbyEngineDelegate>
@property (nonatomic, strong) DbyEngine *engine;
@property (nonatomic, strong) CustomVideoSource *videoSource;
@end

@implementation ChatController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.videoSource = [[CustomVideoSource alloc] init];
    
    self.engine = [DbyEngine sharedEngineWithAppId:@"2f73114f06f4483da779cb1968424625" appkey:@"47f90cb3bb2345ed9d010be3c299eca4" delegate:self];
    
    [self.engine setChannelProfile:DbyChannelProfileCommunication];
    [self.engine enableLocalAudio:YES];
    [self.engine setVideoSource:self.videoSource];
    
    for (NSString *identifier in self.videoSource.identifiers) {
        [self.engine enableLocalVideo:YES sourceIdentifier:identifier];
    }
    
    [self.engine joinChannelById:self.channelId userId:self.uid nickname:nil completeHandler:^(NSInteger errorCode) {
        NSLog(@"%s, %ld",__func__, (long)errorCode);
    }];
    // Do any additional setup after loading the view from its nib.
}

- (void)dbyEngine:(DbyEngine *)engine didJoinedOfUid:(NSString *)uid nickname:(NSString *)nickname
{
    
}

- (void)dbyEngine:(DbyEngine *)engine didLeaveChannel:(NSString *)channel withUid:(NSString *)uid {
    
}

- (void)dbyEngine:(DbyEngine *)engine firstRemoteVideoDecodedOfUid:(NSString *)uid identifier:(NSString *)identifier size:(CGSize)size {
    
}

- (void)dbyEngine:(DbyEngine *)engine remoteVideoStateChangedOfUid:(NSString *)uid identifier:(NSString *)identifier state:(BOOL)enabled {
    
}




@end
