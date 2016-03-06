//
//  SemesterPage.m
//  DatePicker
//
//  Created by Ben Rooke on 2/13/16.
//  Copyright © 2016 NinjaQuant LLC. All rights reserved.
//

#import "SemesterPage.h"
#import "SemesterView.h"

const CGFloat SemesterHeaderLabelHeight = 100.0;

@implementation SemesterPage

- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.semesterView];
        [self addSubview:self.monthHeaderLabel];
        [self addSubview:self.dayHeaderLabel];
    }
    return self;
}

#pragma mark - Lazy Loading

- (SemesterView*)semesterView {
    if (!_semesterView) {
        _semesterView = [[SemesterView alloc] initInsideView:self];
    }
    return _semesterView;
}

- (UILabel*)monthHeaderLabel {
    if (!_monthHeaderLabel) {
        CGFloat width = CGRectGetWidth(self.frame);
        _monthHeaderLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, SemesterHeaderLabelHeight)];
        _monthHeaderLabel.textColor = [UIColor whiteColor];
        _monthHeaderLabel.textAlignment = NSTextAlignmentCenter;
        _monthHeaderLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0];
    }
    return _monthHeaderLabel;
}

- (UILabel*)dayHeaderLabel {
    if (!_dayHeaderLabel) {
        CGFloat width = CGRectGetWidth(self.frame);
        _dayHeaderLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 28, width, SemesterHeaderLabelHeight)];
        _dayHeaderLabel.textColor = [UIColor whiteColor];
        _dayHeaderLabel.textAlignment = NSTextAlignmentCenter;
        _dayHeaderLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0];
    }
    return _dayHeaderLabel;
}

@end
