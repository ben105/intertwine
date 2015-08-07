//
//  ITMultipleBannersViewController.m
//  Dynamic Banner
//
//  Created by Ben Rooke on 5/21/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "ITMultipleBannersViewController.h"
#import "ITDynamicBannerViewController.h"
#import "AppDelegate.h"

@interface ITMultipleBannersViewController ()

@property (nonatomic, strong, readonly) NSArray *viewControllers;
@property (nonatomic, strong) UIScrollView *scrollView;

// Bottom of the screen - tool bar.
@property (nonatomic, strong) UIView *bottomToolBar;
@property (nonatomic, strong) ITAddView *buttonCreateTask;

/* For display messages on the screen, with a dim view that
 * will be covering everything above the bottom bar. */
@property (nonatomic, strong) UIView *dimView;
@property (nonatomic, strong) UILabel *messageLabel;

@end


@implementation ITMultipleBannersViewController

- (BOOL) prefersStatusBarHidden {
    return YES;
}

- (id) initWithBannerViewControllers:(NSArray*)viewControllers {
    self = [super init];
    if (self) {
        
        _viewControllers = viewControllers;
        
        [self.view addSubview:self.scrollView];
        [self.view addSubview:self.dimView];
        [self.dimView addSubview:self.messageLabel];
        [self.view addSubview:self.bottomToolBar];
        [self.view addSubview:self.buttonCreateTask];
        
        CGFloat width = [[UIScreen mainScreen] bounds].size.width;
        CGFloat height = [[UIScreen mainScreen] bounds].size.height;
        for (unsigned i=0; i<[viewControllers count]; ++i) {
            ITDynamicBannerViewController *vc = [viewControllers objectAtIndex:i];
            CGRect frame = CGRectMake(i*width, 0, width, height);
            vc.view.frame = frame;
            [self.scrollView addSubview:vc.view];
        }
        
        CGFloat contentWidth = [viewControllers count] * width;
        CGFloat contentHeight = CGRectGetHeight(self.scrollView.frame);
        [self.scrollView setContentSize:CGSizeMake(contentWidth, contentHeight)];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - AddView Delegate

- (void) willExpand {
    [UIView animateWithDuration:AddViewAnimationDuration
                     animations:^{
                         self.dimView.alpha = 0.3;
                         self.messageLabel.text = @"";
                     }];
}

- (void) willCollapse {
    [UIView animateWithDuration:AddViewAnimationDuration
                     animations:^{
                         self.dimView.alpha = 0;
                         self.messageLabel.text = @"";
                     }];
}

-(void)fingerOverSelection:(AddViewSelection)selection {
    self.messageLabel.text = [ITAddView selectionDescription:selection];
}

-(void)fingerOffSelection {
    self.messageLabel.text = @"";
}

#pragma mark - UI Elements

- (UIScrollView*) scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        _scrollView.pagingEnabled = YES;
        _scrollView.userInteractionEnabled = YES;
    }
    return _scrollView;
}

- (UIView*) bottomToolBar {
    if (!_bottomToolBar) {
        CGRect bounds = [[UIScreen mainScreen] bounds];
        CGFloat width = bounds.size.width;
        CGFloat height = [(AppDelegate*)[UIApplication sharedApplication].delegate bottomTabBarHeight];
        CGFloat y = bounds.size.height - height;
        _bottomToolBar = [[UIView alloc] initWithFrame:CGRectMake(0, y, width, height)];
        _bottomToolBar.backgroundColor = [UIColor colorWithRed:95.0/255.0 green:132.0/255.0 blue:205.0/255.0 alpha:1.0];
    }
    return _bottomToolBar;
}

- (ITAddView *) buttonCreateTask {
    if (!_buttonCreateTask) {
        CGFloat centerOfScreenX = CGRectGetWidth([[UIScreen mainScreen] bounds]) / 2.0;
        CGFloat screenHeight = CGRectGetHeight([[UIScreen mainScreen] bounds]);
        CGFloat centerCreateTaskY = screenHeight - (addViewHeight / 2.0);
        _buttonCreateTask = [[ITAddView alloc] init];
        _buttonCreateTask.delegate = self;
        _buttonCreateTask.center = CGPointMake(centerOfScreenX, centerCreateTaskY);
    }
    return _buttonCreateTask;
}

- (UIView*)dimView {
    if (!_dimView) {
        CGRect bounds = [[UIScreen mainScreen] bounds];
        CGFloat bottomTabBarHeight = [(AppDelegate*)[UIApplication sharedApplication].delegate bottomTabBarHeight];
        CGFloat height = bounds.size.height - bottomTabBarHeight;
        _dimView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, height)];
        _dimView.backgroundColor = [UIColor blackColor];
        _dimView.userInteractionEnabled = NO;
        _dimView.alpha = 0.0;
    }
    return _dimView;
}

- (UILabel*) messageLabel {
    if (!_messageLabel) {
        NSUInteger numberOfLines = 0; // Will automatically write a newline.
        
        CGFloat inset = 8.0;
        CGFloat bottomTabBarHeight = [(AppDelegate*)[UIApplication sharedApplication].delegate bottomTabBarHeight];
        CGRect bounds = [[UIScreen mainScreen] bounds];
        CGFloat width = bounds.size.width - (inset * 2.0);
        CGFloat height = bounds.size.height - bottomTabBarHeight;
        
        _messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        _messageLabel.backgroundColor = [UIColor clearColor];
        _messageLabel.textColor = [UIColor whiteColor];
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.numberOfLines = numberOfLines;
        _messageLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:24];
    }
    return _messageLabel;
}

@end
