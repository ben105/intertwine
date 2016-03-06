//
//  HeaderPagingScrollView.h
//  Sliding
//
//  Created by Ben Rooke on 2/25/16.
//  Copyright © 2016 NinjaQuant LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PagingScrollView.h"
#import "HeaderPagingView.h"

@protocol HeaderPagingScrollViewDataSource <PagingScrollViewDelegate>
@required
- (NSString*)titleForSegment:(NSUInteger)segmentIndex;
@end

@interface HeaderPagingScrollView : PagingScrollView <HeaderPagingViewDelegate>
@property (nonatomic, strong) HeaderPagingView *headerView;
@end
