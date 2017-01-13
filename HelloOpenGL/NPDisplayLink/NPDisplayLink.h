//
//  NPDisplayLink.h
//  NPHelpers
//
//  Created by sntg on 6/29/15.
//  Copyright © 2015 POPPLER. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

@interface NPDisplayLink : NSObject
@property (nonatomic, assign) NSInteger frameInterval;
@property (nonatomic, getter=isPaused, readonly) BOOL paused;
@property (nonatomic, getter=getDuration, readonly) CFTimeInterval duration;
@property (nonatomic, getter=getTimestamp, readonly) CFTimeInterval timestamp;

+ (instancetype)sharedDisplayLink;
+ (instancetype)displayLinkWithTarget:(id)target selector:(SEL)selector;
- (instancetype)initWithTarget:(id)target selector:(SEL)selector;

- (void)addTarget:(id)target selector:(SEL)selector;
- (void)removeTarget:(id)target;

- (void)start;
- (void)stop;
@end
