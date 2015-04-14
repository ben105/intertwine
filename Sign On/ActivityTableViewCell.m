//
//  ActivityTableViewCell.m
//  Intertwine
//
//  Created by Ben Rooke on 4/13/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "ActivityTableViewCell.h"

@implementation ActivityTableViewCell

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.eventLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 260, 30)];
        
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
