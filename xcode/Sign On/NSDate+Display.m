//
//  NSDate+Display.m
//  Intertwine
//
//  Created by Ben Rooke on 2/28/16.
//  Copyright © 2016 Intertwine. All rights reserved.
//

#import "NSDate+Display.h"
#import "EventObject.h"

char NSDateDisplayMonthNames[12][12] = { "January", "Febuary", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};

@implementation NSDate (Display)


+(NSString*)intertwineDateStringForEvent:(EventObject*)event {
    
    NSDate *date = event.timestamp;
    if (date == nil) {
        return nil;
    }
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:date];
    
    /* str will be the string we return. */
    NSString *str = @"";
    if ([event isToday]) {
        str = @"Today";
    } else if ([event isTomorrow]) {
        str = @"Tomorrow";
    } else {
        NSString *month = [NSString stringWithCString:NSDateDisplayMonthNames[components.month - 1] encoding:NSUTF8StringEncoding];
        str = [NSString stringWithFormat:@"%@ %ld", month, components.day];
    }
    if (components.hour != 0) {
        str = [str stringByAppendingString:[NSString stringWithFormat:@" %ld:%ld", components.hour, components.minute]];
    }
    if (event.semester) {
        str = [str stringByAppendingString:[NSString stringWithFormat:@"\nin the %@", event.semester]];
    }
    return str;
}

@end
