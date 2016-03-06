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


#define DETAIL_COLOR [UIColor colorWithRed:195.0/255.0 green:195.0/255.0 blue:195.0/255.0 alpha:0.24]
#define DETAIL_COLOR_COMPLETE [UIColor colorWithRed:1 green:223.0/255.0 blue:58.0/255.0 alpha:0.7]
#define ACTION_COLOR [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5]
#define ACTION_COLOR_COMPLETE [UIColor colorWithRed:1 green:177.0/255.0 blue:2.0/255.0 alpha:0.49]

//#define TITLE_COLOR [UIColor colorWithRed:20.0/255.0 green:81.0/255.0 blue:121.0/255.0 alpha:1.0]
#define TITLE_COLOR [UIColor whiteColor]

#define LABEL_BACKGROUND_COLOR [UIColor colorWithRed:216.0/255.0 green:216.0/255.0 blue:216.0/255.0 alpha:0.35]


const NSUInteger attendeesPerRow = 3.0;
const CGFloat activityCellEdgeSpace = 30.0;
#define ATTENDEE_SPACER ((CGRectGetWidth(self.detailBox.frame) - 2.0*activityCellEdgeSpace - attendeesPerRow * attendeeBubbleWidth)/2.0)

const CGFloat inset = 15.0;
const CGFloat detailBoxHeight = 84.0;
const CGFloat buttonBoxHeight = 75.0;
const CGFloat activityCellHeight = inset*2.0 + detailBoxHeight;

const CGFloat attendeeBubbleWidth = 88.0;
//const CGFloat attendeeBubbleWidth = 98.0;
const CGFloat attendeeLabelSpace = 15.0;
const CGFloat activityCellSpacer = 5.0;
const CGFloat ActivityTableViewCellSpaceBetweenCells = 65.0;
/* We want to figure out the distance from the right side of the screen
 * to the end of the title label. So let's show 3 attendees and 1 partial
 * attendee. And there should be a activityCellSpacer between each attendee, as well
 * as a activityCellSpacer between the first attendee and the title.
 
 [  title   ]-( )-( )-( )-(|
 
 So that gives us 4 activityCellSpacers, 3 full attendee bubble widths, and a partial one. */

#define TITLE_SPACE (CGRectGetWidth([[UIScreen mainScreen] bounds]) - (inset * 2.0)*2.0)

const CGFloat titleHeight = 25.0;
const CGFloat activityCellTitleFontSize = 22.0;

const CGFloat buttonIconWidth = 25.0;
const CGFloat buttonIconInset = 30.0;


const CGFloat coverPhotoHeight = 130.0;

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
    static CGFloat spacer = 7.0;
    self = [super initWithFrame:CGRectMake(0, 0, attendeeBubbleWidth, attendeeBubbleWidth + attendeeLabelSpace + spacer)];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        self.profileView = [[FriendProfileView alloc] initWithFrame:CGRectMake(0, 0, attendeeBubbleWidth, attendeeBubbleWidth)];
        self.profileView.profileID = profileID;
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, attendeeBubbleWidth + spacer, attendeeBubbleWidth, attendeeLabelSpace)];
        self.nameLabel.text = name;
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        self.nameLabel.backgroundColor = [UIColor clearColor];
//        self.nameLabel.textColor = [UIColor colorWithRed:8.0/255.0 green:41.0/255.0 blue:64.0/255.0 alpha:1];
        self.nameLabel.textColor = [UIColor whiteColor];
        self.nameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
        [self checkFit];
        
        [self addSubview:self.profileView];
        [self addSubview:self.nameLabel];
    }
    return self;
}

@end






@interface ActivityTableViewCell ()

@property (nonatomic, strong) UIView *labelBackground;
@property (nonatomic, strong) ButtonBarView *buttonBox;
@property (nonatomic, strong) UIView *detailBox;
@property (nonatomic, strong) UIImageView *coverPhoto;
@property (nonatomic, strong) NSMutableArray *attendeeViews;
@property (nonatomic, strong) UIView *attendeePallet;

/* Attendee placement within the pallet. */
- (void)_clearAttendeeViews;
- (void)_addAttendeeView:(Friend*)attendee;
- (CGFloat)_attendeeViewOffset:(NSUInteger)index;

/* Methods for when an event is complete. */
- (void)_showComments;
- (void)_markComplete;

/* For the resizing and determination of height, these private methods
 * will help. */
- (void) _placeView:(UIView*)view underView:(UIView*)previousView;
+ (CGFloat) _heightForTitle:(NSString*)title;
- (void) _placeTitle;
+ (CGFloat) _heightForDate:(nullable NSDate*)date andSemester:(nullable NSString*)semester;
- (void) _placeDate;
+ (CGFloat) _heightForPalletWithAttendeeCount:(NSUInteger)numberOfAttendees;
- (void) _placePallet;
+ (CGFloat) _heightForButtons;
- (void) _placeButtons;

@end


@implementation ActivityTableViewCell

@synthesize attendees = _attendees;

- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
//        self.contentView.layer.shadowColor = [[UIColor blackColor] CGColor];
//        self.contentView.layer.shadowOffset = CGSizeMake(0, -2);
        
//        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        CGRect contentFrame = self.contentView.frame;
        contentFrame.origin.y = 0;
        contentFrame.size.height = activityCellHeight;
        contentFrame.size.width = [[UIScreen mainScreen] bounds].size.width;
        self.contentView.frame = contentFrame;
        self.contentView.backgroundColor = [UIColor clearColor];
//        self.contentView.layer.shadowColor = [[UIColor blackColor] CGColor];
//        self.contentView.layer.shadowOffset = CGSizeMake(0, -2);
        
        [self.contentView addSubview:self.detailBox];

        [self.detailBox addSubview:self.buttonBox];
        [self.detailBox addSubview:self.labelBackground];
        [self.detailBox addSubview:self.titleLabel];
        [self.detailBox addSubview:self.dateLabel];
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
    CGFloat screenWidth = CGRectGetWidth(self.detailBox.frame);
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
        y = inset + row*([AttendeeView attendeeViewHeight] + inset*2.0);
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

- (void) _placeView:(UIView*)view underView:(UIView*)previousView {
    CGRect frame = view.frame;
    frame.origin.y = CGRectGetMaxY(previousView.frame) + activityCellSpacer;
    view.frame = frame;
}

+ (CGFloat) _heightForTitle:(NSString*)title {
    UILabel *label = [ActivityTableViewCell measuringLabel];
    label.text = title;
    CGFloat newHeight = [label sizeOfMultiLineLabel].height;
    /* We want a minimum title height, so we will check if we assigned
     * lower than the minimum and correct it. */
    if (newHeight < titleHeight) {
        newHeight = titleHeight;
    }
    return newHeight;
}

- (void) _placeTitle {
    /* Capture the frames. */
    CGRect titleLabelFrame = self.titleLabel.frame;
    CGRect labelBackgroundFrame = self.labelBackground.frame;
    /* Grab the new height. */
    CGFloat newHeight = [ActivityTableViewCell _heightForTitle:self.titleLabel.text];
    /* Set the frame's heights. */
    titleLabelFrame.size.height = newHeight;
    labelBackgroundFrame.size.height = newHeight + (inset * 2.0);
    /* Reassign frames. */
    self.titleLabel.frame = titleLabelFrame;
    self.labelBackground.frame = labelBackgroundFrame;
}

+ (CGFloat) _heightForDate:(nullable NSDate*)date andSemester:(nullable NSString*)semester {
    if (date == nil) {
        return 0;
    } else if (semester == nil) {
        return 20.0;
    }
    return 40.0;
}

- (void) _placeDate {
    CGFloat height = [ActivityTableViewCell _heightForDate:self.event.timestamp andSemester:self.event.semester];
    CGRect frame = self.dateLabel.frame;
    frame.size.height = height;
    self.dateLabel.frame = frame;
    [self _placeView:self.dateLabel underView:self.labelBackground];
}

+ (CGFloat) _heightForPalletWithAttendeeCount:(NSUInteger)numberOfAttendees {
    CGFloat numOfRows = ceil((float)numberOfAttendees / (float)attendeesPerRow);
    return inset + (numOfRows * ([AttendeeView attendeeViewHeight] + inset));
}

- (void) _placePallet {
    CGFloat height = [ActivityTableViewCell _heightForPalletWithAttendeeCount:[self.event.attendees count]];
    CGRect frame = self.attendeePallet.frame;
    frame.size.height = height;
    self.attendeePallet.frame = frame;
    [self _placeView:self.attendeePallet underView:self.dateLabel];
}

+ (CGFloat) _heightForButtons {
    return buttonBoxHeight;
}

- (void) _placeButtons {
    [self _placeView:self.buttonBox underView:self.attendeePallet];
}

- (void) resize2 {
    [self _placeTitle];
    [self _placeDate];
    [self _placePallet];
    [self _placeButtons];
    
    CGFloat stretchToY = CGRectGetMaxY(self.buttonBox.frame);
    CGRect frame = self.detailBox.frame;
    frame.size.height = stretchToY;
    self.detailBox.frame = frame;
}

- (void) resize {
    
    [self resize2];
    return;
    
    /* Determine the label height. */
    CGRect titleLabelFrame = self.titleLabel.frame;
    CGRect labelBackgroundFrame = self.labelBackground.frame;
    CGFloat newHeight = [self.titleLabel sizeOfMultiLineLabel].height;
    if (newHeight < titleHeight) {
        newHeight = titleHeight;
    }
    titleLabelFrame.size.height = newHeight;
    labelBackgroundFrame.size.height = newHeight + (inset*2.0);
    titleLabelFrame.size.width = TITLE_SPACE;
    self.titleLabel.frame = titleLabelFrame;
    self.labelBackground.frame = labelBackgroundFrame;
    
    /* Determine the attendee pallet height. */
    NSUInteger lastAttendee = [self.attendees count] - 1;
    CGFloat palletHeight = inset + (lastAttendee/attendeesPerRow) * ([AttendeeView attendeeViewHeight] + (inset*2.0));
    palletHeight += [AttendeeView attendeeViewHeight];
    
    CGRect palletFrame = self.attendeePallet.frame;
    if (self.event.timestamp) {
        CGRect frame = self.dateLabel.frame;
        frame.origin.y = CGRectGetMaxY(self.titleLabel.frame) + inset;
        self.dateLabel.frame = frame;
        palletFrame.origin.y = CGRectGetMaxY(self.dateLabel.frame) + inset;
    } else {
        palletFrame.origin.y = CGRectGetMaxY(titleLabelFrame) + inset;
    }
    palletFrame.size.height = palletHeight;
    self.attendeePallet.frame = palletFrame;
    
    self.detailBox.frame = CGRectMake(inset, inset, CGRectGetWidth(self.contentView.frame) - inset*2. , CGRectGetMaxY(palletFrame) + inset + buttonBoxHeight + activityCellSpacer);
    
    self.buttonBox.center =  CGPointMake(CGRectGetMidX(self.detailBox.frame), CGRectGetMaxY(self.detailBox.frame) - buttonBoxHeight/2.0);

//    if ([self.event.creator.accountID isEqualToString:[IntertwineManager getAccountID]]) {
//        self.buttonBox.buttons = @[self.completedButton, self.likeButton, self.commentButton];
//    } else {
    self.buttonBox.buttons = @[[NSNull null], self.likeButton, self.commentButton, [NSNull null]];
//    }

    
    CGRect contentFrame = self.contentView.frame;
    contentFrame.origin.y = 0;
    contentFrame.size.height = CGRectGetHeight(self.detailBox.frame);
    contentFrame.size.width = [[UIScreen mainScreen] bounds].size.width;
    self.contentView.frame = contentFrame;
}

+ (CGFloat) cellHeightForEvent:(EventObject*)event {
//    CGFloat titleHeight = [ActivityTableViewCell _heightForTitle:event.eventTitle];
//    CGFloat dateHeight = [ActivityTableViewCell _heightForDate:event.timestamp andSemester:event.semester];
//    CGFloat palletHeight = [ActivityTableViewCell _heightForPalletWithAttendeeCount:[event.attendees count]];
//    CGFloat buttonHeight = [ActivityTableViewCell _heightForButtons];
//    
//    return 100;
    
    return [ActivityTableViewCell _heightForTitle:event.eventTitle] +
            activityCellSpacer +
            [ActivityTableViewCell _heightForDate:event.timestamp andSemester:event.semester] +
            activityCellSpacer +
            [ActivityTableViewCell _heightForPalletWithAttendeeCount:[event.attendees count]] +
            activityCellSpacer +
            [ActivityTableViewCell _heightForButtons] +
            ActivityTableViewCellSpaceBetweenCells;
}

+ (CGFloat) cellHeightForEvent:(EventObject*)event andAttendeeCount:(NSUInteger)count{
    
    return [ActivityTableViewCell cellHeightForEvent:event];
    
    if (!event.eventTitle) {
        return activityCellHeight;
    }
    /* Reset the cell comment label width, because if we're using a recycled cell,
     * then the following 'sizeOfMultiLineLabel' will fail. */
    if (!measuringLabel) {
        measuringLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    }
    measuringLabel.frame = CGRectMake(inset, inset, TITLE_SPACE, titleHeight);
    measuringLabel.text = event.eventTitle;
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
    
    if (event.timestamp) {
        palletHeight += 35.0;
    }
    
    return size.height + inset + palletHeight + inset + buttonBoxHeight +(activityCellSpacer) + 45.0;
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

- (UIView*)labelBackground {
    if (!_labelBackground) {
        _labelBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TITLE_SPACE + (inset*2.), titleHeight)];
        _labelBackground.backgroundColor = LABEL_BACKGROUND_COLOR;
        _labelBackground.userInteractionEnabled = NO;
        _labelBackground.layer.borderColor = [[UIColor blackColor] CGColor];
        _labelBackground.layer.borderWidth = 0.5;
    }
    return _labelBackground;
}

- (UILabel*)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(inset, inset, TITLE_SPACE, titleHeight)];
        _titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:activityCellTitleFontSize];
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
        _attendeePallet = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.detailBox.frame), 0)];
        _attendeePallet.backgroundColor = [UIColor clearColor];
    }
    return _attendeePallet;
}


- (UIView*)detailBox {
    if (!_detailBox) {
        _detailBox = [[UIView alloc] initWithFrame:CGRectMake(inset, inset, CGRectGetWidth(self.contentView.frame) - inset*2.0, detailBoxHeight)];
        _detailBox.layer.borderColor = [[UIColor blackColor] CGColor];
        _detailBox.layer.borderWidth = 0.5;
//        _detailBox.layer.cornerRadius = 4.0;
//        _detailBox.layer.shadowColor = [[UIColor blackColor] CGColor];
//        _detailBox.layer.shadowOpacity = 1.0;
//        _detailBox.layer.shadowOffset = CGSizeMake(0, 5);
    }
    return _detailBox;
}

- (ButtonBarView*)buttonBox {
    if (!_buttonBox) {
        _buttonBox = [[ButtonBarView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.detailBox.frame), buttonBoxHeight) buttonArray:@[self.likeButton, self.commentButton]];
        _buttonBox.backgroundColor = [UIColor clearColor];
    }
    return _buttonBox;
}

- (IntertwineButton*)commentButton {
    if (!_commentButton) {
        
        _commentButton = [[IntertwineButton alloc] initWithDetail:@"0" andImage:[UIImage imageNamed:@"CommentIcon.png"]];
        [_commentButton addTarget:self action:@selector(_showComments) forControlEvents:UIControlEventTouchUpInside];
    }
    return _commentButton;
}

- (IntertwineButton*)likeButton {
    if (!_likeButton) {
        _likeButton = [[IntertwineButton alloc] initWithDetail:@"0" andImage:[UIImage imageNamed:@"LikeRed.png"]];
    }
    return _likeButton;
}


- (IntertwineButton*)completedButton {
    if (!_completedButton) {
        _completedButton = [[IntertwineButton alloc] initWithDetail:@"" andImage:[UIImage imageNamed:@"CompletedIcon.png"]];
        [_completedButton addTarget:self action:@selector(_markComplete) forControlEvents:UIControlEventTouchUpInside];
    }
    return _completedButton;
}

//- (UIImageView*)coverPhoto {
//    if (!_coverPhoto) {
//        _coverPhoto = [[UIImageView alloc] initWithFrame:<#(CGRect)#>];
//    }
//}

- (UILabel*)dateLabel {
    if (!_dateLabel) {
        _dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(inset, 0, TITLE_SPACE, 40.0)];
        _dateLabel.backgroundColor = [UIColor clearColor];
        _dateLabel.textColor = [UIColor whiteColor];
        _dateLabel.textAlignment = NSTextAlignmentCenter;
        _dateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:17];
        _dateLabel.numberOfLines = 0;
    }
    return _dateLabel;
}

+ (UILabel*)measuringLabel {
    if (!measuringLabel) {
        measuringLabel.frame = CGRectMake(inset, inset, TITLE_SPACE, titleHeight);
        measuringLabel.font = [UIFont fontWithName:@"Helvetica" size:activityCellTitleFontSize];
        measuringLabel.textAlignment = NSTextAlignmentCenter;
        measuringLabel.numberOfLines = 0;
        measuringLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }
    return measuringLabel;
}

@end
