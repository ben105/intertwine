//
//  PagingScrollView.h
//  Sliding
//
//  Created by Ben Rooke on 2/25/16.
//  Copyright © 2016 NinjaQuant LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PagingScrollViewDelegate <UIScrollViewDelegate>
- (void) didScrollToPage:(NSUInteger)pageNumber;
@end

@interface PagingScrollView : UIScrollView <UIScrollViewDelegate>
@property (nonatomic) NSUInteger numberOfPages;
- (instancetype) initWithFrame:(CGRect)frame numberOfPages:(NSUInteger)pages;

/* Do not call this method directly. */
- (void)pageChanged:(NSUInteger)pageNumber;
- (void)scrollToPage:(NSUInteger)pageNumber;
@end
