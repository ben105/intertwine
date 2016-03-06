//
//  EventViewController.m
//  Invite
//
//  Created by Ben Rooke on 12/30/15.
//  Copyright © 2015 NinjaQuant LLC. All rights reserved.
//

#import "CommentViewController.h"
#import "EventViewController.h"
#import "EventTitleView.h"
#import "IntertwineManager+Events.h"
#import "EventObject.h"
#import "EventFooterBar.h"
#import "Friend.h"

const CGFloat dismissPointY = 70.0;

#define FOOTER_TARGET_Y (TitleViewOriginY + CGRectGetHeight(self.titleView.frame) + EventViewSpacer)

const CGFloat footerToolbarHeight = 50.0;
#define FOOTER_TOOLBAR_FRAME CGRectMake(-2, SCREEN_HEIGHT - footerToolbarHeight, SCREEN_WIDTH + 4.0, footerToolbarHeight)

#define SCREEN_HEIGHT CGRectGetHeight([[UIScreen mainScreen] bounds])
#define SCREEN_WIDTH CGRectGetWidth([[UIScreen mainScreen] bounds])

const CGFloat EventViewAnimationDuration = 0.5;

const CGFloat EventViewSpacer = 22.0;
const CGFloat EventViewInset = 10.0;
#define EventViewInsetWidth (SCREEN_WIDTH - (EventViewInset*2.0))

#define TitleViewEditModeCenterY (SCREEN_HEIGHT * 0.31)
#define TitleViewOffscreenY (TitleViewEditModeCenterY + SCREEN_HEIGHT)
#define TitleViewHeight 72.0

const CGFloat TitleViewOriginY = 50.0;
const CGFloat SlideToCloseCenterY = 30.0;
#define InvitedViewHeightEditMode (SCREEN_HEIGHT * 0.25)
#define InvitedViewHeight (SCREEN_HEIGHT * 0.60)
#define UninvitedViewHeight (SCREEN_HEIGHT * 0.25)


@interface EventViewController ()

@property (nonatomic, strong) EventFooterBar *eventFooterBar;

/* Images saved for the center button. */
@property (nonatomic, strong) UIImage *commentImage;
@property (nonatomic, strong) UIImage *checkMarkImage;

/* Comment view controller for when the user slides up. */
@property (nonatomic, strong) CommentViewController *commentViewController;

/* Scroll view that almost everything will slide on. */
@property (nonatomic, strong) UIScrollView *backgroundScrollView;

/* Original values, in case of editing. */
@property (nonatomic, copy) NSString *originalTitle;
@property (nonatomic, strong) NSArray *originalInvited;
@property (nonatomic, strong) NSArray *originalUninvited;

@property (nonatomic, strong) UIButton *centerButton;
/* The slide up icon indicates that we can slide up to reveal more. */
@property (nonatomic, strong) UIImageView *slideUpIcon;
/* The slide down icon is for closing the comments. */
@property (nonatomic, strong) UIImageView *slideDownIconDark;
/* The slide down icon is for closing the entire event. */
@property (nonatomic, strong) UIButton *slideDownIconLight;

// TODO: Remove the dismiss control.
@property (nonatomic, strong) UIControl *dismissControl;

- (void)_centerButtonAsCheckMark;
- (void)_centerButtonAsCommentIcon;

- (void)_layoutAttendees;

- (void)_addDismissControl;
- (void)_removeDismissControl;

- (void)_showFullEvent;

/* Convenience methods for getting collection view rects. */
- (CGRect)_invitedViewRectOffscreen;
- (CGRect)_invitedViewRectEditMode;
- (CGRect)_invitedViewRect;
- (CGRect)_uninvitedViewRectOffScreen;
- (CGRect)_uninvitedViewRect;

/* Altering view modes. */
- (void)_alterViewForEditMode;
- (void)_startEditing;
- (void)_stopEditing;
- (void)_hideBorders:(BOOL)hide;

/* Scroll view interfacing. */
- (void)_hideToolbarButtons:(CGFloat)yOffset;
- (void)_realignInvitedView:(CGFloat)yOffset;
- (void)_realignTitleView:(CGFloat)yOffset;
- (void)_holdFooterToolBar:(CGFloat)yOffset;

/* Date View stuff. */
- (void) _showDateViewAnimated;

/* Comment button should show comments. */
- (void)_showCommentsAnimated:(BOOL)animated;
- (void)_hideCommentsAnimated:(BOOL)animated;
- (void)_toggleComments;

/* When selecting a date, if it's a brand new event we should
 * remember what the user selected and then wrap it up into a
 * new event. */
@property (nonatomic, copy) NSString *selectedStartDate;
@property (nonatomic) NSUInteger selectedSemesterID;

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

- (void)_stopEditing {
    self.viewMode = ActivityViewEditMode;
    [self _alterViewForEditMode];  // TODO: Get rid of the alterViewForEditMode?
    [self showFullEventAnimated:YES];
}

- (void)_hideBorders:(BOOL)hide {
    [self.invitedView editMode:hide];
    [self.uninvitedView editMode:hide];
    [self.titleView hideBorder:hide];
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
    if ([intertwineFriend.accountID isEqualToString:[IntertwineManager getAccountID]]) {
        return;
    }
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
        
        if ([self.invitedView.friends count]) {
            [self _showFullEvent];
        } else {
            [self editAttendees];
        }
        
        
        /* Put the title view back on the scroll view! */
        [self.titleView removeFromSuperview];
        [self.backgroundScrollView addSubview:self.titleView];
        
        /* And get rid of the dismiss control. */
        [self.dismissControl removeFromSuperview];
    }
}

#pragma mark - Settings Friends Value

- (void)setFriends:(NSArray *)friends {
    _friends = friends;
    [self.uninvitedView addFriends:_friends];
}

#pragma mark - View Methods

- (void)_centerButtonAsCheckMark {
    /* TODO: Let's consider using a save icon for when we're simply editing a preexisiting
     * event, but a check mark if we're creating a new one. */
    [self.centerButton setBackgroundImage:self.checkMarkImage forState:UIControlStateNormal];
    [self.centerButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.centerButton addTarget:self action:@selector(_create) forControlEvents:UIControlEventTouchUpInside];
}

- (void)_centerButtonAsCommentIcon {
    [self.centerButton setBackgroundImage:self.commentImage forState:UIControlStateNormal];
    [self.centerButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.centerButton addTarget:self action:@selector(_toggleComments) forControlEvents:UIControlEventTouchUpInside];
}

- (void)_layoutAttendees {
    for (Friend *attendee in self.event.attendees) {
        [self.invitedView addFriend:attendee];
        for (Friend *friend in self.friends) {
            if ([friend.accountID isEqualToString:attendee.accountID]) {
                [self.uninvitedView setStatus:kInvited forFriend:attendee];
                break;
            }
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setEventTitle:self.event.eventTitle];
    
    /* Place the invitees in the right collection view, and the uninvited
     * in the other collection view. */
    [self _layoutAttendees];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    /* Adding the background scroll view, which will allow the user to
     * interact with most the facets of the view controller. */
    [self.view addSubview:self.backgroundScrollView];
    
    if (!self.viewMode == ActivityViewCreateMode) {
        [self.backgroundScrollView addSubview:self.commentViewController.view];
    }
    
    self.titleView.center = CGPointMake(SCREEN_WIDTH / 2.0, TitleViewOffscreenY);
    [self.backgroundScrollView addSubview:self.titleView];
    [self.view addSubview:self.slideDownIconLight];
    
    if (self.viewMode == ActivityViewCreateMode) {
        [self editTitle];
        [self _centerButtonAsCheckMark];
        self.backgroundScrollView.contentSize = CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT + 20);  // We add 20, otherwise because paging is enabled it won't work.
        self.invitedView.editControl.enabled = NO;
    } else { //if (self.viewMode == ActivityViewEditMode){
        [self showFullEventAnimated:(self.viewMode != ActivityViewCommentMode)];
        [self _centerButtonAsCommentIcon];
    }
    
    if (self.viewMode == ActivityViewCommentMode) {
        [self _showCommentsAnimated:NO];
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

- (void)_addDismissControl {
    [self.view insertSubview:self.dismissControl aboveSubview:self.backgroundScrollView];
    
    /* Add the right control. */
    [self.dismissControl removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
    if (self.viewMode == ActivityViewCreateMode) {
        [self.dismissControl addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [self.dismissControl addTarget:self action:@selector(_showFullEvent) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)_removeDismissControl {
    [self.dismissControl removeFromSuperview];
}

- (void)editTitle {
    
    /* I want the user to be able to touch the background and quit. */
    [self _addDismissControl];
    
    [self.eventFooterBar removeFromSuperview];
    [self.centerButton removeFromSuperview];

    [self.titleView removeFromSuperview];
    [self.view addSubview:self.titleView];
    
    self.backgroundScrollView.scrollEnabled = NO;
    self.slideDownIconLight.hidden = YES;
    [UIView animateWithDuration:EventViewAnimationDuration
                     animations:^{
                         [self _hideBorders:NO];
                         self.titleView.center = CGPointMake(SCREEN_WIDTH / 2.0, TitleViewEditModeCenterY);
                         [self.invitedView setCollectionViewFrame:[self _invitedViewRectOffscreen]];
                         [self.uninvitedView setCollectionViewFrame:[self _uninvitedViewRectOffScreen]];
                     }
                     completion:^(BOOL finished) {
                         [self.titleView.titleTextField becomeFirstResponder];
                         [self.invitedView removeFromSuperview];
                         [self.uninvitedView removeFromSuperview];
                     }];
}

- (void)editAttendees {
    [self _centerButtonAsCheckMark];
    
    if ([self.invitedView superview] == nil) {
        [self.backgroundScrollView addSubview:self.invitedView];
    }
    if ([self.uninvitedView superview] == nil) {
        [self.backgroundScrollView addSubview:self.uninvitedView];
    }
    [UIView animateWithDuration:EventViewAnimationDuration
                     animations:^{
                         [self _hideBorders:NO];
                         CGRect frame = self.titleView.frame;
                         frame.origin.y = TitleViewOriginY;
                         self.titleView.frame = frame;
                         [self.invitedView setCollectionViewFrame:[self _invitedViewRectEditMode]];
                         [self.uninvitedView setCollectionViewFrame:[self _uninvitedViewRect]];
                     }
                     completion:^(BOOL finished) {
                         if ([self.eventFooterBar superview] == nil) {
                             [self.backgroundScrollView addSubview:self.eventFooterBar];
                         }
                         if ([self.centerButton superview] == nil) {
                             [self.backgroundScrollView addSubview:self.centerButton];
                         }
                     }];
}

- (void)_showFullEvent {
    [self showFullEventAnimated:YES];
}

- (void)showFullEventAnimated:(BOOL)animated {
    [self _centerButtonAsCommentIcon];
    
    [self _removeDismissControl];
    self.backgroundScrollView.scrollEnabled = YES;
    self.slideDownIconLight.hidden = NO;
    
    [self.titleView.titleTextField resignFirstResponder]; 
    
    [self.uninvitedView removeFromSuperview];
    if ([self.invitedView superview] == nil) {
        [self.backgroundScrollView addSubview:self.invitedView];
    }
    
    void (^animations)() = ^{
        [self _hideBorders:YES];
        CGRect frame = self.titleView.frame;
        frame.origin.y = TitleViewOriginY;
        self.titleView.frame = frame;
        [self.invitedView setCollectionViewFrame:[self _invitedViewRect]];
        [self.uninvitedView setCollectionViewFrame:[self _uninvitedViewRectOffScreen]];
    };
    
    void (^completion)(BOOL finished) = ^(BOOL finished) {
        if ([self.eventFooterBar superview] == nil) {
            [self.backgroundScrollView addSubview:self.eventFooterBar];
        }
        if ([self.centerButton superview] == nil) {
            [self.backgroundScrollView addSubview:self.centerButton];
        }
        self.backgroundScrollView.contentSize = CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT * 2.0);
        self.commentViewController.view.hidden = NO;

    };
    
    if (animated) {
        [UIView animateWithDuration:EventViewAnimationDuration
                         animations:animations
                         completion:completion];
    } else {
        animations();
        completion(YES);
    }
}

#pragma mark - Dismiss

- (void)dismiss {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(eventViewControllerWillDismiss)]) {
        [self.delegate eventViewControllerWillDismiss];
    }
//    [UIView animateWithDuration:EventViewAnimationDuration
//                     animations:^{
//                         self.titleView.center = CGPointMake(SCREEN_WIDTH / 2.0, TitleViewOffscreenY);
//                         [self.invitedView setCollectionViewFrame:[self _invitedViewRectOffscreen]];
//                         [self.uninvitedView setCollectionViewFrame:[self _uninvitedViewRectOffScreen]];
//                     }
//                     completion:^(BOOL finished) {
//                         if (self.delegate &&
//                             [self.delegate respondsToSelector:@selector(eventViewControllerWillDismiss)]) {
//                             [self.delegate eventViewControllerWillDismiss];
//                         }
//                     }];
}


#pragma mark - Show Date View

- (void) _showDateViewAnimated {
    DayPickerViewController *dayPicker = [DayPickerViewController new];
    dayPicker.delegate = self;
    [self presentViewController:dayPicker animated:YES completion:nil];
}

#pragma mark - Show Comments

- (void)_showCommentsAnimated:(BOOL)animated {
    CGFloat height = CGRectGetHeight(self.view.frame);
    CGFloat width = CGRectGetWidth(self.view.frame);
    CGRect commentsRect = CGRectMake(0, height, width, height);
    [self.backgroundScrollView scrollRectToVisible:commentsRect animated:animated];
}

- (void)_hideCommentsAnimated:(BOOL)animated {
    CGFloat height = CGRectGetHeight(self.view.frame);
    CGFloat width = CGRectGetWidth(self.view.frame);
    CGRect commentsRect = CGRectMake(0, 0, width, height);
    [self.backgroundScrollView scrollRectToVisible:commentsRect animated:animated];
}

- (void)_toggleComments {
    static CGFloat buffer = 15.0;
    if (self.backgroundScrollView.contentOffset.y > CGRectGetHeight(self.view.frame) - buffer) {
        [self _hideCommentsAnimated:YES];
    } else {
        [self _showCommentsAnimated:YES];
    }
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
        EventObject *event = [EventObject new];
        event.eventTitle = title;
        self.event = event;
        self.event.startDate = self.selectedStartDate;
        self.event.semesterID = self.selectedSemesterID;
        [IntertwineManager createEvent:event withFriends:[self.invitedView friends] withResponse:^(id json, NSError *error, NSURLResponse *response) {
            if (error) {
                NSLog(@"An error has occurred trying to create an event!\n%@", error);
                return;
            }
        }];
//        [self showFullEventAnimated:YES];
        [self dismiss];
    } else if (self.viewMode == ActivityViewEditMode || self.viewMode == ActivityViewEditModeIsEditing) {
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
        
        [IntertwineManager editEvent:self.event withTitle:title newTitle:newTitle invited:editInvited uninvited:editUninvited withResponse:^(id json, NSError *error, NSURLResponse *response) {
            if (error) {
                NSLog(@"An error has occurred trying to create an event!\n%@", error);
                return;
            }
        }];
    } else {
        [self _stopEditing];
    }
    
    if ([self.delegate respondsToSelector:@selector(didEditOrCreateEvent:)]) {
        [self.delegate didEditOrCreateEvent:self.event];
    }
}

#pragma mark - Scroll View Delegate

- (void)_hideToolbarButtons:(CGFloat)yOffset {
    static CGFloat maxY = 70.0;
    CGFloat percentage = yOffset / maxY;
    CGFloat alpha = 1 - percentage;
    if (alpha < 0) alpha = 0;
    self.eventFooterBar.locationButtonView.alpha = alpha;
    self.eventFooterBar.dateButtonView.alpha = alpha;
    self.slideUpIcon.alpha = alpha;
    self.slideDownIconLight.alpha = alpha;
}

- (void)_realignInvitedView:(CGFloat)yOffset {
    CGFloat y = TitleViewOriginY;
    CGRect frame = self.titleView.frame;
    frame.origin.y = y + yOffset;
    self.titleView.frame = frame;
    
    y = FOOTER_TARGET_Y;
    frame = self.invitedView.frame;
    frame.origin.y = y + yOffset;
    self.invitedView.frame = frame;
    
    y = y + CGRectGetHeight(self.invitedView.frame) + EventViewSpacer;
    frame = self.uninvitedView.frame;
    frame.origin.y = y + yOffset;
    self.uninvitedView.frame = frame;
    
    /* If we are creating an event, than we don't want to show comments or anything
     * below. */
    if (self.viewMode != ActivityViewCreateMode) {
        static CGFloat maxY = 70.0;
        CGFloat percentage = yOffset / maxY;
        CGFloat alpha = 1 - percentage;
        if (alpha < 0) alpha = 0;
        self.invitedView.alpha = alpha;
        self.uninvitedView.alpha = alpha;
    }
}

- (void)_realignTitleView:(CGFloat)yOffset {
//    CGRect frame = self.titleView.frame;
//    frame.origin.y = TitleViewOriginY - yOffset;
//    self.titleView.frame = frame;
    
    CGPoint center = self.slideDownIconLight.center;
    center.y = SlideToCloseCenterY - yOffset;
    self.slideDownIconLight.center = center;
    
    CGFloat percentToFade = -yOffset / dismissPointY;
    self.titleView.alpha = 1. - percentToFade;
    self.slideDownIconLight.alpha = 1. - percentToFade;
    self.invitedView.alpha = 1. - percentToFade;
    self.uninvitedView.alpha = 1. - percentToFade;
}

- (void)_holdFooterToolBar:(CGFloat)yOffset {
    CGFloat toolBarY = CGRectGetMinY(FOOTER_TOOLBAR_FRAME);
    
    CGRect frame = self.eventFooterBar.frame;
    frame.origin.y = toolBarY + yOffset;
    self.eventFooterBar.frame = frame;
    
    CGPoint center = self.centerButton.center;
    center.y = toolBarY + yOffset;
    self.centerButton.center = center;
}

- (void)_realignFooterToolBar:(CGFloat)yOffset {
    /* First, let's figure out the percentage progress. */
    CGFloat progress = yOffset / CGRectGetHeight(self.backgroundScrollView.frame);
    
    CGFloat targetY = FOOTER_TARGET_Y;
    CGFloat startingY = CGRectGetMinY(FOOTER_TOOLBAR_FRAME);
    
    CGFloat actualY = startingY - ((startingY - targetY) * progress);
    actualY += yOffset;
    /* Set the frame now. */
    CGRect frame = self.eventFooterBar.frame;
    frame.origin.y = actualY;
    self.eventFooterBar.frame = frame;
    
    /* Let's do the same thing with the center button. */
    targetY = targetY + CGRectGetHeight(FOOTER_TOOLBAR_FRAME) / 2.0;
    actualY = startingY - ((startingY - targetY) * progress);
    actualY += yOffset;
    /* Set the frame for the center button. */
    CGPoint center = self.centerButton.center;
    center.y = actualY;
    self.centerButton.center = center;
    
    /*Realign the comment view controller too. */
    startingY = CGRectGetMaxY(FOOTER_TOOLBAR_FRAME);
    targetY = FOOTER_TARGET_Y + CGRectGetHeight(FOOTER_TOOLBAR_FRAME);
    actualY = startingY - ((startingY - targetY) * progress);
    actualY += yOffset;
    frame = self.commentViewController.view.frame;
    frame.origin.y = actualY;
    self.commentViewController.view.frame = frame;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat yOffset = scrollView.contentOffset.y;
    if (yOffset > 0) {
        if (self.viewMode != ActivityViewCommentMode && self.viewMode != ActivityViewCreateMode &&
            [self.centerButton backgroundImageForState:UIControlStateNormal] != self.commentImage) {
            [self _centerButtonAsCommentIcon];
        }
        [self _realignInvitedView:yOffset];
        if (self.viewMode == ActivityViewCreateMode) {
            [self _holdFooterToolBar:yOffset];
        } else {
            /* We want to hide the toolbar buttons within the first 20 pixels. */
            [self _hideToolbarButtons:yOffset];
            [self _realignFooterToolBar:yOffset];
        }
        scrollView.bounces = NO;
    } else {
        if (self.viewMode == ActivityViewEditModeIsEditing &&
            [self.centerButton backgroundImageForState:UIControlStateNormal] == self.commentImage) {
            [self _centerButtonAsCheckMark];
        }
        [self _realignTitleView:yOffset];
        [self _holdFooterToolBar:yOffset];
        scrollView.bounces = YES;
    }
    if (yOffset < -dismissPointY) {
        [self dismiss];
    }
}

#pragma mark - Comment View Controller Delegate

- (void)didEnterCommentMode {
    self.backgroundScrollView.scrollEnabled = NO;
}

- (void)didExitCommentMode {
    self.backgroundScrollView.scrollEnabled = YES;
}


#pragma mark - Blues Friends Delegate

- (void)shouldEnableEditCollectionView {
    [self _startEditing];
    [self editAttendees];
}
- (void)shouldDisableEditCollectionView {
    [self _stopEditing];
}

#pragma mark - Day Picker Delegate

- (void) shouldDismissDayPickerViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) didSelectStartDate:(nonnull NSString*)startDate semesterIndex:(NSUInteger)semesterIndex {
    /* If we are creating, we want to do one thing, and if we're editing let's do another.
     * Basically, update or don't update. */
    if (self.event && self.event.eventID) {
        self.event.startDate = startDate;
        self.event.semesterID = semesterIndex;
        [IntertwineManager editEvent:self.event withTitle:self.event.eventTitle newTitle:nil invited:nil uninvited:nil withResponse:nil];
    } else {
        self.selectedStartDate = startDate;
        self.selectedSemesterID = semesterIndex;
    }
    [self shouldDismissDayPickerViewController];
}


#pragma mark - Lazy Loading

- (UIControl*)dismissControl {
    if (!_dismissControl) {
        CGRect frame = [[UIScreen mainScreen] bounds];
        frame.origin.x = 0;
        frame.origin.y = 0;
        _dismissControl = [[UIControl alloc] initWithFrame:frame];
//        [_dismissControl addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    }
    return _dismissControl;
}

- (UIImage*)commentImage {
    if (!_commentImage) {
        _commentImage = [UIImage imageNamed:@"CommentsSlide.png"]; //TODO: Rename this PNG, it's an awful name!
    }
    return _commentImage;
}

- (UIImage*)checkMarkImage {
    if (!_checkMarkImage) {
        _checkMarkImage = [UIImage imageNamed:@"CompleteIcon.png"];
    }
    return _checkMarkImage;
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
        _invitedView = [[BlueFriendsCollectionView alloc] initWithFrame:[self _invitedViewRectOffscreen]];
        [_invitedView setTitle:@"Invited"];
        _invitedView.delegate = self;
        _invitedView.bluesDelegate = self;
        _invitedView.editControl.enabled = YES;
    }
    return _invitedView;
}

- (BlueFriendsCollectionView*)uninvitedView {
    if (!_uninvitedView) {
        _uninvitedView = [[BlueFriendsCollectionView alloc] initWithFrame:[self _uninvitedViewRectOffScreen]];
        [_uninvitedView setTitle:@"Friends"];
        _uninvitedView.delegate = self;
        _uninvitedView.bluesDelegate = self;
    }
    return _uninvitedView;
}

- (UIButton*)centerButton {
    if (!_centerButton) {
        _centerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_centerButton setBackgroundImage:self.commentImage forState:UIControlStateNormal];
        _centerButton.clipsToBounds = NO;
        
        [_centerButton addTarget:self action:@selector(_toggleComments) forControlEvents:UIControlEventTouchUpInside];
        
        CGFloat buttonHeight = 76.0;
        
        _centerButton.frame = CGRectMake(0, 0, buttonHeight, buttonHeight);
        _centerButton.center = CGPointMake(CGRectGetMidX(self.view.frame), CGRectGetMinY(FOOTER_TOOLBAR_FRAME));
        
        [_centerButton addSubview:self.slideUpIcon];
        self.slideUpIcon.center = CGPointMake(buttonHeight/2.0, -10);
        
        _centerButton.layer.cornerRadius = CGRectGetWidth(_centerButton.frame) / 2.0;
        _centerButton.layer.borderColor = [[UIColor blackColor] CGColor];
    }
    return _centerButton;
}

- (UIImageView*)slideUpIcon {
    if (!_slideUpIcon) {
        UIImage *slideImage = [UIImage imageNamed:@"SlideUp.png"];
        _slideUpIcon = [[UIImageView alloc] initWithImage:slideImage];
        _slideUpIcon.frame = CGRectMake(0, 0, slideImage.size.width, slideImage.size.height);
    }
    return _slideUpIcon;
}

- (UIImageView*)slideDownIconDark {
    if (!_slideDownIconDark) {
        UIImage *slideDownDarkImage = [UIImage imageNamed:@"SlideDownDark.png"];
        _slideDownIconDark = [[UIImageView alloc] initWithImage:slideDownDarkImage];
        _slideDownIconDark.frame = CGRectMake(0, 0, slideDownDarkImage.size.width, slideDownDarkImage.size.height);
        _slideDownIconDark.center = CGPointMake(CGRectGetMidX(self.view.frame), 850);
        _slideDownIconDark.alpha = 0;
    }
    return _slideDownIconDark;
}

- (UIButton*)slideDownIconLight {
    if (!_slideDownIconLight) {
        UIImage *slideDownLightImage = [UIImage imageNamed:@"SlideDownLight.png"];
        _slideDownIconLight = [UIButton buttonWithType:UIButtonTypeCustom];
        _slideDownIconLight.frame = CGRectMake(0, 0, 100.0, 50.0 /*slideDownLightImage.size.height * 2.0*/);
        _slideDownIconLight.center = CGPointMake(CGRectGetMidX(self.view.frame), SlideToCloseCenterY);
        [_slideDownIconLight setImage:slideDownLightImage forState:UIControlStateNormal];
        [_slideDownIconLight addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    }
    return _slideDownIconLight;
}

- (EventFooterBar*)eventFooterBar {
    if (!_eventFooterBar) {
        _eventFooterBar = [[EventFooterBar alloc] initWithFrame:FOOTER_TOOLBAR_FRAME];
        [_eventFooterBar.dateButton addTarget:self action:@selector(_showDateViewAnimated) forControlEvents:UIControlEventTouchUpInside];
    }
    return _eventFooterBar;
}

- (UIScrollView*)backgroundScrollView {
    if (!_backgroundScrollView) {
        CGFloat width = CGRectGetWidth(self.view.frame);
        CGFloat height = CGRectGetHeight(self.view.frame);
        _backgroundScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        _backgroundScrollView.pagingEnabled = YES;
        _backgroundScrollView.contentSize = CGSizeMake(width, height * 2.0);
        _backgroundScrollView.delegate = self;
        _backgroundScrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    }
    return _backgroundScrollView;
}

//- (UILabel*)dateLabel {
//    if (!_dateLabel) {
//        _dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.titleView.frame), CGRectGetWidth(self.view.frame), 30)];
//        _dateLabel.textColor = [UIColor whiteColor];
//    }
//    return _dateLabel;
//}

#pragma mark - Comment View Controller Lazy Loading

- (CommentViewController*)commentViewController {
    if (!_commentViewController) {
        CGFloat height = CGRectGetHeight(self.view.frame) - FOOTER_TARGET_Y - CGRectGetHeight(FOOTER_TOOLBAR_FRAME);
        _commentViewController = [CommentViewController new];
        _commentViewController.view.frame = CGRectMake(0, CGRectGetMaxY(FOOTER_TOOLBAR_FRAME), CGRectGetWidth(self.view.frame), height);
        _commentViewController.event = self.event;
        _commentViewController.delegate = self;
    }
    return _commentViewController;
}

@end
