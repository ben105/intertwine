//
//  NavigationView.h
//  Navigation
//
//  Created by Ben Rooke on 7/15/15.
//  Copyright (c) 2015 Ben Rooke. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NavigationViewDelegate <NSObject>
@optional
- (void)willNavigateToHome:(NSDictionary*)userInfo;
- (void)willNavigateToFriends:(NSDictionary*)userInfo;
- (void)willNavigateToSettings:(NSDictionary*)userInfo;
- (void)didNavigateToHome;
- (void)didNavigateToFriends;
- (void)didNavigateToSettings;
@end

@interface NavigationView : UIView

@property (nonatomic, weak) id<NavigationViewDelegate> delegate;

- (void)navigateToHomeAnimated:(BOOL)animated;
- (void)navigateToFriendsAnimated:(BOOL)animated;
- (void)navigateToSettingsAnimated:(BOOL)animated;

@end

extern const NSString *NavigationViewAnimationDurationKey;
extern const CGFloat navigationViewHeight;