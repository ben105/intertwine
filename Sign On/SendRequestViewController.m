//
//  SendRequestViewController.m
//  Sign On
//
//  Created by Ben Rooke on 1/27/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "SendRequestViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "IntertwineManager+Friends.h"

@interface SendRequestViewController ()

- (void) loadFacebookFriends;

@end

@implementation SendRequestViewController


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {   // called when text changes (including clear)
    if (searchText==nil || [searchText isEqualToString:@""]) {
        [self.tableData replaceObjectAtIndex:0 withObject:@[]];
        self.searchResults = @[];
        [self.friendsTableView reloadData];
        return;
    }
    [IntertwineManager searchAccounts:searchText response:^(id json, NSError *error, NSURLResponse *response) {
        if (!error) {
            NSLog(@"%@", json);
            if ([self.searchBar.text isEqualToString:@""]) {
                return;
            }
            [self.tableData replaceObjectAtIndex:0 withObject:json];
            [self.friendsTableView reloadData];
        } else {
            NSLog(@"ERROR: %@", error);
        }
    }];
}


#pragma mark - Loading Facebook Friends (who are not already your Intertwine friends)

- (void) loadFacebookFriends {
    FBRequest* friendsRequest = [FBRequest requestForMyFriends];
    [friendsRequest startWithCompletionHandler: ^(FBRequestConnection *connection,
                                                  NSDictionary* result,
                                                  NSError *error) {
        NSArray* friends = [result objectForKey:@"data"];
        self.friendSuggestions = friends;
        [self.tableData replaceObjectAtIndex:1 withObject:self.friendSuggestions];
        [self.friendsTableView reloadData];
    }];
}

#pragma mark -

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.friendSuggestions = [[NSArray alloc] init];
    self.tableData = [[NSMutableArray alloc] initWithArray:@[@[],@[]]];
    self.sectionTitles = [[NSArray alloc] initWithObjects:@"Profiles", @"Friend Suggestions",nil];
    // TODO: If facebook account
    [self loadFacebookFriends];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }

    NSArray *section = [self.tableData objectAtIndex:indexPath.section];
    if (indexPath.section == 1) {
        NSDictionary<FBGraphUser>* friend = [section objectAtIndex:indexPath.row];
        NSString *friendName = [friend objectForKey:@"name"];
        cell.textLabel.text = friendName;
    } else {
        NSDictionary *account = [section objectAtIndex:indexPath.row];
        NSString *name = [NSString stringWithFormat:@"%@ %@", [account objectForKey:@"first"], [account objectForKey:@"last"]];
        cell.textLabel.text = name;
    }

    return cell;
}



@end
