//
//  FriendsViewController.h
//  Sign On
//
//  Created by Ben Rooke on 11/27/14.
//  Copyright (c) 2014 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@class PendingRequestTableViewCell;

@protocol FriendsDelegate <NSObject>
- (void) acceptedFriendRequest:(PendingRequestTableViewCell*)cell;
@end

@interface FriendsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, FriendsDelegate>

//@property (nonatomic, weak) id <FBGraphUser> user;
//
//@property (nonatomic, weak) IBOutlet FriendProfileView *profilePictureView;
//@property (nonatomic, weak) IBOutlet UILabel *nameLabel;

@property (nonatomic, strong) UITableView *searchResultsTableView;
@property (nonatomic, strong) UITableView *friendsTableView;
@property (nonatomic, strong) NSArray *cellIdentifiers;

- (IBAction)done;

- (void)getPendingRequests;
- (void)getFriends;

@end
