//
//  IntertwineCalendarDayCell.m
//  DatePicker
//
//  Created by Ben Rooke on 2/13/16.
//  Copyright © 2016 NinjaQuant LLC. All rights reserved.
//

#import "IntertwineCalendarDayCell.h"

const CGFloat dayLabelWidth = 60.0;
const CGFloat dayLabelX = 5.0;
const CGFloat IntertwineCalendarDaySpacing = 25.0;
const CGFloat IntertwineCalendarDayCellHeight = 90.0;

char weekdays[7][10] = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" };

@interface IntertwineCalendarDayCell ()
/* The day label is the numeric day value (i.e. "2") */
@property (nonatomic, strong) UILabel *dayLabel;
/* The day of the week label is the name of the day
 * (i.e. Tuesday ) */
@property (nonatomic, strong) UILabel *dayOfWeekLabel;
@end

@implementation IntertwineCalendarDayCell

- (instancetype)initWithWidth:(CGFloat)width reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithWidth:width reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.dayLabel];
        [self.contentView addSubview:self.dayOfWeekLabel];
        self.contentView.backgroundColor = [UIColor colorWithRed:104.0/255.0 green:104.0/255.0 blue:104.0/255.0 alpha:0.52];
        [self refreshViewToCellHeight:IntertwineCalendarDayCellHeight];
    }
    return self;
}

+(CGFloat)cellHeight {
    return IntertwineCalendarDayCellHeight;
}

#pragma mark - Month and Day Setters

- (NSString*)stringFromDate {
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy'-'MM'-'dd"];
    return [format stringFromDate:_date];
}

- (void)setDate:(NSDate *)date {
    _date = date;
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitWeekday fromDate:date];
    char *weekday = weekdays[components.weekday - 1];
    self.dayOfWeekLabel.text = [NSString stringWithFormat:@"%@", [NSString stringWithCString:weekday encoding:NSUTF8StringEncoding]];
    self.dayLabel.text = [NSString stringWithFormat:@"%ld", components.day];
}



- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Day Getters

- (NSString*) getDay {
    return self.dayLabel.text;
}

- (NSString*) getDayOfWeek {
    return self.dayOfWeekLabel.text;
}

#pragma mark - Lazy Loading

- (UILabel*)dayLabel {
    if (!_dayLabel) {
        _dayLabel = [[UILabel alloc] initWithFrame:CGRectMake(dayLabelX, 0, dayLabelWidth, IntertwineCalendarDayCellHeight)];
        _dayLabel.textAlignment = NSTextAlignmentRight;
        _dayLabel.textColor = [UIColor whiteColor];
        _dayLabel.backgroundColor = [UIColor clearColor];
        _dayLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:30];
        _dayLabel.userInteractionEnabled = NO;
    }
    return _dayLabel;
}

- (UILabel*)dayOfWeekLabel {
    if (!_dayOfWeekLabel) {
        CGFloat x = CGRectGetMaxX(self.dayLabel.frame) + IntertwineCalendarDaySpacing;
        CGFloat width = CGRectGetWidth(self.contentView.frame) - x;
        _dayOfWeekLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, width, IntertwineCalendarDayCellHeight)];
        _dayOfWeekLabel.textAlignment = NSTextAlignmentLeft;
        _dayOfWeekLabel.textColor = [UIColor whiteColor];
        _dayOfWeekLabel.backgroundColor = [UIColor clearColor];
        _dayOfWeekLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:40];
        _dayOfWeekLabel.userInteractionEnabled = NO;
        
        /* Finally, before we finish, let's vertically center this label with
         * the other one. */
        CGPoint center = _dayOfWeekLabel.center;
        center.y = CGRectGetMidY(self.dayLabel.frame);
        _dayOfWeekLabel.center = center;
    }
    return _dayOfWeekLabel;
}

@end
