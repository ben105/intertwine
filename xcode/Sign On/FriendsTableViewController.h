//
//  FriendsTableViewController.h
//  FriendsList
//
//  Created by Ben Rooke on 7/16/15.
//  Copyright (c) 2015 Ben Rooke. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FriendsTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

/* These properties are public because they might need to be loaded
 * by another view controller, and then passed along. */
@property (nonatomic, strong) NSArray *pendingRequests;
@property (nonatomic, strong) NSArray *friends;
@property (nonatomic, strong) NSArray *friendSuggestions;

- (void) hide;
- (void) animateCellsOntoScreen;

@end
