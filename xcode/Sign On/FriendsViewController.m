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

const CGFloat viewWidth = 290;

@interface FriendsViewController ()

@property (nonatomic, strong) NSMutableArray *tableData;
@property (nonatomic, strong) NSArray *sectionTitles;


@property (nonatomic, strong) UIView *header;
@property (nonatomic, strong) UILabel *titleLabel;

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
//    self.profilePictureView.profileID = self.user.objectID;
//    self.nameLabel.text = self.user.name;
    self.view.backgroundColor = [UIColor colorWithRed:20.0/255.0 green:81.0/255.0 blue:121.0/255.0 alpha:0.88];
    self.tableData = [[NSMutableArray alloc] initWithArray:@[@[], @[]]];
    self.sectionTitles = [[NSArray alloc] initWithObjects:@"Friends", @"Pending Requests", nil];
    self.cellIdentifiers = [[NSArray alloc] initWithObjects: @"friend_cell", @"pending_cell", nil];
    [self.view addSubview:self.friendsTableView];
    [self.view addSubview:self.header];
    [self.view addSubview:self.titleLabel];
//    [self.navigationController setHidesBarsOnSwipe:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [self getFriends];
//    [self getPendingRequests];
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











- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSUInteger count = 0;
    for (NSArray *data in self.tableData) {
        if ([data count] > 0) {
            count++;
        }
    }
    return count;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.sectionTitles objectAtIndex:section];
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
    return [[self.tableData objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = [self.cellIdentifiers objectAtIndex:indexPath.section];
    FriendsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        if (indexPath.section == 0) {
            cell = [[FriendsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        } else if (indexPath.section == 1) {
            cell = [[PendingRequestTableViewCell alloc] initWithReuseIdentifier:cellIdentifier];
        }
    }
    NSDictionary<FBGraphUser>* friend = [[self.tableData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSString *friendName = [NSString stringWithFormat:@"%@ %@", [friend objectForKey:@"first"], [friend objectForKey:@"last"]];
//    if (indexPath.section == 1) {
//        [(PendingRequestTableViewCell*)cell setAccountID:[friend objectForKey:@"account_id"]];
//        [(PendingRequestTableViewCell*)cell setDelegate:self];
//    }
    cell.friendLabel.text = friendName;
    cell.friendProfilePicture.profileID = [friend objectForKey:@"facebook_id"];
    cell.accountID = [friend objectForKey:@"id"];
    return cell;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}




#pragma mark - Lazy Loading

- (UITableView*)friendsTableView {
    CGFloat height = CGRectGetHeight([[UIScreen mainScreen] bounds]);
    if (!_friendsTableView) {
        _friendsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 58, viewWidth, height) style:UITableViewStylePlain];
        _friendsTableView.delegate = self;
        _friendsTableView.dataSource = self;
        _friendsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _friendsTableView.backgroundColor = [UIColor clearColor];
    }
    return _friendsTableView;
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
        _titleLabel.text = @"People";
    }
    return _titleLabel;
}

@end
