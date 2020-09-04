//
//  BridgeosOperation+Private.h
//  Bridge
//
//  Created by neutronstarer on 2020/7/31.
//  Copyright © 2020 neutronstarer. All rights reserved.
//

#import "BridgeosOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface BridgeosOperation (Private)

- (instancetype)initWithCompletion:(void(^)(id _Nullable ack, id _Nullable error))completion;

- (void)complete:(NSString* _Nullable)ack error:(id _Nullable)error;

@end

NS_ASSUME_NONNULL_END
