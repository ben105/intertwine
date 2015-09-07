//
//  ActivityTableViewCell.h
//  ActivityCell
//
//  Created by Ben Rooke on 8/24/15.
//  Copyright (c) 2015 Ben Rooke. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EventObject;

@interface ActivityTableViewCell : UITableViewCell

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) NSArray *attendees;

- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier;

@property (nonatomic, strong) EventObject *event;

@end

extern const CGFloat activityCellHeight;