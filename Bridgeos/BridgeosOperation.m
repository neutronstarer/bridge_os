//
//  BridgeosOperation.m
//  Bridge
//
//  Created by neutronstarer on 2020/7/31.
//  Copyright © 2020 neutronstarer. All rights reserved.
//

#import "BridgeosOperation.h"

@interface BridgeosOperation()
{
    BOOL _isExecuting;
    BOOL _isFinished;
    void(^_completion)(id res, id error);
}

@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, strong) NSLock            *lock;

@end

@implementation BridgeosOperation

- (instancetype)initWithCompletion:(void(^)(id ack, id error))completion{
    self = [super init];
    if (self == nil) {
        return nil;
    }
    _lock = [[NSLock alloc]init];
    _completion = completion;
    return self;
}

- (BridgeosOperation*)setTimeout:(NSTimeInterval)timeout{
    [self.lock lock];
    if (self.isFinished == YES){
        [self.lock unlock];
        return self;
    }
    if (self.timer != nil){
        dispatch_source_cancel(self.timer);
    }
    __weak typeof(self) weakSelf = self;
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, INT32_MAX * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(self.timer, ^{
        __strong typeof(weakSelf) self = weakSelf;
        [self complete:nil error:@"timed out"];
    });
    dispatch_resume(self.timer);
    [self.lock unlock];
    return self;
}

- (void)cancel{
    [super cancel];
    [self complete:nil error:@"cancelled"];
}

- (void)start{
    [self.lock lock];
    if (self.isFinished == YES || self.isExecuting == YES){
        [self.lock unlock];
        return;
    }
    self.isExecuting = YES;
    [self.lock unlock];
}

- (void)complete:(NSString* _Nullable)ack error:(id _Nullable)error{
    [self.lock lock];
    if (self.isFinished == YES || self.isExecuting == NO){
        [self.lock unlock];
        return;
    }
    if (self.timer != nil){
        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }
    _completion(ack, error);
    self.isExecuting = YES;
    self.isFinished = YES;
    [self.lock unlock];
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)setIsExecuting:(BOOL)isExecuting {
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = isExecuting;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setIsFinished:(BOOL)isFinished {
    [self willChangeValueForKey:@"isFinished"];
    _isExecuting = isFinished;
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isExecuting{
    return _isExecuting;
}

- (BOOL)isFinished{
    return _isFinished;
}

@end
