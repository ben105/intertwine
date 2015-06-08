//
//  ITDynamicBannerViewController.m
//  Dynamic Banner
//
//  Created by Ben Rooke on 5/18/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "ITDynamicBannerViewController.h"
#import "ITDynamicBannerView.h"
#import "ITBannerTableView.h"
#import "AppDelegate.h"

@interface ITDynamicBannerViewController ()

// This helper methods are here to connect the banner and table view.
- (CGFloat) _progress;
- (void) _stepProgress;
- (void) _snapBannerToMode;

@property (nonatomic, copy) NSString *bannerTitle;
@property (nonatomic, copy) UIImage *bannerImage;
@property (nonatomic, strong) NSArray *tableViewData;

// This is to keep track of if the user has their finger down on the table view.
@property BOOL _fingerDown;

@end

@implementation ITDynamicBannerViewController

- (id) initWithBannerTitle:(NSString*)bannerTitle
               bannerImage:(UIImage*)bannerImage
                data:(NSArray*)tableViewData{
    self = [super init];
    if (self) {
        self.bannerTitle = bannerTitle;
        self.bannerImage = bannerImage;
        self.tableViewData = tableViewData;
        
        self.view.backgroundColor = [UIColor whiteColor];
        
        [self.view addSubview:self.contentTableView];
        [self.view addSubview:self.bannerView];
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






#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120;
}

#pragma mark - Table View Data Source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    return 1;
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        
        // Add the box view
        CGFloat inset = 8.0;
        CGFloat width = [[UIScreen mainScreen] bounds].size.width - (inset*2);
        CGFloat height = 120 - (inset*2);
        UIView *boxView = [[UIView alloc] initWithFrame:CGRectMake(inset, inset, width, height)];
        [boxView setBackgroundColor:[UIColor whiteColor]];
        boxView.layer.borderColor = [[UIColor blackColor] CGColor];
        boxView.layer.borderWidth = 1.0;
        
        [cell addSubview:boxView];
    }
    return cell;
}


# pragma mark - Table View / Banner: Helper Methods

- (CGFloat) _progress {
    return (self.contentTableView.frame.origin.y - smBannerHeight) / (lgBannerHeight - smBannerHeight);
}

- (void) _stepProgress {
    [self.bannerView setValuesForProgress:[self _progress]];
}

- (void) _snapBannerToMode {
    
    CGFloat progress = [self _progress];
    
    // Bail early if the banner is already in large or small position.
    if (progress <= 0 || progress >= 1) {
        return;
    }
    
    
    CGFloat tableY = smBannerHeight;
    CGFloat toProgress = 0;
    if (progress > .50) {
        tableY = lgBannerHeight;
        toProgress = 1;
    }
    
    CGRect frame = self.contentTableView.frame;
    frame.origin.y = tableY;
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.contentTableView.frame = frame;
                         [self.bannerView setValuesForProgress:toProgress];
                     } completion:nil];
}


#pragma mark - Scroll View Delegate

// called on start of dragging (may require some time and or distance to move)
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self._fingerDown = YES;
}

// called on finger up if the user dragged. velocity is in points/millisecond. targetContentOffset may be changed to adjust where the scroll view comes to rest
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset NS_AVAILABLE_IOS(5_0) {
    self._fingerDown = NO;
    [self _snapBannerToMode];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGRect frame = scrollView.frame;
    
    // If the banner is in small mode, and the user is no longer dragging,
    // we don't want to animate the banner.
    if (!self._fingerDown && self.bannerView.progress == 0) {
        return;
    }
    
    if (scrollView.frame.origin.y > smBannerHeight) {
    
        if (scrollView.contentOffset.y > 0 ) {
       
            CGFloat offset = scrollView.contentOffset.y;
       
            [scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
       
            frame.origin.y -= offset;
            
            if (frame.origin.y < smBannerHeight) {
                frame.origin.y = smBannerHeight;
            }
            if (frame.origin.y > lgBannerHeight) {
                frame.origin.y = lgBannerHeight;
            }
            scrollView.frame = frame;
            
        }
    }
    
    if (scrollView.contentOffset.y < 0 && scrollView.frame.origin.y < lgBannerHeight) {
        
        CGFloat offset = scrollView.contentOffset.y;
        
        [scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
        
        frame.origin.y -= offset;
        
        if (frame.origin.y < smBannerHeight) {
            frame.origin.y = smBannerHeight;
        }
        if (frame.origin.y > lgBannerHeight) {
            frame.origin.y = lgBannerHeight;
        }
        scrollView.frame = frame;
    }
    
    
    [self _stepProgress];
}



#pragma mark - UI Elements

- (ITBannerTableView*) contentTableView {
    if (!_contentTableView) {
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        CGFloat bottomToolBarHeight = [(AppDelegate*)[UIApplication sharedApplication].delegate bottomTabBarHeight];
        CGFloat width = screenBounds.size.width;
        CGFloat height = screenBounds.size.height - smBannerHeight - bottomToolBarHeight;
        CGRect tableViewFrame = CGRectMake(0, lgBannerHeight, width, height);
        _contentTableView = [[ITBannerTableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain];
        _contentTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _contentTableView.delegate = self;
        _contentTableView.dataSource = self;
    }
    return _contentTableView;
}

-(ITDynamicBannerView*)bannerView {
    if (!_bannerView) {
        _bannerView = [[ITDynamicBannerView alloc] initWithText:self.bannerTitle
                                                       andImage:self.bannerImage];
    }
    return _bannerView;
}

@end
