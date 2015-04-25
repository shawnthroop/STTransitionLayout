# STTransitionLayout

A UICollectionViewTransitionLayout subclass and UICollectionView extension allowing for customisable layout transition animations.

Highly influenced by [Timothy Moose][moose]'s [TLLayoutTransitioning][ttlt].


## Providing Animations

Start an animated transition by calling `transitionToCollectionViewLayout:completion:` and providing a new STTransitionLayou object from the delegate method `collectionView:transitionLayoutForOldLayout:newLayout:`.

When creating this layout object, provide animations via the `animationProvider` block:

``` objc
- (UICollectionViewTransitionLayout *)collectionView:(UICollectionView *)collectionView transitionLayoutForOldLayout:(UICollectionViewLayout *)fromLayout newLayout:(UICollectionViewLayout *)toLayout
{
    STTransitionLayout *layout = [[STTransitionLayout alloc] initWithCurrentLayout:fromLayout nextLayout:toLayout];
    layout.animationProvider = ^(UICollectionViewLayoutAttributes *fromPose, UICollectionViewLayoutAttributes *toPose) {
      return [[STLayoutAttributeAnimation alloc] initWithInitialAttributes:fromPose target:toPose];
    };

    return layout;
}
```

This is the point where you can customize the spring damping, friction, and even the initial velocity of animations.


## Cell Animations

As you can see in the example above, STLayoutAttributeAnimation objects drive animations for every indexPath in your collection view. These objects will transition the transform, bounds, and center properties between the initial and target attributes passed to them.

To transition other properties, like `transform3D`, override `interpolatePose` in your subclass. Remember to call super.


## Collection View Animations

In addition to animating cells STTransitionLayout objects also transition the `contentSize` and `contentOffset` of the collection view. These values are updated to match the average progress of all cell animations.


## Content Offset

The UICollectionViewTransitionLayout object returned by `transitionToCollectionViewLayout:completion:` is that which you provide in `collectionView:transitionLayoutForOldLayout:newLayout:`. Use this object to set a specific content offset for the transition to end at.

Say you want the transition to end with a certain cell positioned in the center of your collection view:


``` objc
UICollectionViewTransitionLayout *layout = [self.collectionView transitionToCollectionViewLayout:newLayout completion:nil];

if ([layout isKindOfClass:[STTransitionLayout class]])
{
    STTransitionLayout *transitionLayout = (STTransitionLayout *)layout;
    [transitionLayout setToContentOffsetForIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically];
}

```

Alternatively, if Apple's `UICollectionViewScrollPosition`s aren't quite exact enough, call `finalContentOffsetForIndexPath:atScrollPosition:` and then manually set the `toContentOffset` after tweaking the returned CGPoint value.

``` objc
CGPoint offset = [transitionLayout finalContentOffsetForIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop];
transitionLayout.toContentOffset = CGPointMake(offset.x, offset.y - 20.0f);
```


# To-Do

- Transition section headers and footers.



[moose]: https://github.com/wtmoose
[ttlt]: https://github.com/wtmoose/TLLayoutTransitioning
