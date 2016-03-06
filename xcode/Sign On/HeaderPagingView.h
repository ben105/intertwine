//
//  HeaderPagingView.h
//  Sliding
//
//  Created by Ben Rooke on 2/25/16.
//  Copyright © 2016 NinjaQuant LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HeaderPagingViewDelegate <NSObject>

- (void)segmentTouchedAtIndex:(NSUInteger)index;

@end

@interface HeaderPagingView : UIView

@property (nonatomic) NSUInteger numberOfSegments;
@property (nonatomic, weak) id<HeaderPagingViewDelegate> delegate;

- (instancetype) initWithSegmentSize:(NSUInteger)segments;

- (void)setTitle:(NSString*)title forSegment:(NSUInteger)segment;
- (void)moveToSegment:(NSUInteger)segment;

@end
