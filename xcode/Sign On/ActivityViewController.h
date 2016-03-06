//
//  ActivityViewController.h
//  Intertwine
//
//  Created by Ben Rooke on 4/7/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActivityTableViewCell.h"
#import "CommentViewController.h"
#import "NotificationBanner.h"
#import "NotificationMenuViewController.h"
#import "EventViewController.h"
#import "HeaderPagingScrollView.h"

@class FriendsViewController;

@interface ActivityViewController : UIViewController <HeaderPagingScrollViewDataSource, EventViewControllerDelegate, NotificationMenuDelegate, NotificationBannerDelegate, CommentViewDelegate, ActivityCellDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonnull, nonatomic, strong) UITableView *activityTableView;
@property (nonnull, nonatomic, strong) UITableView *upcomingTableView;

@property (nullable, nonatomic, strong) NSMutableArray *events;
@property (nullable, nonatomic, strong) NSMutableArray *todaysEvents;
@property (nullable, nonatomic, strong) NSMutableArray *tomorrowsEvents;
@property (nullable, nonatomic, strong) NSMutableArray *thisWeeksEvents;
@property (nullable, nonatomic, strong) NSMutableArray *thisMonthsEvents;
@property (nullable, nonatomic, strong) NSMutableArray *upcomingEvents;


@property (nullable, nonatomic, strong) FriendsViewController *friendsVC;

- (void) presentRemoteNotification:(NSDictionary * _Nonnull)userInfo inForeground:(BOOL)inForeground;

@end
