//
//  NotificationBanner.m
//  Intertwine
//
//  Created by Ben Rooke on 10/6/15.
//  Copyright © 2015 Intertwine. All rights reserved.
//

#import "NotificationBanner.h"
#import "FriendProfileView.h"
#import "UILabel+DynamicHeight.h"

const CGFloat bannerSpacing = 10.0;
const CGFloat bannerProfilePictureWidth = 38.0;

const CGFloat defaultBannerHeight = 100.0;
const CGFloat defaultBannerLabelHeight = 32.0;
const CGFloat bannerLabelFontSize = 18.0;

const CGFloat maxLabelHeight = 100.0;


@interface NotificationBanner()
- (void)_touchedNotificationBanner;
@end


@implementation NotificationBanner

@synthesize messageLabel = _messageLabel;

- (instancetype) initWithFrame:(CGRect)frame andMessage:(NSString*)message profileID:(NSString*)profileID notifInfo:(NSDictionary*)notifInfo {
    self = [super initWithFrame:frame];
    if (self) {
        self.message = message;
        self.profilePicture.profileID = profileID;
        self.notifInfo = notifInfo;
    }
    return self;
}

- (void) setProfileID:(NSString*)profileID message:(NSString*)message notifInfo:(NSDictionary*)notifInfo {
    self.profilePicture.profileID = profileID;
    self.message = message;
    self.notifInfo = notifInfo;
}



- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:20.0/255.0 green:81.0/255.0 blue:121.0/255.0 alpha:1.0];
        self.bannerHeight = 0;
        [self addSubview:self.profilePicture];
        [self addSubview:self.messageLabel];
        
        [self addTarget:self action:@selector(_touchedNotificationBanner) forControlEvents:UIControlEventTouchUpInside];
//        [self addTarget:self action:@selector(removeFromSuperview) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)_touchedNotificationBanner {
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(didTouchNotificationBanner:)]) {
            [self.delegate didTouchNotificationBanner:self.notifInfo];
        }
    }
}


- (void) setMessage:(NSString *)message {
    _message = message;
    _messageLabel.text = message;
    
    // Determine height.
    CGSize size = [self.messageLabel sizeOfMultiLineLabel];
    
    if (size.height > maxLabelHeight) {
        size.height = maxLabelHeight;
    }
    
    CGRect labelFrame = self.messageLabel.frame;
    labelFrame.size.height = size.height;
    _messageLabel.frame = labelFrame;
    
    
    CGFloat newBannerHeight = defaultBannerHeight;
    if (size.height + (bannerSpacing * 2.0) > defaultBannerHeight) {
        newBannerHeight = size.height + (bannerSpacing * 2.0);
    }
    
    CGRect selfFrame = self.frame;
    selfFrame.size.height = newBannerHeight;
    self.frame = selfFrame;

    CGPoint center = _messageLabel.center;
    _messageLabel.center = CGPointMake(center.x, CGRectGetHeight(self.frame)/2.0);
    
    CGRect profileFrame = self.profilePicture.frame;
    profileFrame.origin.y = _messageLabel.frame.origin.y;
    self.profilePicture.frame = profileFrame;
    
    // Set Height.
    self.bannerHeight = newBannerHeight;
}

#pragma mark - Lazy Loading

- (FriendProfileView*)profilePicture {
    if (!_profilePicture) {
        _profilePicture = [[FriendProfileView alloc] initWithFrame:CGRectMake(bannerSpacing, bannerSpacing, bannerProfilePictureWidth, bannerProfilePictureWidth)];
    }
    return _profilePicture;
}

- (UILabel*)messageLabel {
    if (!_messageLabel) {
        CGFloat viewWidth = CGRectGetWidth(self.frame);
        CGFloat profilePicOffset = bannerSpacing + bannerProfilePictureWidth + bannerSpacing;
        CGFloat labelWidth = viewWidth - profilePicOffset;
        _messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(profilePicOffset, bannerSpacing, labelWidth, defaultBannerLabelHeight)];
        _messageLabel.textColor = [UIColor whiteColor];
        _messageLabel.backgroundColor = [UIColor clearColor];
        _messageLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:bannerLabelFontSize];
        _messageLabel.numberOfLines = 0;
    }
    return _messageLabel;
}

@end
