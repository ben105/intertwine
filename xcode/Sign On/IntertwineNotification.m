//
//  IntertwineNotification.m
//  Intertwine
//
//  Created by Ben Rooke on 10/21/15.
//  Copyright © 2015 Intertwine. All rights reserved.
//

#import "IntertwineNotification.h"

@implementation IntertwineNotification

- (instancetype) initWithID:(NSNumber*)notifID message:(NSString*)message payload:(NSDictionary*)payload sentTime:(NSString*)sentTime {
    self = [super init];
    if (self) {
        self.notificationID = notifID;
        self.message = message;
        self.payload = payload;
        self.sentTime = sentTime;
    }
    return self;
}

@end
