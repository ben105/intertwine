//
//  FriendsTableViewCell.m
//  FriendsList
//
//  Created by Ben Rooke on 7/16/15.
//  Copyright (c) 2015 Ben Rooke. All rights reserved.
//

#import "FriendsTableViewCell.h"
#import <FacebookSDK/FacebookSDK.h>

const CGFloat profilePictureWidth = 46.0;
const CGFloat friendNameFontSize = 14.0;
const CGFloat bufferSpace = 13.0;

const CGFloat friendsCellHeight = 60.0;

#define CELL_WIDTH CGRectGetWidth([self.contentView frame])
#define FRIEND_LABEL_X (bufferSpace * 2.0 + profilePictureWidth)
#define FRIEND_LABEL_FRAME CGRectMake(FRIEND_LABEL_X, 0, CELL_WIDTH - FRIEND_LABEL_X, friendsCellHeight)

#define PROFILE_PIC_CENTER CGPointMake(bufferSpace + profilePictureWidth/2.0, friendsCellHeight/2.0)

@interface FriendsTableViewCell ()
@end


@implementation FriendsTableViewCell

- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.friendLabel];
        [self.contentView addSubview:self.friendProfilePicture];
    }
    return self;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setAccountID:(NSString *)accountID {
    _accountID = accountID;
    self.friendProfilePicture.profileID = accountID;
}

- (UILabel*)friendLabel {
    if (!_friendLabel) {
        _friendLabel = [[UILabel alloc] initWithFrame:FRIEND_LABEL_FRAME];
        _friendLabel.backgroundColor = [UIColor clearColor];
        _friendLabel.textColor = [UIColor whiteColor];
        _friendLabel.textAlignment = NSTextAlignmentLeft;
        _friendLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:friendNameFontSize];
    }
    return _friendLabel;
}

- (FBProfilePictureView*)friendProfilePicture {
    if (!_friendProfilePicture) {
        _friendProfilePicture = [[FBProfilePictureView alloc] initWithFrame:CGRectMake(0, 0, profilePictureWidth, profilePictureWidth)];
        _friendProfilePicture.center = PROFILE_PIC_CENTER;
        _friendProfilePicture.layer.borderColor = [[UIColor whiteColor] CGColor];
        _friendProfilePicture.layer.borderWidth = 1.0;
        _friendProfilePicture.layer.cornerRadius = profilePictureWidth/2.0;
//        _friendProfilePicture.profileID = 0;
    }
    return _friendProfilePicture;
}

@end
