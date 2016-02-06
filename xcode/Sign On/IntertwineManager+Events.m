//
//  IntertwineManager+Events.m
//  Sign On
//
//  Created by Ben Rooke on 3/24/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "IntertwineManager+Events.h"
#import "Friend.h"

const NSString *eventsEndpoint = @"/api/v1/events";
const NSString *eventEditEndpoint = @"/api/v1/edit_event";
const NSString *commentsEndpoint = @"/api/v1/comment";
const NSString *eventCompleteEndpoint = @"/api/v1/event_complete";


@implementation EventDate
@end

@implementation IntertwineManager (Events)

#pragma mark - Comment Create/Read

+ (void) addComment:(NSString*)comment forEvent:(NSString*)title eventNumber:(NSNumber*)eventNumber withResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock {
    /* 
     * Create a NSDictionary of the body we want to POST
     */
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
    [body setObject:comment forKey:@"comment"];
    [body setObject:eventNumber forKey:@"event_id"];
    [body setObject:title forKey:@"title"];
    
    NSData *data = [IntertwineManager loadJSON:body];
    if (data == nil)
        return;
    
    /*
     * Create the HTTP POST request with the data we have as the body.
     */
    NSMutableURLRequest *request = [IntertwineManager getRequest:(NSString*)commentsEndpoint];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:data];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [IntertwineManager sendRequest:request response:responseBlock];
}

+ (void) getCommentsForEvent:(NSNumber*)eventNumber withReponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock {
   
    /* Formulate the HTTP REST URI */
    unsigned long int eventID = [eventNumber unsignedIntegerValue];
    NSString *uri = [NSString stringWithFormat:@"%@/%lu", commentsEndpoint, eventID];
    
    /* Send the request */
    NSMutableURLRequest *request = [IntertwineManager getRequest:uri];
    [request setHTTPMethod:@"GET"];
    [IntertwineManager sendRequest:request response:responseBlock];
}


# pragma mark - Event CRUD

+ (void) createEvent:(NSString*)title withFriends:(NSArray *)friends withEventDate:(EventDate*)eventDate withResponse:(void (^)(id, NSError *, NSURLResponse *))responseBlock {
    /*
     * Turn the 'friends' array into a JSON list of
     * dictionaries.
     * One dictionary with keys 'title' and 'friends',
     * supplying both parameters as values.
     */
    NSMutableArray *jsonFriends = [NSMutableArray new];
    for (Friend *friend in friends) {
        NSString *accountID = friend.accountID;
        [jsonFriends addObject:accountID];
    }
    /*
     * Parent Dictionary to wrap it all.
     */
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *date = nil;
    
    NSString *timezone = [[NSTimeZone systemTimeZone] name];
    
    if (eventDate) {
        date = [NSMutableDictionary new];
        [date setObject:timezone forKey:@"timezone"];
        if (eventDate.date) {
            [date setObject:eventDate.date forKey:@"date"];
        }
        if (eventDate.time) {
            [date setObject:eventDate.time forKey:@"time"];
        }
        if (eventDate.semester) {
            [date setObject:[NSNumber numberWithInt:eventDate.semester] forKey:@"semester"];
        }
    }
    [body setObject:date forKey:@"date"];
    [body setObject:title forKey:@"title"];
    [body setObject:jsonFriends forKey:@"friends"];
    
    NSData *data = [IntertwineManager loadJSON:body];
    if (data == nil)
        return;
    
    /*
     * Now that we have our JSON body,
     * lets create our URL request.
     */
    NSMutableURLRequest *request = [IntertwineManager getRequest:(NSString*)eventsEndpoint];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:data];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [IntertwineManager sendRequest:request response:responseBlock];
}

+ (void) createEvent:(NSString*)title withFriends:(NSArray*)friends withResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock {
    [IntertwineManager createEvent:title withFriends:friends withEventDate:nil withResponse:responseBlock];
}

+ (void) deleteEvent:(NSNumber*)eventID withResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock {
    /*
     * A simple dictionary with one key-value pair,
     * event_id: event ID
     */
    unsigned long int event_id = [eventID unsignedIntegerValue];
    NSMutableDictionary *body = [[NSMutableDictionary alloc] initWithObjects:@[[NSString stringWithFormat:@"%lu",(unsigned long)event_id]] forKeys:@[@"event_id"]];
    
    /*
     * Convert the NSMutableDictionary into JSON data.
     */
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];
    if (error) {
        NSLog(@"Error occured trying to serialize to JSON data, when creating an event.");
        return;
    }
    
    NSMutableURLRequest *request = [IntertwineManager getRequest:(NSString*)eventsEndpoint];
    [request setHTTPMethod:@"DELETE"];
    [request setHTTPBody:data];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [IntertwineManager sendRequest:request response:responseBlock];
}

+ (void) getEventsWithResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock {
    NSMutableURLRequest *request = [IntertwineManager getRequest:(NSString*)eventsEndpoint];
    [request setHTTPMethod:@"GET"];
    [IntertwineManager sendRequest:request response:responseBlock];
}


+ (void) editEvent:(NSNumber*)eventID withTitle:(NSString*)title newTitle:(NSString*)newTitle invited:(NSArray*)invited uninvited:(NSArray*)uninvited withResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock {
    /*
     * We need a dictionary that contains at LEAST the event ID, but optionally also
     * the following items:
     * - title
     * - date
     * - invited
     * - uninvited
     * - location
     */
    unsigned long int event_id = [eventID unsignedIntegerValue];
    NSString *eventIDString = [NSString stringWithFormat:@"%lu", event_id];
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
    [body setObject:eventIDString forKey:@"event_id"];
    [body setObject:title forKey:@"title"];
    if (newTitle) {
        [body setObject:newTitle forKey:@"new_title"];
    }
    if ([invited count]) {
        [body setObject:invited forKey:@"invited"];
    }
    if ([uninvited count]) {
        [body setObject:uninvited forKey:@"uninvited"];
    }
    
    
    /*
     * Convert the NSMutableDictionary into JSON data.
     */
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];
    if (error) {
        NSLog(@"Error occured trying to serialize to JSON data, when completing an event.");
        return;
    }
    
    NSMutableURLRequest *request = [IntertwineManager getRequest:(NSString*)eventEditEndpoint];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:data];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [IntertwineManager sendRequest:request response:responseBlock];
}



+(void)completeEvent:(NSNumber *)eventID withTitle:(NSString*)title withResponse:(void (^)(id, NSError *, NSURLResponse *))responseBlock {
    /*
     * A simple dictionary with one key-value pair,
     * event_id: event ID
     */
    unsigned long int event_id = [eventID unsignedIntegerValue];
    NSMutableDictionary *body = [[NSMutableDictionary alloc] initWithObjects:@[[NSString stringWithFormat:@"%lu",(unsigned long)event_id], title] forKeys:@[@"event_id", @"title"]];
    
    /*
     * Convert the NSMutableDictionary into JSON data.
     */
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];
    if (error) {
        NSLog(@"Error occured trying to serialize to JSON data, when completing an event.");
        return;
    }
    
    NSMutableURLRequest *request = [IntertwineManager getRequest:(NSString*)eventCompleteEndpoint];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:data];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [IntertwineManager sendRequest:request response:responseBlock];
}

@end
