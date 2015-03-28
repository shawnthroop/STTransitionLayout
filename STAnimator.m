//
//  STAnimator.m
//  STCollectionViewTransition
//
//  Created by Shawn Throop on 28/03/15.
//  Copyright (c) 2015 Silent H Designs. All rights reserved.
//

#import "STAnimator.h"

@interface STAnimator ()

@property (nonatomic) UIScreen *screen;
@property (nonatomic) CADisplayLink *displayLink;
@property (nonatomic, strong) NSSet *animations;

@property (nonatomic, copy) void (^completionBlock)();
@property (nonatomic, copy) STAnimationTick tick;
@property (nonatomic) NSNumber *duration;

@end


@implementation STAnimator

- (instancetype)initWithScreen:(UIScreen *)screen
{
    if (self = [super init]) {
        NSAssert(screen != nil, @"Must provide a UIScreen instance for the animator");
        
        _screen = screen;
        _displayLink = [screen displayLinkWithTarget:self selector:@selector(tick:)];
        _displayLink.paused = YES;
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        
        _duration = nil;
    }
    
    return self;
}



- (void)animateAnimations:(NSArray *)animatables withAnimationTick:(STAnimationTick)tick completion:(void (^)())completion
{
    if (!self.displayLink.isPaused || self.animations != nil) {
        NSLog(@"Cannot animate because animation is already in progress");
        return;
    }
    
    NSMutableSet *validAnimations = [NSMutableSet set];
    
    for (id<STAnimatable> animation in animatables) {
        if ([animation conformsToProtocol:@protocol(STAnimatable)]) {
            [validAnimations addObject:animation];
        }
    }
    
    self.animations = [validAnimations copy];
    self.completionBlock = completion;
    self.tick = tick;
    
    self.displayLink.paused = NO;
}


- (void)tick:(CADisplayLink *)displayLink
{
    CFTimeInterval timeDelta = displayLink.duration;
    
    for (id<STAnimatable> animation in [self.animations copy]) {
        if (![animation isFinished]) {
            [animation animationTick:timeDelta];
        }
    }
    
    if (self.tick) {
        self.tick(timeDelta);
    }
    
    self.animations = [self.animations objectsPassingTest:^BOOL(id<STAnimatable> animation, BOOL *stop) {
        return ![animation isFinished];
    }];

    if (self.animations.count == 0) {
        self.displayLink.paused = YES;
        
        if (self.completionBlock) {
            self.completionBlock();
        }
        
        self.animations = nil;
        self.duration = nil;
    }
}

@end








#pragma mark - STSpringAnimation

@interface STSpringAnimation ()

@property (nonatomic, readwrite) CGPoint currentPoint;
@property (nonatomic, readwrite) CGFloat progress;

@property (nonatomic, readwrite) BOOL isFinished;

@end


@implementation STSpringAnimation

- (instancetype)initWithPoint:(CGPoint)initial targetPoint:(CGPoint)target
{
    if (self = [super init]) {
        _initialPoint = initial;
        _targetPoint = target;
        _currentPoint = initial;
        
        _progress = 0.0f;
        
        _friction = 20.0f;
        _springDamping = 250.0f;
        
        _isFinished = CGPointEqualToPoint(_initialPoint, _targetPoint);
    }
    
    return self;
}


- (void)animationTick:(NSTimeInterval)timeDelta
{
    if (self.isFinished) {
        return;
    }
    
    CGFloat time = (CGFloat)timeDelta;
    
    // friction force = velocity * friction constant
    CGPoint frictionForce = STPointMultiply(self.velocity, self.friction);
    
    // spring force = (target point - current position) * spring constant
    CGPoint springForce = STPointMultiply(STPointSubtract(self.targetPoint, self.currentPoint), self.springDamping);
    
    // force = spring force - friction force
    CGPoint force = STPointSubtract(springForce, frictionForce);
    
    // velocity = current velocity + force * time / mass
    self.velocity = STPointAdd(self.velocity, STPointMultiply(force, time));
    
    // position = current position + velocity * time
    self.currentPoint = STPointAdd(self.currentPoint, STPointMultiply(self.velocity, time));
    
    CGFloat speed = STPointLength(self.velocity);
    CGFloat distanceToGoal = STPointLength(STPointSubtract(self.targetPoint, self.currentPoint));
    
    if (speed < 10 && fabsf(distanceToGoal) < 1) {
        self.currentPoint = self.targetPoint;
        self.isFinished = YES;
    }
    
    CGFloat distanceFromInitial = STPointLength(STPointSubtract(self.currentPoint, self.initialPoint));
    CGFloat totalDistance = STPointLength(STPointSubtract(self.targetPoint, self.initialPoint));
    self.progress = distanceFromInitial / totalDistance;
}


static  CGPoint STPointSubtract(CGPoint p1, CGPoint p2) {
    return CGPointMake(p1.x - p2.x, p1.y - p2.y);
}

static  CGPoint STPointAdd(CGPoint p1, CGPoint p2) {
    return CGPointMake(p1.x + p2.x, p1.y + p2.y);
}

static CGPoint STPointMultiply(CGPoint point, CGFloat multiplier) {
    return CGPointMake(point.x * multiplier, point.y * multiplier);
}

static CGPoint STPointDivide(CGPoint point, CGFloat divisor) {
    return CGPointMake(point.x / divisor, point.y / divisor);
}

static CGFloat STPointLength(CGPoint point) {
    return (CGFloat)sqrt(point.x * point.x + point.y * point.y);
}

@end



