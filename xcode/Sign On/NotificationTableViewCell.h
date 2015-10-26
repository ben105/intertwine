//
//  NotificationTableViewCell.h
//  Intertwine
//
//  Created by Ben Rooke on 10/21/15.
//  Copyright © 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NotificationBanner;

@interface NotificationTableViewCell : UITableViewCell

@property (nonatomic, strong) NotificationBanner *notificationView;

- (void) setProfileID:(NSString*)profileID message:(NSString*)message notifInfo:(NSDictionary*)notifInfo;

@end
