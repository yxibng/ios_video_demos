//
//  VideoPreview.h
//  VideoCapture
//
//  Created by yxibng on 2019/10/15.
//  Copyright © 2019 yxibng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoPreview : UIView
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;
@end




NS_ASSUME_NONNULL_END
