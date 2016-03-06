//
//  EventObject.h
//  Intertwine
//
//  Created by Ben Rooke on 4/4/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Friend.h"

@interface EventObject : NSObject

@property (nonatomic, strong) NSNumber *eventID;
@property (nonatomic, strong) NSString *eventTitle;
@property (nonatomic, strong) NSString *eventDescription;
@property (nonatomic, strong) NSDate *updatedTime;
@property (nonatomic, strong) Friend *creator;
@property (nonatomic, strong) NSArray *attendees;

/* For dates. */
@property (nonatomic, copy) NSString *startDate;
@property (nonatomic, copy) NSString *startTime;
@property (nonatomic, copy) NSString *semester;
@property (nonatomic) NSUInteger semesterID;
@property (nonatomic) BOOL isAllDay;
@property (nonatomic, strong) NSDate *timestamp;

/* Completeness */
@property BOOL isComplete;

@property NSUInteger numberOfComments;
@property NSUInteger numberOfLikes;

- (void) extractDateInfo:(NSDictionary*)dateInfo;

- (BOOL) hasDate;
- (BOOL) isToday;
- (BOOL) isTomorrow;
- (BOOL) isThisWeek;
- (BOOL) isThisMonth;

@end
