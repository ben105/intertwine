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
#import "EventViewController.h"

#import "IntertwineManager+Activity.h"
#import "IntertwineManager+Friends.h"
#import "IntertwineManager+Events.h"

#import <AudioToolbox/AudioToolbox.h>

#define BACKGROUND_COLOR [UIColor colorWithRed:21.0/255.0 green:52.0/255.0 blue:88.0/255.0 alpha:1]


const CGFloat headerHeight = 58.0;
const CGFloat footerHeight = 50.0;
const CGFloat y_toolBarItems = 23.0;
#define y_footer CGRectGetHeight([[UIScreen mainScreen] bounds]) - footerHeight

const CGFloat slideSideBarsAnimationSpeed = 0.3;

@interface ActivityViewController ()

@property (nonatomic) SystemSoundID notificationSound;
- (void)_loadNotificationsMenu;

@property (nonatomic) BOOL viewInForeground;

@property (nonatomic, strong) CommentViewController *commentView;
- (void) _presentCommentViewForEvent:(EventObject*)event;

@property (nonatomic, strong) EventViewController *createActivityVC;
@property (nonatomic, strong) UIImageView *backgroundImage;
@property (nonatomic, strong) UIView *header;
@property (nonatomic, strong) UIView *footer;
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
- (void)_markActivityComplete:(EventObject*)event forCell:(ActivityTableViewCell*)cell;
- (void)_presentEventViewController;

@property (nonatomic, strong) NSArray *friends;
@property (nonatomic, strong) UIButton *friendsButton;
- (void) _loadFriends;
- (void) _presentFriendsViewController;

- (void) _load;

- (UITableViewCell*)_tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
- (UITableViewCell*)_tableView:(UITableView*)tableView completedCellForRowAtIndexPath:(NSIndexPath*)indexPath;

@end

@implementation ActivityViewController



#pragma mark - View Stuff

- (void) _clearSubViewControllers {
    [UIView animateWithDuration:slideSideBarsAnimationSpeed animations:^{
        self.blackSheet.alpha = 0;
        CGRect friendsSideFrame = self.view.frame;
        friendsSideFrame.origin.x = friendsSideFrame.size.width;
        friendsSideFrame.origin.y = 0;
        self.friendsVC.view.frame = friendsSideFrame;
    } completion:^(BOOL finished) {
        [self.friendsVC.view removeFromSuperview];
        self.friendsVC = nil;
        [self _load];
    }];
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
    self.events = [[NSMutableArray alloc] init];
    
    self.view.backgroundColor = BACKGROUND_COLOR;
    [self.view addSubview:self.backgroundImage];
    [self.view addSubview:self.header];
    [self.view addSubview:self.footer];

    CGRect frame = self.footer.frame;
    frame.origin.x = 0;
    frame.origin.y = 0;
    self.newActivityButton.frame = frame;
    [self.footer addSubview:self.newActivityButton];

    [self.view addSubview:self.activityTableView];
    
    [self.view addSubview:self.titleLabel];
    self.titleLabel.text = @"Intertwine";
    
    [self.view addSubview:self.gearButton];
    [self.view addSubview:self.notificationsButton];
    [self.view addSubview:self.friendsButton];
    [self.view addSubview:self.blackSheet];
}

- (void)viewWillDisappear:(BOOL)animated {
    self.viewInForeground = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void) _load {
    [self _loadActivities];
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
    
    [self.view addSubview:banner];
    
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
    [self _loadActivities];
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
    [self _loadActivities];
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.commentView.view.alpha = 0;
                     } completion:^(BOOL finished) {
                         [self.commentView.view removeFromSuperview];
                         self.commentView = nil;
                     }];
}

- (void) _presentCommentViewForEvent:(EventObject*)event {
    self.commentView.event = event;
    self.commentView.view.alpha = 0;
    [self.view addSubview:self.commentView.view];
    [UIView animateWithDuration:0.5 animations:^{
        self.commentView.view.alpha = 1;
    }];
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

- (void) eventViewControllerWillDismiss {
    [self.createActivityVC.view removeFromSuperview];
    self.createActivityVC = nil;
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.activityTableView.alpha = 1;
                         self.gearButton.alpha = 1;
                         self.notificationsButton.alpha = 1;
                         self.friendsButton.alpha = 1;
                         self.header.alpha = 1;
                         self.titleLabel.alpha = 1;
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
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.activityTableView.alpha = 0;
                         self.gearButton.alpha = 0;
                         self.notificationsButton.alpha = 0;
                         self.friendsButton.alpha = 0;
                         self.header.alpha = 0;
                         self.titleLabel.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [self.view addSubview:self.createActivityVC.view];
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
        NSMutableArray *newFriendsArray = [[NSMutableArray alloc] init];
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

- (void) _loadActivities {
    [IntertwineManager getActivityFeedWithResponse:^(id json, NSError *error, NSURLResponse *response) {
        if(error) {
            NSLog(@"Error occured!!\n%@", error);
            return;
        }
        
        // Date formatter used in loop.
        NSDateFormatter *format = [[NSDateFormatter alloc] init];
        [format setDateFormat:@"yyyy'-'MM'-'dd HH':'mm':'ss"];
        
        [self.events removeAllObjects];
        for ( NSDictionary *eventDictionary in json ) {
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
            NSMutableArray *attendees = [[NSMutableArray alloc] init];
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
            [self.events addObject:event];
            NSLog(@"Event timestamp: %@", event.timestamp);
        }
//        self.eventCountLabel.text = [NSString stringWithFormat:@"%lu", [self.events count]];
//        [self.eventsTableView reloadData];
        
        NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"updatedTime" ascending:NO];
        [self.events sortUsingDescriptors:@[sortByDate]];
        [self.activityTableView reloadData];
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    EventObject *event = [self.events objectAtIndex:indexPath.row];
    
    // TODO: See if there's a way to just assign the event, and not the individual attributes.
    [self.createActivityVC setEventTitle:event.eventTitle];
    self.createActivityVC.viewMode = ActivityViewEditMode;
//    self.createActivityVC.editEventIsCompleted = event.isComplete;
    self.createActivityVC.event = event;
    
//    NSMutableArray *uninvitedFriends = [self.friends mutableCopy];
//    NSMutableArray *invitedFriends = [NSMutableArray new];
    
    for (Friend *attendee in event.attendees) {
        if ([attendee.accountID isEqualToString:[IntertwineManager getAccountID]]) {
            continue;
        }
        for (Friend *friend in self.friends) {
            if ([friend.accountID isEqualToString:attendee.accountID]) {
                [self.createActivityVC.invitedView addFriend:attendee];
                [self.createActivityVC.uninvitedView setStatus:kInvited forFriend:attendee];
                break;
            }
        }
    }
    
//    self.createActivityVC.uninvitedFriends = uninvitedFriends;
//    self.createActivityVC.invitedFriends = invitedFriends;
    [self _presentEventViewController];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    EventObject *event = [self.events objectAtIndex:indexPath.row];
    CGFloat height = 0;
    if (event.isComplete) {
        height = activityCompleteCellHeight;
    } else {
        height = [ActivityTableViewCell cellHeightForString:event.eventTitle andAttendeeCount:[[event attendees] count]];
    }
    return height;
}


#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.events count];
}


- (UITableViewCell*)_tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *reuseIdentifier = @"activityCell";
    ActivityTableViewCell *cell = (ActivityTableViewCell*)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[ActivityTableViewCell alloc] initWithReuseIdentifier:reuseIdentifier];
    }
    
    EventObject *event = [self.events objectAtIndex:indexPath.row];
    cell.event = event;
    
    cell.commentButton.detailLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)event.numberOfComments];
    cell.delegate = self;
    
    [cell setAttendees:[event attendees]];
    [cell setTitle:event.eventTitle];
    [cell completed:event.isComplete];
    
    return cell;
}

- (UITableViewCell*)_tableView:(UITableView*)tableView completedCellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *reuseIdentifier = @"completedActivityCell";
    ActivityCompleteTableViewCell *cell = (ActivityCompleteTableViewCell*)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[ActivityCompleteTableViewCell alloc] initWithReuseIdentifier:reuseIdentifier];
    }
    EventObject *event = [self.events objectAtIndex:indexPath.row];
    cell.titleLabel.text = event.eventTitle;

    NSMutableArray *firstNames = [[NSMutableArray alloc] init];
    for (Friend *attendee in event.attendees) {
        [firstNames addObject:attendee.first];
    }
    cell.attendeesLabel.text = [firstNames componentsJoinedByString:@", "];
    return cell;
}


- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EventObject *event = [self.events objectAtIndex:indexPath.row];
    UITableViewCell *cell = nil;
    if (event.isComplete) {
        cell = [self _tableView:tableView completedCellForRowAtIndexPath:indexPath];
    } else {
        cell = [self _tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    return cell;
}




- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NSLog(@"Deleting");
    }
}

#pragma mark - Lazy Loading

- (UITableView*)activityTableView {
    if (!_activityTableView) {
        /* Readjust the height of the table view by the height of the header. */
        CGRect frame = self.view.frame;
        frame.size.height -= headerHeight;
        frame.size.height -= footerHeight;
        frame.origin.y += headerHeight;
        
        _activityTableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
        _activityTableView.backgroundColor = [UIColor clearColor];
        _activityTableView.delegate = self;
        _activityTableView.dataSource = self;
        _activityTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//        _activityTableView.allowsSelection = NO;
    }
    return _activityTableView;
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
        _header.backgroundColor = [UIColor colorWithRed:20.0/255.0 green:81.0/255.0 blue:121.0/255.0 alpha:1.0];
//        _header.layer.borderWidth = 1.0;
//        _header.layer.borderColor = [[UIColor colorWithRed:151.0/255.0 green:151.0/255.0 blue:151.0/255.0 alpha:1] CGColor];
    }
    return _header;
}

- (UIView*)footer {
    if (!_footer) {
        _footer = [[UIView alloc] initWithFrame:CGRectMake(-5, y_footer, CGRectGetWidth(self.view.frame) + 10, footerHeight + 2)];
        _footer.backgroundColor = [UIColor colorWithRed:20.0/255.0 green:81.0/255.0 blue:121.0/255.0 alpha:1.0];
        _footer.layer.borderColor = [[UIColor whiteColor] CGColor];
        _footer.layer.borderWidth = 1.0;
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
        _notificationsButton.frame = CGRectMake(CGRectGetMaxX(self.gearButton.frame) + 20, y_toolBarItems, 26.0, 26.0);
        [_notificationsButton addTarget:self action:@selector(_presentNotificationsViewController) forControlEvents:UIControlEventTouchUpInside];
    }
    return _notificationsButton;
}

- (UIButton*)friendsButton {
    if (!_friendsButton) {
        _friendsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_friendsButton setImage:[UIImage imageNamed:@"friends.png"] forState:UIControlStateNormal];
        [_friendsButton addTarget:self action:@selector(_presentFriendsViewController) forControlEvents:UIControlEventTouchUpInside];
        
        CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
        _friendsButton.frame = CGRectMake(screenWidth - 56.0, y_toolBarItems, 46.0, 26.0);
    }
    return _friendsButton;
}

- (UIView*)newActivityButton {
    if (!_newActivityButton) {
        _newActivityButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_newActivityButton setTitle:@"+" forState:UIControlStateNormal];
        [_newActivityButton addTarget:self action:@selector(_newActivity) forControlEvents:UIControlEventTouchUpInside];
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