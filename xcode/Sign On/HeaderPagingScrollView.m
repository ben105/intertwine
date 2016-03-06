//
//  HeaderPagingScrollView.m
//  Sliding
//
//  Created by Ben Rooke on 2/25/16.
//  Copyright © 2016 NinjaQuant LLC. All rights reserved.
//

#import "HeaderPagingScrollView.h"


@interface HeaderPagingScrollView ()
-(void)_initHeaderView;
@property (nonatomic, weak) id<HeaderPagingScrollViewDataSource> headerDataSource;
@end

@implementation HeaderPagingScrollView

//- (instancetype) initWithFrame:(CGRect)frame numberOfPages:(NSUInteger)pages {
//    self = [super initWithFrame:frame numberOfPages:pages];
//    if (self) {
//        [self _initHeaderView];
//    }
//    return self;
//}

-(void)didMoveToSuperview {
    [self _initHeaderView];
}

-(void)_initHeaderView {
    for (int i=0; i<self.numberOfPages; i++) {
        NSString *title = [self.headerDataSource titleForSegment:i];
        [self.headerView setTitle:title forSegment:i];
    }
}

#pragma mark - Paging Calls

- (void)segmentTouchedAtIndex:(NSUInteger)index {
    [self scrollToPage:index];
}

- (void)pageChanged:(NSUInteger)pageNumber {
    [self.headerView moveToSegment:pageNumber];
    [super pageChanged:pageNumber];
}

#pragma mark - Setting Delegate

- (void) setDelegate:(id<HeaderPagingScrollViewDataSource>)delegate {
    self.headerDataSource = delegate;
    [super setDelegate:delegate];
}

#pragma mark - Lazy Loading

- (HeaderPagingView*)headerView {
    if (!_headerView) {
        _headerView = [[HeaderPagingView alloc] initWithSegmentSize:self.numberOfPages];
        _headerView.delegate = self;
    }
    return _headerView;
}

@end
