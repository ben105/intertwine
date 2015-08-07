//
//  Friend.h
//  Sign On
//
//  Created by Ben Rooke on 3/23/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Friend : NSObject

@property (nonatomic, copy) NSString *first;
@property (nonatomic, copy) NSString *last;
@property (nonatomic, copy) NSString *facebookID;
@property (nonatomic, copy) NSString *emailAddress;
@property (nonatomic, copy) NSString *accountID;

- (NSString*) fullName;

@end
