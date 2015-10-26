//
//  NotificationMenuViewController.m
//  Intertwine
//
//  Created by Ben Rooke on 10/21/15.
//  Copyright © 2015 Intertwine. All rights reserved.
//

#import "NotificationMenuViewController.h"
#import "IntertwineNotification.h"
#import "NotificationBanner.h"
#import "NotificationTableViewCell.h"

@interface NotificationMenuViewController ()

@property (nonatomic, strong) UITableView *notificationsTableView;

@property (nonatomic, strong) UIControl *backgroundExit;
- (void)_dismiss;

@end

@implementation NotificationMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (self.notifications == nil) {
        self.notifications = [NSMutableArray new];
    }
    [self.view addSubview:self.backgroundExit];
    [self.view addSubview:self.notificationsTableView];
    
    UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_dismiss)];
    gesture.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:gesture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void)_dismiss {
    if ([self.delegate respondsToSelector:@selector(shouldDismissNotificationMenu)]) {
        [self.delegate shouldDismissNotificationMenu];
    }
}



#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([self.delegate respondsToSelector:@selector(selectedNotificationMenuInfo:)]) {
        IntertwineNotification *notification = [self.notifications objectAtIndex:indexPath.row];
        [self.delegate selectedNotificationMenuInfo:notification.payload];
        [self.delegate shouldDismissNotificationMenu];
    }
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.notifications count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    IntertwineNotification *notification = [self.notifications objectAtIndex:indexPath.row];
    
    static NSString *identifier = @"notification_cell";
    NotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[NotificationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.notificationView.backgroundColor = [UIColor whiteColor];
        cell.notificationView.messageLabel.textColor = [UIColor blackColor];
        cell.notificationView.userInteractionEnabled = NO;
    }

    [cell setProfileID:[notification.payload objectForKey:@"notifier_id"] message:notification.message notifInfo:notification.payload];
    return cell;
}


#pragma mark - Lazy Loading

- (UITableView*) notificationsTableView {
    if (!_notificationsTableView) {
        CGRect viewFrame = self.view.frame;
        CGFloat inset = 30.0;
        viewFrame.origin.x = inset;
        viewFrame.origin.y = inset;
        viewFrame.size.width = viewFrame.size.width - inset*2.0;
        viewFrame.size.height = viewFrame.size.height - inset*2.0;
        
        _notificationsTableView = [[UITableView alloc] initWithFrame:viewFrame];
        _notificationsTableView.delegate = self;
        _notificationsTableView.dataSource = self;
        _notificationsTableView.backgroundColor = [UIColor whiteColor];
    }
    return _notificationsTableView;
}

- (UIControl*)backgroundExit {
    if (!_backgroundExit) {
        _backgroundExit = [[UIControl alloc] initWithFrame:self.view.frame];
        CGRect frame = _backgroundExit.frame;
        frame.origin.x = 0;
        frame.origin.y = 0;
        _backgroundExit.frame = frame;
        _backgroundExit.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.55];
        [_backgroundExit addTarget:self action:@selector(_dismiss) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backgroundExit;
}

@end
