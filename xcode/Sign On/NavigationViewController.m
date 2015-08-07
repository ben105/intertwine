//
//  NavigationViewController.m
//  Navigation
//
//  Created by Ben Rooke on 7/15/15.
//  Copyright (c) 2015 Ben Rooke. All rights reserved.
//

#import "NavigationViewController.h"
#import "FriendsTableViewController.h"
#import "ActivityViewController.h"
#import "IntertwineManager+Friends.h"

const CGFloat spaceUnderNavView = 15.0;

@interface NavigationViewController ()

- (UIImageView*)_backgroundImage;
@property (nonatomic, strong) NavigationView *navView;

@property (nonatomic, strong) UILabel *settingsLabel;
@property (nonatomic, strong) FriendsTableViewController *friendsViewController;
@property (nonatomic, strong) ActivityViewController *activityViewController;

@property (nonatomic, strong) UIScrollView *navigationScrollView;

/* Eager loading! */
- (void)_loadFriendsNavigationScreen;
- (void)_loadActivityNavigationScreen;
- (void)_loadSettingsNavigationScreen;
- (void)_loadAllScreens;

/* Cleaning up navigation screens. */
- (void)_cleanUpFriendsNavigationScreen;
- (void)_cleanUpActivityNavigationScreen;
- (void)_cleanUpSettingsNavigationScreen;
- (void)_cleanUpAllScreens;

@end


@implementation NavigationViewController


#pragma mark - Clean Up Methods

- (void)_cleanUpAllScreens {
    [self _cleanUpActivityNavigationScreen];
    [self _cleanUpFriendsNavigationScreen];
    [self _cleanUpSettingsNavigationScreen];
}

- (void)_cleanUpFriendsNavigationScreen {
    [self.friendsViewController hide];
}

- (void)_cleanUpActivityNavigationScreen {
    /* Do nothing for now. Maybe later, there will be a clean up for prep of an animation? */
}

- (void)_cleanUpSettingsNavigationScreen {
    /* Do nothing for now. Maybe later, there will be a clean up for prep of an animation? */
}

#pragma mark - Navigation View Delegate Methods

- (void)willNavigateToHome:(NSDictionary*)userInfo {
    [self.navigationScrollView setContentOffset:CGPointMake([[UIScreen mainScreen] bounds].size.width, 0) animated:YES];
}

- (void)willNavigateToFriends:(NSDictionary*)userInfo {
    [self.navigationScrollView setContentOffset:CGPointMake([[UIScreen mainScreen] bounds].size.width * 2.0, 0) animated:YES];
//    [UIView animateWithDuration:0.5
//                     animations:^{
//                         CGFloat bufferSpace = 15.0;
//                         CGFloat width = [[UIScreen mainScreen] bounds].size.width;
//                         CGFloat height = [[UIScreen mainScreen] bounds].size.height - navigationViewHeight - bufferSpace;
//                         self.friendsViewController.view.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width * 2.0, navigationViewHeight + bufferSpace, width, height);
//    }];
}

- (void)willNavigateToSettings:(NSDictionary*)userInfo {
    [self.navigationScrollView setContentOffset:CGPointMake(0, 0) animated:YES];
}

- (void)didNavigateToHome {
    [self _cleanUpFriendsNavigationScreen];
    [self _cleanUpSettingsNavigationScreen];
}

- (void)didNavigateToFriends {
    [self _cleanUpSettingsNavigationScreen];
    [self _cleanUpActivityNavigationScreen];
    [self.friendsViewController animateCellsOntoScreen];
}

- (void)didNavigateToSettings {
    [self _cleanUpActivityNavigationScreen];
    [self _cleanUpFriendsNavigationScreen];
}

#pragma mark - View Delegate

- (void)viewDidLoad {
    [super viewDidLoad];

    
    UIImageView *backgroundImage = [self _backgroundImage];
    [self.view insertSubview:backgroundImage atIndex:0];

    [self.view addSubview:self.navigationScrollView];
    [self.view addSubview:self.navView];
    
    [self.navigationScrollView addSubview:self.settingsLabel];

    [self _loadAllScreens];
    /* Cheatly call the sequence of methods for when it loads to home. */
    [self didNavigateToHome];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImageView*)_backgroundImage {
    UIImageView *backgroundImage = [[UIImageView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    backgroundImage.userInteractionEnabled = NO;
    backgroundImage.contentMode = UIViewContentModeScaleAspectFill;
    backgroundImage.image = [UIImage imageNamed:@"background.png"];
    return backgroundImage;
}


#pragma mark - Eager Load

- (void)_loadFriendsNavigationScreen {
    self.friendsViewController = [FriendsTableViewController new];
    CGFloat width = [[UIScreen mainScreen] bounds].size.width;
    CGFloat height = [[UIScreen mainScreen] bounds].size.height - navigationViewHeight - spaceUnderNavView;
    self.friendsViewController.view.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width * 2.0, navigationViewHeight + spaceUnderNavView, width, height);
    [self.navigationScrollView addSubview:self.friendsViewController.view];
}

- (void)_loadActivityNavigationScreen {
    self.activityViewController = [ActivityViewController new];
    CGFloat width = [[UIScreen mainScreen] bounds].size.width;
    CGFloat height = [[UIScreen mainScreen] bounds].size.height - navigationViewHeight - spaceUnderNavView;
    NSLog(@"Height: %g", height);
    self.activityViewController.view.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width, navigationViewHeight + spaceUnderNavView, width, height);
    
    NSLog(@"Height: %g", CGRectGetHeight(self.activityViewController.view.frame));
    [self.navigationScrollView addSubview:self.activityViewController.view];
}

- (void)_loadSettingsNavigationScreen {
    
}

- (void)_loadAllScreens {
    [self _loadActivityNavigationScreen];
    [self _loadFriendsNavigationScreen];
    [self _loadSettingsNavigationScreen];
}


#pragma mark - Lazy Loading

- (UILabel*)settingsLabel {
    if (!_settingsLabel) {
        CGFloat width = [[UIScreen mainScreen] bounds].size.width;
        CGFloat height = 50.0;
        CGPoint center = CGPointMake(CGRectGetMidX([[UIScreen mainScreen] bounds]), CGRectGetMidY([[UIScreen mainScreen] bounds]));
        _settingsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        _settingsLabel.center = center;
        _settingsLabel.text = @"Settings!";
        _settingsLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _settingsLabel;
}


- (UIScrollView*)navigationScrollView {
    if (!_navigationScrollView) {
        _navigationScrollView = [[UIScrollView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        _navigationScrollView.scrollEnabled = NO;
        _navigationScrollView.pagingEnabled = YES;
        _navigationScrollView.contentSize = CGSizeMake([[UIScreen mainScreen] bounds].size.width * 3.0, [[UIScreen mainScreen] bounds].size.height);
        _navigationScrollView.contentOffset = CGPointMake([[UIScreen mainScreen] bounds].size.width, 0);

    }
    return _navigationScrollView;
}


- (NavigationView*)navView {
    if (!_navView) {
        CGFloat width = [[UIScreen mainScreen] bounds].size.width;
        CGFloat height = navigationViewHeight;
        _navView = [[NavigationView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        _navView.delegate = self;
    }
    return _navView;
}


@end
