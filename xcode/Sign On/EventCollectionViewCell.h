//
//  EventCollectionViewCell.h
//  Sign On
//
//  Created by Ben Rooke on 3/23/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FriendProfileView;

@interface EventCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) FriendProfileView *profilePicture;
@property (nonatomic, strong) UILabel *nameLabel;

/* Determines the width programatically based on the screen size. */
+ (CGFloat) cellWidth;
+ (CGFloat) cellHeight;

@end
