//
//  EventCollectionViewCell.h
//  Sign On
//
//  Created by Ben Rooke on 3/23/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FBProfilePictureView;

@interface EventCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) FBProfilePictureView *profilePicture;
@property (nonatomic, strong) UILabel *nameLabel;

@end
