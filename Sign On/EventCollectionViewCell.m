//
//  EventCollectionViewCell.m
//  Sign On
//
//  Created by Ben Rooke on 3/23/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "EventCollectionViewCell.h"
#import <FacebookSDK/FacebookSDK.h>
#import <QuartzCore/QuartzCore.h>

CGFloat sizeOfThumbnails = 65.0;

@implementation EventCollectionViewCell

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CGRect profileFrame = CGRectMake(0, 0, sizeOfThumbnails, sizeOfThumbnails);
        CGRect nameFrame = CGRectMake(0, sizeOfThumbnails, sizeOfThumbnails, 15);
        
        self.profilePicture = [[FBProfilePictureView alloc] initWithFrame:profileFrame];
        self.profilePicture.layer.borderColor = [[UIColor whiteColor] CGColor];
        self.profilePicture.layer.borderWidth = 1.0;
        self.profilePicture.layer.cornerRadius = CGRectGetWidth(profileFrame)/2.0;
        
        self.nameLabel = [[UILabel alloc] initWithFrame:nameFrame];
        self.nameLabel.backgroundColor = [UIColor clearColor];
        self.nameLabel.textColor = [UIColor whiteColor];
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        self.nameLabel.font = [UIFont systemFontOfSize:11];
        
        [self addSubview:self.profilePicture];
        [self addSubview:self.nameLabel];
    }
    return self;
}

@end
