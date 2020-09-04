//
//  BridgeScriptMessageHandler.m
//  Bridge
//
//  Created by neutronstarer on 2020/7/31.
//  Copyright © 2020 neutronstarer. All rights reserved.
//

#import "BridgeosScriptMessageHandler.h"
#import "BridgeosServer+Private.h"

@implementation BridgeosScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    [[BridgeosServer serverWithWebView:message.webView name:message.name createIfNotExist:NO] didReceive:[BridgeosMessage messageWithJSONString:message.body]];
}

@end
