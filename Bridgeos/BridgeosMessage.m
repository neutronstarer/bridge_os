//
//  BridgeosMessage.m
//  Bridge
//
//  Created by neutronstarer on 2020/7/31.
//  Copyright © 2020 neutronstarer. All rights reserved.
//

#import "BridgeosMessage.h"

@implementation BridgeosMessage

- (instancetype)initWithJSONString:(NSString *)JSONString{
    if (JSONString.length==0){
        return nil;
    }
    NSError *e;
    NSDictionary *message = [NSJSONSerialization JSONObjectWithData:[JSONString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&e];
    if (e||!message){
        NSParameterAssert(0);
        return nil;
    }
    self = [self init];
    if (!self) return nil;
    self.mid     = message[@"id"];
    self.from    = message[@"from"];
    self.to      = message[@"to"];
    self.type    = message[@"type"];
    self.method  = message[@"method"];
    self.payload = message[@"payload"];
    self.error   = message[@"error"];
    return self;
}

+ (instancetype)messageWithJSONString:(NSString *)JSONString{
    return [[BridgeosMessage alloc]initWithJSONString:JSONString];
}

- (NSString*)JSONString{
    NSMutableDictionary *message = [NSMutableDictionary dictionaryWithCapacity:6];
    message[@"id"]      = self.mid;
    message[@"from"]    = self.from;
    message[@"to"]      = self.to;
    message[@"type"]    = self.type;
    message[@"method"]  = self.method;
    message[@"payload"] = self.payload;
    message[@"error"]   = self.error;
    NSError *e;
    NSData *data = [NSJSONSerialization dataWithJSONObject:message options:0 error:&e];
    if (e){
        NSParameterAssert(0);
        return nil;
    }
    return [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSString*)description{
    return [self JSONString];
}

@end
