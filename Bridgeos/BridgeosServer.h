//
//  BridgeosServer.h
//  Bridge
//
//  Created by neutronstarer on 2020/7/31.
//  Copyright © 2020 neutronstarer. All rights reserved.
//

#import "BridgeosOperation.h"
#import "BridgeosHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface BridgeosServer : NSObject

+ (nullable instancetype)serverWithWebView:(id)webView name:(NSString* _Nullable)name NS_SWIFT_NAME(server(webView:name:));

+ (BOOL)canHandleWithWebView:(id)webView URLString:(NSString*_Nullable)URLString NS_SWIFT_NAME(canHandle(webView:URLString:));

- (BridgeosHandler *)on:(NSString*)method NS_SWIFT_NAME(on(_:));

- (BridgeosHandler *)objectForKeyedSubscript:(NSString *)method;

@end

NS_ASSUME_NONNULL_END
