//
//  BridgeosConnection.m
//  Bridge
//
//  Created by neutronstarer on 2020/7/31.
//  Copyright © 2020 neutronstarer. All rights reserved.
//

#import "BridgeosConnection.h"

@interface BridgeosConnection()

@property (nonatomic, copy) NSString *connectionId;
@property (nonatomic, copy) void(^emit)(NSString *method, id payload);
@property (nonatomic, copy) BridgeosOperation *(^deliver)(NSString *method, id payload, void(^completion)(id ack, id error));

@end

@implementation BridgeosConnection

- (void)emit:(NSString*)method payload:(id _Nullable)payload {
    self.emit(method, payload);
}

- (BridgeosOperation*)deliver:(NSString*)method payload:(id _Nullable)payload completion:(void(^)(id _Nullable ack, id _Nullable error))completion {
    return self.deliver(method, payload, completion);
}

@end
