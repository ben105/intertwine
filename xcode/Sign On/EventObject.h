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


@end
