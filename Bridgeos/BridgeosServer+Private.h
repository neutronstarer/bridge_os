//
//  BridgeosServer+Private.h
//  Bridge
//
//  Created by neutronstarer on 2020/7/31.
//  Copyright © 2020 neutronstarer. All rights reserved.
//

#import "BridgeosMessage.h"
#import "BridgeosServer.h"

NS_ASSUME_NONNULL_BEGIN

@interface BridgeosServer (Private)

+ (instancetype)serverWithWebView:(id)webView name:(NSString* _Nullable)name createIfNotExist:(BOOL)createIfNotExist;

- (void)didReceive:(BridgeosMessage * _Nullable)message;

@end

NS_ASSUME_NONNULL_END
