//
//  IntertwineCalendarDayCell.h
//  DatePicker
//
//  Created by Ben Rooke on 2/13/16.
//  Copyright © 2016 NinjaQuant LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlideToChooseTableViewCell.h"

@interface IntertwineCalendarDayCell : SlideToChooseTableViewCell
@property (nonatomic, strong) NSDate *date;
- (instancetype)initWithWidth:(CGFloat)width reuseIdentifier:(NSString *)reuseIdentifier;
+(CGFloat)cellHeight;

- (NSString*)stringFromDate;

/* For retrieving the info from the cell. */
- (NSString*) getDay;
- (NSString*) getDayOfWeek;
@end
