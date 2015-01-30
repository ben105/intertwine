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

@interface FriendsViewController ()

@property (nonatomic, strong) NSMutableArray *allFriends;

@end

@implementation FriendsViewController

- (IBAction)done {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) add{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SendRequestViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"SendRequest"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Exit" style:UIBarButtonItemStyleDone target:self action:@selector(done)];
    
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithTitle:@"+" style:UIBarButtonItemStylePlain target:self action:@selector(add)];
    [self.navigationItem setLeftBarButtonItem:done];
    [self.navigationItem setRightBarButtonItem:add];
    
    
    
    self.profilePictureView.profileID = self.user.objectID;
    self.nameLabel.text = self.user.name;
    self.allFriends = [[NSMutableArray alloc] init];
    [self getFriends];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)getFriends {
    
    [IntertwineManager friends:^(id json, NSError *error
                                 , NSURLResponse *response) {
        // If there is valid json returned, we will insert it into the friends array.
        if (json) [self.allFriends insertObject:json atIndex:0];
        if (!error) {
            for (NSDictionary *friend in json) {
                NSString *first = [friend objectForKey:@"first"];
                NSString *last = [friend objectForKey:@"last"];
                NSLog(@"I have a friend named %@ %@", first, last);
            }
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




















- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if([self.allFriends count])
        return [[self.allFriends objectAtIndex:section] count];
    else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    NSDictionary<FBGraphUser>* friend = [[self.allFriends objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSString *friendName = [[friend objectForKey:@"first"] stringByAppendingString:[friend objectForKey:@"last"]];
    cell.textLabel.text = friendName;
    return cell;
}




@end
