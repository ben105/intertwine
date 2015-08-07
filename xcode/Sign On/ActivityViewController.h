//
//  ActivityViewController.h
//  Intertwine
//
//  Created by Ben Rooke on 4/7/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EventTableViewCell.h"

@interface ActivityViewController : UIViewController <EventTableViewCellDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *activityTableView;
@property (nonatomic, strong) NSMutableArray *events;



@end
