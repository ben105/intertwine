//
//  PendingRequestTableViewCell.h
//  Sign On
//
//  Created by Ben Rooke on 1/31/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FriendsViewController.h"
#import "FriendsTableViewCell.h"

@interface PendingRequestTableViewCell : FriendsTableViewCell

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *accountID;

@property (nonatomic, weak) id<FriendsDelegate> delegate;

- (void) accept;
- (void) decline;

- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier;

@end
