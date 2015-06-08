//
//  AppDelegate.h
//  Sign On
//
//  Created by Ben Rooke on 11/27/14.
//  Copyright (c) 2014 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)presentError:(NSString*)title description:(NSString*)description;

/* For the main home screen, getting the bottom bar height. */
- (CGFloat) bottomTabBarHeight;

@end

