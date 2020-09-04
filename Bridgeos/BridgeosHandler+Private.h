//
//  BridgeosHandler+Private.h
//  Bridge
//
//  Created by neutronstarer on 2020/7/31.
//  Copyright © 2020 neutronstarer. All rights reserved.
//

#import "BridgeosConnection.h"
#import "BridgeosHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface BridgeosHandler (Private)

@property (nonatomic, copy) _Nullable id(^onEvent)(BridgeosConnection *connection, id _Nullable payload, void(^reply)(id _Nullable ack, id _Nullable error));
@property (nonatomic, copy, nullable) void(^onCancel)(id _Nullable cancelContext);

@end

NS_ASSUME_NONNULL_END
