//
//  STTransitionLayout.h
//  STCollectionViewTransition
//
//  Created by Shawn Throop on 28/03/15.
//  Copyright (c) 2015 Silent H Designs. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "STAnimator.h"


@interface STLayoutAttributeAnimation : STSpringAnimation

@property (nonatomic, readonly) NSIndexPath *indexPath;
@property (nonatomic, readonly) UICollectionViewLayoutAttributes *attributes;

- (instancetype)initWithInitialAttributes:(UICollectionViewLayoutAttributes *)initial target:(UICollectionViewLayoutAttributes *)target NS_DESIGNATED_INITIALIZER;

- (void)interpolatePose;

@end




@protocol STTransitionLayoutProtocol <NSObject>

- (void)collectionViewDidCompleteTransition:(UICollectionView *)collectionView;

@end


typedef STLayoutAttributeAnimation *(^STLayoutAttributeAnimationBlock)(UICollectionViewLayoutAttributes *fromPose, UICollectionViewLayoutAttributes *toPose);

@interface STTransitionLayout : UICollectionViewTransitionLayout <STTransitionLayoutProtocol>

@property (nonatomic, readonly) CGPoint fromContentOffset;
@property (nonatomic) CGPoint toContentOffset;

@property (nonatomic, copy) STLayoutAttributeAnimationBlock animationProvider;

- (instancetype)initWithCurrentLayout:(UICollectionViewLayout *)currentLayout nextLayout:(UICollectionViewLayout *)newLayout;

@end
