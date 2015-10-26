//
//  ActivityAlertView.h
//  Intertwine
//
//  Created by Ben Rooke on 10/7/15.
//  Copyright © 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EventObject;
@class ActivityTableViewCell;

@interface ActivityAlertView : UIAlertView

@property (nonatomic, strong) EventObject *event;
@property (nonatomic, strong) ActivityTableViewCell *contextCell;

@end
