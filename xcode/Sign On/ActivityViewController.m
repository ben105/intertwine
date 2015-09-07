//
//  ActivityViewController.m
//  Intertwine
//
//  Created by Ben Rooke on 4/7/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "ActivityViewController.h"
#import "ActivityTableViewCell.h"
#import "EventObject.h"
#import "Friend.h"
#import "FriendsViewController.h"
#import "CommentViewController.h"

#import "IntertwineManager+Activity.h"
#import "IntertwineManager+Friends.h"


const CGFloat headerHeight = 58.0;
const CGFloat footerHeight = 50.0;
const CGFloat y_toolBarItems = 27.0;
#define y_footer CGRectGetHeight([[UIScreen mainScreen] bounds]) - footerHeight

const CGFloat slideSideBarsAnimationSpeed = 0.3;

@interface ActivityViewController ()

@property (nonatomic, strong) NewActivityViewController *createActivityVC;
@property (nonatomic, strong) UIImageView *backgroundImage;
@property (nonatomic, strong) UIView *header;
@property (nonatomic, strong) UIView *footer;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *gearButton;

@property (nonatomic, strong) UIControl *blackSheet;
- (void) _clearSubViewControllers;

@property (nonatomic, strong) UIButton *newActivityButton;
- (void) _newActivity;
- (void) _loadActivities;

@property (nonatomic, strong) NSArray *friends;
@property (nonatomic, strong) UIButton *friendsButton;
- (void) _loadFriends;
- (void) _presentFriendsViewController;

@end

@implementation ActivityViewController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void) _clearSubViewControllers {
    [UIView animateWithDuration:slideSideBarsAnimationSpeed animations:^{
        self.blackSheet.alpha = 0;
        
        CGRect friendsSideFrame = self.view.frame;
        friendsSideFrame.origin.x = friendsSideFrame.size.width;
        friendsSideFrame.origin.y = 0;
        self.friendsVC.view.frame = friendsSideFrame;
    }];
}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.events = [[NSMutableArray alloc] init];
    
    self.view.backgroundColor = [UIColor colorWithRed:23.0/255.0 green:60.0/255.0 blue:104.0/255.0 alpha:1.0];
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
    self.titleLabel.text = @"Activities";
    
    [self.view addSubview:self.gearButton];
    [self.view addSubview:self.friendsButton];
    [self.view addSubview:self.blackSheet];
    [self.view addSubview:self.friendsVC.view];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self _loadActivities];
    [self _loadFriends];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - New Activity

- (void) _newActivity {
    [self presentViewController:self.createActivityVC animated:YES completion:nil];
}

- (void) closeEventCreation {
    [self.createActivityVC dismissViewControllerAnimated:YES completion:^{
        [self _loadActivities];
    }];
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



#pragma mark - Events

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
            event.eventDescription = [eventDictionary objectForKey:@"description"];
            
            // Get the updated time (for sorting later)
            NSString *timeString = [eventDictionary objectForKey:@"updated_time"];
            event.updatedTime = [format dateFromString:timeString];
            
            // Inititate the creator from the creator dictionary
            NSDictionary *creatorDictionary = [eventDictionary objectForKey:@"creator"];
            event.creator = [[Friend alloc] init];
            event.creator.first = [creatorDictionary objectForKey:@"first"];
            event.creator.last = [creatorDictionary objectForKey:@"last"];
            event.creator.accountID = [creatorDictionary objectForKey:@"id"];
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
                attendee.accountID = [attendeesDictionary objectForKey:@"id"];
                [attendees addObject:attendee];
            }
            event.attendees = attendees;
            [self.events addObject:event];
        }
//        self.eventCountLabel.text = [NSString stringWithFormat:@"%lu", [self.events count]];
//        [self.eventsTableView reloadData];
        
        NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"updatedTime" ascending:NO];
        [self.events sortUsingDescriptors:@[sortByDate]];
        [self.activityTableView reloadData];
    }];
}















#pragma mark - Event Cell Delegate

- (void) presentCommentsWithEvent:(EventObject *)event {
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    CommentViewController *commentVC = [storyboard instantiateViewControllerWithIdentifier:@"Comment"];
//    commentVC.event = event;
//    [self presentViewController:commentVC animated:YES completion:nil];
}


















#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundView.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    CommentViewController *commentVC = [storyboard instantiateViewControllerWithIdentifier:@"Comment"];
    EventObject *event = [self.events objectAtIndex:indexPath.row];
    commentVC.event = event;
    [self presentViewController:commentVC animated:YES completion:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return activityCellHeight;
}

#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.events count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ActivityTableViewCell *cell = (ActivityTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[ActivityTableViewCell alloc] initWithReuseIdentifier:@"cell"];
    }
    EventObject *event = [self.events objectAtIndex:indexPath.row];
    cell.event = event;
    cell.titleLabel.text = event.eventTitle;
    [cell setAttendees:[event attendees]];
    
    return cell;
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
    }
    return _activityTableView;
}

- (UIImageView*)backgroundImage {
    if (!_backgroundImage) {
        _backgroundImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BackgroundImage.png"]];
        _backgroundImage.frame = [[UIScreen mainScreen] bounds];
        _backgroundImage.alpha = 0.25;
    }
    return _backgroundImage;
}

- (UIView*)header {
    if (!_header) {
        _header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), headerHeight)];
        _header.backgroundColor = [UIColor colorWithRed:20.0/255.0 green:81.0/255.0 blue:121.0/255.0 alpha:1.0];
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

- (UIButton*)friendsButton {
    if (!_friendsButton) {
        _friendsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_friendsButton setBackgroundImage:[UIImage imageNamed:@"friends.png"] forState:UIControlStateNormal];
        [_friendsButton addTarget:self action:@selector(_presentFriendsViewController) forControlEvents:UIControlEventTouchUpInside];
        
        CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
        _friendsButton.frame = CGRectMake(screenWidth - 36.0, y_toolBarItems, 26.0, 26.0);
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

- (NewActivityViewController*)createActivityVC {
    if (!_createActivityVC) {
        _createActivityVC = [NewActivityViewController new];
        _createActivityVC.delegate = self;
        _createActivityVC.friends = self.friends;
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
    }
    return _friendsVC;
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

@end