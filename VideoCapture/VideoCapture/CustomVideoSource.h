//
//  CustomVideoSource.h
//  VideoCapture
//
//  Created by yxibng on 2020/5/8.
//  Copyright © 2020 yxibng. All rights reserved.
//

#import <Foundation/Foundation.h>
@import DbyPaas_iOS;

NS_ASSUME_NONNULL_BEGIN

@interface CustomVideoSource : NSObject <DbyVideoSourceProtocol>

@property (strong) id<DbyVideoFrameConsumer> consumer;

- (void)shouldStop:(NSString *)identifier;
- (void)shouldStart:(NSString *)identifier;


@property (nonatomic, copy) NSArray<NSString *> * identifiers;

@end

NS_ASSUME_NONNULL_END
