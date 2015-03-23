//
//  PendingRequestTableViewCell.h
//  Sign On
//
//  Created by Ben Rooke on 1/31/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FriendsViewController.h"

@interface PendingRequestTableViewCell : UITableViewCell

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *accountID;

@property (nonatomic, weak) id<FriendsDelegate> delegate;

- (void) accept;
- (void) decline;

- (id) initWithReuseIdentifier:reuseIdentifier;

@end
