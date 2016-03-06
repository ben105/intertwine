//
//  SemesterView.m
//  DatePicker
//
//  Created by Ben Rooke on 1/19/16.
//  Copyright © 2016 NinjaQuant LLC. All rights reserved.
//

#import "SemesterView.h"

@interface SemesterView()

/* Outter width will be the value of the width of the parent view. */
@property (nonatomic, strong) UIView *parentView;

@property (nonatomic, strong) UIScrollView *morningScrollView;
@property (nonatomic, strong) UIScrollView *afternoonScrollView;
@property (nonatomic, strong) UIScrollView *eveningScrollView;
@property (nonatomic, strong) UILabel *morningLabel;
@property (nonatomic, strong) UILabel *afternoonLabel;
@property (nonatomic, strong) UILabel *eveningLabel;

- (CGFloat)_yForSemesterIndex:(NSUInteger)index;
- (UIScrollView*)_scrollViewForIndex:(NSUInteger)index;
- (UILabel*)_label;

@end



const CGFloat SemesterViewInset = 20.0;
const CGFloat SemesterViewHeight = 324.0;
const CGFloat SemesterScrollViewHeight = SemesterViewHeight / 3.0;

#define SEMESTER_PARENT_VIEW_X (-CGRectGetMinX(self.frame))
#define SEMESTER_PARENT_VIEW_WIDTH CGRectGetWidth(self.parentView.frame)


@implementation SemesterView

- (CGFloat)_yForSemesterIndex:(NSUInteger)index {
    NSAssert(index < 3, @"Cannot have a semster index greater than 2");
    return SemesterScrollViewHeight * index;
}

- (UIScrollView*)_scrollViewForIndex:(NSUInteger)index {
    CGFloat y = [self _yForSemesterIndex:index];
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(SEMESTER_PARENT_VIEW_X, y, SEMESTER_PARENT_VIEW_WIDTH, SemesterScrollViewHeight)];
    scrollView.contentSize = CGSizeMake(SEMESTER_PARENT_VIEW_WIDTH * 2.0, SemesterScrollViewHeight);
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.delegate = self;
    scrollView.backgroundColor = [UIColor clearColor];
    return scrollView;
}

- (UILabel*) _label {
    /**
     * We need to put an inset on these labels because they are being placed on the scroll view
     * which is positioned negative inset from 0.   */
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(SemesterViewInset, 0, CGRectGetWidth(self.frame), SemesterScrollViewHeight)];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:25];
    label.backgroundColor = [UIColor colorWithRed:104.0/255.0 green:104.0/255.0 blue:104.0/255.0 alpha:0.52];
//    label.layer.borderColor = [[UIColor grayColor] CGColor];
//    label.layer.borderWidth = 4.0;
    return label;
}

- (instancetype)initInsideView:(UIView*)view {
    CGFloat width = CGRectGetWidth(view.frame) - SemesterViewInset * 2.0;
    self = [super initWithFrame:CGRectMake(0, 0, width, SemesterViewHeight)];
    if (self) {
        self.parentView = view;
        CGFloat centerX = CGRectGetWidth(self.parentView.frame) / 2.0;
        CGFloat centerY = CGRectGetHeight(self.parentView.frame) / 2.0;
        self.center = CGPointMake(centerX, centerY);
        
        self.layer.cornerRadius = 8.0;
        self.backgroundColor = [UIColor clearColor];

        
//        /* We want the illusion of the selection being slid off the side. */
        self.clipsToBounds = YES;
        
        [self addSubview:self.morningScrollView];
        [self addSubview:self.afternoonScrollView];
        [self addSubview:self.eveningScrollView];
        
        [self.morningScrollView addSubview:self.morningLabel];
        [self.afternoonScrollView addSubview:self.afternoonLabel];
        [self.eveningScrollView addSubview:self.eveningLabel];
    }
    return self;
}


#pragma mark - Scroll View Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSString *semesterName = nil;
    if (scrollView == self.morningScrollView) {
        semesterName = @"Morning";
    } else if (scrollView == self.afternoonScrollView) {
        semesterName = @"Afternoon";
    } else if (scrollView == self.eveningScrollView) {
        semesterName = @"Evening";
    }
    if (semesterName != nil && [self.delegate respondsToSelector:@selector(semesterName:scrollProgress:)]) {
        static CGFloat startingPoint = 80;
        CGPoint point = scrollView.contentOffset;
        if (point.x > startingPoint) {
            CGFloat width = CGRectGetWidth(self.parentView.frame) - SemesterViewInset * 2.0;
            [self.delegate semesterName:semesterName scrollProgress:(point.x - startingPoint) / (width - startingPoint)];
        }
    }
}


#pragma mark - Lazy Loading

- (UIScrollView*)morningScrollView {
    if (!_morningScrollView) {
        _morningScrollView = [self _scrollViewForIndex:0];
    }
    return _morningScrollView;
}

- (UIScrollView*)afternoonScrollView {
    if (!_afternoonScrollView) {
        _afternoonScrollView = [self _scrollViewForIndex:1];
    }
    return _afternoonScrollView;
}

- (UIScrollView*)eveningScrollView {
    if (!_eveningScrollView) {
        _eveningScrollView = [self _scrollViewForIndex:2];
    }
    return _eveningScrollView;
}

- (UILabel*)morningLabel {
    if (!_morningLabel) {
        _morningLabel = [self _label];
        _morningLabel.text = @"Morning";
    }
    return _morningLabel;
}

- (UILabel*)afternoonLabel {
    if (!_afternoonLabel) {
        _afternoonLabel = [self _label];
        _afternoonLabel.text = @"Afternoon";
    }
    return _afternoonLabel;
}

- (UILabel*)eveningLabel {
    if (!_eveningLabel) {
        _eveningLabel = [self _label];
        _eveningLabel.text = @"Evening";
    }
    return _eveningLabel;
}

@end
