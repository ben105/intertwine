//
//  ActivityViewController.h
//  Intertwine
//
//  Created by Ben Rooke on 4/7/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActivityTableViewCell.h"
#import "NewActivityViewController.h"
#import "CommentViewController.h"
#import "NotificationBanner.h"
#import "NotificationMenuViewController.h"

@class FriendsViewController;

@interface ActivityViewController : UIViewController <NotificationMenuDelegate, NotificationBannerDelegate, CommentViewDelegate, ActivityCellDelegate, ActivityCreationDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *activityTableView;
@property (nonatomic, strong) NSMutableArray *events;

@property (nonatomic, strong) FriendsViewController *friendsVC;

- (void) presentRemoteNotification:(NSDictionary * _Nonnull)userInfo inForeground:(BOOL)inForeground;

@end
