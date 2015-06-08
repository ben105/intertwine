//
//  ITMultipleBannersViewController.h
//  Dynamic Banner
//
//  Created by Ben Rooke on 5/21/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ITAddView.h"

@interface ITMultipleBannersViewController : UIViewController <ITAddViewDelegate>

- (id) initWithBannerViewControllers:(NSArray*)viewControllers;

@end
