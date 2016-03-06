//
//  EventFooterBar.h
//  Intertwine
//
//  Created by Ben Rooke on 2/15/16.
//  Copyright © 2016 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EventFooterBar : UIView

@property (nonatomic, strong) UIView *locationButtonView;
@property (nonatomic, strong) UIView *dateButtonView;
@property (nonatomic, strong) UIButton *locationButton;
@property (nonatomic, strong) UIButton *dateButton;
@property (nonatomic, strong) UILabel *locationButtonLabel;
@property (nonatomic, strong) UILabel *dateButtonLabel;

@end
