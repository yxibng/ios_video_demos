//
//  VideoConfig.h
//  VideoCapture
//
//  Created by yxibng on 2019/12/6.
//  Copyright © 2019 yxibng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Video Dimension

extern CGSize const VideoDimension160x120;
extern CGSize const VideoDimension320x240;
extern CGSize const VideoDimension480x360;
extern CGSize const VideoDimension640x480;
extern CGSize const VideoDimension640x360;
extern CGSize const VideoDimension960x720;
extern CGSize const VideoDimension1280x720;


@interface VideoConfig : NSObject


@end

NS_ASSUME_NONNULL_END
