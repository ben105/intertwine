//
//  ActivityViewController.m
//  Intertwine
//
//  Created by Ben Rooke on 4/7/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "ActivityViewController.h"
#import "ActivityCompleteTableViewCell.h"
#import "EventObject.h"
#import "Friend.h"
#import "FriendProfileView.h"
#import "FriendsViewController.h"
#import "CommentViewController.h"
#import "ButtonBarView.h"
#import "NotificationBanner.h"
#import "ActivityAlertView.h"
#import "NotificationMenuViewController.h"
#import "IntertwineNotification.h"
#import "NSDate+Display.h"

#import "IntertwineManager+Activity.h"
#import "IntertwineManager+Friends.h"
#import "IntertwineManager+Events.h"

#import <AudioToolbox/AudioToolbox.h>

#define BACKGROUND_COLOR [UIColor colorWithRed:21.0/255.0 green:52.0/255.0 blue:88.0/255.0 alpha:1]
#define ACTIVITY_VIEW_HEADER_COLOR [UIColor colorWithRed:0 green:0 blue:0 alpha:0.19]
#define HEADER_COLOR_NON_TRANSPARENT [UIColor colorWithRed:14.0/255.0 green:39.0/255.0 blue:64.0/255.0 alpha:1]
const char titles[2][12] = { "Upcoming", "Activity" };

const CGFloat ActivityViewSectionHeaderHeight = 50.0;
const CGFloat headerHeight = 80.0;
const CGFloat footerHeight = 50.0;
const CGFloat y_toolBarItems = headerHeight / 2.0;
#define y_footer CGRectGetHeight(self.view.frame) - footerHeight

const CGFloat slideSideBarsAnimationSpeed = 0.3;

@interface ActivityViewController ()

/* To switch between the two table views, we should put a background scroll
 * view on the view. */
@property (nonatomic, strong) HeaderPagingScrollView *backgroundScrollView;

@property (nonatomic) SystemSoundID notificationSound;
- (void)_loadNotificationsMenu;

@property (nonatomic) BOOL viewInForeground;

@property (nonatomic, strong) CommentViewController *commentView;
- (void) _presentCommentViewForEvent:(EventObject*)event;

@property (nonatomic, strong) EventViewController *createActivityVC;
@property (nonatomic, strong) UIImageView *backgroundImage;
@property (nonatomic, strong) UIView *header;
@property (nonatomic, strong) UIImageView *footer;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *gearButton;

@property (nonatomic, strong) UIButton *notificationsButton;
@property (nonatomic, strong) NSMutableArray *savedNotifications;
@property (nonatomic, strong) NotificationMenuViewController *notificationMenuViewController;
- (void) _presentNotificationsViewController;

@property (nonatomic, strong) UIControl *blackSheet;
- (void) _clearSubViewControllers;

@property (nonatomic, strong) UIButton *newActivityButton;
- (void) _newActivity;
- (void) _loadActivities;
- (void) _removeUpcomingActivities;
- (void) _sortUpcomingActivitiesIntoSections;
- (void) _updateAvailableSections;
- (void) _loadUpcomingActivities;

/* Sorting method. */
- (void) _sortArrayByDate:(NSMutableArray*)unsortedArray;

/* Once receiving JSON from the server, translate it into a mutable dictionary. */
- (NSMutableArray*) _extractEventsFromJSON:(id)json;

- (void)_markActivityComplete:(EventObject*)event forCell:(ActivityTableViewCell*)cell;
- (void)_presentEventViewController;

@property (nonatomic, strong) NSArray *friends;
@property (nonatomic, strong) UIButton *friendsButton;
- (void) _loadFriends;
- (void) _presentFriendsViewController;

- (void) _load;

/* Private methods for how we handle the table view data sources. */
- (NSInteger)_activityTableViewNumberOfRowsInSection:(NSInteger)section;
- (UITableViewCell*)_activityTableViewNormalCellForRowAtIndexPath:(NSIndexPath*)indexPath;
- (UITableViewCell*)_activityTableViewCompletedCellForRowAtIndexPath:(NSIndexPath*)indexPath;
- (UITableViewCell*)_activityTableViewCellForRowAtIndexPath:(NSIndexPath*)indexPath;
- (UITableViewCell*)_upcomingTableViewCellForRowAtIndexPath:(NSIndexPath*)indexPath;

/* Because we have different arrays for each type of upcoming event,
 * we need a way to keep track of the section count, and which section
 * has data from which event. */
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSMutableArray *availableSections;
@property (nonatomic, strong) NSArray *sectionNames;

@end


@implementation ActivityViewController

#pragma mark - View Management

- (void) _clearSubViewControllers {
    [UIView animateWithDuration:slideSideBarsAnimationSpeed animations:^{
        self.blackSheet.alpha = 0;
        CGRect friendsSideFrame = self.view.frame;
        friendsSideFrame.origin.x = friendsSideFrame.size.width;
        friendsSideFrame.origin.y = 0;
        self.friendsVC.view.frame = friendsSideFrame;
    } completion:^(BOOL finished) {
        [self.friendsVC.view removeFromSuperview];
        _friendsVC = nil;
        [self _load];
    }];
}

- (void) _showViews {
    self.activityTableView.alpha = 1;
    self.upcomingTableView.alpha = 1;
    self.gearButton.alpha = 1;
    self.notificationsButton.alpha = 1;
    self.friendsButton.alpha = 1;
    self.header.alpha = 1;
    self.titleLabel.alpha = 1;
    self.footer.alpha = 1;
    self.newActivityButton.alpha = 1;
}

- (void) _hideViews {
    self.activityTableView.alpha = 0;
    self.upcomingTableView.alpha = 0;
    self.gearButton.alpha = 0;
    self.notificationsButton.alpha = 0;
    self.friendsButton.alpha = 0;
    self.header.alpha = 0;
    self.titleLabel.alpha = 0;
    self.footer.alpha = 0;
    self.newActivityButton.alpha = 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *path  = [[NSBundle mainBundle] pathForResource:@"Submarine" ofType:@"aiff"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        NSURL *pathURL = [NSURL fileURLWithPath:path];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef) pathURL, &_notificationSound);
    }
    else
    {
        NSLog(@"Error, sound file not found: %@", path);
    }
    
    
    [IntertwineManager updateDeviceToken:[IntertwineManager getDeviceToken]];
    
    // Do any additional setup after loading the view.
    self.events = [NSMutableArray new];
    self.upcomingEvents = [NSMutableArray new];
    self.todaysEvents = [NSMutableArray new];
    self.tomorrowsEvents = [NSMutableArray new];
    self.thisWeeksEvents = [NSMutableArray new];
    self.thisMonthsEvents = [NSMutableArray new];
    
    self.availableSections = [NSMutableArray new];
    self.sections = @[self.todaysEvents, self.tomorrowsEvents, self.thisWeeksEvents, self.thisMonthsEvents, self.upcomingEvents];
    self.sectionNames = @[@"Today", @"Tomorrow", @"This Week", @"This Month", @"Upcoming"];
    
    self.view.backgroundColor = BACKGROUND_COLOR;
    [self.view addSubview:self.backgroundImage];
    
    [self.view addSubview:self.backgroundScrollView];
    [self.backgroundScrollView addSubview:self.activityTableView];
    [self.backgroundScrollView addSubview:self.upcomingTableView];
    
    [self.view addSubview:self.header];
    [self.view addSubview:self.footer];

//    CGRect frame = self.footer.frame;
//    frame.origin.x = 0;
//    frame.origin.y = 0;
//    self.newActivityButton.frame = frame;
    [self.view addSubview:self.newActivityButton];
    
//    [self.view addSubview:self.titleLabel];
//    self.titleLabel.text = @"Intertwine";
    
//    [self.view addSubview:self.gearButton];
    [self.view addSubview:self.notificationsButton];
//    [self.view addSubview:self.friendsButton];
    [self.view addSubview:self.blackSheet];
}

- (void)viewWillDisappear:(BOOL)animated {
    self.viewInForeground = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void) _load {
    [self _loadActivities];
    [self _loadUpcomingActivities];
    [self _loadFriends];
    [self _loadNotificationsMenu];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.viewInForeground = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_load)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [self _load];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Notification Menu

- (void)_loadNotificationsMenu {
    [IntertwineManager getNotificationsWithResponse:^(id json, NSError *error, NSURLResponse *response) {
        if (error) {
            NSLog(@"Error while trying to get notifications for menu: %@", error);
            return;
        }
        [self.savedNotifications removeAllObjects];
        for (NSDictionary *notificationDict in json) {
            IntertwineNotification *notification = [[IntertwineNotification alloc] initWithID:[notificationDict objectForKey:@"id"]
                                                                                      message:[notificationDict objectForKey:@"message"]
                                                                                      payload:[notificationDict objectForKey:@"payload"]
                                                                                     sentTime:[notificationDict objectForKey:@"sent_time"]];
            [self.savedNotifications addObject:notification];
        }
    }];
}

- (void) _presentNotificationsViewController {
    self.notificationMenuViewController.notifications = self.savedNotifications;
    self.notificationMenuViewController.delegate = self;
    self.notificationMenuViewController.view.alpha = 0;

    CGRect frame = self.notificationMenuViewController.view.frame;
    frame.origin.y = frame.size.height;
    self.notificationMenuViewController.view.frame = frame;
    
    [self.view addSubview:self.notificationMenuViewController.view];
    [UIView animateWithDuration:0.5 animations:^{
        CGRect frame = self.notificationMenuViewController.view.frame;
        frame.origin.y = 0;
        self.notificationMenuViewController.view.frame = frame;
        self.notificationMenuViewController.view.alpha = 1;
    }];
}

#pragma mark - Notifications Received

- (NSInteger)_findEventWithEventID:(NSNumber*)eventID {
    NSUInteger eventInteger = [eventID unsignedIntegerValue];
    // Iterate through the event cell data to find the same event ID.
    EventObject *foundEvent = nil;
    int i=0;
    for (;i<[self.events count]; i++) {
        EventObject *currentEvent = [self.events objectAtIndex:i];
        if ([[currentEvent eventID] unsignedIntegerValue] == eventInteger) {
            foundEvent = currentEvent;
            break;
        }
    }
    if (foundEvent == nil) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Found" message:@"The event can't be found." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
//        [alert show];
        return -1;
    }
    return i;
}

- (void) _jumpToEvent:(NSInteger)index {
    [self.activityTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}


- (void) _performAction:(NotificationAction)action forEvent:(NSNumber*)eventID{
    
    // First find the event, so we can easily jump to it or present comments.
    NSInteger indexOfEvent = [self _findEventWithEventID:(NSNumber*)eventID];
    if (indexOfEvent == -1) {
        return;
    }
    EventObject *event = [self.events objectAtIndex:indexOfEvent];
    
    switch (action) {
        case kJumpTo:
            [self _jumpToEvent:indexOfEvent];
            break;
        case kShowEvent:
            // Alpha version of the app, nothing happens...
            break;
        case kShowEventComments:
            {
                [self _jumpToEvent:indexOfEvent];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self _presentCommentViewForEvent:event];
                });
            }
            break;
        default:
            break;
    }
}

-(void)_extractUserInfoAndPerformAction:(NSDictionary*)userInfo {
    NSNumber *actionNumber = [userInfo objectForKey:@"action"];
    if ((NSNull*)actionNumber != [NSNull null]) {
        NotificationAction action = [actionNumber integerValue];
        NSNumber *eventNumber = [userInfo objectForKey:@"event_id"];
        if ((NSNull*)eventNumber == [NSNull null]) {
            return;
        }
        [self _performAction:action forEvent:eventNumber];
    }
}

-(void)didTouchNotificationBanner:(NSDictionary*)notifInfo {
    [self _extractUserInfoAndPerformAction:notifInfo];
}

- (void)_presentBanner:(NSDictionary * _Nonnull)userInfo {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    NSString *msg = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
    
    NotificationBanner *banner = [[NotificationBanner alloc] initWithFrame:CGRectMake(0, -defaultBannerHeight, CGRectGetWidth(self.view.frame), defaultBannerHeight)
                                                                andMessage:msg
                                                                 profileID:[userInfo objectForKey:@"notifier_id"]
                                                                 notifInfo:userInfo];
    banner.delegate = self;
    
    [self.view insertSubview:banner atIndex:500];
    
    [UIView animateWithDuration:1.0 animations:^{
        CGRect frame = banner.frame;
        frame.origin.y += frame.size.height;
        banner.frame = frame;
    } completion:^(BOOL finished) {
        [self performSelector:@selector(_dismissBanner:) withObject:banner afterDelay:3.0];
    }];
}

- (void)_dismissBanner:(NotificationBanner*)banner {
    [UIView animateWithDuration:1.0 animations:^{
        CGRect frame = banner.frame;
        frame.origin.y = 0 - frame.size.height;
        banner.frame = frame;
    }];
}

- (void) presentRemoteNotification:(NSDictionary * _Nonnull)userInfo inForeground:(BOOL)inForeground{
    if (inForeground) {
        AudioServicesPlaySystemSound(self.notificationSound);
        [self _presentBanner:userInfo];
    } else {
        [self _extractUserInfoAndPerformAction:userInfo];
    }
}

#pragma mark - Notification Menu Delegate

- (void)shouldDismissNotificationMenu {
    [self _load];
    [UIView animateWithDuration:0.5
                     animations:^{
                         CGRect frame = self.notificationMenuViewController.view.frame;
                         frame.origin.y = frame.size.height;
                         self.notificationMenuViewController.view.frame = frame;
//                         self.notificationMenuViewController.view.alpha = 0;
                     } completion:^(BOOL finished) {
                         [self.notificationMenuViewController.view removeFromSuperview];
                         self.notificationMenuViewController = nil;
                     }];
}

- (void)selectedNotificationMenuInfo:(NSDictionary*)notifInfo {
    [self _extractUserInfoAndPerformAction:notifInfo];
}

#pragma mark - Comment View Delegate

- (void)shouldDismissCommentView {
    [self _load];
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.commentView.view.alpha = 0;
                     } completion:^(BOOL finished) {
                         [self.commentView.view removeFromSuperview];
                         self.commentView = nil;
                     }];
}

- (void) _presentCommentViewForEvent:(EventObject*)event {
    self.createActivityVC.viewMode = ActivityViewCommentMode;
    self.createActivityVC.event = event;
    [self _presentEventViewController];
    
//    self.commentView.event = event;
//    self.commentView.view.alpha = 0;
//    [self.view addSubview:self.commentView.view];
//    [UIView animateWithDuration:0.5 animations:^{
//        self.commentView.view.alpha = 1;
//    }];
}

#pragma mark - Completion of Activity

- (void)_markActivityComplete:(EventObject*)event forCell:(ActivityTableViewCell*)cell{
    [IntertwineManager completeEvent:event.eventID withTitle:event.eventTitle withResponse:^(id json, NSError *error, NSURLResponse *response) {
        if (error) {
            NSLog(@"Error occured when trying to mark an event complete!\n%@", error);
        } else {
            NSIndexPath* sourceIndexPath = [self.activityTableView indexPathForCell:cell];
            NSIndexPath* destIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            
            NSUInteger row = sourceIndexPath.row;
            EventObject *event = [self.events objectAtIndex:row];
            event.isComplete = YES;
            [self.events removeObjectAtIndex:row];
            [self.events insertObject:event atIndex:0];
            
            [self.activityTableView moveRowAtIndexPath:sourceIndexPath toIndexPath:destIndexPath];
            [self.activityTableView reloadRowsAtIndexPaths:@[sourceIndexPath, destIndexPath] withRowAnimation:YES];
        }
    }];
}

#pragma mark - Event View Controller Delegate

- (void) _didEditOrCreateEventInUpcoming:(EventObject*)event {
    if ([self.upcomingEvents indexOfObject:event] == NSNotFound) {
        [self.upcomingEvents addObject:event];
    }
    [self _reloadUpcomingActivitiesTable];
}

- (void) _didEditOrCreateEventInActivity:(EventObject*)event {
    if ([self.events indexOfObject:event] == NSNotFound) {
        [self.events addObject:event];
    }
    [self _reloadActivitesTables];
}

- (void) didEditOrCreateEvent:(EventObject*)event {
    [self _didEditOrCreateEventInActivity:event];
    if (event.startDate) {
        [self _didEditOrCreateEventInUpcoming:event];
    }
}

- (void) eventViewControllerWillDismiss {
    [self _load];
    [self performSelector:@selector(_load) withObject:nil afterDelay:2];
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.createActivityVC.view.alpha = 0;
                         [self _showViews];
                     } completion:^(BOOL finished) {
                         [self.createActivityVC.view removeFromSuperview];
                         _createActivityVC = nil;
                     }];
}

#pragma mark - Activity Cell Delegate 

- (void)didSelectCommentButton:(EventObject*)event forCell:(ActivityTableViewCell*)cell {
    [self _presentCommentViewForEvent:event];
}

- (void)didSelectLikeButton:(EventObject*)event forCell:(ActivityTableViewCell*)cell {
    
}

- (void)didSelectCompleteButton:(EventObject*)event forCell:(ActivityTableViewCell*)cell {
    ActivityAlertView *alertView = [[ActivityAlertView alloc] initWithTitle:@"Complete Event"
                                                        message:@"Are you sure you want to mark this event as complete?"
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:@"Yes", nil];
    alertView.event = event;
    alertView.contextCell = cell;
    [alertView show];
}





#pragma mark - New Activity

- (void) _presentEventViewController {
    [self.view addSubview:self.createActivityVC.view];
    [UIView animateWithDuration:0.3
                     animations:^{
                         [self _hideViews];
                     }
                     completion:^(BOOL finished) {
//                         [self.view addSubview:self.createActivityVC.view];
                     }];
}

- (void) _newActivity {
    self.createActivityVC.viewMode = ActivityViewCreateMode;
    [self _presentEventViewController];
}

#pragma mark - Friends

- (void)_loadFriends {
    [IntertwineManager friends:^(id json, NSError *error, NSURLResponse *response) {
        if (error) {
            NSLog(@"Error occured!! Friends were not loaded. Error: %@", error);
            return;
        }
        if (!json) {
            NSLog(@"No JSON returned back from request.");
            return;
        }
        NSMutableArray *newFriendsArray = [NSMutableArray new];
        for (NSDictionary *friendDictionary in json) {
            Friend *friend = [[Friend alloc] init];
            friend.first = [friendDictionary objectForKey:@"first"];
            friend.last = [friendDictionary objectForKey:@"last"];
            friend.emailAddress = [friendDictionary objectForKey:@"email"];
            friend.facebookID = [friendDictionary objectForKey:@"facebook_id"];
            friend.accountID = [friendDictionary objectForKey:@"account_id"];
            [newFriendsArray addObject:friend];
        }
        self.friends = newFriendsArray;
    }];
}

- (void) _presentFriendsViewController {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    screenRect.origin.x = CGRectGetWidth(screenRect);
    screenRect.origin.y = 0;
    self.friendsVC.view.frame = screenRect;
    
    [UIView animateWithDuration:slideSideBarsAnimationSpeed animations:^{
        self.blackSheet.alpha = 1;
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        screenRect.origin.x = 320 - 218;
        self.friendsVC.view.frame = screenRect;
    }];
}



#pragma mark - Activities

- (void) _sortArrayByDate:(NSMutableArray*)unsortedArray {
    NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
    [unsortedArray sortUsingDescriptors:@[sortByDate]];
}

- (NSMutableArray*) _extractEventsFromJSON:(id)json {
    
    // Date formatter used in loop.
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy'-'MM'-'dd HH':'mm':'ss"];
    
    NSMutableArray *events = [[NSMutableArray alloc] initWithCapacity:[(NSArray*)json count]];
    for (NSDictionary *eventDictionary in json) {
        EventObject *event = [[EventObject alloc] init];
        event.eventID = [eventDictionary objectForKey:@"id"];
        event.eventTitle = [eventDictionary objectForKey:@"title"];
        
        [event extractDateInfo:[eventDictionary objectForKey:@"date"]];
        
        event.numberOfComments = [[eventDictionary objectForKey:@"comment_count"] unsignedIntegerValue];
        
        event.eventDescription = [eventDictionary objectForKey:@"description"];
        event.isComplete = [[eventDictionary objectForKey:@"completed"] boolValue];
        
        // Get the updated time (for sorting later)
        NSString *timeString = [eventDictionary objectForKey:@"updated_time"];
        event.updatedTime = [format dateFromString:timeString];
        
        // Inititate the creator from the creator dictionary
        NSDictionary *creatorDictionary = [eventDictionary objectForKey:@"creator"];
        event.creator = [[Friend alloc] init];
        event.creator.first = [creatorDictionary objectForKey:@"first"];
        event.creator.last = [creatorDictionary objectForKey:@"last"];
        event.creator.accountID = [[creatorDictionary objectForKey:@"id"] stringValue];
        event.creator.facebookID = [creatorDictionary objectForKey:@"facebook_id"];
        event.creator.emailAddress = [creatorDictionary objectForKey:@"email"];
        
        // Assign the attendees
        NSArray *attendeeList = [eventDictionary objectForKey:@"attendees"];
        NSMutableArray *attendees = [NSMutableArray new];
        for ( NSDictionary *attendeesDictionary in attendeeList) {
            Friend *attendee = [[Friend alloc] init];
            attendee.first = [attendeesDictionary objectForKey:@"first"];
            attendee.last = [attendeesDictionary objectForKey:@"last"];
            attendee.emailAddress = [attendeesDictionary objectForKey:@"email"];
            attendee.facebookID = [attendeesDictionary objectForKey:@"facebook_id"];
            attendee.accountID = [[attendeesDictionary objectForKey:@"id"] stringValue];
            [attendees addObject:attendee];
        }
        event.attendees = attendees;
        [events addObject:event];
    }
    return events;
}

- (void) _removeUpcomingActivities {
    [self.upcomingEvents removeAllObjects];
    [self.todaysEvents removeAllObjects];
    [self.tomorrowsEvents removeAllObjects];
    [self.thisWeeksEvents removeAllObjects];
    [self.thisMonthsEvents removeAllObjects];
}

- (void) _sortUpcomingActivitiesIntoSections {
    NSMutableArray *objectsToRemove = [NSMutableArray new];
    for (EventObject *event in self.upcomingEvents) {
        if ([event isToday]) {
            if ([self.todaysEvents indexOfObject:event] == NSNotFound) {
                [self.todaysEvents addObject:event];
            }
        } else if ([event isTomorrow]) {
            if ([self.tomorrowsEvents indexOfObject:event] == NSNotFound) {
                [self.tomorrowsEvents addObject:event];
            }
        } else if ([event isThisWeek]) {
            if ([self.thisWeeksEvents indexOfObject:event] == NSNotFound) {
                [self.thisWeeksEvents addObject:event];
            }
        } else if ([event isThisMonth]) {
            if ([self.thisMonthsEvents indexOfObject:event] == NSNotFound) {
                [self.thisMonthsEvents addObject:event];
            }
        } else {
            continue;
        }
        [objectsToRemove addObject:event];
    }
    [self.upcomingEvents removeObjectsInArray:objectsToRemove];
    [self _sortArrayByDate:self.upcomingEvents];
    [self _sortArrayByDate:self.todaysEvents];
    [self _sortArrayByDate:self.tomorrowsEvents];
    [self _sortArrayByDate:self.thisWeeksEvents];
    [self _sortArrayByDate:self.thisMonthsEvents];
}

- (void) _updateAvailableSections {
    [self.availableSections removeAllObjects];
    if ([self.todaysEvents count]) {
        [self.availableSections addObject:@0];
    }
    if ([self.tomorrowsEvents count]) {
        [self.availableSections addObject:@1];
    }
    if ([self.thisWeeksEvents count]) {
        [self.availableSections addObject:@2];
    }
    if ([self.thisMonthsEvents count]) {
        [self.availableSections addObject:@3];
    }
    if ([self.upcomingEvents count]) {
        [self.availableSections addObject:@4];
    }
}

- (void) _reloadUpcomingActivitiesTable {
    [self _sortUpcomingActivitiesIntoSections];
    [self _updateAvailableSections];
    [self.upcomingTableView reloadData];
}

- (void) _loadUpcomingActivities {
    [IntertwineManager getUpcomingActivitiesWithResponse:^(id json, NSError *error, NSURLResponse *response) {
        if (error) {
            NSLog(@"Error occured!!\n%@", error);
            return;
        }
        [self _removeUpcomingActivities];
        self.upcomingEvents = [self _extractEventsFromJSON:json];
        [self _reloadUpcomingActivitiesTable];
    }];
}

- (void) _reloadActivitesTables {
    NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"updatedTime" ascending:NO];
    [self.events sortUsingDescriptors:@[sortByDate]];
    [self.activityTableView reloadData];
}

- (void) _loadActivities {
    [IntertwineManager getActivityFeedWithResponse:^(id json, NSError *error, NSURLResponse *response) {
        if(error) {
            NSLog(@"Error occured!!\n%@", error);
            return;
        }
        
        [self.events removeAllObjects];
        self.events = [self _extractEventsFromJSON:json];
        [self _reloadActivitesTables];
    }];
}





#pragma mark - Alert View Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self _markActivityComplete:[(ActivityAlertView*)alertView event] forCell:[(ActivityAlertView*)alertView contextCell]];
    }
}



#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundView.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    EventObject *event = nil;
    if (tableView == self.activityTableView) {
        event = [self.events objectAtIndex:indexPath.row];
    } else {
        NSInteger sectionIndex = [[self.availableSections objectAtIndex:indexPath.section] integerValue];
        NSMutableArray *sectionArray = [self.sections objectAtIndex:sectionIndex];
        event = [sectionArray objectAtIndex:indexPath.row];
    }
    self.createActivityVC.viewMode = ActivityViewEditMode;
    self.createActivityVC.event = event;
    [self _presentEventViewController];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    EventObject *event = nil;
    if (tableView == self.activityTableView) {
        event = [self.events objectAtIndex:indexPath.row];
    } else {
        NSInteger sectionIndex = [[self.availableSections objectAtIndex:indexPath.section] integerValue];
        NSMutableArray *sectionArray = [self.sections objectAtIndex:sectionIndex];
        event = [sectionArray objectAtIndex:indexPath.row];
    }
    CGFloat height = 0;
    if (event.isComplete) {
        height = activityCompleteCellHeight;
    } else {
        height = [ActivityTableViewCell cellHeightForEvent:event andAttendeeCount:[[event attendees] count]];
    }
    return height;
}


#pragma mark - Table View Number of Sections

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat height = 0;
    if (tableView == self.upcomingTableView) {
        height = ActivityViewSectionHeaderHeight;
    }
    return height;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *view = nil;
    if (tableView == self.upcomingTableView) {
        view = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.upcomingTableView.frame), ActivityViewSectionHeaderHeight)];
        view.backgroundColor = HEADER_COLOR_NON_TRANSPARENT;
        view.textAlignment = NSTextAlignmentCenter;
        view.textColor = [UIColor whiteColor];
        view.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
        
        NSInteger sectionIndex = [[self.availableSections objectAtIndex:section] integerValue];
        view.text = [self.sectionNames objectAtIndex:sectionIndex];
    }
    return view;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle = nil;
    if (tableView == self.upcomingTableView) {
        NSInteger sectionIndex = [[self.availableSections objectAtIndex:section] integerValue];
        sectionTitle = [self.sectionNames objectAtIndex:sectionIndex];
    }
    return sectionTitle;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger numberOfSections = 1;
    if (tableView == self.upcomingTableView) {
        /* We need to count the number of arrays that were filled during
         * the data load.
         * There should be an array for each section:
            - Today
            - Tomorrow
            - This week
            - This month
            - The rest of time!
         */
        return [self.availableSections count];
    }
    return numberOfSections;
}


#pragma mark - Table View Number of Rows in Section

- (NSInteger)_activityTableViewNumberOfRowsInSection:(NSInteger)section {
    return [self.events count];
}

- (NSInteger)_upcomingTableViewNumberOfRowsInSection:(NSInteger)section {
//    return [self.upcomingEvents count];
    /* We should have an array for each section. 
     * The sum game is, just that. Sum up the arrays. */
    NSInteger sectionIndex = [[self.availableSections objectAtIndex:section] integerValue];
    NSMutableArray *sectionArray = [self.sections objectAtIndex:sectionIndex];
    return [sectionArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if (tableView == self.activityTableView) {
        numberOfRows = [self _activityTableViewNumberOfRowsInSection:section];
    } else if (tableView == self.upcomingTableView) {
        numberOfRows = [self _upcomingTableViewNumberOfRowsInSection:section];
    }
    return numberOfRows;
}


#pragma mark - Table View Cell for Row at Index Path

- (UITableViewCell*)_activityTableViewNormalCellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *reuseIdentifier = @"activityCell";
    ActivityTableViewCell *cell = (ActivityTableViewCell*)[self.activityTableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[ActivityTableViewCell alloc] initWithReuseIdentifier:reuseIdentifier];
    }
    
    EventObject *event = [self.events objectAtIndex:indexPath.row];
    cell.event = event;
    cell.dateLabel.text = [NSDate intertwineDateStringForEvent:event];
    
    cell.commentButton.detailLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)event.numberOfComments];
    cell.delegate = self;
    
    [cell setAttendees:[event attendees]];
    [cell setTitle:event.eventTitle];
    [cell completed:event.isComplete];
    
    return cell;
}

- (UITableViewCell*)_activityTableViewCompletedCellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *reuseIdentifier = @"completedActivityCell";
    ActivityCompleteTableViewCell *cell = (ActivityCompleteTableViewCell*)[self.activityTableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[ActivityCompleteTableViewCell alloc] initWithReuseIdentifier:reuseIdentifier];
    }
    EventObject *event = [self.events objectAtIndex:indexPath.row];
    cell.titleLabel.text = event.eventTitle;

    NSMutableArray *firstNames = [NSMutableArray new];
    for (Friend *attendee in event.attendees) {
        [firstNames addObject:attendee.first];
    }
    cell.attendeesLabel.text = [firstNames componentsJoinedByString:@", "];
    return cell;
}


- (UITableViewCell*)_activityTableViewCellForRowAtIndexPath:(NSIndexPath*)indexPath {
    EventObject *event = [self.events objectAtIndex:indexPath.row];
    UITableViewCell *cell = nil;
    if (event.isComplete) {
        cell = [self _activityTableViewCompletedCellForRowAtIndexPath:indexPath];
    } else {
        cell = [self _activityTableViewNormalCellForRowAtIndexPath:indexPath];
    }
    return cell;
}

- (UITableViewCell*)_upcomingTableViewCellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *reuseIdentifier = @"upcomingCell";
    
    NSInteger sectionIndex = [[self.availableSections objectAtIndex:indexPath.section] integerValue];
    NSMutableArray *section = [self.sections objectAtIndex:sectionIndex];
    EventObject *event = [section objectAtIndex:indexPath.row];
    ActivityTableViewCell *cell = (ActivityTableViewCell*)[self.upcomingTableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[ActivityTableViewCell alloc] initWithReuseIdentifier:reuseIdentifier];
    }
    cell.event = event;
    
    cell.commentButton.detailLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)event.numberOfComments];
    cell.delegate = self;
    cell.dateLabel.text = [NSDate intertwineDateStringForEvent:event];
    
    [cell setAttendees:[event attendees]];
    [cell setTitle:event.eventTitle];
    [cell completed:event.isComplete];
    
    return cell;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (tableView == self.activityTableView) {
        cell = [self _activityTableViewCellForRowAtIndexPath:indexPath];
    } else if (tableView == self.upcomingTableView) {
        cell = [self _upcomingTableViewCellForRowAtIndexPath:indexPath];
    }
    return cell;
}


#pragma mark - Header View Data Source

- (NSString*)titleForSegment:(NSUInteger)segmentIndex {
    NSString *title = [NSString stringWithCString:titles[segmentIndex] encoding:NSUTF8StringEncoding];
    return title;
}

#pragma mark - Table View Commit Editing Style

//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//    
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        // Delete the row from the data source
//        NSLog(@"Deleting");
//    }
//}

#pragma mark - Lazy Loading

- (HeaderPagingScrollView*)backgroundScrollView {
    if (!_backgroundScrollView) {
        CGRect frame = self.view.frame;
        frame.origin.x = 0;
        frame.origin.y = 0;
        _backgroundScrollView = [[HeaderPagingScrollView alloc] initWithFrame:frame numberOfPages:2];
        _backgroundScrollView.delegate = self;
        CGFloat yCenter = CGRectGetHeight(self.header.frame)/2. ;
        _backgroundScrollView.headerView.center = CGPointMake(CGRectGetWidth(self.header.frame)/2.0, yCenter);
        [self.header addSubview:_backgroundScrollView.headerView];
    }
    return _backgroundScrollView;
}

- (UITableView*)activityTableView {
    if (!_activityTableView) {
        /* Readjust the height of the table view by the height of the header. */
        CGRect frame = self.view.frame;
        frame.size.height -= headerHeight;
//        frame.size.height -= footerHeight;
        frame.origin.y += headerHeight;
        frame.origin.x += CGRectGetWidth(self.view.frame);
        
        _activityTableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
        _activityTableView.backgroundColor = [UIColor clearColor];
        _activityTableView.delegate = self;
        _activityTableView.dataSource = self;
        _activityTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//        _activityTableView.allowsSelection = NO;
    }
    return _activityTableView;
}

- (UITableView*)upcomingTableView {
    if (!_upcomingTableView) {
        /* Readjust the height of the table view by the height of the header. */
        CGRect frame = self.view.frame;
        frame.size.height -= headerHeight;
//        frame.size.height -= footerHeight;
        frame.origin.y += headerHeight;
        frame.origin.x = 0;
//        frame.origin.x += CGRectGetWidth(self.view.frame);
        
        _upcomingTableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
        _upcomingTableView.backgroundColor = [UIColor clearColor];
        _upcomingTableView.delegate = self;
        _upcomingTableView.dataSource = self;
        _upcomingTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _upcomingTableView;
}

- (UIImageView*)backgroundImage {
    if (!_backgroundImage) {
        _backgroundImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BackgroundImage.png"]];
        _backgroundImage.frame = [[UIScreen mainScreen] bounds];
        _backgroundImage.alpha = 0.20;
    }
    return _backgroundImage;
}

- (UIView*)header {
    if (!_header) {
        _header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), headerHeight)];
//        _header.backgroundColor = [UIColor colorWithRed:20.0/255.0 green:81.0/255.0 blue:121.0/255.0 alpha:1.0];
        _header.backgroundColor = ACTIVITY_VIEW_HEADER_COLOR;
//        _header.layer.borderWidth = 1.0;
//        _header.layer.borderColor = [[UIColor colorWithRed:151.0/255.0 green:151.0/255.0 blue:151.0/255.0 alpha:1] CGColor];
    }
    return _header;
}

- (UIImageView*)footer {
    if (!_footer) {
        CGFloat screenHeight = CGRectGetHeight(self.view.frame);
        CGFloat screenWidth = CGRectGetWidth(self.view.frame);
        UIImage *gradientBottom = [UIImage imageNamed:@"BottomGradient.png"];
        _footer = [[UIImageView alloc] initWithImage:gradientBottom];
        _footer.frame = CGRectMake(0, screenHeight-gradientBottom.size.height, screenWidth, gradientBottom.size.height);
        _footer.userInteractionEnabled = NO;
    }
    return _footer;
}

- (UILabel*)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, y_toolBarItems, CGRectGetWidth(self.view.frame), 24)];
        _titleLabel.backgroundColor = [UIColor clearColor];
//        _titleLabel.textColor = [UIColor colorWithRed:20.0/255.0 green:77.0/255.0 blue:111.0/255.0 alpha:1];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:22];
    }
    return _titleLabel;
}

- (UIButton*)gearButton {
    if (!_gearButton) {
        _gearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_gearButton setBackgroundImage:[UIImage imageNamed:@"gear.png"] forState:UIControlStateNormal];
        _gearButton.frame = CGRectMake(10.0, y_toolBarItems, 26.0, 26.0);
    }
    return _gearButton;
}

- (UIButton*)notificationsButton {
    if (!_notificationsButton) {
        _notificationsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_notificationsButton setImage:[UIImage imageNamed:@"notifications_icon.png"] forState:UIControlStateNormal];
        _notificationsButton.frame = CGRectMake(28, 0, 26.0, 26.0);
        CGPoint center = _notificationsButton.center;
        center.y = y_toolBarItems;
        _notificationsButton.center = center;
        [_notificationsButton addTarget:self action:@selector(_presentNotificationsViewController) forControlEvents:UIControlEventTouchUpInside];
    }
    return _notificationsButton;
}

- (UIButton*)friendsButton {
    if (!_friendsButton) {
        _friendsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_friendsButton setImage:[UIImage imageNamed:@"friends.png"] forState:UIControlStateNormal];
        [_friendsButton addTarget:self action:@selector(_presentFriendsViewController) forControlEvents:UIControlEventTouchUpInside];
        
        CGFloat screenWidth = CGRectGetWidth(self.view.frame);
        _friendsButton.frame = CGRectMake(screenWidth - 56.0, y_toolBarItems, 46.0, 26.0);
    }
    return _friendsButton;
}

- (UIView*)newActivityButton {
    if (!_newActivityButton) {
        _newActivityButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        [_newActivityButton setTitle:@"+" forState:UIControlStateNormal];
        UIImage *plusButton = [UIImage imageNamed:@"PlusRed.png"];
        [_newActivityButton setImage:plusButton forState:UIControlStateNormal];
        [_newActivityButton addTarget:self action:@selector(_newActivity) forControlEvents:UIControlEventTouchUpInside];
        CGFloat screenWidth = CGRectGetWidth(self.view.frame);
        CGFloat screenHeight = CGRectGetHeight(self.view.frame);
        CGFloat inset = 20.0;
        _newActivityButton.frame = CGRectMake(screenWidth - plusButton.size.width - inset, screenHeight - plusButton.size.height - inset, plusButton.size.width, plusButton.size.height);
    }
    return _newActivityButton;
}

- (EventViewController*)createActivityVC {
    if (!_createActivityVC) {
        _createActivityVC = [EventViewController new];
        _createActivityVC.friends = self.friends;
        _createActivityVC.delegate = self;
    }
    return _createActivityVC;
}

- (FriendsViewController*)friendsVC {
    if (!_friendsVC) {
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        screenRect.origin.x = CGRectGetWidth(screenRect);
        screenRect.origin.y = 0;
        
        _friendsVC = [FriendsViewController new];
        _friendsVC.view.frame = screenRect;
        [self.view addSubview:self.friendsVC.view];

    }
    return _friendsVC;
}

- (NotificationMenuViewController*) notificationMenuViewController {
    if (!_notificationMenuViewController) {
        _notificationMenuViewController = [NotificationMenuViewController new];
    }
    return _notificationMenuViewController;
}

- (UIView*)blackSheet {
    if (!_blackSheet) {
        CGRect frame = self.view.frame;
        frame.origin.x = 0;
        frame.origin.y = 0;
        _blackSheet = [[UIControl alloc] initWithFrame:frame];
        _blackSheet.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.55];
        _blackSheet.alpha = 0;
        [_blackSheet addTarget:self action:@selector(_clearSubViewControllers) forControlEvents:UIControlEventTouchUpInside];
    }
    return _blackSheet;
}

- (CommentViewController*)commentView {
    if (!_commentView) {
        _commentView = [CommentViewController new];
        _commentView.delegate = self;
        _commentView.view.frame = [[UIScreen mainScreen] bounds];
        _commentView.view.alpha = 0;
    }
    return _commentView;
}

-(NSMutableArray*)savedNotifications {
    if (!_savedNotifications) {
        _savedNotifications = [NSMutableArray new];
    }
    return _savedNotifications;
}

@end