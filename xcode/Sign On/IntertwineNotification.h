//
//  IntertwineNotification.h
//  Intertwine
//
//  Created by Ben Rooke on 10/21/15.
//  Copyright © 2015 Intertwine. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IntertwineNotification : NSObject

@property (nonatomic, copy) NSNumber *notificationID;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSDictionary *payload;
@property (nonatomic, copy) NSString *sentTime;

- (instancetype) initWithID:(NSNumber*)notifID message:(NSString*)message payload:(NSDictionary*)payload sentTime:(NSString*)sentTime;

@end
