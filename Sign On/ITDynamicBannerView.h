//
//  ITDynamicBannerView.h
//  Dynamic Banner
//
//  Created by Ben Rooke on 5/17/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ITDynamicBannerView : UIView

@property CGFloat progress;

- (id) initWithText:(NSString*)bannerText andImage:(UIImage*)bannerImage;

// Setter/Getter for the banner text.
- (NSString*)bannerText;
- (void) setBannerText:(NSString*)bannerText;

// Setter/Getter for the banner image.
- (void) setBannerImage:(UIImage*)bannerImage;
- (UIImage*)bannerImage;

// Animation methods.
- (void) animateToSmallMode;
- (void) animateToLargeMode;
- (void) toggleMode;

// Put the views in a position for a given progress.
- (void) setValuesForProgress:(CGFloat)progress;

extern const CGFloat lgBannerHeight;
extern const CGFloat smBannerHeight;

@end
