//
//  EventCollectionViewCell.m
//  Sign On
//
//  Created by Ben Rooke on 3/23/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "EventCollectionViewCell.h"
#import "FriendProfileView.h"
#import <FacebookSDK/FacebookSDK.h>
#import <QuartzCore/QuartzCore.h>


const CGFloat labelHeight = 12.0;
const CGFloat extraSpace = 15.0;

@interface EventCollectionViewCell()
+ (CGFloat) _bubbleWidth;
@end

@implementation EventCollectionViewCell

/* Determine the bubble (profile pic) width programatically, because
 * different size screens will need to fill different spaces. */
+ (CGFloat) _bubbleWidth {
    CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    CGFloat interitemSpacing = 15.0;
    /* If we want 4 bubbles across the screen, that means there will be 5 spaces.
     * Think about it... */
    return (screenWidth - (interitemSpacing * 5.0)) / 4.0;
}

+ (CGFloat) cellWidth {
    /* some extra space for interspacng */
    return [EventCollectionViewCell _bubbleWidth] + extraSpace;
}

+ (CGFloat) cellHeight {
    return [EventCollectionViewCell _bubbleWidth] + labelHeight;
}

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat bubbleWidth = [EventCollectionViewCell _bubbleWidth];
        CGRect profileFrame = CGRectMake(extraSpace, 0, bubbleWidth, bubbleWidth);
        CGRect labelFrame = CGRectMake(extraSpace, bubbleWidth, bubbleWidth, labelHeight);
        
        self.profilePicture = [[FriendProfileView alloc] initWithFrame:profileFrame];
//        self.profilePicture.layer.borderColor = [[UIColor blackColor] CGColor];
//        self.profilePicture.layer.borderWidth = 1.0;
//        self.profilePicture.layer.cornerRadius = CGRectGetWidth(profileFrame)/2.0;
        
        self.nameLabel = [[UILabel alloc] initWithFrame:labelFrame];
        self.nameLabel.backgroundColor = [UIColor clearColor];
        self.nameLabel.textColor = [UIColor blackColor];
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        self.nameLabel.font = [UIFont systemFontOfSize:11];
        
        [self addSubview:self.profilePicture];
        [self addSubview:self.nameLabel];
    }
    return self;
}

@end
