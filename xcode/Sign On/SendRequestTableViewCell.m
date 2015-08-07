//
//  SendRequestTableViewCell.m
//  Sign On
//
//  Created by Ben Rooke on 2/5/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "SendRequestTableViewCell.h"

@interface SendRequestTableViewCell ()

@property (nonatomic, strong) UILabel *sentLabel;

@end

@implementation SendRequestTableViewCell

- (id) initWithSentStatus:(BOOL)hasSent reuseIdentifier:reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.hasSent = hasSent;
        CGFloat x = self.contentView.frame.size.width - 30;
        CGFloat y = 10;
        CGFloat height = 20;
        CGFloat width = 90;
        
        self.sentLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, width, height)];
        self.sentLabel.textColor = [UIColor blackColor];
        self.sentLabel.backgroundColor = [UIColor clearColor];
        [self.sentLabel setFont:[UIFont systemFontOfSize:12]];
        self.sentLabel.text = @"";
        if (hasSent) {
            self.sentLabel.text = @"Sent";
        }
        [self addSubview:self.sentLabel];
    }
    return self;
}

- (void) setSentStatus:(BOOL)hasSent {
    self.hasSent = hasSent;
    if (hasSent) {
        self.sentLabel.text = @"Sent";
    } else {
        self.sentLabel.text = @"";
    }
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
