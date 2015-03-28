//
//  UICollectionView+STTransitionLayout.m
//  STCollectionViewTransition
//
//  Created by Shawn Throop on 28/03/15.
//  Copyright (c) 2015 Silent H Designs. All rights reserved.
//

#import "UICollectionView+STTransitionLayout.h"
#import <objc/runtime.h>

static char kSTTransitionLayoutKey;

@implementation UICollectionView (STTransitionLayout)

- (UICollectionViewTransitionLayout *)st_transitionLayout
{
    return objc_getAssociatedObject(self, &kSTTransitionLayoutKey);
}

- (void)st_setTransitionLayout:(UICollectionViewTransitionLayout *)transitionLayout
{
    objc_setAssociatedObject(self, &kSTTransitionLayoutKey, transitionLayout, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}



- (UICollectionViewTransitionLayout *)transitionToCollectionViewLayout:(UICollectionViewLayout *)newLayout completion:(void (^)())completionHandler
{
    __weak typeof(self) welf = self;
    UICollectionViewTransitionLayout *layout = [self startInteractiveTransitionToCollectionViewLayout:newLayout completion:^(BOOL completed, BOOL finished) {
        
        typeof(welf) strongSelf = welf;
        
        UICollectionViewTransitionLayout *transitionLayout = [strongSelf st_transitionLayout];
        if ([transitionLayout conformsToProtocol:@protocol(STTransitionLayoutProtocol)]) {
            id<STTransitionLayoutProtocol>l = (id<STTransitionLayoutProtocol>)transitionLayout;
            [l collectionViewDidCompleteTransition:strongSelf];
        }
        
        if (completionHandler) {
            completionHandler();
        }
        
        [strongSelf st_setTransitionLayout:nil];
    }];
    
    [self st_setTransitionLayout:layout];
    return layout;
}


- (BOOL)isInteractiveTransitionInProgress
{
    return [self st_transitionLayout] != nil;
}


@end
