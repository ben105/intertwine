//
//  ActivityTableViewCell.h
//  Intertwine
//
//  Created by Ben Rooke on 4/13/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ActivityTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *eventLabel;

@property (nonatomic, strong) UITableView *attendeesTableView;

@end
