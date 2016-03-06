//
//  PagingScrollView.m
//  Sliding
//
//  Created by Ben Rooke on 2/25/16.
//  Copyright © 2016 NinjaQuant LLC. All rights reserved.
//

#import "PagingScrollView.h"

@interface PagingScrollView ()
@property (nonatomic, weak) id<PagingScrollViewDelegate> pagingDelegate;
@property NSUInteger previousPage;
- (void)_callScrollToPageNumber;
@end

@implementation PagingScrollView

- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        /* The view cannot clip because then the header view won't
         * display. */
//        self.clipsToBounds = NO;
        [super setDelegate:self];
        self.pagingEnabled = YES;
        self.numberOfPages = 0;
        self.previousPage = 0;
    }
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame numberOfPages:(NSUInteger)pages {
    self = [self initWithFrame:frame];
    if (self) {
        self.numberOfPages = pages;
        
        /* Set up the content offset for the number of pages. */
        CGFloat width = CGRectGetWidth(frame);
        CGFloat height = CGRectGetHeight(frame);
        CGFloat contentSizeWidth = width * pages;
        self.contentSize = CGSizeMake(contentSizeWidth, height);
    }
    return self;
}

- (void) setContentSize:(CGSize)contentSize {
    [super setContentSize:contentSize];
    CGFloat width = CGRectGetWidth(self.frame);
    self.numberOfPages = (NSUInteger)(contentSize.width / width);
}

- (void)pageChanged:(NSUInteger)pageNumber {
    if ([self.pagingDelegate respondsToSelector:@selector(didScrollToPage:)]) {
        [self.pagingDelegate didScrollToPage:pageNumber];
    }
    self.previousPage = pageNumber;
}

- (void)scrollToPage:(NSUInteger)pageNumber {
    CGFloat width = CGRectGetWidth(self.frame);
    [self setContentOffset:CGPointMake(width*pageNumber, 0) animated:YES];
}

- (void)_callScrollToPageNumber {
    CGFloat x = self.contentOffset.x;
    CGFloat width = CGRectGetWidth(self.frame);
    NSUInteger pageNumber = (NSUInteger)(x/width);
    if (pageNumber != self.previousPage) {
        [self pageChanged:pageNumber];
    }
}

#pragma mark - Scroll View Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self.pagingDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [self.pagingDelegate scrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if ([self.pagingDelegate respondsToSelector:@selector(scrollViewDidZoom:)]) {
        [self.pagingDelegate scrollViewDidZoom:scrollView];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if ([self.pagingDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
        [self.pagingDelegate scrollViewWillBeginDragging:scrollView];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if ([self.pagingDelegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) {
        [self.pagingDelegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if ([self.pagingDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [self.pagingDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if ([self.pagingDelegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)]) {
        [self.pagingDelegate scrollViewWillBeginDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == self) {
        [self _callScrollToPageNumber];
    }
    if ([self.pagingDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [self.pagingDelegate scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if ([self.pagingDelegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
        [self.pagingDelegate scrollViewDidEndScrollingAnimation:scrollView];
    }
}

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if ([self.pagingDelegate respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
        return [self.pagingDelegate viewForZoomingInScrollView:scrollView];
    }
    return nil;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view {
    if ([self.pagingDelegate respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)]) {
        [self.pagingDelegate scrollViewWillBeginZooming:scrollView withView:view];
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view atScale:(CGFloat)scale {
    if ([self.pagingDelegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)]) {
        [self.pagingDelegate scrollViewDidEndZooming:scrollView withView:view atScale:scale];
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    if ([self.pagingDelegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)]) {
        return [self.pagingDelegate scrollViewShouldScrollToTop:scrollView];
    }
    return YES;
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    if ([self.pagingDelegate respondsToSelector:@selector(scrollViewDidScrollToTop:)]) {
        [self.pagingDelegate scrollViewDidScrollToTop:scrollView];
    }
}


#pragma mark - Lazy Loading

- (void) setDelegate:(id<PagingScrollViewDelegate>)delegate {
    self.pagingDelegate = delegate;
}

//- (UIScrollView*)scrollView {
//    if (!_scrollView) {
//        CGFloat width = CGRectGetWidth(self.frame);
//        CGFloat height = CGRectGetHeight(self.frame);
//        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
//        _scrollView.delegate = self;
//        _scrollView.pagingEnabled = YES;
//    }
//    return _scrollView;
//}

@end
