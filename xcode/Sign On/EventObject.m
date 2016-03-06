//
//  EventObject.m
//  Intertwine
//
//  Created by Ben Rooke on 4/4/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "EventObject.h"

#define ONE_DAY (60*60*24)
#define TWO_DAYS (ONE_DAY * 2)
#define ONE_WEEK (ONE_DAY * 7)

const NSString *kStartDateEventKey = @"start_date";
const NSString *kStartTimeEventKey = @"start_time";
const NSString *kSemesterIdEventKey = @"semester_id";
const NSString *kAllDayEventKey = @"all_day";

char semesterNames[4][10] = {"morning", "afternoon", "evening"};
NSString* semesterNameForIndex(unsigned char index) {
    return [NSString stringWithCString:semesterNames[index] encoding:NSUTF8StringEncoding];
}


@interface EventObject ()
- (NSDate*)_getUnpreciseToday;
@end


@implementation EventObject

-(instancetype)init {
    self = [super init];
    if (self) {
        /* There are some date objects we need to set to nil. */
        self.startDate = nil;
        self.startTime = nil;
        self.isAllDay = NO;
        self.semester = nil;
    }
    return self;
}

- (void)setSemesterID:(NSUInteger)semesterID {
    _semesterID = semesterID;
    _semester = semesterNameForIndex(semesterID);
}

-(NSDate*)timestamp {
    if (!self.startDate) {
        return nil;
    }
    NSString *dateString = self.startDate;
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy'-'MM'-'dd HH':'mm':'ss"];
    [format setTimeZone:[NSTimeZone systemTimeZone]];
    if (self.startTime && self.startDate) {
        dateString = [NSString stringWithFormat:@"%@ %@", self.startDate, self.startTime];
    } else {
        dateString = [NSString stringWithFormat:@"%@ 00:00:00", self.startDate];
    }
    _timestamp = [format dateFromString:dateString];
    return _timestamp;
}

- (void) extractDateInfo:(NSDictionary*)dateInfo {
    /* The order in which we care about the date info is like this:
       1) We want to know if there is at least a start date.
       2) Check if it is set for all day. If it is - we're done.
       3) If it's not set for all day, check if there is a semester of the day.
       4) Finally, check for the start time. If there is no start time, and we
          already know that it's not for all day, don't do anything.
     */
    
    // We don't assign the start date right away to the self instance because we might have an
    // ill formed dateInfo object.
    NSString *startDate = [dateInfo objectForKey:kStartDateEventKey];
    if ((NSNull*)startDate == [NSNull null] || !startDate) {
        /* There's nothing to do here, because 
         * we need at least a start date. */
        return;
    }
    self.startDate = startDate;
    
    id allDayObject = [dateInfo objectForKey:kAllDayEventKey];
    if ((NSNull*)allDayObject != [NSNull null]) {
        BOOL isAllDay = [(NSNumber*)allDayObject boolValue];
        self.isAllDay = isAllDay;
        if (isAllDay) {
            /* We can end here, because we know it's all day. */
            return;
        }
    }
    id semesterObject = [dateInfo objectForKey:kSemesterIdEventKey];
    if ((NSNull*)semesterObject != [NSNull null]) {
        NSUInteger semesterID = [(NSNumber*)semesterObject unsignedIntegerValue];
        self.semesterID = semesterID;
        /* If we have a semester ID > 0 then we can stop here and assign
         * the date and semester ID. */
        self.semester = semesterNameForIndex(semesterID);
        return;
    }
    NSString *startTime = [dateInfo objectForKey:kStartTimeEventKey];
    if ((NSNull*)startTime != [NSNull null]) {
        NSRange range = [startTime rangeOfString:@"+"];
        if (range.location != NSNotFound) {
            startTime = [startTime substringToIndex:range.location];
        }
        self.startTime = startTime;
    }
}

#pragma mark - Convenience Methods for Ordering Events by Date

- (NSDate*)_getUnpreciseToday {
    NSDate *now = [NSDate date];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                                  fromDate:now];
    return [[NSCalendar currentCalendar] dateFromComponents:components];
}

- (BOOL) hasDate {
    return self.startDate != nil;
}

- (BOOL) isInPast {
    NSComparisonResult result = [self.timestamp compare:[self _getUnpreciseToday]];
    return result == NSOrderedAscending;
}

- (BOOL) isToday {
    if ([self isInPast]) {
        return NO;
    }
    NSDate *tomorrow = [NSDate dateWithTimeInterval:ONE_DAY sinceDate:[self _getUnpreciseToday]];
    NSComparisonResult result = [self.timestamp compare:tomorrow];
    return result == NSOrderedAscending;
}

- (BOOL) isTomorrow {
    if ([self isInPast]) {
        return NO;
    }
    NSDate *twoDays = [NSDate dateWithTimeInterval:TWO_DAYS sinceDate:[self _getUnpreciseToday]];
    NSComparisonResult result = [self.timestamp compare:twoDays];
    return ![self isToday] && (result == NSOrderedAscending);
}

- (BOOL) isThisWeek {
    if ([self isInPast]) {
        return NO;
    }
    NSDate *thisWeek = [NSDate dateWithTimeInterval:ONE_WEEK sinceDate:[self _getUnpreciseToday]];
    NSComparisonResult result = [self.timestamp compare:thisWeek];
    return result == NSOrderedAscending;
}

- (BOOL) isThisMonth {
    if (self.timestamp == nil) {
        return NO;
    }
    if ([self isInPast]) {
        return NO;
    }
    NSDate *today = [self _getUnpreciseToday];
    NSDateComponents *todaysComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitMonth | NSCalendarUnitYear
                                                                         fromDate:today];
    NSDateComponents *eventDateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitMonth | NSCalendarUnitYear
                                                                            fromDate:self.timestamp];
    return (todaysComponents.year == eventDateComponents.year) && (todaysComponents.month == eventDateComponents.month);
}


@end
