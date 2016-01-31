//
//  EventViewController.m
//  Invite
//
//  Created by Ben Rooke on 12/30/15.
//  Copyright © 2015 NinjaQuant LLC. All rights reserved.
//

#import "EventViewController.h"
#import "EventTitleView.h"
#import "IntertwineManager+Events.h"
#import "EventObject.h"
#import "Friend.h"


const CGFloat footerToolbarHeight = 55.0;
#define FOOTER_TOOLBAR_FRAME CGRectMake(-2, SCREEN_HEIGHT - footerToolbarHeight, SCREEN_WIDTH + 4.0, footerToolbarHeight)

#define SCREEN_HEIGHT CGRectGetHeight([[UIScreen mainScreen] bounds])
#define SCREEN_WIDTH CGRectGetWidth([[UIScreen mainScreen] bounds])

const CGFloat EventViewAnimationDuration = 0.5;

const CGFloat EventViewSpacer = 47.0;
const CGFloat EventViewInset = 10.0;
#define EventViewInsetWidth (SCREEN_WIDTH - (EventViewInset*2.0))

#define TitleViewEditModeCenterY (SCREEN_HEIGHT * 0.31)
#define TitleViewOffscreenY (TitleViewEditModeCenterY + SCREEN_HEIGHT)
#define TitleViewHeight 72.0

const CGFloat TitleViewOriginY = 45.0;
#define InvitedViewHeightEditMode (SCREEN_HEIGHT * 0.25)
#define InvitedViewHeight (SCREEN_HEIGHT * 0.50)
#define UninvitedViewHeight (SCREEN_HEIGHT * 0.25)


@interface EventViewController ()

/* Original values, in case of editing. */
@property (nonatomic, copy) NSString *originalTitle;
@property (nonatomic, strong) NSArray *originalInvited;
@property (nonatomic, strong) NSArray *originalUninvited;

@property (nonatomic, strong) UIView *footerToolbar;
@property (nonatomic, strong) UIButton *doneButton;
@property (nonatomic, strong) UIControl *dismissControl;

- (void)editTitle;
- (void)editAttendees;

/* Convenience methods for getting collection view rects. */
- (CGRect)_invitedViewRectOffscreen;
- (CGRect)_invitedViewRectEditMode;
- (CGRect)_invitedViewRect;
- (CGRect)_uninvitedViewRectOffScreen;
- (CGRect)_uninvitedViewRect;

/* Altering view modes. */
- (void)_alterViewForEditMode;
- (void)_startEditing;

@end


@implementation EventViewController

#pragma mark - Editing

- (void)setEventTitle:(NSString*)title {
    if ([title isEqualToString:@""]) {
        return;
    }
    self.titleView.titleTextField.text = title;
    self.titleView.placeholderLabel.hidden = YES;
    
}

- (void)_startEditing {
    self.viewMode = ActivityViewEditModeIsEditing;
    [self _alterViewForEditMode];
    
}

#pragma mark - Alter for Edit Mode

- (void)_alterViewForEditMode {
    switch (self.viewMode) {
        case ActivityViewEditModeIsEditing:
        case ActivityViewCreateMode:
        case ActivityViewEditMode:
        default:
            break;
    }
}

#pragma mark - Rect Getters

- (CGRect)_invitedViewRectOffscreen {
    CGRect frame = [self _invitedViewRectEditMode];
    frame.origin.y += SCREEN_HEIGHT;
    return frame;
}

- (CGRect)_invitedViewRectEditMode {
    CGFloat y = CGRectGetMaxY(self.titleView.frame) + EventViewSpacer;
    return CGRectMake(EventViewInset, y, EventViewInsetWidth, InvitedViewHeightEditMode);
}

- (CGRect)_invitedViewRect {
    CGRect frame = [self _invitedViewRectEditMode];
    frame.size.height = InvitedViewHeight;
    return frame;
}

- (CGRect)_uninvitedViewRectOffScreen {
    CGRect frame = [self _uninvitedViewRect];
    frame.origin.y += SCREEN_HEIGHT;
    return frame;
}

- (CGRect)_uninvitedViewRect {
    CGFloat y = CGRectGetMaxY(self.invitedView.frame) + EventViewSpacer;
    return CGRectMake(EventViewInset, y, EventViewInsetWidth, UninvitedViewHeight);
}

#pragma mark - Event View Controller Delegate

- (void)friendsCollectionView:(FriendsCollectionView*)collectionView didSelectFriend:(Friend*)intertwineFriend {
    if (collectionView == self.uninvitedView) {
        [self.invitedView addFriend:intertwineFriend];
        [self.uninvitedView setStatus:kInvited forFriend:intertwineFriend];
    } else if (collectionView == self.invitedView) {
        [self.invitedView removeFriend:intertwineFriend];
        [self.uninvitedView setStatus:kNormal forFriend:intertwineFriend];
    }
}

#pragma mark - Event Title Delegate

- (void)willEditTitle {
    CGFloat currentY = CGRectGetMidY(self.titleView.frame);
    if (currentY != TitleViewEditModeCenterY) {
        [self editTitle];
    }
}

- (void)didEnterTitle:(NSString *)title {
    if ([title isEqualToString:@""]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                                 message:@"Enter a title"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Okay"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           [alertController dismissViewControllerAnimated:YES completion:nil];
                                                       }];
        [alertController addAction:action];
        [self presentViewController:alertController animated:YES completion:nil];
        
    } else {
        [self editAttendees];
    }
}

#pragma mark - Settings Friends Value

- (void)setFriends:(NSArray *)friends {
    _friends = friends;
    [self.uninvitedView addFriends:_friends];
}

#pragma mark - View Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    /* First thing first, add the dismiss control. */
    [self.view addSubview:self.dismissControl];
    
    self.titleView.center = CGPointMake(SCREEN_WIDTH / 2.0, TitleViewOffscreenY);
    [self.view addSubview:self.titleView];
    if (self.viewMode == ActivityViewCreateMode) {
        [self editTitle];
    } else if (self.viewMode == ActivityViewEditMode){
        [self editAttendees];
    }
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.originalTitle = self.titleView.titleTextField.text;
    self.originalInvited = [self.invitedView friends];
    self.originalUninvited = [self.uninvitedView friends];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Modes

- (void)editTitle {
    [self.footerToolbar removeFromSuperview];
    [self.doneButton removeFromSuperview];
    [UIView animateWithDuration:EventViewAnimationDuration
                     animations:^{
                         self.titleView.center = CGPointMake(SCREEN_WIDTH / 2.0, TitleViewEditModeCenterY);
                         self.invitedView.frame = [self _invitedViewRectOffscreen];
                         self.uninvitedView.frame = [self _uninvitedViewRectOffScreen];
                     }
                     completion:^(BOOL finished) {
                         [self.titleView.titleTextField becomeFirstResponder];
                         [self.invitedView removeFromSuperview];
                         [self.uninvitedView removeFromSuperview];
                     }];
}

- (void)editAttendees {
    [self.view addSubview:self.invitedView];
    [self.view addSubview:self.uninvitedView];
    [UIView animateWithDuration:EventViewAnimationDuration
                     animations:^{
                         CGRect frame = self.titleView.frame;
                         frame.origin.y = TitleViewOriginY;
                         self.titleView.frame = frame;
                         self.invitedView.frame = [self _invitedViewRectEditMode];
                         self.uninvitedView.frame = [self _uninvitedViewRect];
                     }
                     completion:^(BOOL finished) {
                         [self.view addSubview:self.footerToolbar];
                         [self.view addSubview:self.doneButton];
                     }];
}

#pragma mark - Dismiss

- (void)dismiss {
    [UIView animateWithDuration:EventViewAnimationDuration
                     animations:^{
                         self.titleView.center = CGPointMake(SCREEN_WIDTH / 2.0, TitleViewOffscreenY);
                         self.invitedView.frame = [self _invitedViewRectOffscreen];
                         self.uninvitedView.frame = [self _uninvitedViewRectOffScreen];
                     }
                     completion:^(BOOL finished) {
                         if (self.delegate &&
                             [self.delegate respondsToSelector:@selector(eventViewControllerWillDismiss)]) {
                             [self.delegate eventViewControllerWillDismiss];
                         }
                     }];
}

#pragma mark - Create Event

- (void)_create {
    NSString *title = self.titleView.titleTextField.text;
    if ([title isEqualToString:@""] || !title) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:@"Enter a title for the event."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Okay"
                                                         style:UIAlertActionStyleDefault
                                                       handler:nil];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    if ([[self.invitedView friends] count] == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:@"Invite at least one friend."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Okay"
                                                         style:UIAlertActionStyleDefault
                                                       handler:nil];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    if (self.viewMode == ActivityViewCreateMode) {
        [IntertwineManager createEvent:title withFriends:[self.invitedView friends] withResponse:^(id json, NSError *error, NSURLResponse *response) {
            if (error) {
                NSLog(@"An error has occurred trying to create an event!\n%@", error);
                return;
            }
            [self dismiss];
        }];
    } else {
        NSString *newTitle = nil;
        if (![title isEqualToString:self.originalTitle]) {
            newTitle = title;
        }
        
        NSSet *originalInvited = [NSSet setWithArray:self.originalInvited];
        NSMutableSet *invited = [NSMutableSet setWithArray:[self.invitedView friends]];
        NSSet *originalUninvited = [NSSet setWithArray:self.originalUninvited];
        NSMutableSet *uninvited = [NSMutableSet setWithArray:[self.uninvitedView friends]];
        
        [invited minusSet:originalInvited];
        NSMutableArray *editInvited = [NSMutableArray new];
        for (Friend *friend in invited){
            [editInvited addObject:[friend dictionary]];
        }
        
        [uninvited minusSet:originalUninvited];
        NSMutableArray *editUninvited = [NSMutableArray new];
        for (Friend *friend in uninvited) {
            [editUninvited addObject:[friend dictionary]];
        }
        
        [IntertwineManager editEvent:self.event.eventID withTitle:title newTitle:newTitle invited:editInvited uninvited:editUninvited withResponse:^(id json, NSError *error, NSURLResponse *response) {
            if (error) {
                NSLog(@"An error has occurred trying to create an event!\n%@", error);
                return;
            }
            [self dismiss];
        }];
    }
    
    [self dismiss];
}

#pragma mark - Lazy Loading

- (UIControl*)dismissControl {
    if (!_dismissControl) {
        CGRect frame = [[UIScreen mainScreen] bounds];
        frame.origin.x = 0;
        frame.origin.y = 0;
        _dismissControl = [[UIControl alloc] initWithFrame:frame];
        [_dismissControl addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    }
    return _dismissControl;
}

- (EventTitleView*)titleView {
    if (!_titleView) {
        _titleView = [[EventTitleView alloc] initWithFrame:CGRectMake(EventViewInset, 0, EventViewInsetWidth, TitleViewHeight)];
        _titleView.center = CGPointMake(SCREEN_WIDTH / 2.0, TitleViewEditModeCenterY);
        _titleView.delegate = self;
    }
    return _titleView;
}

- (BlueFriendsCollectionView*)invitedView {
    if (!_invitedView) {
        _invitedView = [[BlueFriendsCollectionView alloc] initWithFrame:[self _invitedViewRectOffscreen]
                                                         andBubbleWidth:40.0];
        [_invitedView setTitle:@"Invited"];
        _invitedView.delegate = self;
    }
    return _invitedView;
}

- (BlueFriendsCollectionView*)uninvitedView {
    if (!_uninvitedView) {
        _uninvitedView = [[BlueFriendsCollectionView alloc] initWithFrame:[self _uninvitedViewRectOffScreen]
                                                               andBubbleWidth:40];
        [_uninvitedView setTitle:@"Friends"];
        _uninvitedView.delegate = self;
    }
    return _uninvitedView;
}

- (UIButton*)doneButton {
    if (!_doneButton) {
        _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_doneButton setBackgroundImage:[UIImage imageNamed:@"CompleteIcon.png"] forState:UIControlStateNormal];
        
        [_doneButton addTarget:self action:@selector(_create) forControlEvents:UIControlEventTouchUpInside];
        
        CGFloat buttonHeight = 60.0;
        
        _doneButton.frame = CGRectMake(0, 0, buttonHeight, buttonHeight);
        _doneButton.center = CGPointMake(CGRectGetMidX(self.view.frame), CGRectGetMinY(FOOTER_TOOLBAR_FRAME));
        
        _doneButton.layer.cornerRadius = CGRectGetWidth(_doneButton.frame) / 2.0;
        _doneButton.layer.borderColor = [[UIColor blackColor] CGColor];
    }
    return _doneButton;
}

- (UIView*)footerToolbar {
    if (!_footerToolbar) {
        _footerToolbar = [[UIView alloc] initWithFrame:FOOTER_TOOLBAR_FRAME];
        _footerToolbar.backgroundColor = [UIColor colorWithRed:20.0/255.0 green:81.0/255.0 blue:121.0/255.0 alpha:1.0];
    }
    return _footerToolbar;
}

@end
