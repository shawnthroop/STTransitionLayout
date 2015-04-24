//
//  STAnimator.h
//  STCollectionViewTransition
//
//  Created by Shawn Throop on 28/03/15.
//  Copyright (c) 2015 Silent H Designs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol STAnimatable <NSObject>

- (void)animationTick:(NSTimeInterval)timeDelta;
- (CGFloat)progress;
- (BOOL)isFinished;

@end



typedef void(^STAnimationTick)(NSTimeInterval timeDelta);

@interface STAnimator : NSObject

@property (nonatomic, readonly) BOOL isAnimating;

- (instancetype)initWithScreen:(UIScreen *)screen;

- (void)animateAnimations:(NSArray *)animations withAnimationTick:(STAnimationTick)tick completion:(void(^)())completion;

- (void)cancelAllAnimations;

@end






@interface STSpringAnimation : NSObject <STAnimatable>

@property (nonatomic, readonly) CGPoint initialPoint;
@property (nonatomic, readonly) CGPoint targetPoint;
@property (nonatomic, readonly) CGPoint currentPoint;

@property (nonatomic) CGFloat friction;         // Default value: 20.0f
@property (nonatomic) CGFloat springDamping;    // Default value: 250.0f

@property (nonatomic) CGPoint velocity;

@property (nonatomic, readonly) CGFloat progress;
@property (nonatomic, readonly) BOOL isFinished;

- (instancetype)initWithPoint:(CGPoint)initial targetPoint:(CGPoint)target;

- (void)animationTick:(NSTimeInterval)timeDelta;

@end