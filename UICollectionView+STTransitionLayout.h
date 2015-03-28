//
//  UICollectionView+STTransitionLayout.h
//  STCollectionViewTransition
//
//  Created by Shawn Throop on 28/03/15.
//  Copyright (c) 2015 Silent H Designs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STTransitionLayout.h"

@interface UICollectionView (STTransitionLayout)

- (BOOL)isInteractiveTransitionInProgress;

- (UICollectionViewTransitionLayout *)transitionToCollectionViewLayout:(UICollectionViewLayout *)newLayout completion:(void(^)())completionHandler;

@end
