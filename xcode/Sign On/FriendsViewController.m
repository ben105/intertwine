//
//  FriendsViewController.m
//  Sign On
//
//  Created by Ben Rooke on 11/27/14.
//  Copyright (c) 2014 Intertwine. All rights reserved.
//

#import "FriendsViewController.h"
#import "FriendsTableViewCell.h"
#import "IntertwineManager+Friends.h"
#import "SendRequestViewController.h"
#import "PendingRequestTableViewCell.h"

#define viewWidth (0.7733333333 * CGRectGetWidth([[UIScreen mainScreen] bounds]))
#define tableFrame CGRectMake(0, 58, viewWidth, CGRectGetHeight([[UIScreen mainScreen] bounds]))

@interface FriendsViewController ()

@property (nonatomic, strong) NSMutableArray *tableData;
@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic, strong) NSArray *friendSuggestions;
@property (nonatomic, strong) NSArray *sectionTitles;

@property (nonatomic, strong) UISearchBar *searchBar;

@property (nonatomic, strong) UIView *header;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIButton *addFriendButton;
- (void)addFriend:(id)sender;
- (void)_sendFriendRequest:(NSDictionary*)friend;

@property (nonatomic, strong) UIButton *closeFriendButton;
- (void)closeAddFriend:(id)sender;

- (void)_reloadSearchResultsTable;
- (void) _loadFacebookFriends;
- (void)_searchForAccount:(NSString*)searchString;

- (void)_showSearchResultsTableView;
- (void)_showFriendsTableView;
@end



@implementation FriendsViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}


- (IBAction)done {
//    AccountType accountType = [IntertwineManager accountType];
//    if (accountType == kAccountTypeFacebook) {
//        [FBSession.activeSession closeAndClearTokenInformation];
//    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)]];
//    self.profilePictureView.profileID = self.user.objectID;
//    self.nameLabel.text = self.user.name;
    self.view.backgroundColor = [UIColor colorWithRed:20.0/255.0 green:81.0/255.0 blue:121.0/255.0 alpha:0.88];
    self.tableData = [[NSMutableArray alloc] initWithArray:@[@[], @[]]];
    self.sectionTitles = [[NSArray alloc] initWithObjects:@"Friends", @"Pending Requests", nil];
    self.cellIdentifiers = [[NSArray alloc] initWithObjects: @"friend_cell", @"pending_cell", nil];
    [self.view addSubview:self.friendsTableView];
    [self.view addSubview:self.searchResultsTableView];
    [self.view addSubview:self.header];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.addFriendButton];
    [self.view addSubview:self.closeFriendButton];
    [self.view addSubview:self.searchBar];
}

- (void)viewWillAppear:(BOOL)animated {
    self.closeFriendButton.alpha = 0;
    self.searchBar.alpha = 0;
    self.searchResultsTableView.alpha = 0;
    self.titleLabel.alpha = 1;
    self.addFriendButton.alpha = 1;
    self.friendsTableView.alpha = 1;
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.view endEditing:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [self getFriends];
    [self getPendingRequests];
    [super viewDidAppear:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Friends

- (void) acceptedFriendRequest:(PendingRequestTableViewCell*)cell {
    NSIndexPath *indexPath = [self.friendsTableView indexPathForCell:cell];
    
    NSMutableArray *data = nil;
    if (indexPath.section == 0) {
        if ([[self.tableData objectAtIndex:0] count] > 0) {
            data = [self.tableData objectAtIndex:0];
        } else {
            data = [self.tableData objectAtIndex:1];
        }
    } else {
        data = [self.tableData objectAtIndex:1];
    }

    
    [self.friendsTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [data removeObjectAtIndex:indexPath.row];

    [self getPendingRequests];
    [self getFriends];
}

- (void)getPendingRequests {
    [IntertwineManager pendingRequest:^(id json, NSError *error, NSURLResponse *response) {
        if (!error) {
            if (json) {
                [self.tableData replaceObjectAtIndex:1 withObject:json];
            } else {
                [self.tableData replaceObjectAtIndex:1 withObject:@[]];
            }
            [self.friendsTableView reloadData]; // Do we need to reload data if the 'getFriends' method will do that for us?
        }
    }];
}


- (void)getFriends {
    
    [IntertwineManager friends:^(id json, NSError *error
                                 , NSURLResponse *response) {
        // If there is valid json returned, we will insert it into the friends array.
        if (!error) {
            if (json) {
                [self.tableData replaceObjectAtIndex:0 withObject:json];
            } else {
                [self.tableData replaceObjectAtIndex:0 withObject:@[]];
            }
            [self.friendsTableView reloadData];
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


#pragma mark - Adding Friends

- (void)addFriend:(id)sender {
    [self _showSearchResultsTableView];
}

- (void)closeAddFriend:(id)sender {
    [self.view endEditing:YES];
    [self _showFriendsTableView];
}

- (void)_sendFriendRequest:(NSDictionary*)friend {
    [IntertwineManager sendFriendRequest:[friend objectForKey:@"id"] response:^(id json, NSError *error, NSURLResponse *response) {
        if (error) {
            NSLog(@"Error trying to send friend request %@",error);
        }
    }];
}


#pragma mark - Searching Accounts

- (void)_searchForAccount:(NSString*)searchString {
    [IntertwineManager searchAccounts:searchString response:^(id json, NSError *error, NSURLResponse *response) {
        if (!error) {
            // Check if the person has deleted the string since request was sent!
            if ([self.searchBar.text isEqualToString:@""]) {
                return;
            }
            if (json) {
                NSLog(@"Search results... %@", json);
                self.searchResults = [json copy];
                
            } else {
                self.searchResults = @[];
            }
            [self.searchResultsTableView reloadData];
        } else {
            NSLog(@"Error trying to load friend's search results: %@", error);
        }
    }];
}


#pragma mark - Presenting Tables

- (void)_reloadSearchResultsTable {
    [self _searchForAccount:self.searchBar.text];
    [self _loadFacebookFriends];
}

- (void)_showSearchResultsTableView {
    [self _loadFacebookFriends];
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.friendsTableView.alpha = 0;
                         self.addFriendButton.alpha = 0;
                         self.titleLabel.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.2
                                          animations:^{
                                              self.searchResultsTableView.alpha = 1;
                                              self.closeFriendButton.alpha = 1;
                                              self.searchBar.alpha = 1;
                                          }];
                     }];
}

- (void)_showFriendsTableView {
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.searchResultsTableView.alpha = 0;
                         self.closeFriendButton.alpha = 0;
                         self.searchBar.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.2
                                          animations:^{
                                              self.friendsTableView.alpha = 1;
                                              self.addFriendButton.alpha = 1;
                                              self.titleLabel.alpha = 1;
                                          }];
                     }];
}


#pragma mark - Table View Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSUInteger count = 0;
    if (tableView == self.friendsTableView) {
        for (NSArray *data in self.tableData) {
        if ([data count] > 0) {
            count++;
            }
        }
        return count;
    }
    if ([self.searchResults count] > 0) {
        count++;
    }
    if ([self.friendSuggestions count] > 0) {
        count++;
    }
    return count;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (tableView == self.friendsTableView) {
        if (section == 0) {
            if ([[self.tableData objectAtIndex:0] count] > 0) {
                return @"Friends";
            } else {
                return @"Pending Requests";
            }
        } else if (section == 1) {
            return @"Pending Requests";
        }
    } else if (tableView == self.searchResultsTableView) {
        if (section == 0) {
            if ([self.searchResults count] > 0) {
                return @"Search Results";
            } else {
                return @"Friend Suggestions";
            }
        } else {
            return @"Friend Suggestions";
        }
    }
    return @"";
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return friendsCellHeight;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView *) view;
        tableViewHeaderFooterView.textLabel.textColor = [UIColor whiteColor];
        tableViewHeaderFooterView.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:11];
        tableViewHeaderFooterView.textLabel.backgroundColor = [UIColor clearColor];
        tableViewHeaderFooterView.backgroundView.backgroundColor = [UIColor clearColor];
    }
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.friendsTableView) {
        NSArray *friends = [self.tableData objectAtIndex:0];
        NSArray *pending = [self.tableData objectAtIndex:1];
        if (section == 0) {
            if ([friends count] == 0 && [pending count] > 0) {
                return [pending count];
            } else {
                return [friends count];
            }
        } else {
            return [pending count];
        };
    } else if (tableView == self.searchResultsTableView) {
        if (section == 0) {
            if ([self.searchResults count] == 0 && [self.friendSuggestions count] > 0) {
                return [self.friendSuggestions count];
            } else {
                NSLog(@"SEARH RESULTS COUNT: %lu", (unsigned long)[self.searchResults count]);
                return [self.searchResults count];
            }
        } else {
            return [self.friendSuggestions count];
        }
    }
    return 0;
}


- (UITableViewCell*)_friendsTableViewCellForIndexPath:(NSIndexPath*)indexPath {
    NSString *cellIdentifier = [self.cellIdentifiers objectAtIndex:indexPath.section];
    
    NSArray *data = nil;
    if (indexPath.section == 0) {
        if ([[self.tableData objectAtIndex:0] count] > 0) {
            data = [self.tableData objectAtIndex:0];
        } else {
            data = [self.tableData objectAtIndex:1];
        }
    } else {
        data = [self.tableData objectAtIndex:1];
    }
    
    id cell = [self.friendsTableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        if (indexPath.section == 0) {
            if ([[self.tableData objectAtIndex:0] count] > 0) {
                cell = [[FriendsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            } else {
                cell = [[PendingRequestTableViewCell alloc] initWithReuseIdentifier:cellIdentifier];
            }
        } else if (indexPath.section == 1) {
            cell = [[PendingRequestTableViewCell alloc] initWithReuseIdentifier:cellIdentifier];
        }
    }
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    NSDictionary<FBGraphUser>* friend = [data objectAtIndex:indexPath.row];
    NSString *friendName = [NSString stringWithFormat:@"%@ %@", [friend objectForKey:@"first"], [friend objectForKey:@"last"]];
    if (data == [self.tableData objectAtIndex:1]) {
        [(PendingRequestTableViewCell*)cell setAccountID:[friend objectForKey:@"account_id"]];
        [(PendingRequestTableViewCell*)cell setName:friendName];
        [(PendingRequestTableViewCell*)cell setDelegate:self];
    } else {
        [(FriendsTableViewCell*)cell friendLabel].text = friendName;
        [(FriendsTableViewCell*)cell friendProfilePicture].profileID = [friend objectForKey:@"facebook_id"];
        [(FriendsTableViewCell*)cell setAccountID:[friend objectForKey:@"id"]];
    }
    return cell;
}

- (UITableViewCell*)_searchResultsTableViewCellForIndexPath:(NSIndexPath*)indexPath {
    FriendsTableViewCell *cell = [self.friendsTableView dequeueReusableCellWithIdentifier:@"friend_cell"];
    if (!cell) {
        cell = [[FriendsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"friend_cell"];
    }
    NSArray *data = nil;
    if (indexPath.section == 0) {
        if ([self.searchResults count] > 0) {
            data = self.searchResults;
        } else {
            data = self.friendSuggestions;
        }
    } else {
        data = self.friendSuggestions;
    }
    NSDictionary<FBGraphUser>* friend = [data objectAtIndex:indexPath.row];
    NSString *friendName = [NSString stringWithFormat:@"%@ %@", [friend objectForKey:@"first"], [friend objectForKey:@"last"]];
    cell.friendLabel.text = friendName;
    cell.friendProfilePicture.profileID = [friend objectForKey:@"facebook_id"];
    cell.accountID = [friend objectForKey:@"id"];
    
    [cell isFaded:[[friend objectForKey:@"sent"] boolValue]];
    
    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.friendsTableView) {
        return [self _friendsTableViewCellForIndexPath:indexPath];
    }
    return [self _searchResultsTableViewCellForIndexPath:indexPath];
}


- (void) _didSelectSearchResultsTableViewIndexPath:(NSIndexPath *)indexPath {
    NSArray *data = nil;
    if (indexPath.section == 0) {
        if ([self.searchResults count] > 0) {
            data = self.searchResults;
        } else {
            data = self.friendSuggestions;
        }
    } else {
        data = self.friendSuggestions;
    }
    NSDictionary *account = [data objectAtIndex:indexPath.row];
    BOOL hasSent = [[account objectForKey:@"sent"] boolValue];
    if (hasSent) {
        [self.searchResultsTableView deselectRowAtIndexPath:indexPath animated:NO];
    } else {
        [self.searchResultsTableView deselectRowAtIndexPath:indexPath animated:YES];
        
        FriendsTableViewCell *cell = (FriendsTableViewCell*)[self.searchResultsTableView cellForRowAtIndexPath:indexPath];
        [cell isFaded:YES];
        
        [self _sendFriendRequest:account];
    }
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchResultsTableView) {
        [self _didSelectSearchResultsTableViewIndexPath:indexPath];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}


#pragma mark - Friend Suggestions

- (void) _loadFacebookFriends {
    FBRequest* fbRequest = [FBRequest requestForMyFriends];
    [fbRequest startWithCompletionHandler: ^(FBRequestConnection *connection,
                                             NSDictionary* result,
                                             NSError *error) {
        if (error || [result count] == 0) {
            NSLog(@"Failed to retrieve list of Facebook friends\n%@", error);
            self.friendSuggestions = @[];
            [self.searchResultsTableView reloadData];
            return;
        }
        NSArray* friends = [result objectForKey:@"data"];
        if ([friends count] == 0) {
            self.friendSuggestions = @[];
            [self.searchResultsTableView reloadData];
            return;
        }
        NSMutableArray *facebookIDs = [[NSMutableArray alloc] init];
        for (NSDictionary *friend in friends) {
            NSNumber *facebookIDNumber = [friend objectForKey:@"id"];
            NSString *facebookIDString = [NSString stringWithFormat:@"%d", [facebookIDNumber intValue]];
            [facebookIDs addObject:facebookIDString];
        }
        [IntertwineManager getFacebookFriends:facebookIDs withResponse:^(id json, NSError *error, NSURLResponse *response) {
            if (!error) {
                if(json) {
                    self.friendSuggestions = [json copy];
                } else {
                    self.friendSuggestions = @[];
                }
                [self.searchResultsTableView reloadData];
            } else {
                NSLog(@"Failed to retrieve friend suggestions: %@", error);
            }
        }];
        
    }];
}


#pragma mark - Search Bar Delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText==nil || [searchText isEqualToString:@""]) {
        self.searchResults = @[];
        [self.searchResultsTableView reloadData];
        return;
    }
    [self _searchForAccount:searchText];
}



#pragma mark - Lazy Loading

- (UITableView*)friendsTableView {
    if (!_friendsTableView) {
        _friendsTableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
        _friendsTableView.delegate = self;
        _friendsTableView.dataSource = self;
        _friendsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _friendsTableView.backgroundColor = [UIColor clearColor];
    }
    return _friendsTableView;
}

- (UITableView*)searchResultsTableView {
    if (!_searchResultsTableView) {
        _searchResultsTableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
        _searchResultsTableView.alpha = 0;
        _searchResultsTableView.delegate = self;
        _searchResultsTableView.dataSource = self;
        _searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _searchResultsTableView.backgroundColor = [UIColor clearColor];
    }
    return _searchResultsTableView;
}

- (UIView*)header {
    if (!_header) {
        _header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, 50)];
        _header.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.3];
    }
    return _header;
}

- (UILabel*)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 22, viewWidth, 31)];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = @"Friends";
    }
    return _titleLabel;
}

- (UIButton*)addFriendButton {
    if (!_addFriendButton) {
        _addFriendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_addFriendButton setTitle:@"+" forState:UIControlStateNormal];
        [_addFriendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_addFriendButton addTarget:self action:@selector(addFriend:) forControlEvents:UIControlEventTouchUpInside];
        _addFriendButton.frame = CGRectMake(viewWidth - 50, 20, 31, 31);
    }
    return _addFriendButton;
}

- (UIButton*)closeFriendButton {
    if (!_closeFriendButton) {
        _closeFriendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeFriendButton setTitle:@"x" forState:UIControlStateNormal];
        [_closeFriendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_closeFriendButton addTarget:self action:@selector(closeAddFriend:) forControlEvents:UIControlEventTouchUpInside];
        _closeFriendButton.frame = CGRectMake(0, 18, 31, 31);
        _closeFriendButton.alpha = 0;
    }
    return _closeFriendButton;
}

- (UISearchBar*)searchBar {
    if (!_searchBar) {
        _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(31, 24, viewWidth - 60, 23)];
        _searchBar.alpha = 0;
        _searchBar.backgroundColor = [UIColor clearColor];
        _searchBar.backgroundImage = nil;
//        _searchBar.searchBarStyle = UISearchBarStyleMinimal;
        _searchBar.delegate = self;
    }
    return _searchBar;
}

@end
