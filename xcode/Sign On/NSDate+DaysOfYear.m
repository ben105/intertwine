//
//  NSDate+DaysOfYear.m
//  DatePicker
//
//  Created by Ben Rooke on 2/10/16.
//  Copyright © 2016 NinjaQuant LLC. All rights reserved.
//

#import "NSDate+DaysOfYear.h"

@implementation NSDate (DaysOfYear)

+ (NSDate *)dateWithDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year {
    NSDateComponents *components = [NSDateComponents new];
    components.day = day;
    components.month = month;
    components.year = year;
    return [[NSCalendar currentCalendar] dateFromComponents:components];
}

+ (NSDate *)dateFromComponents:(NSDateComponents*)components {
    return [[NSCalendar currentCalendar] dateFromComponents:components];
}

+ (BOOL)isLeapYear:(NSInteger)year {
    return [NSDate daysInYear:year] == 366;
}

+ (NSInteger)daysInYear:(NSInteger)year {
    if (year % 400 == 0)        return 366;
    else if (year % 100 == 0)   return 365;
    else if (year % 4 == 0)     return 366;
    else                        return 365;
}

- (NSDate *)firstDayInYear:(NSInteger)year {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setDateFormat:@"MM/dd/yyyy"];
    return [fmt dateFromString:[NSString stringWithFormat:@"01/01/%ld", year]];
}


+ (NSDate *)dateWithDayInterval:(NSInteger)dayInterval sinceDate:(NSDate *)referenceDate {
    static NSInteger SECONDS_PER_DAY = 60 * 60 * 24;
    return [NSDate dateWithTimeInterval:dayInterval * SECONDS_PER_DAY sinceDate:referenceDate];
}

@end
