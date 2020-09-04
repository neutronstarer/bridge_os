//
//  BridgeosServer.m
//  Bridge
//
//  Created by neutronstarer on 2020/7/31.
//  Copyright © 2020 neutronstarer. All rights reserved.
//

#import "BridgeosServer.h"
#import "BridgeosMessage.h"

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif
#import <WebKit/WebKit.h>

#import "BridgeosScriptMessageHandler.h"
#import "BridgeosHandler+Private.h"
#import "BridgeosOperation+Private.h"
#import "BridgeosConnection+Private.h"

static NSString * const QueryFormat = @";(function(){try{return window['bridge_hub_%@'].query();}catch(e){return '[]'};})();";
static NSString * const TransmitFormat  = @";(function(){try{return window['bridge_hub_%@'].transmit('%@');}catch(e){return false};})();";

static inline NSString *EscapedJSString(NSString *v){
    NSMutableString *s = [NSMutableString stringWithCapacity:v.length];
    for (NSUInteger i = 0,len = v.length;i<len;i++){
        unichar c = [v characterAtIndex:i];
        switch (c) {
            case '\\':
                [s appendString:@"\\\\"];
                break;
            case '\'':
                [s appendString:@"\\'"];
                break;
            case '"':
                [s appendString:@"\\\""];
                break;
            default:
                [s appendString:[NSString stringWithCharacters:&c length:1]];
                break;
        }
    }
    [s replaceOccurrencesOfString:@"\u2028" withString:@"\\u2028" options:0  range:NSMakeRange(0, s.length)];
    [s replaceOccurrencesOfString:@"\u2029" withString:@"\\u2029" options:0  range:NSMakeRange(0, s.length)];
    return s;
}

static inline NSString *OperationIdOf(NSString *connectionId, NSNumber *mid){
    return [NSString stringWithFormat:@"%@-%@",connectionId, mid];
}

static inline NSString *cancelIdOf(NSString *connectionId, NSNumber *mid){
    return [NSString stringWithFormat:@"%@-%@",connectionId, mid];
}

@interface BridgeosServer()

@property (nonatomic, copy  ) NSString            *name;
@property (nonatomic, strong) NSMutableDictionary<NSString*, BridgeosConnection*> *connectionByName;
@property (nonatomic, strong) NSMutableDictionary<NSString*, BridgeosHandler*> *handlerByMethod;
@property (nonatomic, strong) NSMutableDictionary<NSString*, void(^)(void)> *cancelById;
@property (nonatomic, strong) NSMapTable<NSString*, BridgeosOperation*> *operationById;
@property (nonatomic, strong) NSOperationQueue    *operationQueue;
@property (atomic,    assign) NSInteger           idx;

@property (nonatomic, copy  ) void(^evaluate)(NSString *js,void(^completionHandler)(id result));

@end

@implementation BridgeosServer

+ (instancetype)serverWithWebView:(id)webView name:(NSString* _Nullable)name{
    return [self serverWithWebView:webView name:name createIfNotExist:YES];
}

+ (instancetype)serverWithWebView:(id)webView name:(NSString* _Nullable)name createIfNotExist:(BOOL)createIfNotExist{
    static dispatch_semaphore_t lock;
    static NSMapTable<id,NSMutableDictionary*> *serversByWebView;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = dispatch_semaphore_create(1);
        serversByWebView = [NSMapTable weakToStrongObjectsMapTable];
    });
    if (name.length == 0){
        name = @"<name>";
    }
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    NSMutableDictionary *serversByName = [serversByWebView objectForKey:webView];
    if (serversByName == nil){
        serversByName = [NSMutableDictionary dictionary];
        [serversByWebView setObject:serversByName forKey:webView];
    }
    BridgeosServer *server = serversByName[name];
    if (server)  {
        dispatch_semaphore_signal(lock);
        return server;
    }
    if (createIfNotExist == false){
        dispatch_semaphore_signal(lock);
        return server;
    }
    server = [[self alloc]initWithWebView:webView name:name];
    serversByName[name] = server;
    dispatch_semaphore_signal(lock);
    return server;
}

- (instancetype)initWithWebView:(id)webView name:(NSString*)name{
    self = [super init];
    if (self == nil) return nil;
    if (name.length == 0) {
        NSParameterAssert(0);
        return nil;
    }
    self.name = name;
    self.connectionByName = [NSMutableDictionary dictionary];
    self.handlerByMethod = [NSMutableDictionary dictionary];
    self.cancelById = [NSMutableDictionary dictionary];
    self.operationQueue = [[NSOperationQueue alloc]init];
    self.operationById = [NSMapTable strongToWeakObjectsMapTable];
    if ([self initializeEvaluationWithWebView:webView name:name] == false) {
        NSParameterAssert(0);
        return nil;
    }
    return self;
}

- (BOOL)initializeEvaluationWithWebView:(id)webView name:(NSString*)name{
    __weak typeof(webView) weakWebView = webView;
#if TARGET_OS_OSX
    if ([webView isKindOfClass:WebView.class]){
        self.evaluate = ^(NSString *js, void (^completionHandler)(id result)) {
            if ([NSThread isMainThread]){
                __strong typeof(weakWebView) webView = weakWebView;
                id result = [(WebView*)webView stringByEvaluatingJavaScriptFromString:js];
                if(completionHandler) completionHandler(result);
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakWebView) webView = weakWebView;
                    id result = [(WebView*)webView stringByEvaluatingJavaScriptFromString:js];
                    if(completionHandler) completionHandler(result);
                });
            }
        };
        return YES;
    }
#elif !TARGET_OS_UIKITFORMAC
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if ([webView isKindOfClass:UIWebView.class]){
        self.evaluate = ^(NSString *js, void (^completionHandler)(id result)) {
            if ([NSThread isMainThread]){
                __strong typeof(weakWebView) webView = weakWebView;
                id result = [(UIWebView*)webView stringByEvaluatingJavaScriptFromString:js];
                if(completionHandler) completionHandler(result);
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakWebView) webView = weakWebView;
                    id result = [(UIWebView*)webView stringByEvaluatingJavaScriptFromString:js];
                    if(completionHandler) completionHandler(result);
                });
            }
        };
        return YES;
    }
#pragma clang diagnostic pop
#endif
    if ([webView isKindOfClass:WKWebView.class]){
        [[(WKWebView*)webView configuration].userContentController addScriptMessageHandler:[[BridgeosScriptMessageHandler alloc]init] name:name];
        self.evaluate = ^(NSString *js, void (^completionHandler)(id result)) {
            if ([NSThread isMainThread]){
                __strong typeof(weakWebView) webView = weakWebView;
                [(WKWebView*)webView evaluateJavaScript:js completionHandler:^(id result, NSError * error) {
                    if(completionHandler) completionHandler(result);
                }];
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakWebView) webView = weakWebView;
                    [(WKWebView*)webView evaluateJavaScript:js completionHandler:^(id result, NSError * error) {
                        if(completionHandler) completionHandler(result);
                    }];
                });
            }
        };
        return YES;
    }
    return NO;
}

+ (BOOL)canHandleWithWebView:(id)webView URLString:(NSString*_Nullable)URLString{
    static NSRegularExpression *canHandleRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        canHandleRegex = [NSRegularExpression regularExpressionWithPattern:@"^https://bridge/([^/]+)\\?name=(.+)$" options:0 error:nil];
    });
    NSTextCheckingResult *result = [canHandleRegex firstMatchInString:URLString options:0 range:NSMakeRange(0, URLString.length)];
    if (result == NO) return NO;
    NSString *name = [[URLString substringWithRange:[result rangeAtIndex:2]] stringByRemovingPercentEncoding];
    BridgeosServer *server = [self serverWithWebView:webView name:name createIfNotExist:NO];
    if (server == nil) return YES;
    NSString *action = [URLString substringWithRange:[result rangeAtIndex:1]];
    if ([action isEqualToString:@"load"]) [server load];
    else if([action isEqualToString:@"query"]) [server query];
    return YES;
}

- (void)sendMessage:(BridgeosMessage*)message completion:(void(^)(BOOL success))completion{
    NSString *JSONString = [message JSONString];
    if (JSONString == nil){
        NSParameterAssert(0);
        if(completion) completion(NO);
        return;
    }
    self.evaluate([NSString stringWithFormat:TransmitFormat, self.name, EscapedJSString(JSONString)],^(id result){
        if(completion) completion([result boolValue]);
    });
}

- (void)emit:(NSString*)connectionId method:(NSString*)method payload:(id)payload{
    [self sendMessage:({
        BridgeosMessage *v = [[BridgeosMessage alloc]init];
        v.mid = @(self.idx++);
        v.to = connectionId;
        v.type = @"emit";
        v.method = method;
        v.payload = payload;
        v;
    }) completion:nil];
}

- (BridgeosOperation *)deliver:(NSString*)connectionId method:(NSString*)method payload:(id _Nullable)payload completion:(void(^)(id _Nullable ack, id _Nullable error))completion{
    __weak typeof(self) weakSelf = self;
    NSNumber *mid = @(self.idx++);
    NSString *operationId = [NSString stringWithFormat:@"%@-%@",connectionId, mid];
    BridgeosOperation *operation = [[BridgeosOperation alloc] initWithCompletion:completion];
    [self sendMessage:({
        BridgeosMessage *v = [[BridgeosMessage alloc]init];
        v.mid = mid;
        v.to = connectionId;
        v.type = @"deliver";
        v.method = method;
        v.payload = payload;
        v;
    }) completion:^(BOOL success) {
        if (success == true){
            return;
        }
        __strong typeof(weakSelf) self = weakSelf;
        [self completeOperationById:operationId ack:nil error:@"fail to send message"];
    }];
    [self.operationById setObject:operation forKey:operationId];
    [self.operationQueue addOperation:operation];
    return operation;
}

- (BridgeosHandler *)objectForKeyedSubscript:(NSString *)key{
    return [self on:key];
}

- (BridgeosHandler *)on:(NSString*)method{
    BridgeosHandler *handler = self.handlerByMethod[method];
    if (handler != nil){
        return handler;
    }
    handler = [[BridgeosHandler alloc]init];
    self.handlerByMethod[method] = handler;
    return handler;
}

- (void)completeOperationById:(NSString*)operationId ack:(id)ack error:(id)error{
    BridgeosOperation *operation = [self.operationById objectForKey:operationId];
    if (operation == nil){
        return;
    }
    [operation complete:ack error:error];
}

- (void)load{
    NSString *resource;
#ifdef DEBUG
    resource = @"hub";
#else
    resource = @"hub.min";
#endif
    NSString *js = [[NSString stringWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:resource ofType:@"js"] encoding:NSUTF8StringEncoding error:nil] stringByReplacingOccurrencesOfString:@"<name>" withString:self.name];
    self.evaluate(js, nil);
}

- (void)query{
    __weak typeof(self) weakSelf = self;
    self.evaluate([NSString stringWithFormat:QueryFormat, self.name], ^(id result) {
        __strong typeof(weakSelf) self = weakSelf;
        if ([result length] == 0) return;
        NSError *error;
        NSArray *messages = [NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
        if (error != nil){
            NSParameterAssert(0);
            return;
        }
        [messages enumerateObjectsUsingBlock:^(NSString * JSONString, NSUInteger idx, BOOL * stop) {
            [self didReceive:[BridgeosMessage messageWithJSONString:JSONString]];
        }];
    });
}

- (void)didReceive:(BridgeosMessage *)message{
    if (message == nil){
        NSParameterAssert(0);
        return;
    }
    NSNumber *mid    = message.mid;
    NSString *from   = message.from;
    NSString *type   = message.type;
    NSString *method = message.method;
    id payload       = message.payload;
    id error         = message.error;
    if (from.length == 0){
        return;
    }
    if ([type isEqualToString:@"connect"]){
        if (self.connectionByName[from] != nil){
            return;
        }
        BridgeosConnection *connection = [[BridgeosConnection alloc]init];
        connection.connectionId = from;
        __weak typeof(self) weakSelf = self;
        connection.emit = ^(NSString * method, id payload) {
            [weakSelf emit:from method:method payload:payload];
        };
        connection.deliver = ^BridgeosOperation * _Nonnull(NSString * method, id payload, void (^completion)(id, id)) {
            return [weakSelf deliver:from method:method payload:payload completion:completion];
        };
        self.connectionByName[from] = connection;
        BridgeosHandler *handler = self.handlerByMethod[@"connect"];
        if (handler == nil){
            return;
        }
        handler.onEvent(connection , payload, ^(id res, id error) {});
        return;
    }
    BridgeosConnection *connection = self.connectionByName[from];
    if (connection == nil){
        return;
    }
    if ([type isEqualToString:@"disconnect"]){
        if (self.connectionByName[from] == nil){
            return;
        }
        self.connectionByName[from] = nil;
        NSString *prefix = [NSString stringWithFormat:@"%@-", from];
        do {
            NSString *key = [[self.operationById keyEnumerator] nextObject];
            if (key == nil){
                break;
            }
            if ([key hasPrefix:prefix] == NO){
                continue;
            }
            [self completeOperationById:key ack:nil error:@"disconnected"];
        }while (YES);
        BridgeosHandler *handler = self.handlerByMethod[@"disconnect"];
        if (handler == nil){
            return;
        }
        handler.onEvent(connection, payload, ^(id ack, id error) {});
        return;
    }
    if ([type isEqualToString:@"ack"]){
        NSString *operationId = OperationIdOf(from, mid);
        [self completeOperationById:operationId ack:payload error:error];
        return;
    }
    if ([type isEqualToString:@"cancel"]){
        NSString *cancelId = cancelIdOf(from, mid);
        void(^cancel)(void) = self.cancelById[cancelId];
        if (cancel == nil){
            return;
        }
        cancel();
        return;
    }
    if ([type isEqualToString:@"emit"]){
        BridgeosHandler *handler = self.handlerByMethod[method];
        if (handler == nil){
            return;
        }
        handler.onEvent(connection, payload, ^(id ack, id error) {});
        return;
    }
    __weak typeof(self) weakSelf = self;
    void (^reply)(id ack, id error) = ^(id ack, id error){
        __strong typeof(weakSelf) self = weakSelf;
        [self sendMessage:({
            BridgeosMessage *v = [[BridgeosMessage alloc] init];
            v.mid = mid;
            v.to = from;
            v.type = @"ack";
            v.payload = ack;
            v.error = error;
            v;
        }) completion:nil];
    };
    if ([type isEqualToString:@"deliver"]){
        BridgeosHandler *handler = self.handlerByMethod[method];
        if (handler == nil){
            reply(nil, @"unsuppoted method");
            return;
        }
        NSString *cancelId = cancelIdOf(from, mid);
        __block BOOL completed = NO;
        id cancelContext = handler.onEvent(connection, payload, ^(id ack, id error) {
            if (completed == YES){
                return;
            }
            completed = YES;
            __strong typeof(weakSelf) self = weakSelf;
            self.cancelById[cancelId] = nil;
            reply(ack, error);
        });
        void(^cancel)(id cancelContext) = handler.onCancel;
        if (cancel == nil){
            return;
        }
        self.cancelById[cancelId] = ^(){
            if (completed == YES){
                return;
            }
            completed = YES;
            __strong typeof(weakSelf) self = weakSelf;
            self.cancelById[cancelId] = nil;
            cancel(cancelContext);
        };
        return;
    }
}

@end
