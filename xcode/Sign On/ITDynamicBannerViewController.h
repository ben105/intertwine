//
//  ITDynamicBannerViewController.h
//  Dynamic Banner
//
//  Created by Ben Rooke on 5/18/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ITDynamicBannerView;
@class ITBannerTableView;

@interface ITDynamicBannerViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>

- (id) initWithBannerTitle:(NSString*)bannerTitle bannerImage:(UIImage*)bannerImage data:(NSArray*)tableViewData;

// This will be the banner or title on the top of the view controller.
@property (nonatomic, strong) ITDynamicBannerView *bannerView;

// This is the scroll view from which the content will be displayed.
@property (nonatomic, strong) ITBannerTableView *contentTableView;

@end
