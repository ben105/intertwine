//
//  SendRequestTableViewCell.h
//  Sign On
//
//  Created by Ben Rooke on 2/5/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SendRequestTableViewCell : UITableViewCell

@property (nonatomic) BOOL hasSent;

- (id) initWithSentStatus:(BOOL)hasSent reuseIdentifier:reuseIdentifier;

- (void) setSentStatus:(BOOL)hasSent;

@end
