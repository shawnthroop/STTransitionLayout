//
//  STTransitionLayout.m
//  STCollectionViewTransition
//
//  Created by Shawn Throop on 28/03/15.
//  Copyright (c) 2015 Silent H Designs. All rights reserved.
//

#import "STTransitionLayout.h"

@interface STTransitionLayout ()

@property (nonatomic) STAnimator *animator;
@property (nonatomic, readwrite) NSDictionary *animations;

@property (nonatomic, readwrite) CGPoint fromContentOffset;
@property BOOL savedUserInteractionState;

@property (nonatomic) CGSize transitionContentSize;

@end


static NSString * const STCellKind = @"STCellKind";


@implementation STTransitionLayout

- (instancetype)initWithCurrentLayout:(UICollectionViewLayout *)currentLayout nextLayout:(UICollectionViewLayout *)newLayout
{
    if (self = [super initWithCurrentLayout:currentLayout nextLayout:newLayout]) {
        _fromContentOffset = currentLayout.collectionView.contentOffset;
        _toContentOffset = _fromContentOffset;
        _transitionContentSize = currentLayout.collectionViewContentSize;
        _animator = [[STAnimator alloc] initWithScreen:currentLayout.collectionView.window.screen];
    }
    
    return self;
}



- (void)setTransitionProgress:(CGFloat)transitionProgress
{
    if (self.transitionProgress != transitionProgress) {
        super.transitionProgress = transitionProgress;

        CGFloat t = transitionProgress;
        CGFloat f = 1 - t;
        
        // Update the offset
        CGPoint offset = CGPointZero;
        offset.x = f * self.fromContentOffset.x + t * self.toContentOffset.x;
        offset.y = f * self.fromContentOffset.y + t * self.toContentOffset.y;
        self.collectionView.contentOffset = offset;
        
        // Calculate the content size. We don't set directly, it will be asked for in -collectionViewContentSize
        CGSize size = CGSizeZero;
        size.width = f * self.currentLayout.collectionViewContentSize.width + t * self.nextLayout.collectionViewContentSize.width;
        size.height = f * self.currentLayout.collectionViewContentSize.height + t * self.nextLayout.collectionViewContentSize.height;
        self.transitionContentSize = size;
    }
}



#pragma mark - STTransitionLayoutProtocol


- (void)collectionViewDidCompleteTransition:(UICollectionView *)collectionView
{
    collectionView.contentOffset = self.toContentOffset;
}




#pragma mark - UICollectionViewLayout (UISubclassingHooks)


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
            if (strongSelf) {
                // Grab the average progress of all animations still animating
                CGFloat avgProgress = [[strongSelf.animations.allValues valueForKeyPath:@"@avg.progress"] floatValue];
                strongSelf.transitionProgress = avgProgress;
                
                // Invalidate the layout to update the positions of the cells
                [strongSelf invalidateLayout];
            }
            
        } completion:^{
            
            typeof(welf) strongSelf = welf;
            if (strongSelf) {
                // Finish the interaction and restore the saved userInteractionEnabled property
                [strongSelf.collectionView finishInteractiveTransition];
                strongSelf.collectionView.userInteractionEnabled = strongSelf.savedUserInteractionState;
            }
        }];
        
        self.savedUserInteractionState = self.collectionView.userInteractionEnabled;
        self.collectionView.userInteractionEnabled = NO;
    }
}




- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    // Add some padding to the rect incase of spring animations
    rect = CGRectInset(rect, -200, -200);
    NSMutableArray *poses = [NSMutableArray array];
    
    for (STLayoutAttributeAnimation *animation in self.animations.allValues) {
        UICollectionViewLayoutAttributes *pose = animation.attributes;
        
        // Only return the layout attributes within the rect
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
    return self.transitionContentSize;
}





- (void)setToContentOffset:(CGPoint)toContentOffset
{
    if (!CGPointEqualToPoint(_toContentOffset, toContentOffset)) {
        _toContentOffset = toContentOffset;
        [self invalidateLayout];
    }
}


- (void)setToContentOffsetForIndexPath:(NSIndexPath *)toIndexPath atScrollPosition:(UICollectionViewScrollPosition)position
{
    self.toContentOffset = [self finalContentOffsetForIndexPath:toIndexPath atScrollPosition:position];
}


- (CGPoint)finalContentOffsetForIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UICollectionViewScrollPosition)position;
{
    if (!indexPath) {
        return CGPointZero;
    }
    
    CGFloat x = 0.0f;
    CGFloat y = 0.0f;
    
    CGRect cellFrame = [self.nextLayout layoutAttributesForItemAtIndexPath:indexPath].frame;
    CGFloat minLineSpace = 0.0f;
    CGFloat minItemSpace = 0.0f;
    
    // Grab the flow layout spacing attributes
    if ([self.nextLayout isKindOfClass:[UICollectionViewFlowLayout class]]) {
        UICollectionViewFlowLayout *flow = (UICollectionViewFlowLayout *)self.nextLayout;
        minLineSpace = flow.minimumLineSpacing;
        minItemSpace = flow.minimumInteritemSpacing;
    }

    CGSize contentSize = self.nextLayout.collectionViewContentSize;
    CGRect insetFrame = UIEdgeInsetsInsetRect(self.collectionView.frame, self.collectionView.contentInset);
    
    
    // Vertical
    if (contentSize.height > CGRectGetHeight(insetFrame)) {
        CGFloat maxY = contentSize.height - CGRectGetHeight(insetFrame);
        CGRect adjustedCellFrame = UIEdgeInsetsInsetRect(cellFrame, UIEdgeInsetsMake(-minLineSpace, 0, 0, 0));
        
        switch (position) {
            case UICollectionViewScrollPositionLeft:
            case UICollectionViewScrollPositionTop: {
                y = adjustedCellFrame.origin.y;
                break;
            }
            case UICollectionViewScrollPositionRight:
            case UICollectionViewScrollPositionBottom: {
                y = adjustedCellFrame.origin.y - (CGRectGetHeight(insetFrame) - CGRectGetHeight(adjustedCellFrame) - minLineSpace);
                break;
            }
            case UICollectionViewScrollPositionCenteredHorizontally:
            case UICollectionViewScrollPositionCenteredVertically: {
                y = adjustedCellFrame.origin.y - ((CGRectGetHeight(insetFrame) / 2) - (CGRectGetHeight(adjustedCellFrame) / 2) - (minLineSpace / 2));
                break;
            }
                
            default:
                break;
        }
        
        y = MAX(0, MIN(y, maxY));
    }
    
    if (contentSize.width > CGRectGetWidth(insetFrame)) {
        CGFloat maxX = contentSize.width - CGRectGetWidth(insetFrame);
        CGRect adjustedCellFrame = UIEdgeInsetsInsetRect(cellFrame, UIEdgeInsetsMake(0, -minItemSpace, 0, 0));
        
        switch (position) {
            case UICollectionViewScrollPositionTop:
            case UICollectionViewScrollPositionLeft: {
                x = adjustedCellFrame.origin.x;
                break;
            }
            case UICollectionViewScrollPositionRight:
            case UICollectionViewScrollPositionBottom: {
                x = adjustedCellFrame.origin.x - (CGRectGetWidth(insetFrame) - CGRectGetWidth(adjustedCellFrame) - minItemSpace);
                break;
            }
            case UICollectionViewScrollPositionCenteredVertically:
            case UICollectionViewScrollPositionCenteredHorizontally:
            {
                x = adjustedCellFrame.origin.x - ((CGRectGetWidth(insetFrame) / 2) - (CGRectGetWidth(adjustedCellFrame) / 2) - (minItemSpace / 2));
                break;
            }
                
            default:
                break;
        }
        
        x = MAX(0, MIN(x, maxX));
    }
    
    return CGPointMake(x - self.collectionView.contentInset.left, y - self.collectionView.contentInset.top);
}




#pragma mark - Convenience Methods


- (NSString *)keyForIndexPath:(NSIndexPath *)indexPath kind:(NSString *)kind
{
    return [NSString stringWithFormat:@"%zd-%zd-%@", indexPath.row, indexPath.section, kind];
}


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
    
    UICollectionViewLayoutAttributes *initialAttributes = self.initialAttributes;
    UICollectionViewLayoutAttributes *targetAttributes = self.targetAttributes;

    
    CGRect bounds = self.attributes.bounds;
    bounds.size.width = f * initialAttributes.bounds.size.width + t * targetAttributes.bounds.size.width;
    bounds.size.height = f * initialAttributes.bounds.size.height + t * targetAttributes.bounds.size.height;
    self.attributes.bounds = bounds;
    
    self.attributes.center = self.currentPoint;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform.a = f * initialAttributes.transform.a + t * targetAttributes.transform.a;
    transform.b = f * initialAttributes.transform.b + t * targetAttributes.transform.b;
    transform.c = f * initialAttributes.transform.c + t * targetAttributes.transform.c;
    transform.d = f * initialAttributes.transform.d + t * targetAttributes.transform.d;
    transform.tx = f * initialAttributes.transform.tx + t * targetAttributes.transform.tx;
    transform.ty = f * initialAttributes.transform.ty + t * targetAttributes.transform.ty;
    self.attributes.transform = transform;
}

@end
