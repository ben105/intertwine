//
//  FriendsViewController.m
//  Sign On
//
//  Created by Ben Rooke on 11/27/14.
//  Copyright (c) 2014 Intertwine. All rights reserved.
//

#import "FriendsViewController.h"
#import "IntertwineManager+Friends.h"
#import "SendRequestViewController.h"
#import "PendingRequestTableViewCell.h"

@interface FriendsViewController ()

@property (nonatomic, strong) NSMutableArray *tableData;
@property (nonatomic, strong) NSArray *sectionTitles;

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

- (void) add{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SendRequestViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"SendRequest"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.profilePictureView.profileID = self.user.objectID;
    self.nameLabel.text = self.user.name;
    self.tableData = [[NSMutableArray alloc] initWithArray:@[@[], @[]]];
    self.sectionTitles = [[NSArray alloc] initWithObjects:@"Friends", @"Pending Requests", nil];
    self.cellIdentifiers = [[NSArray alloc] initWithObjects: @"friend_cell", @"pending_cell", nil];
    [self.navigationController setHidesBarsOnSwipe:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [self getFriends];
    [self getPendingRequests];
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Exit" style:UIBarButtonItemStyleDone target:self action:@selector(done)];
    
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithTitle:@"+" style:UIBarButtonItemStylePlain target:self action:@selector(add)];
    [self.navigationItem setLeftBarButtonItem:done animated:NO];
    [self.navigationItem setRightBarButtonItem:add animated:NO];
    
    [super viewDidAppear:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Friends

- (void) acceptedFriendRequest:(PendingRequestTableViewCell*)cell {
    NSIndexPath *indexPath = [self.friendsTableView indexPathForCell:cell];
    [[self.tableData objectAtIndex:indexPath.section] removeObjectAtIndex:indexPath.row];
    [self.friendsTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self getPendingRequests];
    [self getFriends];
}

- (void)getPendingRequests {
    [IntertwineManager pendingRequest:^(id json, NSError *error, NSURLResponse *response) {
        if (!error) {
            if (json) {
                [self.tableData replaceObjectAtIndex:1 withObject:json];
                [self getFriends];
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
            for (NSDictionary *friend in json) {
                NSString *first = [friend objectForKey:@"first"];
                NSString *last = [friend objectForKey:@"last"];            }
            if (json) {
                [self.tableData replaceObjectAtIndex:0 withObject:json];
            } else {
                [self.tableData replaceObjectAtIndex:0 withObject:@[]];
            }
            [self.friendsTableView reloadData];
        }
        [self.friendsTableView reloadData];
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











- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.tableData count];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.sectionTitles objectAtIndex:section];
}








- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.tableData objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    NSString *cellIdentifier = [self.cellIdentifiers objectAtIndex:indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        if (indexPath.section == 0) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        } else if (indexPath.section == 1) {
            cell = [[PendingRequestTableViewCell alloc] initWithReuseIdentifier:cellIdentifier];
        }
    }
    NSDictionary<FBGraphUser>* friend = [[self.tableData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSString *friendName = [NSString stringWithFormat:@"%@ %@", [friend objectForKey:@"first"], [friend objectForKey:@"last"]];
    if (indexPath.section == 1) {
        [(PendingRequestTableViewCell*)cell setAccountID:[friend objectForKey:@"account_id"]];
        [(PendingRequestTableViewCell*)cell setDelegate:self];
    }
    cell.textLabel.text = friendName;
    return cell;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
