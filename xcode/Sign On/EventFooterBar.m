//
//  EventFooterBar.m
//  Intertwine
//
//  Created by Ben Rooke on 2/15/16.
//  Copyright © 2016 Intertwine. All rights reserved.
//

#import "EventFooterBar.h"


/* FooterButtonDistanceFromScreen is how far away we place
 * those buttons on the footer from the edge of the screen. */
const CGFloat FooterButtonDistanceFromScreen = 55.0;


@implementation EventFooterBar

- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.locationButtonView];
        [self addSubview:self.dateButtonView];
        self.backgroundColor = [UIColor colorWithRed:20.0/255.0 green:81.0/255.0 blue:121.0/255.0 alpha:1.0];
        self.clipsToBounds = NO;
    }
    return self;
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if ( CGRectContainsPoint(self.dateButtonView.frame, point) ) {
        return YES;
    }
    if ( CGRectContainsPoint(self.locationButtonView.frame, point) ) {
        return YES;
    }
    return [super pointInside:point withEvent:event];
}

#pragma mark - Lazy Loading Footer Buttons

- (UIView*)locationButtonView {
    if (!_locationButtonView) {
        UIImage *locationImage = [UIImage imageNamed:@"Location.png"];
        CGFloat width = locationImage.size.width;
        CGFloat height = locationImage.size.height;
        _locationButtonView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height + 20)];
        _locationButtonView.backgroundColor = [UIColor clearColor];
        /* Add the location button. */
        [_locationButtonView addSubview:self.locationButton];
        self.locationButton.frame = CGRectMake(0, 0, width, height);
        self.locationButton.center = CGPointMake(width/2.0, height/2.0);
        [self.locationButton setBackgroundImage:locationImage forState:UIControlStateNormal];
        /* Add the location title. */
        [_locationButtonView addSubview:self.locationButtonLabel];
        CGRect frame = self.locationButtonLabel.frame;
        frame.origin.y = height;
        frame.origin.x = 0;
        frame.size.width = width;
        self.locationButtonLabel.frame = frame;

        _locationButtonView.center = CGPointMake(FooterButtonDistanceFromScreen, 0);
    }
    return _locationButtonView;
}

- (UIView*)dateButtonView {
    if (!_dateButtonView) {
        UIImage *dateImage = [UIImage imageNamed:@"Date.png"];
        CGFloat width = dateImage.size.width;
        CGFloat height = dateImage.size.height;
        _dateButtonView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height + 20)];
        _dateButtonView.backgroundColor = [UIColor clearColor];
        
        /* Add the location button. */
        [_dateButtonView addSubview:self.dateButton];
        self.dateButton.frame = CGRectMake(0, 0, width, height);
        self.dateButton.center = CGPointMake(width/2.0, height/2.0);
        [self.dateButton setBackgroundImage:dateImage forState:UIControlStateNormal];
        /* Add the location title. */
        [_dateButtonView addSubview:self.dateButtonLabel];
        CGRect frame = self.dateButtonLabel.frame;
        frame.origin.y = height;
        frame.origin.x = 0;
        frame.size.width = width;
        self.dateButtonLabel.frame = frame;
        
        CGFloat centerX = CGRectGetWidth(self.frame) - FooterButtonDistanceFromScreen;
        _dateButtonView.center = CGPointMake(centerX, 0);
    }
    return _dateButtonView;
}

- (UIButton*)locationButton {
    if (!_locationButton) {
        _locationButton = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    return _locationButton;
}

- (UIButton*)dateButton {
    if (!_dateButton) {
        _dateButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        [_dateButton addTarget:self action:@selector(_showDateViewAnimated) forControlEvents:UIControlEventTouchUpInside];
    }
    return _dateButton;
}

- (UILabel*)locationButtonLabel {
    if (!_locationButtonLabel) {
        _locationButtonLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 15)];
        _locationButtonLabel.textColor = [UIColor whiteColor];
        _locationButtonLabel.backgroundColor = [UIColor clearColor];
        _locationButtonLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:8];
        _locationButtonLabel.textAlignment = NSTextAlignmentCenter;
        _locationButtonLabel.text = @"Location";
    }
    return _locationButtonLabel;
}

- (UILabel*)dateButtonLabel {
    if (!_dateButtonLabel) {
        _dateButtonLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 15)];
        _dateButtonLabel.textColor = [UIColor whiteColor];
        _dateButtonLabel.backgroundColor = [UIColor clearColor];
        _dateButtonLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:8];
        _dateButtonLabel.textAlignment = NSTextAlignmentCenter;
        _dateButtonLabel.text = @"Date";
    }
    return _dateButtonLabel;
}

@end
