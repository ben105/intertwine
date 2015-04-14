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
const NSString *commentsEndpoint = @"/api/v1/comment";

@implementation IntertwineManager (Events)

#pragma mark - Comment Create/Read

+ (void) addComment:(NSString*)comment forEvent:(NSNumber*)eventNumber withResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock {
    /* 
     * Create a NSDictionary of the body we want to POST
     */
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
    [body setObject:comment forKey:@"comment"];
    [body setObject:eventNumber forKey:@"event_id"];
    
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
    /*
     * Create a body to hold the event ID
     */
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
    [body setObject:eventNumber forKey:@"event_id"];
    
    /*
     * Turn the dictionary into serialized JSON
     */
    NSData *data = [IntertwineManager loadJSON:body];
    if (data == nil) {
        return;
    }
    
    /* Send the request */
    NSMutableURLRequest *request = [IntertwineManager getRequest:(NSString*)commentsEndpoint];
    [request setHTTPMethod:@"GET"];
    [request setHTTPBody:data];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [IntertwineManager sendRequest:request response:responseBlock];
}


# pragma mark - Event CRUD

+ (void) createEvent:(NSString*)title withFriends:(NSArray*)friends withResponse:(void (^)(id json, NSError *error, NSURLResponse *response))responseBlock {
    /*
     * Turn the 'friends' array into a JSON list of
     * dictionaries.
     * One dictionary with keys 'title' and 'friends', 
     * supplying both parameters as values.
     */
    NSMutableArray *jsonFriends = [[NSMutableArray alloc] init];
    for (Friend *friend in friends) {
        NSString *accountID = friend.accountID;
        [jsonFriends addObject:accountID];
    }
    /*
     * Parent Dictionary to wrap it all.
     */
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
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

@end
