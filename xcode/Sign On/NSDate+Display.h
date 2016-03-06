//
//  NSDate+Display.h
//  Intertwine
//
//  Created by Ben Rooke on 2/28/16.
//  Copyright © 2016 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EventObject;

@interface NSDate (Display)
+(NSString*)intertwineDateStringForEvent:(EventObject*)event;
@end
