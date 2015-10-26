//
//  NotificationBanner.h
//  Intertwine
//
//  Created by Ben Rooke on 10/6/15.
//  Copyright © 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FriendProfileView;

@protocol NotificationBannerDelegate <NSObject>
@optional
-(void)didTouchNotificationBanner:(NSDictionary*)notifInfo;

@end


@interface NotificationBanner : UIControl

- (instancetype) initWithFrame:(CGRect)frame andMessage:(NSString*)message profileID:(NSString*)profileID notifInfo:(NSDictionary*)notifInfo;
- (void) setProfileID:(NSString*)profileID message:(NSString*)message notifInfo:(NSDictionary*)notifInfo;

@property (nonatomic, weak) id<NotificationBannerDelegate> delegate;

@property (nonatomic, copy) NSString *message;
@property (nonatomic, strong, readonly) UILabel *messageLabel;
@property (nonatomic, strong) FriendProfileView *profilePicture;

@property (nonatomic) CGFloat bannerHeight;

@property (nonatomic, strong) NSDictionary *notifInfo;

@end

extern const CGFloat defaultBannerHeight;