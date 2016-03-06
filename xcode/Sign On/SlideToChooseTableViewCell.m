//
//  SlideToChooseTableViewCell.m
//  DatePicker
//
//  Created by Ben Rooke on 1/18/16.
//  Copyright © 2016 NinjaQuant LLC. All rights reserved.
//

#import "SlideToChooseTableViewCell.h"

@interface SlideToChooseTableViewCell ()
@property (nonatomic) CGFloat cellWidth;
@property (nonatomic, strong) UIImageView *slideLeftIcon;
@end

@implementation SlideToChooseTableViewCell

- (instancetype)initWithWidth:(CGFloat)width reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.cellWidth = width;
        
        /* Resize the content view to fit the width. */
        CGRect frame = self.contentView.frame;
        frame.size.width = width;
        self.contentView.frame = frame;
        
        [self.contentView removeFromSuperview];
        [self addSubview:self.backgroundScrollView];
        [self.backgroundScrollView addSubview:self.contentView];
        [self.backgroundScrollView addSubview:self.slideLeftIcon];
        
        [self.backgroundScrollView setUserInteractionEnabled:NO];
        [self.contentView addGestureRecognizer:self.backgroundScrollView.panGestureRecognizer];
    }
    return self;
}

//- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
//    [super setSelected:selected animated:animated];
//    // Configure the view for the selected state
//}

#pragma mark - Scroll View Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(tableViewCell:scrollProgress:)]) {
        static CGFloat startingPoint = 80;
        CGPoint point = scrollView.contentOffset;
        if (point.x > startingPoint) {
            CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
            CGFloat percentage = (point.x - startingPoint) / (screenWidth - startingPoint);
            [self.delegate tableViewCell:self scrollProgress:percentage];
        }
    }
}

- (void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if ([self.delegate respondsToSelector:@selector(tableViewCellDidEndDragging:)]) {
        [self.delegate tableViewCellDidEndDragging:self];
    }
}

#pragma mark - Refresh View

- (void) refreshView {
    self.backgroundScrollView.frame = self.contentView.frame;
    self.slideLeftIcon.center = CGPointMake(CGRectGetWidth(self.backgroundScrollView.frame) - 20.0,
                                        CGRectGetHeight(self.backgroundScrollView.frame) / 2.0);
}

- (void) refreshViewToCellHeight:(CGFloat)cellHeight {
    CGRect frame = self.contentView.frame;
    frame.size.height = cellHeight;
    self.contentView.frame = frame;
    [self refreshView];
}

- (void) resetScrollableCell {
    [self.backgroundScrollView setContentOffset:CGPointMake(0, 0)];
}

#pragma mark - Lazy Loading

- (UIImageView*) slideLeftIcon {
    if (!_slideLeftIcon) {
        UIImage *slideLeftImage = [UIImage imageNamed:@"SlideLeft.png"];
        _slideLeftIcon = [[UIImageView alloc] initWithImage:slideLeftImage];
        _slideLeftIcon.frame = CGRectMake(0, 0, slideLeftImage.size.width, slideLeftImage.size.height);
        _slideLeftIcon.center = CGPointMake(CGRectGetWidth(self.backgroundScrollView.frame) - 20.0,
                                            CGRectGetHeight(self.backgroundScrollView.frame) / 2.0);
    }
    return _slideLeftIcon;
}

- (UIScrollView*)backgroundScrollView{
    if (!_backgroundScrollView) {
        _backgroundScrollView = [[UIScrollView alloc] initWithFrame:self.contentView.frame];
        _backgroundScrollView.backgroundColor = [UIColor clearColor];
        _backgroundScrollView.contentSize = CGSizeMake(self.cellWidth * 2.0, CGRectGetHeight(self.frame));
        _backgroundScrollView.pagingEnabled = YES;
        _backgroundScrollView.showsHorizontalScrollIndicator = NO;
        _backgroundScrollView.showsVerticalScrollIndicator = NO;
        _backgroundScrollView.delegate = self;
    }
    return _backgroundScrollView;
}

@end
