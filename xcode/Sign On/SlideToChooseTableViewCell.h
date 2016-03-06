//
//  SlideToChooseTableViewCell.h
//  DatePicker
//
//  Created by Ben Rooke on 1/18/16.
//  Copyright © 2016 NinjaQuant LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SlideToChooseTableViewCell;

@protocol SlideToChooseTableViewCellDelegate <NSObject>
@optional
- (void)tableViewCell:(SlideToChooseTableViewCell*)cell scrollProgress:(CGFloat)percentage;
- (void)tableViewCellDidEndDragging:(SlideToChooseTableViewCell*)cell;
@end

@interface SlideToChooseTableViewCell : UITableViewCell <UIScrollViewDelegate>

- (instancetype)initWithWidth:(CGFloat)width reuseIdentifier:(NSString *)reuseIdentifier;
@property (nonatomic, strong) UIScrollView *backgroundScrollView;
@property (nonatomic, weak) id<SlideToChooseTableViewCellDelegate> delegate;


/* This method is for when the user of this class creates a subclass, and wants to
 * adjust the layout with the new cell height. */
- (void) refreshView;
- (void) refreshViewToCellHeight:(CGFloat)cellHeight;

/* We want to let the user of this class to determine when the cells should be reset. */
- (void) resetScrollableCell;

@end
