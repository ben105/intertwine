//
//  FriendsTableViewController.m
//  FriendsList
//
//  Created by Ben Rooke on 7/16/15.
//  Copyright (c) 2015 Ben Rooke. All rights reserved.
//

#import "FriendsTableViewController.h"
#import "FriendsTableViewCell.h"
#import <FacebookSDK/FacebookSDK.h>
#import "IntertwineManager+Friends.h"
#import "FriendProfileView.h"


const CGFloat sectionHeaderHeight = 34.0;
const CGFloat sectionHeaderFontSize = 15.0;
#define SECTION_HEADER_FILL_COLOR [UIColor colorWithRed:28.0/255.0 green:82.0/255.0 blue:145.0/255.0 alpha:1.0]

const NSString *pendingRequestsHeader = @"Pending Requests";
const NSString *friendsHeader = @"Friends";
const NSString *friendSuggestionsHeader = @"Friend Suggestions";


@interface FriendsTableViewController ()

/* Friend's table methods and properties. */
@property (nonatomic, strong) UITableView *friendsTableView;
@property (nonatomic, strong) NSArray *friendsTableViewSectionHeaders;
@property (nonatomic, strong) NSMutableDictionary *friendsDataDictionary;
- (NSArray*)_dataForSection:(NSInteger)section;

/* For animating the cells onto screen (and section headers). */
- (void)_animateTextOntoScreen;
@property (nonatomic, strong) NSMutableArray *labelsToRemove;

- (void)_loadFriends;

@end

@implementation FriendsTableViewController

#pragma mark - Loading Friend Data

- (void)_loadFriends {
    [IntertwineManager friends:^(id json, NSError *error
                                 , NSURLResponse *response) {
        // If there is valid json returned, we will insert it into the friends array.
        if (!error) {
            if (json) {
                self.friends = (NSArray*)json;
            }
        }
    }];
}


#pragma mark - View Delegate Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    if (!self.pendingRequests) {
        self.pendingRequests = @[];
    }
    if (!self.friendSuggestions) {
        self.friendSuggestions = @[];
    }
    if (!self.friends) {
        self.friends = @[];
    }
    
    [self.view addSubview:self.friendsTableView];
    
    /* Let's load in all the data!
     * Note, we must add some caching logic later. */
    [self _loadFriends];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Animating Table Onto Screen

- (void) hide {
//    CGRect frame = self.friendsTableView.frame;
//    frame.origin.x += 9999;
//    self.friendsTableView.frame = frame;
    self.friendsTableView.alpha = 0.0;
}

- (void) animateCellsOntoScreen {
    
    [self _animateTextOntoScreen]; // There is a delay here.
    
    [self hide];
    
    NSMutableArray *picsToRemove = [NSMutableArray new];
    
    NSArray *cells = [self.friendsTableView visibleCells];
    NSUInteger index = 0;
    for (FriendsTableViewCell *cell in cells) {
        FriendProfileView *profilePicture = cell.friendProfilePicture;
        
        CGRect destFrame = [cell.contentView convertRect:profilePicture.frame toView:self.view];
        CGRect animatableFrame = destFrame;
        animatableFrame.origin.y += [[UIScreen mainScreen] bounds].size.height; // At least the screen height is safe.
        
        /* Create a new animatable profile picture. Add it to the view. */
        FriendProfileView *animatableProfilePic = [[FriendProfileView alloc] initWithFrame:animatableFrame];
        animatableProfilePic.profileID = profilePicture.profileID;
        [self.view addSubview:animatableProfilePic];
        
        [picsToRemove addObject:animatableProfilePic];
        
        [UIView animateWithDuration:1.7
                              delay:(float)index * 0.3
             usingSpringWithDamping:0.4
              initialSpringVelocity:4.0
                            options:0
                         animations:^{
                             animatableProfilePic.frame = destFrame;
                         }
                         completion:^(BOOL finished){
                             
                             if (index >= [cells count] - 1) {
                                 [picsToRemove makeObjectsPerformSelector:@selector(removeFromSuperview)];
                                 [self.labelsToRemove makeObjectsPerformSelector:@selector(removeFromSuperview)];
                                 self.friendsTableView.alpha = 1.0;
                             }
                         }];
        
        index += 1;
    }
    
    if ([cells count] == 0) {
        self.friendsTableView.alpha = 1.0;
        [self.friendsTableView reloadData];
    }
}

- (void)_animateTextOntoScreen {
    
    self.labelsToRemove = [NSMutableArray new];
    NSArray *cells = [self.friendsTableView visibleCells];
    for (FriendsTableViewCell *cell in cells) {

        CGRect labelRect = [cell.contentView convertRect:cell.friendLabel.frame toView:self.view];
        
        UILabel *animatableFriendLabel = [[UILabel alloc] initWithFrame:labelRect];
        animatableFriendLabel.text = cell.friendLabel.text;
        animatableFriendLabel.textColor = cell.friendLabel.textColor;
        animatableFriendLabel.backgroundColor = cell.friendLabel.backgroundColor;
        animatableFriendLabel.textAlignment = cell.friendLabel.textAlignment;
        animatableFriendLabel.font = cell.friendLabel.font;
        animatableFriendLabel.clipsToBounds = YES;
        
        CGRect startRect = animatableFriendLabel.frame;
        CGFloat destWidth = cell.friendLabel.frame.size.width;
        startRect.size.width = 0;
        animatableFriendLabel.frame = startRect;
        
        [self.view addSubview:animatableFriendLabel];
        [self.labelsToRemove addObject:animatableFriendLabel];
        
        CGRect destRect = startRect;
        destRect.size.width = destWidth;
        
        [UIView animateWithDuration:1.0
                              delay:1.3
                            options:UIViewAnimationOptionOverrideInheritedOptions
                         animations:^{
                             animatableFriendLabel.frame = destRect;
                         }
                         completion:nil];
    }
}

#pragma mark - Table View Data Source Methods

- (NSArray*)_dataForSection:(NSInteger)section {
    NSString *sectionName = [self.friendsTableViewSectionHeaders objectAtIndex:section];
    return [self.friendsDataDictionary objectForKey:sectionName];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.friendsTableViewSectionHeaders count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self _dataForSection:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"friends_cell";
    FriendsTableViewCell *cell = (FriendsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[FriendsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    NSDictionary *friend = [[self _dataForSection:indexPath.section] objectAtIndex:indexPath.row];
    NSString *first = [friend objectForKey:@"first"];
    NSString *last = [friend objectForKey:@"last"];
    NSString *accountID = [friend objectForKey:@"facebook_id"];
    cell.friendLabel.text = [NSString stringWithFormat:@"%@ %@", first, last];
    cell.accountID = accountID;
    return cell;
}


#pragma mark - Table View Delegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return friendsCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return sectionHeaderHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    NSArray *data = [self _dataForSection:section];
    if ([data count] == 0) {
        return nil;
    }
    
    NSString *sectionHeader = [self.friendsTableViewSectionHeaders objectAtIndex:section];
    CGFloat height = sectionHeaderHeight ;
    CGFloat width = tableView.frame.size.width;
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    headerView.backgroundColor = SECTION_HEADER_FILL_COLOR;

    UIView *topStrip = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 0.5)];
    topStrip.backgroundColor = [UIColor whiteColor];
    
    UIView *bottomStrip = [[UIView alloc] initWithFrame:CGRectMake(0, height - 0.5, width, 0.5)];
    bottomStrip.backgroundColor = [UIColor whiteColor];
    
    UILabel *sectionLabel = [[UILabel alloc] initWithFrame:headerView.frame];
    sectionLabel.text = sectionHeader;
    sectionLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:sectionHeaderFontSize];
    sectionLabel.textColor = [UIColor whiteColor];
    sectionLabel.backgroundColor = [UIColor clearColor];
    sectionLabel.textAlignment = NSTextAlignmentCenter;
    
    [headerView addSubview:topStrip];
    [headerView addSubview:bottomStrip];
    [headerView addSubview:sectionLabel];
    
    return headerView;
}


- (NSMutableDictionary*)friendsDataDictionary {
    if (!_friendsDataDictionary) {
        _friendsDataDictionary = [[NSMutableDictionary alloc] init];
    }
    return _friendsDataDictionary;
}

- (NSArray*)friendsTableViewSectionHeaders {
    if (!_friendsTableViewSectionHeaders) {
        _friendsTableViewSectionHeaders = [[NSArray alloc] initWithObjects:pendingRequestsHeader, friendSuggestionsHeader, friendsHeader, nil];
    }
    return _friendsTableViewSectionHeaders;
}

- (UITableView*)friendsTableView {
    if (!_friendsTableView) {
        _friendsTableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
        _friendsTableView.delegate = self;
        _friendsTableView.dataSource = self;
        _friendsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _friendsTableView.backgroundColor = [UIColor clearColor];
    }
    return _friendsTableView;
}

#pragma mark - Special Setters for Data

- (void)setFriends:(NSArray *)friends {
    _friends = friends;
    if ([_friends count] > 0) {
        [self.friendsDataDictionary setObject:_friends forKey:friendsHeader];
    } else {
        [self.friendsDataDictionary removeObjectForKey:friendsHeader];
    }
    [self.friendsTableView reloadData];
}

- (void)setPendingRequests:(NSArray *)pendingRequests {
    _pendingRequests = pendingRequests;
    if ([_pendingRequests count] > 0) {
        [self.friendsDataDictionary setObject:_pendingRequests forKey:pendingRequestsHeader];
    } else {
        [self.friendsDataDictionary removeObjectForKey:pendingRequestsHeader];
    }
    [self.friendsTableView reloadData];
}

- (void)setFriendSuggestions:(NSArray *)friendSuggestions {
    _friendSuggestions = friendSuggestions;
    if ([_friendSuggestions count] > 0) {
        [self.friendsDataDictionary setObject:_friendSuggestions forKey:friendSuggestionsHeader];
    } else {
        [self.friendsDataDictionary removeObjectForKey:friendSuggestionsHeader];
    }
    [self.friendsTableView reloadData];
}

@end
