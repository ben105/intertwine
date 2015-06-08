//
//  ITDynamicBannerView.m
//  Dynamic Banner
//
//  Created by Ben Rooke on 5/17/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "ITDynamicBannerView.h"

#pragma mark - Global Declerations

/* The Banner View has two different modes, small-mode and large-mode. This
 * is why it's called a dynamic banner view. 
 * In the code, you might see a prefix 'sm' or 'lg'. This stands for small
 * and large, respectively. It corresponds to variables pertaining to the 
 * small and large view mode. */

const CGFloat lgBannerImageViewWidth = 83.0;
const CGFloat smBannerImageViewWidth = 45.0;

const CGFloat smBannerLabelHeight = 36.0;
const CGFloat lgBannerLabelHeight = 56.0;
const CGFloat smBannerLabelFontSize = 30.0;
const CGFloat lgBannerLabelFontSize = 48.0;

/* The following constants represent the x and y coordinates for the label
 * and image subviews. Keep in mind that these are the values at the terminal
 * key frames, so to speak. If the dynamic banner is slowly animating between
 * the two states, it will set the values to some intermediary float. This
 * can be accomplished by adding the small and large values, and multiplying
 * by the percentage of the animation progress. */
const CGFloat smBannerLabelY = 17.0;
const CGFloat lgBannerLabelY = 93.0;
const CGFloat smBannerImageViewY = 13.0;
const CGFloat smBannerImageViewX = 30.0;
const CGFloat lgBannerImageViewY = 10.0;

CGFloat animationTime = 0.5;
CGFloat framesPerSecond = 60;

#define lgBannerImageViewX CGRectGetMidX([[UIScreen mainScreen] bounds]) - (lgBannerImageViewWidth/2.0)
#define SCREEN_WIDTH CGRectGetWidth([[UIScreen mainScreen] bounds])

/* Convenience method to determine the intermediate value between two points.
 * Simply doing the distance formula, essentially. */
CGFloat intermediateValue(CGFloat start, CGFloat end, CGFloat progress) {
    if (progress < 0.0 || progress > 1.0) {
        NSString *reason = [NSString stringWithFormat:@"Progress value is expected to be a percentage [0 - 1]. Value given: %lf", progress];
        NSException *exception = [NSException exceptionWithName:@"Invalid Argument"
                                                         reason:reason
                                                       userInfo:nil];
        [exception raise];
    }
    return start + (end - start) * progress;
}

CGFloat intermediateBannerLabelHeight(CGFloat progress) {
    return intermediateValue(smBannerLabelHeight, lgBannerLabelHeight, progress);
}

CGFloat intermediateBannerLabelY(CGFloat progress) {
    return intermediateValue(smBannerLabelY, lgBannerLabelY, progress);
}

CGFloat intermediateBannerImageViewY(CGFloat progress) {
    return intermediateValue(smBannerImageViewY, lgBannerImageViewY, progress);
}

CGFloat intermediateBannerImageViewX(CGFloat progress) {
    return intermediateValue(smBannerImageViewX, lgBannerImageViewX, progress);
}

CGFloat intermediateBannerImageViewWidth(CGFloat progress) {
    return intermediateValue(smBannerImageViewWidth, lgBannerImageViewWidth, progress);
}

CGFloat intermediateBannerLabelFont(CGFloat progress) {
    return intermediateValue(smBannerLabelFontSize, lgBannerLabelFontSize, progress);
}

/* Banner height, which doesn't need to change between modes, because it's
 * transparent. As long as the height can encompass the views in large mode,
 * it should be fine. */
const CGFloat lgBannerHeight = 155.0;
const CGFloat smBannerHeight = 60.0;

#pragma mark - Private Interface

@interface ITDynamicBannerView()

@property BOOL isSmallMode;

@property (nonatomic, strong) UILabel *bannerLabel;
@property (nonatomic, strong) UIImageView *bannerImageView;

@end


#pragma mark - Implementation

@implementation ITDynamicBannerView

@synthesize bannerLabel = _bannerLabel;
@synthesize bannerImageView = _bannerImageView;

- (id) initWithText:(NSString*)bannerText andImage:(UIImage*)bannerImage {
    // Create the banner rect. Screen width, and preset height.
    // Height is set by global const, above (lgBannerHeight).
    CGRect bannerRect = CGRectMake(0, 0, SCREEN_WIDTH, lgBannerHeight);
    
    // Initiate with the banner rectangle.
    self = [super initWithFrame:bannerRect];
    if (self) {
 
        CGRect imageViewRect = CGRectMake(lgBannerImageViewX, lgBannerImageViewY, lgBannerImageViewWidth, lgBannerImageViewWidth);
        self.bannerImageView = [[UIImageView alloc] initWithImage:bannerImage];
        self.bannerImageView.frame = imageViewRect;
        self.bannerImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.bannerImageView.layer.cornerRadius = CGRectGetWidth(imageViewRect) / 2.0;
        
        self.bannerLabel.text = bannerText;
        
        [self addSubview:self.bannerImageView];
        [self addSubview:self.bannerLabel];
        
        self.isSmallMode = NO;
        self.progress = 1.0;
        self.userInteractionEnabled = NO;
    }
    return self;
}


#pragma mark - Banner Text Setter and Getter
- (NSString*)bannerText {
    return self.bannerLabel.text;
}

- (void) setBannerText:(NSString*)bannerText {
    self.bannerLabel.text = bannerText;
}


#pragma mark - Banner Image Setter and Getter
- (void) setBannerImage:(UIImage*)bannerImage {
    self.bannerImageView.image = bannerImage;
}

- (UIImage*)bannerImage {
    return self.bannerImageView.image;
}


#pragma mark - Animate Between the Two Modes (Binary)

- (void) animateToSmallMode {
    NSTimer *timer = [NSTimer timerWithTimeInterval:1/framesPerSecond
                                             target:self
                                           selector:@selector(makeSmaller:)
                                           userInfo:nil
                                            repeats:YES];
    NSRunLoop *runloop = [NSRunLoop mainRunLoop];
    [runloop addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void) makeSmaller:(NSTimer*)timer {
    self.progress -= 0.1;
    if (self.progress <= 0) {
        self.progress = 0;
        [timer invalidate];
        self.isSmallMode = YES;
    }
    [self setValuesForProgress:self.progress];
}

- (void) animateToLargeMode {
    NSTimer *timer = [NSTimer timerWithTimeInterval:1/framesPerSecond
                                             target:self
                                           selector:@selector(makeLarger:)
                                           userInfo:nil
                                            repeats:YES];
    NSRunLoop *runloop = [NSRunLoop currentRunLoop];
    [runloop addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void) makeLarger:(NSTimer*)timer {
    self.progress += 0.1;
    if (self.progress >= 1) {
        self.progress = 1;
        [timer invalidate];
        self.isSmallMode = NO;
    }
    [self setValuesForProgress:self.progress];
}


- (void) toggleMode {
    if (self.isSmallMode) {
        [self animateToLargeMode];
    } else {
        [self animateToSmallMode];
    }
}



#pragma mark - Animate Smoothly Over Progress

- (void) setValuesForProgress:(CGFloat)progress {
    self.progress = progress;
    
    CGFloat labelY = intermediateBannerLabelY(progress);
    CGFloat labelHeight = intermediateBannerLabelHeight(progress);
    CGFloat imageViewY = intermediateBannerImageViewY(progress);
    CGFloat imageViewX = intermediateBannerImageViewX(progress);
    CGFloat imageViewWidth = intermediateBannerImageViewWidth(progress);
    CGFloat labelFont = intermediateBannerLabelFont(progress);
    
    self.bannerLabel.frame = CGRectMake(0, labelY, SCREEN_WIDTH, labelHeight);
    self.bannerLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:labelFont];
    self.bannerImageView.frame = CGRectMake(imageViewX, imageViewY, imageViewWidth, imageViewWidth);
}


# pragma mark - UI Elements


- (UILabel*) bannerLabel {
    if (!_bannerLabel) {
        /* We will intialize the banner in large-mode to begin with, and
         * assume that the view is prepared for that.
         * Possible update later would include a boolean arguement for
         * whether we initialize in small mode or large mode. */
        CGRect labelRect = CGRectMake(0, lgBannerLabelY, SCREEN_WIDTH, lgBannerLabelHeight);

        UIColor *bannerLabelColor = [UIColor colorWithRed:104.0/255.0 green:104.0/255.0 blue:113.0/255.0 alpha:1];

        // If we successfull initiated, we can add the label and image subviews.
        _bannerLabel = [[UILabel alloc] initWithFrame:labelRect];
        _bannerLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:lgBannerLabelFontSize];
        _bannerLabel.textColor = bannerLabelColor;
        _bannerLabel.backgroundColor = [UIColor clearColor];
        _bannerLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _bannerLabel;
}

@end
