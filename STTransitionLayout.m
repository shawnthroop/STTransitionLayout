//
//  STTransitionLayout.m
//  STCollectionViewTransition
//
//  Created by Shawn Throop on 28/03/15.
//  Copyright (c) 2015 Silent H Designs. All rights reserved.
//

#import "STTransitionLayout.h"

@interface STTransitionLayout () <STAnimatorDelegate>

@property (nonatomic) STAnimator *animator;
@property (nonatomic) NSDictionary *animations;

@property (nonatomic, readwrite) CGPoint fromContentOffset;
@property (nonatomic) BOOL toContentOffsetInitialized;

@end


static NSString * const STCellKind = @"STCellKind";


@implementation STTransitionLayout

- (instancetype)initWithCurrentLayout:(UICollectionViewLayout *)currentLayout nextLayout:(UICollectionViewLayout *)newLayout
{
    if (self = [super initWithCurrentLayout:currentLayout nextLayout:newLayout]) {
        _fromContentOffset = currentLayout.collectionView.contentOffset;
        
        _animator = [[STAnimator alloc] initWithScreen:currentLayout.collectionView.window.screen];
        _animator.delegate = self;
    }
    
    return self;
}



- (void)setTransitionProgress:(CGFloat)transitionProgress
{
    if (self.transitionProgress != transitionProgress) {
        super.transitionProgress = transitionProgress;
        
        if (self.toContentOffsetInitialized) {
            
            CGFloat t = self.transitionProgress;
            CGFloat f = 1 - t;
            CGPoint offset = CGPointMake(f * self.fromContentOffset.x + t * self.toContentOffset.x, f * self.fromContentOffset.y + t * self.toContentOffset.y);
            
            self.collectionView.contentOffset = offset;
        }
    }
}


- (void)setToContentOffset:(CGPoint)toContentOffset
{
    self.toContentOffsetInitialized = YES;
    if (!CGPointEqualToPoint(_toContentOffset, toContentOffset)) {
        _toContentOffset = toContentOffset;
        [self invalidateLayout];
    }
}


- (void)collectionViewDidCompleteTransition:(UICollectionView *)collectionView
{
    if (self.toContentOffsetInitialized) {
        collectionView.contentOffset = self.toContentOffset;
    }
}


- (void)prepareLayout
{
    [super prepareLayout];
    
    if (!self.animations) {
        
        NSMutableDictionary *animations = [NSMutableDictionary dictionary];
        for (NSInteger section = 0; section < [self.collectionView numberOfSections]; section++) {
            for (NSInteger item = 0; item < [self.collectionView numberOfItemsInSection:section]; item++) {
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
                NSString *key = [self keyForIndexPath:indexPath kind:STCellKind];
                
                UICollectionViewLayoutAttributes *initialAttributes = [self.currentLayout layoutAttributesForItemAtIndexPath:indexPath];
                UICollectionViewLayoutAttributes *targetAttributes = [self.nextLayout layoutAttributesForItemAtIndexPath:indexPath];
                
                STLayoutAttributeAnimation *animation = self.animationProvider ? self.animationProvider(initialAttributes, targetAttributes) : [[STLayoutAttributeAnimation alloc] initWithInitialAttributes:initialAttributes target:targetAttributes];
                
                if ([animation isKindOfClass:[STLayoutAttributeAnimation class]]) {
                    animations[key] = animation;
                }
            }
        }
        
        self.animations = [animations copy];
        
        __weak typeof(self) welf = self;
        [self.animator animateAnimations:self.animations.allValues withAnimationTick:^(NSTimeInterval timeDelta) {
            
            typeof(welf) strongSelf = welf;
            CGFloat avgProgress = [[strongSelf.animations.allValues valueForKeyPath:@"@avg.progress"] floatValue];
            strongSelf.transitionProgress = avgProgress;
            
            [strongSelf invalidateLayout];
            
        } completion:^{
            typeof(welf) strongSelf = welf;
            [strongSelf.collectionView finishInteractiveTransition];
        }];
        
//        [self.animator addAnimations:self.animations.allValues];
    }
}


- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    rect = CGRectInset(rect, -100, -100);
    
    NSMutableArray *poses = [NSMutableArray array];
    
    for (STLayoutAttributeAnimation *animation in self.animations.allValues) {
        UICollectionViewLayoutAttributes *pose = animation.attributes;
        CGRect intersection = CGRectIntersection(rect, pose.frame);
        if (!CGRectIsEmpty(intersection)) {
            [poses addObject:pose];
        }
    }

    return poses;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [self keyForIndexPath:indexPath kind:STCellKind];
    STLayoutAttributeAnimation *animation = self.animations[key];
    
    return animation.attributes;
}

- (CGSize)collectionViewContentSize
{
    return self.currentLayout.collectionViewContentSize;
}


#pragma mark - STAnimatorDelegate

- (void)animatorDidBeginAnimating:(STAnimator *)animator
{

}



- (void)animatorDidEndAnimating:(STAnimator *)animator
{
//    [self.collectionView finishInteractiveTransition];
}



- (void)animatorDidTick:(STAnimator *)animator withTimeDelta:(NSTimeInterval)timeDelta
{
//    CGFloat avgProgress = [[self.animations.allValues valueForKeyPath:@"@avg.progress"] floatValue];
//    self.transitionProgress = avgProgress;
//    
//    [self invalidateLayout];
}




#pragma mark - Convenience Methods


- (NSString *)keyForIndexPath:(NSIndexPath *)indexPath kind:(NSString *)kind
{
    return [NSString stringWithFormat:@"%zd-%zd-%@", indexPath.row, indexPath.section, kind];
}


@end




@interface STLayoutAttributeAnimation ()

@property (nonatomic, readonly) UICollectionViewLayoutAttributes *initialAttributes;
@property (nonatomic, readonly) UICollectionViewLayoutAttributes *targetAttributes;

@end

@implementation STLayoutAttributeAnimation

- (instancetype)initWithInitialAttributes:(UICollectionViewLayoutAttributes *)initial target:(UICollectionViewLayoutAttributes *)target
{
    if (self = [super initWithPoint:initial.center targetPoint:target.center]) {
        _initialAttributes = initial;
        _targetAttributes = target;
        
        _attributes = [initial copy];
    }
    
    return self;
}

- (NSIndexPath *)indexPath
{
    return _attributes.indexPath;
}


- (void)animationTick:(NSTimeInterval)timeDelta
{
    [super animationTick:timeDelta];
    
    self.attributes.center = self.currentPoint;

    [self interpolatePose];
}

- (void)interpolatePose
{
    CGFloat t = self.progress;
    CGFloat f = 1 - t;
    
    CGRect bounds = CGRectZero;
    bounds.size.width = f * self.initialAttributes.bounds.size.width + t * self.targetAttributes.bounds.size.width;
    bounds.size.height = f * self.initialAttributes.bounds.size.height + t * self.targetAttributes.bounds.size.height;
    self.attributes.bounds = bounds;
    
    self.attributes.center = self.currentPoint;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform.a = f * self.initialAttributes.transform.a + t * self.targetAttributes.transform.a;
    transform.b = f * self.initialAttributes.transform.b + t * self.targetAttributes.transform.b;
    transform.c = f * self.initialAttributes.transform.c + t * self.targetAttributes.transform.c;
    transform.d = f * self.initialAttributes.transform.d + t * self.targetAttributes.transform.d;
    transform.tx = f * self.initialAttributes.transform.tx + t * self.targetAttributes.transform.tx;
    transform.ty = f * self.initialAttributes.transform.ty + t * self.targetAttributes.transform.ty;
    self.attributes.transform = transform;
}

@end
