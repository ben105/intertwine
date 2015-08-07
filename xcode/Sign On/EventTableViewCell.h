//
//  EventTableViewCell.h
//  Intertwine
//
//  Created by Ben Rooke on 4/1/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EventObject;


@protocol EventTableViewCellDelegate <NSObject>
- (void) presentCommentsWithEvent:(EventObject*)event;
@end

@interface EventTableViewCell : UITableViewCell

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier indentLength:(CGFloat)indent;

@property (nonatomic, strong) UILabel  *eventLabel;
@property (nonatomic, strong) UILabel  *friendsLabel;
@property (nonatomic, strong) UILabel *commentLabel;

@property (nonatomic, weak) EventObject *event;

@property (nonatomic, weak) id <EventTableViewCellDelegate>delegate;

- (void) setCreatorThumbnailWithID:(NSString*)profileID facebook:(BOOL)isFacebook;
- (void) setAttendees:(NSArray*)attendees;
- (void) setAttendeeCount:(NSUInteger)count;


@end


extern CGFloat innerCellWidth;
extern CGFloat innerCellHeight;
extern CGFloat outterCellHeight;