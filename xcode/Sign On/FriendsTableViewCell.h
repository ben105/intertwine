//
//  FriendsTableViewCell.h
//  FriendsList
//
//  Created by Ben Rooke on 7/16/15.
//  Copyright (c) 2015 Ben Rooke. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FBProfilePictureView;

@interface FriendsTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *friendLabel;
@property (nonatomic, copy) NSString *accountID;
@property (nonatomic, strong) FBProfilePictureView *friendProfilePicture;

- (void)isFaded:(BOOL)faded;

@end

extern const CGFloat friendsCellHeight;