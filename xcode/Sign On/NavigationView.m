//
//  NavigationView.m
//  Navigation
//
//  Created by Ben Rooke on 7/15/15.
//  Copyright (c) 2015 Ben Rooke. All rights reserved.
//

#import "NavigationView.h"

const CGFloat navigationViewHeight = 150.0;

/* Values to help place the visuals for the navigation. */
#define SCREEN_MIDDLE_Y CGRectGetMidY([self frame])
#define SCREEN_MIDDLE_X CGRectGetMidX([self frame])

const CGFloat navTitleWidth = 95.0;
const CGFloat navTitleHeight = 18.0;
const CGFloat navTitleFontSize = 30.0;
#define NAV_TITLE_CENTER CGPointMake(SCREEN_MIDDLE_X, CGRectGetMaxY([self frame]) - navTitleHeight/2.0)
#define SEGREGATION_LINE_Y CGRectGetMaxY([self frame]) - (navTitleHeight / 2.0)
const CGFloat segregationLineThickness = 1.0;
#define SEGREGATION_LINE_COLOR [UIColor colorWithRed:1 green:1 blue:1 alpha:0.6]
const CGFloat segregationLineEdgeFromScreen = 14.0;
#define SEGREGATION_LINE_WIDTH SCREEN_MIDDLE_X - (navTitleWidth / 2.0) - (20.0)

const CGFloat navButtonLargeHeight = 37.0;
const CGFloat navButtonSmallHeight = 18.0;
const CGFloat distanceFromEdge = 40.0 + navButtonSmallHeight / 2.0;
#define NAV_LEFT_BUTTON_CENTER CGPointMake(distanceFromEdge, \
                                           SCREEN_MIDDLE_Y)
#define NAV_RIGHT_BUTTON_CENTER CGPointMake(SCREEN_MIDDLE_X * 2.0 - distanceFromEdge, \
                                            SCREEN_MIDDLE_Y)
#define NAV_CENTER_BUTTON_CENTER CGPointMake(SCREEN_MIDDLE_X, SCREEN_MIDDLE_Y)
#define NAV_OFFSCREEN_LEFT_BUTTON_CENTER CGPointMake(-distanceFromEdge, SCREEN_MIDDLE_Y)
#define NAV_OFFSCREEN_RIGHT_BUTTON_CENTER CGPointMake(SCREEN_MIDDLE_X * 2.0 + distanceFromEdge, SCREEN_MIDDLE_Y)

const CGFloat navBubbleWidth = 64.0;
#define BUBBLE_FILL_COLOR [UIColor colorWithRed:121.0/255.0 green:157.0/255.0 blue:192.0/255.0 alpha:1.0]
#define BUBBLE_BORDER_COLOR [UIColor colorWithRed:24.0/255.0 green:74.0/255.0 blue:135.0/255.0 alpha:1.0]

const NSString *NavigationViewAnimationDurationKey = @"kNavigationViewAnimationDurationKey";

/* Animation durations. */
const CGFloat titleFadeDuration = 0.2;
const CGFloat navButtonShiftDuration = 0.3;

/* For quick reference:
 * The navigation order is settings, home, friends. 
 * The following enum can be helpful for determing
 * how to navigate. */
typedef enum {
    settingsSelection,
    homeSelection,
    friendsSelection
} Selection;


@interface NavigationView ()

@property (nonatomic) Selection currentSelection;

/* Icons. */
@property (nonatomic, strong) UIButton *settingsIcon;
@property (nonatomic, strong) UIButton *homeIcon;
@property (nonatomic, strong) UIButton *friendsIcon;
/* And the background bubble; goes over the selected icon. */
@property (nonatomic, strong) UIView *selectionBubble;
@property (nonatomic, strong) UIView *nextSelectionBubble;

/* Resizing the icons can be annoying because they all have different widths. 
 * This convenience function can help. */
- (CGSize)_sizeForNewHeight:(CGFloat)height forIcon:(UIButton*)icon;
- (void)_downsizeIcon:(UIButton*)icon;
- (void)_downsizeAllIcons;
- (void)_resizeIcon:(UIButton*)icon withHeight:(CGFloat)height;
- (void)_upsizeIcon:(UIButton*)icon;

/* Delegate helpers. */
- (NSDictionary*)_userInfoWithAnimationSpeed:(CGFloat)duration;
- (BOOL)_makeDelegateCallForSelection:(Selection)selection;

/* Button selectors */
- (void)_touchedSettingsIcon;
- (void)_touchedHomeIcon;
- (void)_touchedFriendsIcon;

/* Convenience method to consolidate animation logic. */
- (void)_navigateWithInfo:(NSDictionary*)animateInfo forSelection:(Selection)selection animated:(BOOL)animated;
- (void)_completedForSelection:(Selection)selection animated:(BOOL)animated;

/* Methods for hiding and showing the title. */
@property (nonatomic, strong) UILabel *navTitle;
@property (nonatomic, strong) UIView *segregationLineLeft;
@property (nonatomic, strong) UIView *segregationLineRight;
- (void)_hideNavigationTitleAnimated:(BOOL)animated;
- (void)_revealNavigationTitle:(NSString*)title animated:(BOOL)animated;
- (NSString*)_navigationTitleForSelection:(Selection)selection;

/* Lazy load convenience method. */
- (UIView*)_buildSelectionBubble;

@end


@implementation NavigationView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.currentSelection = homeSelection;

        /* Here, the order of adding subviews DOES matter.
         * The selection bubble needs to be before the icons, so that it is displayed
         * underneath the icons. */
        [self addSubview:self.selectionBubble];
        [self addSubview:self.settingsIcon];
        [self addSubview:self.homeIcon];
        [self addSubview:self.friendsIcon];

        [self addSubview:self.segregationLineLeft];
        [self addSubview:self.segregationLineRight];
        [self addSubview:self.navTitle];
        
    }
    return self;
}


#pragma mark - Navigation Title Methods

- (void)_hideNavigationTitleAnimated:(BOOL)animated {
    if (!animated) {
        self.navTitle.alpha = 0.0;
        return;
    }
    [UIView animateWithDuration:titleFadeDuration
                     animations:^{
                         self.navTitle.alpha = 0.0;
                     }];
}

- (void)_revealNavigationTitle:(NSString*)title animated:(BOOL)animated {
    if (self.navTitle.alpha > 0.0 || !animated) {
        self.navTitle.alpha = 1.0;
        self.navTitle.text = title;
        return;
    }
    self.navTitle.text = title;
    [UIView animateWithDuration:titleFadeDuration
                     animations:^{
                         self.navTitle.alpha = 1.0;
                     }];
    
}

- (NSString*)_navigationTitleForSelection:(Selection)selection {
    switch (selection) {
        case settingsSelection:
            return @"Settings";
        case homeSelection:
            return @"Home";
        case friendsSelection:
            return @"Friends";
        default:
            [NSException raise:@"Invalid Argument" format:@"Invalid selection case, when trying to determine navigation title for selection %d", selection];
            break;
    }
    return @"";
}


#pragma mark - Resizing Icons

- (CGSize) _sizeForNewHeight:(CGFloat)height forIcon:(UIButton*)icon {
    if (icon == nil) {
        NSLog(@"Received a nil icon for resizing in NavigationView.");
        return CGSizeZero;
    }
    
    /* Stupid workaround bug fix (the friends icon looks too big). */
    if (icon == self.friendsIcon && height == navButtonLargeHeight) {
        height -= 5;
    }
    
    /* The scale will be
     * a height:width scale. */
    UIImage *iconImage = [icon backgroundImageForState:UIControlStateNormal];
    CGFloat iconScale = iconImage.size.height / iconImage.size.width;
    CGFloat width = height / iconScale;
    NSAssert(width > 0, @"Width must be greater than 0, when rescaling!");
    
    /* Return the new size! */
    return CGSizeMake(width, height);
}

- (void)_resizeIcon:(UIButton*)icon withHeight:(CGFloat)height {
    CGSize newSize = [self _sizeForNewHeight:height forIcon:icon];
    CGPoint newCenter = [icon center];
    CGRect newRect = icon.frame;
    newRect.size.height = newSize.height;
    newRect.size.width = newSize.width;
    
    icon.frame = newRect;
    icon.center = newCenter; // Keep it centered ;)
}

- (void)_upsizeIcon:(UIButton*)icon {
    [self _resizeIcon:icon withHeight:navButtonLargeHeight];
}

- (void)_downsizeIcon:(UIButton*)icon {
    [self _resizeIcon:icon withHeight:navButtonSmallHeight];
}

- (void)_downsizeAllIcons {
    for (UIButton *icon in @[self.settingsIcon, self.homeIcon, self.friendsIcon]) {
        [self _downsizeIcon:icon];
    }
}


#pragma mark - Delegate Helpers

/* This function will return NO if the delegate does not receive the selector call.
 * It will return YES if everything goes smoothly. */
- (BOOL)_makeDelegateCallForSelection:(Selection)selection {
    SEL delegateMethod = nil;
    switch (selection) {
        case settingsSelection:
            delegateMethod = @selector(willNavigateToSettings:);
            break;
        case homeSelection:
            delegateMethod = @selector(willNavigateToHome:);
            break;
        case friendsSelection:
            delegateMethod = @selector(willNavigateToFriends:);
            break;
        default:
            [NSException raise:@"Invalid Argument" format:@"Invalid selection case, when calling delegate's 'didSelect' variant"];
            return NO;
    }
    
    if ([self.delegate respondsToSelector:delegateMethod]) {
        NSDictionary *userInfo = [self _userInfoWithAnimationSpeed:navButtonShiftDuration];
        [self.delegate performSelector:delegateMethod withObject:userInfo];
        return YES;
    }
    /* Reaching this point means the delegate did not respond to the selector. */
    return NO;
}

- (NSDictionary*)_userInfoWithAnimationSpeed:(CGFloat)duration {
    return @{ NavigationViewAnimationDurationKey: @(duration) };
}


#pragma mark - Navigation Methods

- (void)_completedForSelection:(Selection)selection animated:(BOOL)animated{
    self.currentSelection = selection;
    
    /* Determine the correct delegate method to call. */
    SEL delegateMethod = nil;
    switch (selection) {
        case settingsSelection:
            delegateMethod = @selector(didNavigateToSettings);
            break;
        case homeSelection:
            delegateMethod = @selector(didNavigateToHome);
            break;
        case friendsSelection:
            delegateMethod = @selector(didNavigateToFriends);
            break;
        default:
            [NSException raise:@"Invalid Argument" format:@"Invalid selection case, when calling delegate's 'didSelect' variant"];
            return;
    }

    if ([self.delegate respondsToSelector:delegateMethod]) {
        [self.delegate performSelector:delegateMethod withObject:nil];
    }
    [self _revealNavigationTitle:[self _navigationTitleForSelection:selection] animated:animated];
}

- (void)_navigateWithInfo:(NSDictionary*)animateInfo forSelection:(Selection)selection animated:(BOOL)animated{
    if (self.currentSelection == selection) {
        return;
    }
    
    /* Determine the previously selected icon. */
    UIButton *previousIcon = nil;
    switch (self.currentSelection) {
        case homeSelection:
            previousIcon = self.homeIcon;
            break;
        case friendsSelection:
            previousIcon = self.friendsIcon;
            break;
        case settingsSelection:
            previousIcon = self.settingsIcon;
            break;
        default:
            [NSException raise:@"Invalid Argument" format:@"Invalid selection case, when trying to animate to new selection."];
            break;
    }
    
    /* Determine the new selected icon! */
    UIButton *selectedIcon = nil;
    switch (selection) {
        case homeSelection:
            selectedIcon = self.homeIcon;
            break;
        case friendsSelection:
            selectedIcon = self.friendsIcon;
            break;
        case settingsSelection:
            selectedIcon = self.settingsIcon;
            break;
        default:
            [NSException raise:@"Invalid Argument" format:@"Invalid selection case, when trying to animate to new selection."];
            break;
    }
    [self insertSubview:self.nextSelectionBubble atIndex:0];
    self.nextSelectionBubble.center = selectedIcon.center;
    
    /* Make the delegate call. */
    [self _makeDelegateCallForSelection:selection];
    
    /* Fade the current navigation title. */
    [self _hideNavigationTitleAnimated:animated];
    
    CGPoint settingsCenter = [[animateInfo objectForKey:@"settings"] CGPointValue];
    CGPoint homeCenter = [[animateInfo objectForKey:@"home"] CGPointValue];
    CGPoint friendsCenter = [[animateInfo objectForKey:@"friends"] CGPointValue];
    void (^animationBlock)(void) = ^{
        /* Set all the frames by default to the small values. */
        [self _downsizeAllIcons];
        /* Then resize the new selected icon to be larger! */
        [self _upsizeIcon:selectedIcon];
        
        self.settingsIcon.center = settingsCenter;
        self.homeIcon.center = homeCenter;
        self.friendsIcon.center = friendsCenter;
        
        self.selectionBubble.frame = CGRectZero;
        self.selectionBubble.center = previousIcon.center;
        
        self.nextSelectionBubble.frame = CGRectMake(0, 0, navBubbleWidth, navBubbleWidth);
        self.nextSelectionBubble.center = selectedIcon.center;
        
    };
    void (^completedBlock)(BOOL finished) = ^(BOOL finished) {
        /* Reassign the selection bubble to the new bubble. */
        self.selectionBubble = self.nextSelectionBubble;
        self.nextSelectionBubble = nil;
        [self _completedForSelection:selection animated:animated];
    };
    if (animated) {
        [UIView animateWithDuration:navButtonShiftDuration animations:animationBlock completion:completedBlock];
    } else {
        animationBlock();
        completedBlock(YES);
    }
}

- (void)navigateToHomeAnimated:(BOOL)animated {
    /* Create a dictionary to conveniently animate icons to new locations
     * (And a bonus of setting the next title). */
    NSDictionary *animationInfo = @{
                                    @"settings": [NSValue valueWithCGPoint:NAV_LEFT_BUTTON_CENTER],
                                    @"home": [NSValue valueWithCGPoint:NAV_CENTER_BUTTON_CENTER],
                                    @"friends": [NSValue valueWithCGPoint:NAV_RIGHT_BUTTON_CENTER]
                                    };
    [self _navigateWithInfo:animationInfo forSelection:homeSelection animated:animated];
}

- (void)navigateToFriendsAnimated:(BOOL)animated {
    /* Create a dictionary to conveniently animate icons to new locations
     * (And a bonus of setting the next title). */
    NSDictionary *animationInfo = @{
                                    @"settings": [NSValue valueWithCGPoint:NAV_OFFSCREEN_LEFT_BUTTON_CENTER],
                                    @"home": [NSValue valueWithCGPoint:NAV_LEFT_BUTTON_CENTER],
                                    @"friends": [NSValue valueWithCGPoint:NAV_CENTER_BUTTON_CENTER]
                                    };
    [self _navigateWithInfo:animationInfo forSelection:friendsSelection animated:animated];
}

- (void)navigateToSettingsAnimated:(BOOL)animated {
    /* Create a dictionary to conveniently animate icons to new locations
     * (And a bonus of setting the next title). */
    NSDictionary *animationInfo = @{
                                    @"settings": [NSValue valueWithCGPoint:NAV_CENTER_BUTTON_CENTER],
                                    @"home": [NSValue valueWithCGPoint:NAV_RIGHT_BUTTON_CENTER],
                                    @"friends": [NSValue valueWithCGPoint:NAV_OFFSCREEN_RIGHT_BUTTON_CENTER]
                                    };
    [self _navigateWithInfo:animationInfo forSelection:settingsSelection animated:animated];
}

/* And of course, the button selectors! All of these will animate the navigation. */
- (void)_touchedSettingsIcon {
    [self navigateToSettingsAnimated:YES];
}

- (void)_touchedHomeIcon {
    [self navigateToHomeAnimated:YES];
}

- (void)_touchedFriendsIcon {
    [self navigateToFriendsAnimated:YES];
}


#pragma mark - Lazy Loading

- (UIButton*)settingsIcon {
    if (!_settingsIcon) {
        _settingsIcon = [UIButton buttonWithType:UIButtonTypeCustom];
        /* Set the background image. */
        UIImage *gearIcon = [UIImage imageNamed:@"gear_icon.png"];
        [_settingsIcon setBackgroundImage:gearIcon forState:UIControlStateNormal];
        /* Set the right size for the button.
         * Do the layout. */
        CGSize gearSize = [self _sizeForNewHeight:navButtonSmallHeight forIcon:_settingsIcon];
        _settingsIcon.frame = CGRectMake(0, 0, gearSize.width, gearSize.height);
        _settingsIcon.center = NAV_LEFT_BUTTON_CENTER;
        [_settingsIcon addTarget:self action:@selector(_touchedSettingsIcon) forControlEvents:UIControlEventTouchUpInside];
    }
    return _settingsIcon;
}

- (UIButton*)homeIcon {
    if (!_homeIcon) {
        _homeIcon = [UIButton buttonWithType:UIButtonTypeCustom];
        /* Set the background image. */
        UIImage *homeIcon = [UIImage imageNamed:@"home_icon.png"];
        [_homeIcon setBackgroundImage:homeIcon forState:UIControlStateNormal];
        /* Set the right size for the button.
         * Do the layout. */
        CGSize homeSize = [self _sizeForNewHeight:navButtonLargeHeight forIcon:_homeIcon];
        _homeIcon.frame = CGRectMake(0, 0, homeSize.width, homeSize.height);
        _homeIcon.center = NAV_CENTER_BUTTON_CENTER;
        [_homeIcon addTarget:self action:@selector(_touchedHomeIcon) forControlEvents:UIControlEventTouchUpInside];
    }
    return _homeIcon;
}

- (UIButton*)friendsIcon {
    if (!_friendsIcon) {
        _friendsIcon = [UIButton buttonWithType:UIButtonTypeCustom];
        /* Set the background image. */
        UIImage *friendsIcon = [UIImage imageNamed:@"friends_icon.png"];
        [_friendsIcon setBackgroundImage:friendsIcon forState:UIControlStateNormal];
        /* Set the right size for the button.
         * Do the layout. */
        CGSize friendSize = [self _sizeForNewHeight:navButtonSmallHeight forIcon:_friendsIcon];
        _friendsIcon.frame = CGRectMake(0, 0, friendSize.width, friendSize.height);
        _friendsIcon.center = NAV_RIGHT_BUTTON_CENTER;
        [_friendsIcon addTarget:self action:@selector(_touchedFriendsIcon) forControlEvents:UIControlEventTouchUpInside];
    }
    return _friendsIcon;
}

- (UIView*)_buildSelectionBubble {
    UIView *bubble = [[UIView alloc] initWithFrame:CGRectMake(0, 0, navBubbleWidth, navBubbleWidth)];
    bubble.center = NAV_CENTER_BUTTON_CENTER;
    bubble.userInteractionEnabled = NO;
    bubble.backgroundColor = BUBBLE_FILL_COLOR;
    bubble.layer.borderColor = [BUBBLE_BORDER_COLOR CGColor];
    bubble.layer.borderWidth = 0.5;
    bubble.layer.cornerRadius = navBubbleWidth / 2.0;
    return bubble;
}

- (UIView*)selectionBubble {
    if (!_selectionBubble) {
        _selectionBubble = [self _buildSelectionBubble];
    }
    return _selectionBubble;
}

- (UIView*)nextSelectionBubble {
    if (!_nextSelectionBubble) {
        _nextSelectionBubble = [self _buildSelectionBubble];
        _nextSelectionBubble.frame = CGRectZero;
    }
    return _nextSelectionBubble;
}

- (UILabel*)navTitle {
    if (!_navTitle) {
        _navTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, navTitleWidth, navTitleHeight)];
        _navTitle.center = NAV_TITLE_CENTER;
        _navTitle.text = [self _navigationTitleForSelection:homeSelection];
        _navTitle.textColor = [UIColor whiteColor];
        _navTitle.backgroundColor = [UIColor clearColor];
        _navTitle.textAlignment = NSTextAlignmentCenter;
    }
    return _navTitle;
}

- (UIView*)segregationLineLeft {
    if (!_segregationLineLeft) {
        _segregationLineLeft = [[UIView alloc] initWithFrame:CGRectMake(segregationLineEdgeFromScreen, SEGREGATION_LINE_Y, SEGREGATION_LINE_WIDTH, segregationLineThickness)];
        _segregationLineLeft.backgroundColor = SEGREGATION_LINE_COLOR;
        _segregationLineLeft.userInteractionEnabled = NO;
    }
    return _segregationLineLeft;
}

- (UIView*)segregationLineRight {
    if (!_segregationLineRight) {
        CGFloat selfWidth = CGRectGetWidth([self frame]);
        CGFloat lineWidth = SEGREGATION_LINE_WIDTH;
        CGFloat buffer = segregationLineEdgeFromScreen;
        
        CGFloat x = selfWidth - lineWidth - buffer;
        _segregationLineRight = [[UIView alloc] initWithFrame:CGRectMake(x, SEGREGATION_LINE_Y, SEGREGATION_LINE_WIDTH, segregationLineThickness)];
        _segregationLineRight.backgroundColor = SEGREGATION_LINE_COLOR;
        _segregationLineRight.userInteractionEnabled = NO;
    }
    return _segregationLineRight;
}

@end
