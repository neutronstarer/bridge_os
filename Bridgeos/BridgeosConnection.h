//
//  BridgeosConnection.h
//  Bridge
//
//  Created by neutronstarer on 2020/7/31.
//  Copyright © 2020 neutronstarer. All rights reserved.
//

#import "BridgeosOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface BridgeosConnection : NSObject

@property (nonatomic, copy, readonly) NSString *connectionId;

- (void)emit:(NSString*)method payload:(id _Nullable)payload NS_SWIFT_NAME(emit(method:payload:));

- (BridgeosOperation*)deliver:(NSString*)method payload:(id _Nullable)payload completion:(void(^)(id _Nullable ack, id _Nullable error))completion NS_SWIFT_NAME(deliver(method:payload:completion:));

@end

NS_ASSUME_NONNULL_END
