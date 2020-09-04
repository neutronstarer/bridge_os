//
//  BridgeosOperation.h
//  Bridge
//
//  Created by neutronstarer on 2020/7/31.
//  Copyright © 2020 neutronstarer. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BridgeosOperation : NSOperation

- (BridgeosOperation*)setTimeout:(NSTimeInterval)timeout NS_SWIFT_NAME(setTimeout(_:));

@end

NS_ASSUME_NONNULL_END
