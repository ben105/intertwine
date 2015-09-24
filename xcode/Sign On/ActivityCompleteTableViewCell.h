//
//  ActivityCompleteTableViewCell.h
//  Intertwine
//
//  Created by Ben Rooke on 9/20/15.
//  Copyright © 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ActivityCompleteTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *attendeesLabel;

- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier;

@end

extern const CGFloat activityCompleteCellHeight;