//
//  AppDelegate.m
//  Sign On
//
//  Created by Ben Rooke on 11/27/14.
//  Copyright (c) 2014 Intertwine. All rights reserved.
//

#import "AppDelegate.h"
#import "IntertwineManager.h"
#import "IntertwineManager+Friends.h"
#import "ActivityViewController.h"
#import <FacebookSDK/FacebookSDK.h>


#import "IntertwineManager+Events.h"
#import "Friend.h"

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    // Call FBAppCall's handleOpenURL:sourceApplication to handle Facebook app responses
    BOOL wasHandled = [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    
    // You can add your app-specific url handling code here if needed
    return wasHandled;
}

- (void)presentError:(NSString*)title description:(NSString*)description {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:description delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
    [alert show];
}

- (CGFloat) bottomTabBarHeight {
    return 44.0;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [FBLoginView class];
    
    
//    Friend *f = [Friend new];
//    f.first = @"David";
//    f.last = @"Matthew";
//    f.accountID = @"18";
//    EventDate *d = [EventDate new];
//    d.semester = 0;
//    d.date = @"2015-02-05";
//    d.time = @"12:00:00";
//    [IntertwineManager createEvent:@"Test Event" withFriends:@[f] withEventDate:d withResponse:^(id json, NSError *error, NSURLResponse *response) {
//        if (error) {
//            NSLog(@"Error: %@", error);
//        }
//    }];
    
    
    NSDictionary *remoteNotif = [launchOptions objectForKey: UIApplicationLaunchOptionsRemoteNotificationKey];
    
    //Accept push notification when app is not open
    if (remoteNotif) {
        NSLog(@"Remote notification info: %@", remoteNotif);
        [self presentNotificationBanner:remoteNotif inForeground:NO];
        return YES;
    }
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    //This code will work in iOS 8.0 xcode 6.0 or later
    
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge
                                                                                         |UIUserNotificationTypeSound
                                                                                         |UIUserNotificationTypeAlert) categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    
    NSLog(@"Is registered: %d", [[UIApplication sharedApplication] isRegisteredForRemoteNotifications]);
    
#else
    //register to receive notifications
    UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:myTypes];
#endif

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}



#pragma mark - Receiving Push Notifications

- (void)presentNotificationBanner:(NSDictionary * _Nonnull)userInfo inForeground:(BOOL)inForeground{
    [(ActivityViewController*)[(id)self.window.rootViewController activityViewController] presentRemoteNotification:(NSDictionary * _Nonnull)userInfo inForeground:inForeground];
}

- (void)application:(UIApplication * _Nonnull)application didReceiveRemoteNotification:(NSDictionary * _Nonnull)userInfo {
    UIApplicationState state = [application applicationState];
    // user tapped notification while app was in background
    if (state == UIApplicationStateInactive || state == UIApplicationStateBackground) {
        // go to screen relevant to Notification content
        [self presentNotificationBanner:userInfo inForeground:NO];
    } else {
        // App is in UIApplicationStateActive (running in foreground)
        // perhaps show an UIAlertView
        [self presentNotificationBanner:userInfo inForeground:YES];
    }
}



#pragma mark - Remote Notifications (Push Notifications)


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"Device token: %@", deviceToken);
    [IntertwineManager setDeviceToken:deviceToken];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    NSLog(@"Failed to get token, error: %@", error);
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
// Only COMPILE this if compiled against BaseSDK iOS8.0 or greater
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    //register to receive notifications
    NSLog(@"Did register user notification settings!");
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler
{
    NSLog(@"Identifier: %@", identifier);
    //handle the actions
    if ([identifier isEqualToString:@"declineAction"]){
    }
    else if ([identifier isEqualToString:@"answerAction"]){
    }
}
#endif




@end
