//
//  PrototypeViewController.m
//  Sign On
//
//  Created by Ben Rooke on 3/2/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "PrototypeViewController.h"
#import "FriendsViewController.h"
#import "NewEventViewController.h"
#import "IntertwineManager+Friends.h"
#import "Friend.h"
#import <QuartzCore/QuartzCore.h>
#import <FacebookSDK/FacebookSDK.h>

@interface PrototypeViewController ()

- (void) circleProfilePic;

@end

@implementation PrototypeViewController


- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Event Creation

- (IBAction)openEventCreation:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    NewEventViewController *newEventVC = [storyboard instantiateViewControllerWithIdentifier:@"CreateEvent"];
    newEventVC.title = @"Create Event";
    newEventVC.friends = self.friends;
    [self presentViewController:newEventVC animated:YES completion:nil];
}

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


#pragma mark -

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
    
    [self circleProfilePic];
    self.profilePicture.profileID = self.facebookID;
    self.profilePicture.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.profilePicture.layer.borderWidth = 2.0;
    self.nameLabel.text = self.username;
    // Do any additional setup after loading the view.
    
    self.friends = [[NSMutableArray alloc] init];
    [self loadFriends];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Loading Data From Server

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
        for (NSDictionary *friendDictionary in json) {
            Friend *friend = [[Friend alloc] init];
            friend.first = [friendDictionary objectForKey:@"first"];
            friend.last = [friendDictionary objectForKey:@"last"];
            friend.emailAddress = [friendDictionary objectForKey:@"email"];
            friend.facebookID = [friendDictionary objectForKey:@"facebookID"];
            [self.friends addObject:friend];
        }
    }];
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
