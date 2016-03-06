//
//  EventViewController.h
//  Invite
//
//  Created by Ben Rooke on 12/30/15.
//  Copyright © 2015 NinjaQuant LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlueFriendsCollectionView.h"
#import "EventTitleView.h"
#import "DayPickerViewController.h"

@class EventObject;

typedef enum {
    ActivityViewCreateMode,
    // This might be better phrased as "FullMode" or something.
    ActivityViewEditMode,
    ActivityViewEditModeIsEditing,
    ActivityViewCommentMode
} ActivityViewMode;


@protocol EventViewControllerDelegate <NSObject>
@required
- (void) eventViewControllerWillDismiss;
- (void) didEditOrCreateEvent:(EventObject*)event;
@end


@interface EventViewController : UIViewController <DayPickerDelegate, BlueFriendsDelegate, FriendsCollectionViewDelegate, CommentViewDelegate, EventTitleViewDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) EventTitleView *titleView;
@property (nonatomic) ActivityViewMode viewMode;
@property (nonatomic, strong) EventObject *event;
@property (nonatomic, weak) id<EventViewControllerDelegate> delegate;

@property (nonatomic, strong) BlueFriendsCollectionView *invitedView;
@property (nonatomic, strong) BlueFriendsCollectionView *uninvitedView;

/* The friends array keeps track of the list of your friends. */
@property (nonatomic, strong) NSArray *friends;

- (void)editTitle;
- (void)editAttendees;
- (void)showFullEventAnimated:(BOOL)animated;

- (void)setEventTitle:(NSString*)title;


@end
