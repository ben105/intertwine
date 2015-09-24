//
//  ActivityTableViewCell.m
//  ActivityCell
//
//  Created by Ben Rooke on 8/24/15.
//  Copyright (c) 2015 Ben Rooke. All rights reserved.
//

#import "ActivityTableViewCell.h"
#import "CommentViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "Friend.h"
#import "EventObject.h"
#import "FriendProfileView.h"
#import "ButtonBarView.h"
#import "IntertwineManager.h"

#import "UILabel+DynamicHeight.h"


#define DETAIL_COLOR [UIColor colorWithRed:1 green:1 blue:1 alpha:0.85]
#define DETAIL_COLOR_COMPLETE [UIColor colorWithRed:1 green:223.0/255.0 blue:58.0/255.0 alpha:0.7]
#define ACTION_COLOR [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5]
#define ACTION_COLOR_COMPLETE [UIColor colorWithRed:1 green:177.0/255.0 blue:2.0/255.0 alpha:0.49]

#define TITLE_COLOR [UIColor colorWithRed:8.0/255.0 green:41.0/255.0 blue:64.0/255.0 alpha:1.0]


const NSUInteger attendeesPerRow = 3.0;
const CGFloat activityCellEdgeSpace = 30.0;
#define ATTENDEE_SPACER ((CGRectGetWidth([[UIScreen mainScreen] bounds]) - 2.0*activityCellEdgeSpace - attendeesPerRow * attendeeBubbleWidth)/2.0)

const CGFloat inset = 10.0;
const CGFloat detailBoxHeight = 84.0;
const CGFloat buttonBoxHeight = 60.0;
const CGFloat activityCellHeight = inset*2.0 + detailBoxHeight;

const CGFloat attendeeBubbleWidth = 78.0;
const CGFloat attendeeLabelSpace = 15.0;
const CGFloat activityCellSpacer = 5.0;
/* We want to figure out the distance from the right side of the screen
 * to the end of the title label. So let's show 3 attendees and 1 partial
 * attendee. And there should be a activityCellSpacer between each attendee, as well
 * as a activityCellSpacer between the first attendee and the title.
 
 [  title   ]-( )-( )-( )-(|
 
 So that gives us 4 activityCellSpacers, 3 full attendee bubble widths, and a partial one. */

#define TITLE_SPACE ([[UIScreen mainScreen] bounds].size.width - (inset * 2.0))

const CGFloat titleHeight = 48.0;
const CGFloat activityCellTitleFontSize = 22.0;


const CGFloat buttonIconWidth = 25.0;
const CGFloat buttonIconInset = 30.0;


/* Global label object, for measuring height of cell. */
UILabel *measuringLabel;




@interface AttendeeView : UIView

@property (nonatomic, strong) FriendProfileView *profileView;
@property (nonatomic, strong) UILabel *nameLabel;
- (void) checkFit;

+ (CGFloat) attendeeViewHeight;
@end

@implementation AttendeeView

+ (CGFloat) attendeeViewHeight {
    return attendeeBubbleWidth + attendeeLabelSpace + 3.0;
}

- (void) checkFit {
    NSArray *components = [self.nameLabel.text componentsSeparatedByString:@" "];
    CGSize size = [self.nameLabel.text sizeWithAttributes:@{NSFontAttributeName : self.nameLabel.font}];
    if (size.width > self.nameLabel.bounds.size.width) {
        NSString *firstName = [components objectAtIndex:0];
        if ([components count] > 1) {
            NSString *lastName = [components objectAtIndex:1];
            unichar c = [lastName characterAtIndex:0];
            self.nameLabel.text = [NSString stringWithFormat:@"%@ %c.", firstName, c];
            CGSize size = [self.nameLabel.text sizeWithAttributes:@{NSFontAttributeName : self.nameLabel.font}];
            if (size.width > self.nameLabel.bounds.size.width && [components count] > 1) {
                unichar f = [firstName characterAtIndex:0];
                self.nameLabel.text = [NSString stringWithFormat:@"%c.%c.", f, c];
            }
        } else {
            unichar f = [firstName characterAtIndex:0];
            self.nameLabel.text = [NSString stringWithFormat:@"%c.", f];
        }
    }
}

- (id) initWithName:(NSString*)name andProfileID:(NSString*)profileID {
    static CGFloat spacer = 3.0;
    self = [super initWithFrame:CGRectMake(0, 0, attendeeBubbleWidth, attendeeBubbleWidth + attendeeLabelSpace + spacer)];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        self.profileView = [[FriendProfileView alloc] initWithFrame:CGRectMake(0, 0, attendeeBubbleWidth, attendeeBubbleWidth)];
        self.profileView.profileID = profileID;
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, attendeeBubbleWidth + spacer, attendeeBubbleWidth, attendeeLabelSpace)];
        self.nameLabel.text = name;
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        self.nameLabel.backgroundColor = [UIColor clearColor];
        self.nameLabel.textColor = [UIColor colorWithRed:8.0/255.0 green:41.0/255.0 blue:64.0/255.0 alpha:1];
        self.nameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
        [self checkFit];
        
        [self addSubview:self.profileView];
        [self addSubview:self.nameLabel];
    }
    return self;
}

@end






@interface ActivityTableViewCell ()

@property (nonatomic, strong) ButtonBarView *buttonBox;

@property (nonatomic, strong) UIView *detailBox;
@property (nonatomic, strong) NSMutableArray *attendeeViews;
@property (nonatomic, strong) UIView *attendeePallet;
- (void)_clearAttendeeViews;
- (void)_addAttendeeView:(Friend*)attendee;
- (CGFloat)_attendeeViewOffset:(NSUInteger)index;


- (void)_showComments;
- (void)_markComplete;
@end


@implementation ActivityTableViewCell

@synthesize attendees = _attendees;

- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.contentView.layer.shadowOffset = CGSizeMake(0, -2);
        
        
        CGRect contentFrame = self.contentView.frame;
        contentFrame.origin.y = 0;
        contentFrame.size.height = activityCellHeight;
        contentFrame.size.width = [[UIScreen mainScreen] bounds].size.width;
        self.contentView.frame = contentFrame;
        self.contentView.backgroundColor = [UIColor clearColor];
        self.contentView.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.contentView.layer.shadowOffset = CGSizeMake(0, -2);
        
        [self.contentView addSubview:self.detailBox];

        [self.detailBox addSubview:self.buttonBox];
        [self.detailBox addSubview:self.titleLabel];
        [self.detailBox addSubview:self.attendeePallet];
    }
    return self;
}


#pragma mark - Attendee Views

- (CGFloat)_attendeeViewOffset:(NSUInteger)index {
    return TITLE_SPACE + (activityCellSpacer * (CGFloat)index) + (attendeeBubbleWidth * (CGFloat)(index - 1));
}

- (void) _clearAttendeeViews {
    for (UIView *aSubview in self.attendeeViews) {
        [aSubview removeFromSuperview];
    }
    [self.attendeeViews removeAllObjects];
}

- (void) _addAttendeeView:(Friend*)attendee {
    
    CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    
    CGFloat x = 0;
    CGFloat y = 0;
    
    if ([self.attendees count] == 2) {
        
        y = inset;
        x = 0;
        
        switch ([self.attendees indexOfObject:attendee]) {
            case 0:
                x = screenWidth/2.0 - attendeeBubbleWidth - (ATTENDEE_SPACER / 2.0);
                break;
            case 1:
                x = screenWidth/2.0 + (ATTENDEE_SPACER/2.0);
                break;
            default:
                break;
        }

    } else {
    
        NSUInteger i = [self.attendees indexOfObject:attendee];
        NSUInteger column = i % attendeesPerRow;
        NSUInteger row = i / attendeesPerRow;
        x = activityCellEdgeSpace + column*(attendeeBubbleWidth + ATTENDEE_SPACER);
        y = inset + row*([AttendeeView attendeeViewHeight] + inset);
    }
    
    AttendeeView *attendeeView = [[AttendeeView alloc] initWithName:attendee.fullName andProfileID:attendee.facebookID];
    CGRect frame = attendeeView.frame;
    frame.origin.x = x;
    frame.origin.y = y;
    attendeeView.frame = frame;
    
    /* Keep track of the attendee views, so we can remove them on a cell recycle. */
    [self.attendeeViews addObject:attendeeView];
    /* Add the new view to the scroll view. */
    [self.attendeePallet addSubview:attendeeView];
}

#pragma mark - Cell Height

- (void) resize {
    
    /* Determine the label height. */
    CGRect titleLabelFrame = self.titleLabel.frame;
    CGFloat newHeight = [self.titleLabel sizeOfMultiLineLabel].height;
    if (newHeight < titleHeight) {
        newHeight = titleHeight;
    }
    titleLabelFrame.size.height = newHeight;
    titleLabelFrame.size.width = TITLE_SPACE;
    self.titleLabel.frame = titleLabelFrame;
    
    /* Determine the attendee pallet height. */
    NSUInteger lastAttendee = [self.attendees count] - 1;
    CGFloat palletHeight = inset + (lastAttendee/attendeesPerRow) * ([AttendeeView attendeeViewHeight] + (inset));
    palletHeight += [AttendeeView attendeeViewHeight];
    
    CGRect palletFrame = self.attendeePallet.frame;
    palletFrame.origin.y = CGRectGetMaxY(titleLabelFrame);
    palletFrame.size.height = palletHeight;
    self.attendeePallet.frame = palletFrame;
    
    
    self.detailBox.frame = CGRectMake(0, inset, CGRectGetWidth(self.contentView.frame), newHeight + palletHeight + buttonBoxHeight + activityCellSpacer);
    
    CGRect frame = self.buttonBox.frame;
    frame.origin.y = CGRectGetMaxY(palletFrame);
    self.buttonBox.frame = frame;

    if ([self.event.creator.accountID isEqualToString:[IntertwineManager getAccountID]]) {
        self.buttonBox.buttons = @[self.likeButton, self.commentButton, self.completedButton];
    } else {
        self.buttonBox.buttons = @[self.likeButton, self.commentButton];
    }

    
    CGRect contentFrame = self.contentView.frame;
    contentFrame.origin.y = 0;
    contentFrame.size.height = CGRectGetHeight(self.detailBox.frame);
    contentFrame.size.width = [[UIScreen mainScreen] bounds].size.width;
    self.contentView.frame = contentFrame;
}

+ (CGFloat) cellHeightForString:(NSString*)title andAttendeeCount:(NSUInteger)count{
    if (!title) {
        return activityCellHeight;
    }
    /* Reset the cell comment label width, because if we're using a recycled cell,
     * then the following 'sizeOfMultiLineLabel' will fail. */
    if (!measuringLabel) {
        measuringLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    }
    measuringLabel.frame = CGRectMake(15, activityCellSpacer, TITLE_SPACE, titleHeight);
    measuringLabel.text = title;
    measuringLabel.font = [UIFont fontWithName:@"Helvetica" size:activityCellTitleFontSize];
    measuringLabel.textAlignment = NSTextAlignmentCenter;
    measuringLabel.numberOfLines = 0;
    measuringLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    CGSize size = [measuringLabel sizeOfMultiLineLabel];
    if (size.height < titleHeight) {
        size.height = titleHeight;
    }
    
    CGFloat palletHeight = inset + ((count-1)/attendeesPerRow) * ([AttendeeView attendeeViewHeight] + (inset));
    palletHeight += [AttendeeView attendeeViewHeight];
    
    return size.height + palletHeight + buttonBoxHeight +(activityCellSpacer) + 15.0;
}


#pragma mark - Completing Activity

- (void)_markComplete {
    if ([self.delegate respondsToSelector:@selector(didSelectCompleteButton:forCell:)]) {
        [self.delegate didSelectCompleteButton:self.event forCell:self];
    }
}

- (void)completed:(BOOL)isComplete {
    if (isComplete) {
        self.detailBox.backgroundColor = DETAIL_COLOR;
//        self.buttonBox.backgroundColor = ACTION_COLOR_COMPLETE;
    } else {
        self.detailBox.backgroundColor = DETAIL_COLOR;
//        self.buttonBox.backgroundColor = ACTION_COLOR;
    }
}


#pragma mark - Title 

- (void)setTitle:(NSString*)title {
    self.titleLabel.text = title;
    [self resize];
}


#pragma mark - Comments

- (void)_showComments {
    if (self.delegate != nil) {
        if ([self.delegate respondsToSelector:@selector(didSelectCommentButton:forCell:)]) {
            [self.delegate didSelectCommentButton:self.event forCell:self];
        }
    }
}


#pragma mark - Lazy Loading

- (UILabel*)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(inset, 0, TITLE_SPACE, titleHeight)];
        _titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:activityCellTitleFontSize];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = TITLE_COLOR;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 0;
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _titleLabel.userInteractionEnabled = NO;
    }
    return _titleLabel;
}

- (NSArray*)attendees {
    if (!_attendees) {
        _attendees = [[NSArray alloc] init];
    }
    return _attendees;
}

- (void) setAttendees:(NSArray *)attendees {
    _attendees = attendees;
    [self _clearAttendeeViews];

    NSUInteger i;
    for (i=0; i<[attendees count]; ++i) {
        [self _addAttendeeView:[attendees objectAtIndex:i]];
    }
    
    /* Migth have to reszie the cell here. */
    [self resize];
    
//    CGFloat furthestView = [self _attendeeViewOffset:i] + attendeeBubbleWidth + activityCellSpacer;
//    self.scrollView.contentSize = CGSizeMake(furthestView, self.scrollView.contentSize.height);
}

- (NSMutableArray*)attendeeViews {
    if (!_attendeeViews) {
        _attendeeViews = [[NSMutableArray alloc] init];
    }
    return _attendeeViews;
}

- (UIView*) attendeePallet {
    if (!_attendeePallet) {
        _attendeePallet = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.contentView.frame), 0)];
        _attendeePallet.backgroundColor = [UIColor clearColor];
    }
    return _attendeePallet;
}


- (UIView*)detailBox {
    if (!_detailBox) {
        _detailBox = [[UIView alloc] initWithFrame:CGRectMake(0, inset, CGRectGetWidth(self.contentView.frame), detailBoxHeight)];
        _detailBox.layer.shadowColor = [[UIColor blackColor] CGColor];
        _detailBox.layer.shadowOpacity = 0.7;
        _detailBox.layer.shadowOffset = CGSizeMake(0, -3);
    }
    return _detailBox;
}

- (ButtonBarView*)buttonBox {
    if (!_buttonBox) {
        _buttonBox = [[ButtonBarView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, buttonBoxHeight) buttonArray:@[self.likeButton, self.commentButton]];
        _buttonBox.backgroundColor = [UIColor clearColor];
    }
    return _buttonBox;
}

- (IntertwineButton*)commentButton {
    if (!_commentButton) {
        
        _commentButton = [[IntertwineButton alloc] initWithDetail:@"0 comments" andImage:[UIImage imageNamed:@"CommentIcon.png"]];
        [_commentButton addTarget:self action:@selector(_showComments) forControlEvents:UIControlEventTouchUpInside];
    }
    return _commentButton;
}

- (IntertwineButton*)likeButton {
    if (!_likeButton) {
        _likeButton = [[IntertwineButton alloc] initWithDetail:@"0 likes" andImage:[UIImage imageNamed:@"LikeIcon.png"]];
    }
    return _likeButton;
}


- (IntertwineButton*)completedButton {
    if (!_completedButton) {
        _completedButton = [[IntertwineButton alloc] initWithDetail:@"completed" andImage:[UIImage imageNamed:@"CompletedIcon.png"]];
        [_completedButton addTarget:self action:@selector(_markComplete) forControlEvents:UIControlEventTouchUpInside];
    }
    return _completedButton;
}


@end
