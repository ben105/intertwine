//
//  PendingRequestTableViewCell.m
//  Sign On
//
//  Created by Ben Rooke on 1/31/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "PendingRequestTableViewCell.h"
#import "IntertwineManager+Friends.h"


const CGFloat buttonWidth = 70.0;

@interface PendingRequestTableViewCell ()

- (void) _addButtons;
- (void) _refresh;

@end


@implementation PendingRequestTableViewCell

@synthesize accountID;
@synthesize delegate;
@synthesize name;

- (void) _refresh {
    if ([self.delegate respondsToSelector:@selector(acceptedFriendRequest:)]) {
        [self.delegate acceptedFriendRequest:self];
    }
}

- (void) _addButtons {
    
    CGFloat height = self.contentView.frame.size.height;
    
    CGRect acceptButtonFrame = CGRectMake([[UIScreen mainScreen] bounds].size.width - buttonWidth - 10.0, 5, buttonWidth, height);
    CGRect declineButtonFrame = CGRectMake([[UIScreen mainScreen] bounds].size.width - buttonWidth*2 - 15.0, 5, buttonWidth, height);
    UIButton *acceptButton  = [[UIButton alloc] initWithFrame:acceptButtonFrame];
    UIButton *declineButton = [[UIButton alloc] initWithFrame:declineButtonFrame];
    
    [acceptButton addTarget:self action:@selector(accept) forControlEvents:UIControlEventTouchUpInside];
    [declineButton addTarget:self action:@selector(decline) forControlEvents:UIControlEventTouchUpInside];
    
    [acceptButton setTitle:@"Accept" forState:UIControlStateNormal];
    [acceptButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [declineButton setTitle:@"Decline" forState:UIControlStateNormal];
    [declineButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [self.contentView addSubview:acceptButton];
    [self.contentView addSubview:declineButton];
}



- (void) accept {
    NSLog(@"Accept!");
    [IntertwineManager acceptFriendRequest:self.accountID response:^(id json, NSError *error, NSURLResponse *response) {
        [self _refresh];
    }];
}

- (void) decline {
    NSLog(@"Decline!");
    [IntertwineManager declineFriendRequest:self.accountID response:^(id json, NSError *error, NSURLResponse *response) {
        [self _refresh];
    }];
}





- (id) initWithReuseIdentifier:reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        [self _addButtons];
    }
    return self;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
