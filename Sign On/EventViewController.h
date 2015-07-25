//
//  EventViewController.h
//  Sign On
//
//  Created by Ben Rooke on 3/2/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsViewController.h"
#import "NewActivityViewController.h"
#import "EventTableViewCell.h"

@class FBProfilePictureView;

@interface EventViewController : UIViewController <SettingsDelegate, ActivityCreationDelegate, EventTableViewCellDelegate,
                                                    UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) SettingsViewController *settingsViewController;
@property (nonatomic, strong) NewActivityViewController *eventCreationViewController;

@property (nonatomic, strong) UIControl *dimView;

@property (nonatomic, weak) IBOutlet FBProfilePictureView *profilePicture;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;

@property (nonatomic, weak) IBOutlet UILabel *eventCountLabel;
@property (nonatomic, weak) IBOutlet UILabel *friendCountLabel;

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *facebookID;

@property (nonatomic, strong) NSMutableArray *friends;

@property (nonatomic, strong) NSMutableArray *events;
@property (nonatomic, weak) IBOutlet UITableView *eventsTableView;
- (void) loadEvents;

- (void) refresh;

- (IBAction)openSettings:(id)sender;
- (IBAction)closeSettings:(id)sender;

- (IBAction)openFriends:(id)sender;

- (IBAction)openEventCreation:(id)sender;

- (void)loadFriends;

@end
