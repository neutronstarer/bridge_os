//
//  BridgeosHandler.m
//  Bridge
//
//  Created by neutronstarer on 2020/7/31.
//  Copyright © 2020 neutronstarer. All rights reserved.
//

#import "BridgeosHandler.h"
#import "BridgeosConnection.h"

@interface BridgeosHandler ()

@property (nonatomic, copy) _Nullable id(^onEvent)(BridgeosConnection *connection, id _Nullable payload, void(^reply)(id _Nullable ack, id _Nullable error));
@property (nonatomic, copy, nullable) void(^onCancel)(id _Nullable cancelContext);

@end

@implementation BridgeosHandler

- (BridgeosHandler *)event:(_Nullable id(^)(BridgeosConnection *connection, id _Nullable payload, void(^reply)(id _Nullable ack, id _Nullable error)))onEvent{
    self.onEvent = onEvent;
    return self;
}

- (BridgeosHandler *)cancel:(void(^)(id _Nullable cancelContext))onCancel{
    self.onCancel = onCancel;
    return self;
}

@end
