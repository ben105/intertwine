//
//  NSDate+DaysOfYear.h
//  DatePicker
//
//  Created by Ben Rooke on 2/10/16.
//  Copyright © 2016 NinjaQuant LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSDate (DaysOfYear)
+ (NSDate *)dateWithDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year;
+ (NSDate *)dateFromComponents:(NSDateComponents*)components;
+ (BOOL)isLeapYear:(NSInteger)year;
+ (NSInteger)daysInYear:(NSInteger)year;
- (NSDate *)firstDayInYear:(NSInteger)year;
+ (NSDate *)dateWithDayInterval:(NSInteger)dayInterval sinceDate:(NSDate *)referenceDate;
@end