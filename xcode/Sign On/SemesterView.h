//
//  SemesterView.h
//  DatePicker
//
//  Created by Ben Rooke on 1/19/16.
//  Copyright © 2016 NinjaQuant LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SemesterViewDelegate <NSObject>
@optional
-(void)semesterName:(NSString*)semesterName scrollProgress:(CGFloat)percentage;
@end

@interface SemesterView : UIView <UIScrollViewDelegate>
- (instancetype)initInsideView:(UIView*)view;
@property (nonatomic, weak) id<SemesterViewDelegate> delegate;
@end
