//
//  BridgeosConnection+Private.h
//  Bridge
//
//  Created by neutronstarer on 2020/7/31.
//  Copyright © 2020 neutronstarer. All rights reserved.
//

#import "BridgeosConnection.h"

NS_ASSUME_NONNULL_BEGIN

@interface BridgeosConnection (Private)

@property (nonatomic, copy) NSString *connectionId;
@property (nonatomic, copy) void(^emit)(NSString *method, id payload);
@property (nonatomic, copy) BridgeosOperation *(^deliver)(NSString *method, id payload, void(^completion)(id ack, id error));

@end

NS_ASSUME_NONNULL_END
