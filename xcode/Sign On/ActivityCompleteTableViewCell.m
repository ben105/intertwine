//
//  ActivityCompleteTableViewCell.m
//  Intertwine
//
//  Created by Ben Rooke on 9/20/15.
//  Copyright © 2015 Intertwine. All rights reserved.
//

#import "ActivityCompleteTableViewCell.h"

const CGFloat activityCompleteCellHeight = 143.0;
const CGFloat activityStarHeight = 65.0;

const CGFloat completedDetailBoxHeight = 100.0;

const CGFloat activityCompleteCellSpacer = 5.0;

@interface ActivityCompleteTableViewCell ()

@property (nonatomic, strong) UIImageView *star;
@property (nonatomic, strong) UIView *detailBox;

@end


@implementation ActivityCompleteTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.contentView.layer.shadowOffset = CGSizeMake(0, -2);
                
        CGRect contentFrame = self.contentView.frame;
        contentFrame.origin.y = 0;
        contentFrame.size.height = activityCompleteCellHeight;
        contentFrame.size.width = [[UIScreen mainScreen] bounds].size.width;
        self.contentView.frame = contentFrame;
        self.contentView.backgroundColor = [UIColor clearColor];
        
        [self.contentView addSubview:self.detailBox];
        [self.contentView addSubview:self.star];
    }
    return self;
}



#pragma mark - Lazy Loading

- (UILabel*) titleLabel {
    if (!_titleLabel) {
        static float inset = 15.0;
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(inset, 0, CGRectGetWidth(self.detailBox.frame) - (inset*2.0), 25)];
        [_titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:22]];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = [UIColor blackColor];
        
        CGPoint center = _titleLabel.center;
        center.y = CGRectGetHeight(self.detailBox.frame)/2.0;
        _titleLabel.center = center;
    }
    return _titleLabel;
}

- (UILabel*)attendeesLabel {
    if (!_attendeesLabel) {
        static float inset = 60.0;
        _attendeesLabel = [[UILabel alloc] initWithFrame:CGRectMake(inset, 0, CGRectGetWidth(self.detailBox.frame) - (inset*2.0), 15)];
        [_attendeesLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:10]];
        _attendeesLabel.textAlignment = NSTextAlignmentCenter;
        _attendeesLabel.backgroundColor = [UIColor clearColor];
        _attendeesLabel.textColor = [UIColor blackColor];
        
        CGRect frame = _titleLabel.frame;
        frame.origin.y = CGRectGetMaxY(self.titleLabel.frame);
        _attendeesLabel.frame = frame;
    }
    return _attendeesLabel;
}

- (UIView*)detailBox {
    if (!_detailBox) {
        static float inset = 15.0;
        _detailBox = [[UIView alloc] initWithFrame:CGRectMake(inset, CGRectGetMidY(self.star.frame), CGRectGetWidth(self.contentView.frame) - (inset*2.0), completedDetailBoxHeight)];
        _detailBox.layer.cornerRadius = 5.0;
//        _detailBox.backgroundColor = [UIColor colorWithRed:233.0/255.0 green:196.0/255.0 blue:92.0/255.0 alpha:1.0];
        _detailBox.backgroundColor = [UIColor whiteColor];
        _detailBox.layer.borderWidth = 1.0;
        _detailBox.layer.borderColor = [[UIColor blackColor] CGColor];
//        _detailBox.layer.shadowColor = [[UIColor blackColor] CGColor];
//        _detailBox.layer.shadowOffset = CGSizeMake(0, -2);
//        _detailBox.layer.shadowOpacity = 0.7;
        
        [_detailBox addSubview:self.titleLabel];
        [_detailBox addSubview:self.attendeesLabel];
    }
    return _detailBox;
}

- (UIImageView*)star {
    if (!_star) {
        _star = [[UIImageView alloc] initWithFrame:CGRectMake(0, activityCompleteCellSpacer, activityStarHeight, activityStarHeight)];
        _star.image = [UIImage imageNamed:@"star.png"];
        
        CGPoint center = _star.center;
        center.x = CGRectGetMidX(self.contentView.frame);
        _star.center = center;
    }
    return _star;
}


@end
