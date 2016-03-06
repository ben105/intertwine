//
//  HeaderPagingView.m
//  Sliding
//
//  Created by Ben Rooke on 2/25/16.
//  Copyright © 2016 NinjaQuant LLC. All rights reserved.
//

#import "HeaderPagingView.h"

const CGFloat HeaderPagingViewWidth = 190.0;
const CGFloat HeaderPagingViewHeight = 30.0;
const CGFloat HeaderPagingViewCornerRadius = HeaderPagingViewHeight / 2.0;

#define HEADER_VIEW_BACKGROUND_COLOR [UIColor colorWithRed:0 green:0 blue:0 alpha:0.35]
#define HEADER_VIEW_SELECTION_COLOR [UIColor colorWithRed:199.0/255.0 green:51.0/255.0 blue:56.0/255.0 alpha:1.0]

@interface HeaderPagingView ()
@property (nonatomic, strong) UIView *segmentSelectorView;
@property (nonatomic, strong) NSMutableArray *segmentButtons;
@end

@implementation HeaderPagingView

- (instancetype) initWithSegmentSize:(NSUInteger)segments {
    /* Determine the width */
    // TODO: Dynamically determine width. For now I will set it to a default width.
    self = [super initWithFrame:CGRectMake(0, 0, HeaderPagingViewWidth, HeaderPagingViewHeight)];
    if (self) {
        self.numberOfSegments = segments;
        self.backgroundColor = HEADER_VIEW_BACKGROUND_COLOR;
        self.layer.cornerRadius = HeaderPagingViewCornerRadius;
        self.layer.borderWidth = 0.5;
        self.layer.borderColor = [[UIColor colorWithWhite:1 alpha:0.8] CGColor];
        [self addSubview:self.segmentSelectorView];
    }
    return self;
}

- (void)setTitle:(NSString*)title forSegment:(NSUInteger)segment {
    UIButton *button = [self.segmentButtons objectAtIndex:segment];
    [button setTitle:title forState:UIControlStateNormal];
    [self addSubview:button];
}

#pragma mark - Move the Segment

- (void)moveToSegment:(NSUInteger)segment {
    CGFloat width = HeaderPagingViewWidth / self.numberOfSegments;
    CGFloat x = width/2.0 + width*segment;
    if (self.segmentSelectorView.center.x == x) {
        return;
    }
    [UIView animateWithDuration:0.3 animations:^{
        CGPoint center = self.segmentSelectorView.center;
        center.x = x;
        self.segmentSelectorView.center = center;
    }];
}

- (void)_buttonTouchedMoveToSegment:(id)sender {
    NSUInteger buttonIndex = [self.segmentButtons indexOfObject:sender];
    [self moveToSegment:buttonIndex];
    if ([self.delegate respondsToSelector:@selector(segmentTouchedAtIndex:)]) {
        [self.delegate segmentTouchedAtIndex:buttonIndex];
    }
}

#pragma mark - Lazy Loading

- (UIView*)segmentSelectorView {
    if (!_segmentSelectorView) {
        CGFloat width = HeaderPagingViewWidth / self.numberOfSegments;
        _segmentSelectorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, HeaderPagingViewHeight)];
        _segmentSelectorView.backgroundColor = HEADER_VIEW_SELECTION_COLOR;
        _segmentSelectorView.layer.cornerRadius = HeaderPagingViewCornerRadius;
        _segmentSelectorView.layer.borderWidth = 0.5;
        _segmentSelectorView.layer.borderColor = [[UIColor whiteColor] CGColor];
        _segmentSelectorView.center = CGPointMake(width/2.0, CGRectGetMidY(self.frame));
    }
    return _segmentSelectorView;
}

- (NSMutableArray*)segmentButtons {
    if (!_segmentButtons) {
        CGFloat width = HeaderPagingViewWidth / self.numberOfSegments;
        _segmentButtons = [[NSMutableArray alloc] initWithCapacity:self.numberOfSegments];
        for (int i=0; i<self.numberOfSegments; i++) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.frame = CGRectMake(0, 0, width, HeaderPagingViewHeight);
            button.center = CGPointMake(width/2.0 + width*i, HeaderPagingViewHeight/2.0);
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(_buttonTouchedMoveToSegment:) forControlEvents:UIControlEventTouchUpInside];
            button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
            [_segmentButtons addObject:button];
        }
    }
    return _segmentButtons;
}

@end
