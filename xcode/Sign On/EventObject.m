//
//  EventObject.m
//  Intertwine
//
//  Created by Ben Rooke on 4/4/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "EventObject.h"

@interface EventObject ()
@property (nonatomic, copy) NSString *startDate;
@property (nonatomic, copy) NSString *startTime;
@end


const NSString *kStartDateEventKey = @"start_date";
const NSString *kStartTimeEventKey = @"start_time";
const NSString *kSemesterIdEventKey = @"semester_id";
const NSString *kAllDayEventKey = @"all_day";

char semesterNames[3][10] = {"Morning", "Afternoon", "Evening"};
NSString* semesterNameForIndex(unsigned char index) {
    return [NSString stringWithCString:semesterNames[index] encoding:NSUTF8StringEncoding];
}

@implementation EventObject

-(NSDate*)timestamp {
    if (!self.startDate) {
        return nil;
    }
    NSString *dateString = self.startDate;
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy'-'MM'-'dd"];
    if (self.startTime && self.startDate) {
        dateString = [NSString stringWithFormat:@"%@ %@", self.startDate, self.startTime];
        [format setDateFormat:@"yyyy'-'MM'-'dd HH':'mm':'ss"];
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
    if (!startDate) {
        /* There's nothing to do here, because 
         * we need at least a start date. */
        return;
    }
    id allDayObject = [dateInfo objectForKey:kAllDayEventKey];
    if ((NSNull*)allDayObject != [NSNull null]) {
        BOOL isAllDay = [(NSNumber*)allDayObject boolValue];
        /* We can end here, because we know it's all day. */
        self.isAllDay = isAllDay;
        self.startDate = startDate;
        return;
    }
    id semesterObject = [dateInfo objectForKey:kSemesterIdEventKey];
    if ((NSNull*)semesterObject != [NSNull null]) {
        NSUInteger semesterID = [(NSNumber*)semesterObject unsignedIntegerValue];
        /* If we have a semester ID > 0 then we can stop here and assign
         * the date and semester ID. */
        self.semester = semesterNameForIndex(semesterID - 1);   // Subtract 1 because of 0 indexing.
        self.startDate = startDate;
        return;
    }
    NSString *startTime = [dateInfo objectForKey:kStartTimeEventKey];
    if (startTime) {
        self.startTime = startTime;
        self.startDate = startDate;
    }
}

@end
