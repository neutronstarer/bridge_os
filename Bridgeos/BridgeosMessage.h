//
//  BridgeosMessage.h
//  Bridge
//
//  Created by neutronstarer on 2020/7/31.
//  Copyright © 2020 neutronstarer. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BridgeosMessage : NSObject

@property (nonatomic, copy  , nullable) NSNumber *mid;
@property (nonatomic, copy  , nullable) NSString *from;
@property (nonatomic, copy  , nullable) NSString *to;
@property (nonatomic, copy  , nullable) NSString *type;
@property (nonatomic, copy  , nullable) NSString *method;
@property (nonatomic, strong, nullable) id       payload;
@property (nonatomic, strong, nullable) id       error;

+ (instancetype)messageWithJSONString:(NSString* _Nullable)JSONString;

- (NSString* _Nullable)JSONString;

@end

NS_ASSUME_NONNULL_END
