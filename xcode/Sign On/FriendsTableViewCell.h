//
//  FriendsTableViewCell.h
//  FriendsList
//
//  Created by Ben Rooke on 7/16/15.
//  Copyright (c) 2015 Ben Rooke. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FriendProfileView;

@interface FriendsTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *friendLabel;
@property (nonatomic, copy) NSString *accountID;
@property (nonatomic, strong) FriendProfileView *friendProfilePicture;

- (void)isFaded:(BOOL)faded;

@end

extern const CGFloat friendsCellHeight;