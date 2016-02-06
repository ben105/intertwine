//
//  IntertwineManager+Events.h
//  Sign On
//
//  Created by Ben Rooke on 3/24/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IntertwineManager.h"

typedef enum {
    kEventDateSemesterMorning,
    kEventDateSemesterAfternoon,
    kEventDateSemesterEvening
} EventDateSemester;


@interface EventDate : NSObject
@property (nonatomic, copy) NSString* date;
@property (nonatomic, copy) NSString* time;
@property (nonatomic) EventDateSemester semester;
@end



@interface IntertwineManager (Events)

+ (void) addComment:(NSString*)comment forEvent:(NSString*)title eventNumber:(NSNumber*)eventNumber withResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock;
+ (void) getCommentsForEvent:(NSNumber*)eventNumber withReponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock;

+ (void) createEvent:(NSString*)title withFriends:(NSArray *)friends withEventDate:(EventDate*)eventDate withResponse:(void (^)(id, NSError *, NSURLResponse *))responseBlock;
+ (void) createEvent:(NSString*)title withFriends:(NSArray*)friends withResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock;
+ (void) deleteEvent:(NSNumber*)eventID withResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock;
+ (void) editEvent:(NSNumber*)eventID withTitle:(NSString*)title newTitle:(NSString*)newTitle invited:(NSArray*)invited uninvited:(NSArray*)uninvited withResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock;
+ (void) getEventsWithResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock;

+ (void) completeEvent:(NSNumber*)eventID withTitle:(NSString*)title withResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock;

@end