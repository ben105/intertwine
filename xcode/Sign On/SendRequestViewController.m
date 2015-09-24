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
#import "SendRequestTableViewCell.h"

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
            if ([self.searchBar.text isEqualToString:@""]) {
                return;
            }
            if (json) {
                [self.tableData replaceObjectAtIndex:0 withObject:json];

            } else {
                [self.tableData replaceObjectAtIndex:0 withObject:@[]];
            }
            [self.friendsTableView reloadData];
        } else {
            NSLog(@"ERROR: %@", error);
        }
    }];
}


#pragma mark - Loading Facebook Friends (who are not already your Intertwine friends)

- (void) loadFacebookFriends {
    FBRequest* fbRequest = [FBRequest requestForMyFriends];
    [fbRequest startWithCompletionHandler: ^(FBRequestConnection *connection,
                                                  NSDictionary* result,
                                                  NSError *error) {
        if (error || [result count] == 0) {
            NSLog(@"Failed to retrieve list of Facebook friends\n%@", error);
            return;
        }
        NSArray* friends = [result objectForKey:@"data"];
        if ([friends count] == 0) {
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
                    [self.tableData replaceObjectAtIndex:1 withObject:json];
                } else {
                    [self.tableData replaceObjectAtIndex:1 withObject:@[]];
                }
                [self.friendsTableView reloadData];
            }
        }];
        
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
   
    NSArray *section = [self.tableData objectAtIndex:indexPath.section];
    NSDictionary *account = [section objectAtIndex:indexPath.row];
    
    SendRequestTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        BOOL hasSent = [[account objectForKey:@"sent"] boolValue];
        cell = [[SendRequestTableViewCell alloc] initWithSentStatus:hasSent reuseIdentifier:@"cell"];
    }

    NSString *name = [NSString stringWithFormat:@"%@ %@", [account objectForKey:@"first"], [account objectForKey:@"last"]];
    cell.textLabel.text = name;
    BOOL hasSent = [[account objectForKey:@"sent"] boolValue];
    [cell setSentStatus:hasSent];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *account = [[self.tableData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    BOOL hasSent = [[account objectForKey:@"sent"] boolValue];
    if (hasSent) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    } else {
        [IntertwineManager sendFriendRequest:[account objectForKey:@"account_id"] response:^(id json, NSError *error, NSURLResponse *response) {
            if (error) {
                NSLog(@"%@",error);
            } else {
                SendRequestTableViewCell *cell = (SendRequestTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
                [cell setSentStatus:YES];
            }
        }];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }

}


@end
