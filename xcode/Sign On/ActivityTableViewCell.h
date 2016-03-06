//
//  ActivityTableViewCell.h
//  ActivityCell
//
//  Created by Ben Rooke on 8/24/15.
//  Copyright (c) 2015 Ben Rooke. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EventObject;
@class IntertwineButton;
@class ActivityTableViewCell;

@protocol ActivityCellDelegate <NSObject>
@optional
- (void)didSelectCommentButton:(EventObject*)event forCell:(ActivityTableViewCell*)cell;
- (void)didSelectLikeButton:(EventObject*)event forCell:(ActivityTableViewCell*)cell;
- (void)didSelectCompleteButton:(EventObject*)event forCell:(ActivityTableViewCell*)cell;
@end



@interface ActivityTableViewCell : UITableViewCell

@property (nonatomic, weak) id<ActivityCellDelegate> delegate;

@property (nonatomic, strong) IntertwineButton *completedButton;
@property (nonatomic, strong) IntertwineButton *commentButton;
@property (nonatomic, strong) IntertwineButton *likeButton;

@property (nonatomic, strong) UILabel *titleLabel;
- (void)setTitle:(NSString*)title;

@property (nonatomic, strong) UILabel *dateLabel;

@property (nonatomic, strong) NSArray *attendees;

- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier;

@property (nonatomic, strong) EventObject *event;

- (void) resize;
+ (CGFloat) cellHeightForEvent:(EventObject*)event andAttendeeCount:(NSUInteger)count;

- (void)completed:(BOOL)isComplete;

@end

extern const CGFloat activityCellHeight;