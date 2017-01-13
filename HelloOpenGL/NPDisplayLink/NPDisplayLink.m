//
//  NPDisplayLink.m
//  NPHelpers
//
//  Created by sntg on 6/29/15.
//  Copyright © 2015 POPPLER. All rights reserved.
//

#import "NPDisplayLink.h"


@interface NPDisplayLink ()
@property (nonatomic, readwrite) CFTimeInterval duration;
@property (nonatomic, readwrite) CFTimeInterval timestamp;
@property (nonatomic, strong) NSMapTable *targets;
@end

@implementation NPDisplayLink {
    CVDisplayLinkRef displayLink;
}

+ (instancetype)sharedDisplayLink
{
    static dispatch_once_t once_token;
    static NPDisplayLink *instance;
    dispatch_once(&once_token, ^{
        instance = [NPDisplayLink new];
        [instance start];
    });
    return instance;
}

+ (instancetype)displayLinkWithTarget:(id)target selector:(SEL)selector
{
    return [[self alloc] initWithTarget:target selector:selector];
}

- (instancetype)init
{
    if (self = [super init]) {
        self.targets = [NSMapTable weakToStrongObjectsMapTable];
        self.frameInterval = 1;
        [self createCVDisplayLink];
        CVDisplayLinkSetOutputCallback(displayLink, &NPDisplayLinkCallback, (__bridge void *)self);
    }
    return self;
}

- (instancetype)initWithTarget:(id)target selector:(SEL)selector
{
    if (self = [self init]) {
        [self addTarget:target selector:selector];
    }
    return self;
}

- (void)dealloc
{
    [self stop];
    CVDisplayLinkRelease(displayLink);
}

static CVReturn NPDisplayLinkCallback(CVDisplayLinkRef displayLink,
                                      const CVTimeStamp *now,
                                      const CVTimeStamp *outputTime,
                                      CVOptionFlags flagsIn,
                                      CVOptionFlags *flagsOut,
                                      void *displayLinkContext)
{
    [(__bridge NPDisplayLink *)displayLinkContext getFrameForTime:outputTime];
    return kCVReturnSuccess;
}

- (void)getFrameForTime:(const CVTimeStamp *)outputTime
{
    @synchronized(self.targets) {
        for (id target in [self.targets keyEnumerator]) {
            SEL selector = [[self.targets objectForKey:target] pointerValue];
//            [target performSelector:selector onThread:[NSThread currentThread] withObject:(__bridge id)(outputTime) waitUntilDone:YES];
            ((void (*)(id, SEL, const CVTimeStamp*))[target methodForSelector:selector])(target, selector, outputTime);
//            [target performSelector:selector withObject:(__bridge id)(outputTime)];
        }
    }
}

- (void)addTarget:(id)target selector:(SEL)selector
{
    @synchronized(self.targets) {
        [self.targets setObject:[NSValue valueWithPointer:selector] forKey:target];
    }
}

- (void)removeTarget:(id)target
{
    @synchronized(self.targets) {
        [self.targets removeObjectForKey:target];
    }
}

- (void)createCVDisplayLink
{
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
}

- (void)start
{
    CVDisplayLinkStart(displayLink);
}

- (void)stop
{
    CVDisplayLinkStop(displayLink);
}

- (CFTimeInterval)getDuration
{
    CVTime time = CVDisplayLinkGetNominalOutputVideoRefreshPeriod(displayLink);
    return (CFTimeInterval)time.timeValue / time.timeScale;
}

- (CFTimeInterval)getTimestamp
{
    CVTimeStamp timeStamp = { .version = 0 };
    CVDisplayLinkGetCurrentTime(displayLink, &timeStamp);
    return (CFTimeInterval)timeStamp.hostTime;
}

- (BOOL)isPaused
{
    return !CVDisplayLinkIsRunning(displayLink);
}


@end
