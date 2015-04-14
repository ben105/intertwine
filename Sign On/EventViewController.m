//
//  EventViewController.m
//  Sign On
//
//  Created by Ben Rooke on 3/2/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "EventViewController.h"
#import "FriendsViewController.h"
#import "IntertwineManager+Friends.h"
#import "Friend.h"
#import "IntertwineManager+Events.h"
#import "CommentViewController.h"

#import "EventObject.h"

#import <QuartzCore/QuartzCore.h>
#import <FacebookSDK/FacebookSDK.h>

@interface EventViewController ()

- (void) circleProfilePic;

@end

@implementation EventViewController


- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Event Creation




#pragma mark - Friends

- (IBAction)openFriends:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FriendsViewController *friendsVC = [storyboard instantiateViewControllerWithIdentifier:@"Friends"];
    friendsVC.title = @"Friends";
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:friendsVC];
    [self presentViewController:nav animated:YES completion:nil];
}


#pragma mark - Settings

- (void) touchedLogout {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)openSettings:(id)sender {
    // Instantiate the settings view controller.
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.settingsViewController = [storyboard instantiateViewControllerWithIdentifier:@"Settings"];
    self.settingsViewController.delegate = self;
    
    // Refactor the frame.
    CGRect frame = CGRectMake(0 - 60.0, 0, 60.0, CGRectGetHeight([[UIScreen mainScreen] bounds]));
    self.settingsViewController.view.frame = frame;
    CGFloat settingsWidth = CGRectGetWidth(self.settingsViewController.view.frame);
    
    // Add the views.
    [self.view addSubview:self.dimView];
    [self.view addSubview:self.settingsViewController.view];

    // Animate the view onto screen.
    [UIView animateWithDuration:0.5 animations:^{
        // Move the back ground
        CGRect mainFrame = self.view.frame;
        mainFrame.origin.x += (settingsWidth * 0.5);
        self.view.frame = mainFrame;
        
        CGRect newFrame = self.settingsViewController.view.frame;
        newFrame.origin.x = newFrame.origin.x + settingsWidth * 0.5;
        self.settingsViewController.view.frame = newFrame;
        self.dimView.alpha = 0.6;
    }];
}

- (IBAction)closeSettings:(id)sender {
    CGFloat settingsWidth = CGRectGetWidth(self.settingsViewController.view.frame);
    [UIView animateWithDuration:0.5 animations:^{
        // Move the back ground
        CGRect mainFrame = self.view.frame;
        mainFrame.origin.x -= (settingsWidth * 0.5);
        self.view.frame = mainFrame;
        
        CGRect newFrame = self.settingsViewController.view.frame;
        newFrame.origin.x = newFrame.origin.x - settingsWidth * 0.5;
        self.settingsViewController.view.frame = newFrame;
        self.dimView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.dimView removeFromSuperview];
        [self.settingsViewController.view removeFromSuperview];
        self.settingsViewController = nil;
    }];
}


#pragma mark - View Management

- (void) circleProfilePic {
    CGFloat width = CGRectGetWidth(self.profilePicture.frame);
    self.profilePicture.layer.cornerRadius = width/2.0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create the dim view for when we slide things onto screen
    self.dimView = [[UIControl alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.dimView.backgroundColor = [UIColor blackColor];
    self.dimView.alpha = 0.0;
    [self.dimView addTarget:self action:@selector(closeSettings:) forControlEvents:UIControlEventTouchDown];
    
    [IntertwineManager updateDeviceToken:[IntertwineManager getDeviceToken]];
    
    [self circleProfilePic];
    self.profilePicture.profileID = self.facebookID;
    self.profilePicture.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.profilePicture.layer.borderWidth = 2.0;
    self.nameLabel.text = self.username;
    // Do any additional setup after loading the view.
    
    self.events = [[NSMutableArray alloc] init];
    self.friends = [[NSMutableArray alloc] init];
    
    UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(refresh)];
    gesture.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:gesture];
    
    // Create button image
    UIImage *createImage = [UIImage imageNamed:@"PlusButton.png"];
    UIButton *createButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [createButton setBackgroundImage:createImage forState:UIControlStateNormal];
    [createButton addTarget:self action:@selector(createNewEvent) forControlEvents:UIControlEventTouchUpInside];
    
    //Set the button frame
    CGFloat width = createImage.size.width;
    CGFloat height = createImage.size.height;
    CGPoint bottomRight = { CGRectGetMaxX([[UIScreen mainScreen] bounds]), CGRectGetMaxY([[UIScreen mainScreen] bounds]) };
    CGFloat x = bottomRight.x - width;
    CGFloat y = bottomRight.y - height;
    CGRect buttonRect = CGRectMake(x, y, width, height);
    createButton.frame = buttonRect;
    
    //Add button to view
    [self.view addSubview:createButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [self refresh];
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Loading Data From Server

- (void) refresh {
    [self loadEvents];
    [self loadFriends];
}

- (void) loadEvents {
    [IntertwineManager getEventsWithResponse:^(id json, NSError *error, NSURLResponse *response) {
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
        self.eventCountLabel.text = [NSString stringWithFormat:@"%lu", [self.events count]];
        [self.eventsTableView reloadData];
        
        NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"updatedTime" ascending:NO];
        [self.events sortUsingDescriptors:@[sortByDate]];
    }];
}

- (void)loadFriends {
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
        self.friendCountLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[self.friends count]];
    }];
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return outterCellHeight;
}

#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.events count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EventTableViewCell *cell = (EventTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[EventTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    EventObject *event = [self.events objectAtIndex:indexPath.row];
    cell.event = event;
    cell.delegate = self;
    cell.eventLabel.text = event.eventTitle;
    
    NSString *facebookID = event.creator.facebookID;
    
    [cell setCreatorThumbnailWithID:facebookID facebook:YES];
    [cell setAttendeeCount:[event.attendees count]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        EventObject *event = [self.events objectAtIndex:indexPath.row];
        NSLog(@"EVENT ID:  %@", event.eventID);
        [IntertwineManager deleteEvent:event.eventID withResponse:^(id json, NSError *error, NSURLResponse *response) {
            if (error) {
                NSLog(@"Error on deleting row: %@", error);
            }
        }];
        [self.events removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView reloadData];
    }
}

- (IBAction)createNewEvent {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.eventCreationViewController = [storyboard instantiateViewControllerWithIdentifier:@"CreateEvent"];
    self.eventCreationViewController.title = @"Create Event";
    self.eventCreationViewController.friends = self.friends;
    self.eventCreationViewController.delegate = self;
    
    CGFloat width = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    CGFloat height = CGRectGetHeight([[UIScreen mainScreen] bounds]);
    CGRect screenRect = CGRectMake(0, 0, width, height);
    self.eventCreationViewController.view.frame = screenRect;
    self.eventCreationViewController.view.alpha = 0.0;
    
    /*
     * Add the subviews.
     */
    [self.view addSubview:self.dimView];
    [self.view addSubview:self.eventCreationViewController.view];

    
    /*
     * Animate the event creation view controller
     * onto screen.
     */
    [UIView animateWithDuration:0.6 animations:^{
        self.dimView.alpha = 0.85;
        self.eventCreationViewController.view.alpha = 1.0;
    }];
    
    //    [self presentViewController:newEventVC animated:YES completion:nil];
}

- (void) closeEventCreation {
    
    /*
     * Animate the event creation view controller
     * OFF screen.
     */
    [self refresh];
    [UIView animateWithDuration:0.6 animations:^{
        self.dimView.alpha = 0;
        self.eventCreationViewController.view.alpha = 0;
    } completion:^(BOOL finished) {
        [self.dimView removeFromSuperview];
        [self.eventCreationViewController.view removeFromSuperview];
        self.eventCreationViewController = nil;
    }];
}



#pragma mark - Event Cell Delegate

- (void) presentCommentsWithEvent:(EventObject *)event {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    CommentViewController *commentVC = [storyboard instantiateViewControllerWithIdentifier:@"Comment"];
    commentVC.event = event;
    [self presentViewController:commentVC animated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
