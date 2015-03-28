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


//@class STAnimator;
//@protocol STAnimatorDelegate
//
//- (void)animatorDidBeginAnimating:(STAnimator *)animator;
//- (void)animatorDidTick:(STAnimator *)animator withTimeDelta:(NSTimeInterval)timeDelta;
//- (void)animatorDidEndAnimating:(STAnimator *)animator;
//
//@end


typedef void(^STAnimationTick)(NSTimeInterval timeDelta);

@interface STAnimator : NSObject

- (instancetype)initWithScreen:(UIScreen *)screen;

- (void)animateAnimations:(NSArray *)animatables withAnimationTick:(STAnimationTick)tick completion:(void(^)())completion;
//- (void)animateAnimations:(NSArray *)animatables withAnimationTick:(STAnimationTick)tick duration:(CGFloat)duration completion:(void (^)())completion;
//
//- (void)addAnimations:(NSArray *)animatables;
//- (void)removeAnimations:(NSArray *)animatables;

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