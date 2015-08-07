//
//  CommentObject.h
//  Intertwine
//
//  Created by Ben Rooke on 4/13/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Friend;

@interface CommentObject : NSObject

@property (nonatomic, copy) NSString *comment;
@property (nonatomic, strong) NSNumber *eventID;
@property (nonatomic, strong) Friend *commentator;

@end
