//
//  NotificationMenuViewController.h
//  Intertwine
//
//  Created by Ben Rooke on 10/21/15.
//  Copyright © 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NotificationMenuDelegate <NSObject>
@optional
- (void)shouldDismissNotificationMenu;
- (void)selectedNotificationMenuInfo:(NSDictionary*)notifInfo;
@end

@interface NotificationMenuViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) id<NotificationMenuDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *notifications;

@end
