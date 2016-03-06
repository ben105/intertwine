//
//  SemesterPage.h
//  DatePicker
//
//  Created by Ben Rooke on 2/13/16.
//  Copyright © 2016 NinjaQuant LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SemesterView;

@interface SemesterPage : UIView
@property (nonnull, nonatomic, strong) SemesterView *semesterView;
@property (nonnull, nonatomic, strong) UILabel *monthHeaderLabel;
@property (nonnull, nonatomic, strong) UILabel *dayHeaderLabel;
@end
