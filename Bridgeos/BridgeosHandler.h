//
//  BridgeosHandler.h
//  Bridge
//
//  Created by neutronstarer on 2020/7/31.
//  Copyright © 2020 neutronstarer. All rights reserved.
//

#import "BridgeosConnection.h"

NS_ASSUME_NONNULL_BEGIN

@interface BridgeosHandler : NSObject
/// on event
- (BridgeosHandler *)event:(_Nullable id(^)(BridgeosConnection *connection, id _Nullable payload, void(^reply)(id _Nullable ack, id _Nullable error)))onEvent NS_SWIFT_NAME(event(_:));
- (BridgeosHandler *)cancel:(void(^)(id _Nullable cancelContext))onCancel NS_SWIFT_NAME(cancel(_:));

@end

NS_ASSUME_NONNULL_END
