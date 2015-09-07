//
//  ActivityTableViewCell.m
//  ActivityCell
//
//  Created by Ben Rooke on 8/24/15.
//  Copyright (c) 2015 Ben Rooke. All rights reserved.
//

#import "ActivityTableViewCell.h"
#import <FacebookSDK/FacebookSDK.h>
#import "Friend.h"

const CGFloat inset = 10.0;
const CGFloat detailBoxHeight = 84.0;
const CGFloat buttonBoxHeight = 35.0;
const CGFloat activityCellHeight = inset*2.0 + detailBoxHeight + buttonBoxHeight;

const CGFloat attendeeBubbleWidth = 52.0;
const CGFloat partialBubbleWidth = 15.0;
const CGFloat activityCellSpacer = 10.0;
/* We want to figure out the distance from the right side of the screen
 * to the end of the title label. So let's show 3 attendees and 1 partial
 * attendee. And there should be a activityCellSpacer between each attendee, as well
 * as a activityCellSpacer between the first attendee and the title.
 
 [  title   ]-( )-( )-( )-(|
 
 So that gives us 4 activityCellSpacers, 3 full attendee bubble widths, and a partial one. */

const CGFloat attendeeSpace = (activityCellSpacer * 4.0) + (attendeeBubbleWidth * 3.0) + partialBubbleWidth;
#define TITLE_SPACE [[UIScreen mainScreen] bounds].size.width - attendeeSpace

const CGFloat titleHeight = 36.0;
const CGFloat activityCellTitleFontSize = 24.0;

const CGFloat gradientWidth = 30.0;

@interface ActivityTableViewCell ()
@property (nonatomic, strong) UIView *detailBox;
@property (nonatomic, strong) UIView *buttonBox;
@property (nonatomic, strong) NSMutableArray *attendeeViews;
- (void)_clearAttendeeViews;
- (void)_addAttendeeView:(Friend*)attendee;
- (CGFloat)_attendeeViewOffset:(NSUInteger)index;
@end


@implementation ActivityTableViewCell

@synthesize attendees = _attendees;

- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        CGRect contentFrame = self.contentView.frame;
        contentFrame.origin.y = 0;
        contentFrame.size.height = activityCellHeight;
        contentFrame.size.width = [[UIScreen mainScreen] bounds].size.width;
        self.contentView.frame = contentFrame;
        self.contentView.backgroundColor = [UIColor clearColor];
        
        [self.contentView addSubview:self.detailBox];
        [self.contentView addSubview:self.buttonBox];
        
        [self.detailBox addSubview:self.scrollView];
        [self.detailBox addSubview:self.titleLabel];
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
    NSUInteger number = [self.attendeeViews count] + 1;
    CGFloat x = [self _attendeeViewOffset:number];
    
    FBProfilePictureView *attendeeView = [[FBProfilePictureView alloc] initWithFrame:CGRectMake(x, activityCellSpacer, attendeeBubbleWidth, attendeeBubbleWidth)];
    attendeeView.layer.cornerRadius = attendeeBubbleWidth / 2.0;
    attendeeView.profileID = attendee.facebookID;
    
    [self.attendeeViews addObject:attendeeView];
    [self.scrollView addSubview:attendeeView];
}


#pragma mark - Lazy Loading

- (UIScrollView*)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.contentView.frame), CGRectGetHeight(self.contentView.frame))];
        _scrollView.contentSize = CGSizeMake(CGRectGetWidth(_scrollView.frame) * 2.0, CGRectGetHeight(_scrollView.frame));
        _scrollView.pagingEnabled = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
    }
    return _scrollView;
}

- (UILabel*)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, activityCellSpacer, TITLE_SPACE, titleHeight)];
        _titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:activityCellTitleFontSize];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
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
    CGFloat furthestView = [self _attendeeViewOffset:i] + attendeeBubbleWidth + activityCellSpacer;
    self.scrollView.contentSize = CGSizeMake(furthestView, self.scrollView.contentSize.height);
}

- (NSMutableArray*)attendeeViews {
    if (!_attendeeViews) {
        _attendeeViews = [[NSMutableArray alloc] init];
    }
    return _attendeeViews;
}

- (UIView*)buttonBox {
    if (!_buttonBox) {
        _buttonBox = [[UIView alloc] initWithFrame:CGRectMake(0, inset+detailBoxHeight, CGRectGetWidth(self.contentView.frame), buttonBoxHeight)];
        _buttonBox.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
    }
    return _buttonBox;
}

- (UIView*)detailBox {
    if (!_detailBox) {
        _detailBox = [[UIView alloc] initWithFrame:CGRectMake(0, inset, CGRectGetWidth(self.contentView.frame), detailBoxHeight)];
        _detailBox.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.3];
    }
    return _detailBox;
}

@end
