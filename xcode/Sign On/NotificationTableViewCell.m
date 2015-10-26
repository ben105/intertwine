//
//  NotificationTableViewCell.m
//  Intertwine
//
//  Created by Ben Rooke on 10/21/15.
//  Copyright © 2015 Intertwine. All rights reserved.
//

#import "NotificationTableViewCell.h"
#import "NotificationBanner.h"

@implementation NotificationTableViewCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.notificationView = [[NotificationBanner alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.contentView.frame), 120)];
        [self.contentView addSubview:self.notificationView];
    }
    return self;
}

- (void) setProfileID:(NSString*)profileID message:(NSString*)message notifInfo:(NSDictionary*)notifInfo {
    if (self.notificationView == nil)
        return;
    [self.notificationView setProfileID:profileID message:message notifInfo:notifInfo];
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


@end
