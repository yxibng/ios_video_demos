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
@property (weak, nonatomic) IBOutlet UIView *videoView_1;
@property (weak, nonatomic) IBOutlet UIView *videoView_2;
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

- (void)dbyEngine:(DbyEngine *)engine didJoinChannel:(NSString *)channel withUid:(NSString *)uid nickname:(NSString *)nickname {
    NSLog(@"%s, channel = %@, uid = %@", __FUNCTION__, channel, uid);
}


- (void)dbyEngine:(DbyEngine *)engine joinWithError:(NSInteger)errorCode {
    NSLog(@"%s, errorCode = %zd", __FUNCTION__, errorCode);
}


- (void)dbyEngine:(DbyEngine *)engine didJoinedOfUid:(NSString *)uid nickname:(NSString *)nickname
{
    NSLog(@"%s, %@", __func__, uid);
}

- (void)dbyEngine:(DbyEngine *)engine didLeaveChannel:(NSString *)channel withUid:(NSString *)uid {

    NSLog(@"%s, %@", __func__, uid);

}

- (void)dbyEngine:(DbyEngine *)engine firstRemoteVideoDecodedOfUid:(NSString *)uid identifier:(NSString *)identifier size:(CGSize)size {
    NSLog(@"%s, uid = %@, identifier = %@", __func__, uid, identifier);

}

- (void)dbyEngine:(DbyEngine *)engine remoteVideoStateChangedOfUid:(NSString *)uid identifier:(NSString *)identifier state:(BOOL)enabled {
    
    NSLog(@"%s, uid = %@, identifier = %@", __func__, uid, identifier);
    
    assert(identifier != nil);
    
    if (enabled) {
        NSInteger index = [self.videoSource.identifiers indexOfObject:identifier];
        if (index == 0) {
            DbyVideoCanvas *canvas = [DbyVideoCanvas canvasWithView:self.videoView_1 uid:uid identifier:identifier];
            [self.engine setupRemoteVideo:canvas];
        } else {
            DbyVideoCanvas *canvas = [DbyVideoCanvas canvasWithView:self.videoView_2 uid:uid identifier:identifier];
            [self.engine setupRemoteVideo:canvas];
        }
        
    }
    
    
}




@end
