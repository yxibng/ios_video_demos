//
//  LoginController.m
//  VideoCapture
//
//  Created by yxibng on 2020/5/8.
//  Copyright © 2020 yxibng. All rights reserved.
//

#import "LoginController.h"
#import "ChatController.h"

@interface LoginController ()

@property (weak, nonatomic) IBOutlet UITextField *channelTF;
@property (weak, nonatomic) IBOutlet UITextField *uidTF;

@end


@implementation LoginController

- (IBAction)join:(id)sender {
    
    NSString *channelId = self.channelTF.text;
    NSString *uid = self.uidTF.text;
    
    
    if (!channelId.length || !uid.length) {
        return;
    }
    
    
    ChatController *vc = [[ChatController alloc] init];
    vc.channelId = channelId;
    vc.uid = uid;
    [self.navigationController pushViewController:vc animated:YES];
    
}

@end
