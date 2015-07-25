//
//  NewActivityViewController.m
//  Sign On
//
//  Created by Ben Rooke on 3/21/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "NewActivityViewController.h"
#import "Friend.h"
#import "EventCollectionViewCell.h"
#import "IntertwineManager+Events.h""
#import <FacebookSDK/FacebookSDK.h>


/* Use an OffscreenCell class to keep track of the information of
 * where cells used to be, before they flew offscreen. */
@interface OffscreenCell : NSObject
@property (nonatomic, strong) EventCollectionViewCell *cell;
@property (nonatomic) CGPoint onscreenPoint;
@end

@implementation OffscreenCell
@end


/* Here are some measurements for the cells inside the collection
 * views. Provided in the layout instances. */
const CGFloat collectionCellInteritemSpacing = 15.0;
const CGFloat collectionCellLineSpacing = 0.0;

const CGFloat headerToolbarHeight = 60.0;
const CGFloat footerToolbarHeight = 55.0;
const CGFloat titleFontSize = 24.0;

const CGFloat invitedLabelHeight = 28.0;
const CGFloat invitedLabelFontSize = 16.0;

const CGFloat lineSeparatorInset = 24.0;

const NSString *kCollectionIdentifier = @"colleciton_id";

const CGFloat distanceCellsMoveOffscreen = 800.0;

#define IntertwineColorBlue [UIColor colorWithRed:59.0/255.0 green:140.0/255.0 blue:212.0/255.0 alpha:1.0]
#define IntertwineColorOffWhite [UIColor colorWithRed:236.0/255.0 green:236.0/255.0 blue:236.0/255.0 alpha:1.0]
#define IntertwineColorDarkGray [UIColor colorWithRed:151.0/255.0 green:151.0/255.0 blue:151.0/255.0 alpha:1.0]

#define SCREEN_WIDTH CGRectGetWidth([[UIScreen mainScreen] bounds])
#define SCREEN_HEIGHT CGRectGetHeight([[UIScreen mainScreen] bounds])
#define SCREEN_MIDDLE_Y CGRectGetMidY([[UIScreen mainScreen] bounds])
#define SCREEN_MIDDLE_X CGRectGetMidX([[UIScreen mainScreen] bounds])

#define HEADER_TOOLBAR_FRAME CGRectMake(0, 0, SCREEN_WIDTH, headerToolbarHeight)
#define FOOTER_TOOLBAR_FRAME CGRectMake(-2, SCREEN_HEIGHT - footerToolbarHeight, SCREEN_WIDTH + 4.0, footerToolbarHeight)

#define LINE_SEPARATOR_FRAME CGRectMake(lineSeparatorInset, SCREEN_MIDDLE_Y, SCREEN_WIDTH - (2 * lineSeparatorInset), 1.5)

@interface NewActivityViewController ()

@property (nonatomic, strong) UILabel *addFriendsLabel;

/* We need to keep track of the cells when they're offscreen, 
 * so we can animate them back onto the screen. */
@property (nonatomic, strong) NSMutableArray *offscreenInvitedCells;
@property (nonatomic, strong) NSMutableArray *offscreenUninvitedCells;

/* Invite label, to distinguish which collection view is for the invited. */
@property (nonatomic, strong) UILabel *invitedLabel;

/* Line separator, is for aesthetically splitting the two view controllers. */
@property (nonatomic, strong) UIView *lineSeparator;

@property (nonatomic, strong) UICollectionViewFlowLayout *invitedCollectionViewLayout;
@property (nonatomic, strong) UICollectionViewFlowLayout *uninvitedCollectionViewLayout;

@property (nonatomic, strong) UIView *footerToolbar;
@property (nonatomic, strong) UIButton *doneButton;

/* We want to keep track of the keyboard notifications, because it looks better
 * to show and hide the top toolbar with the same speed as the keyboard. */
- (void) _keyboardWillShow:(NSDictionary*)userInfo;
- (void) _keyboardWillHide:(NSDictionary*)userInfo;

- (void) _titleEditMode:(BOOL)on animationSpeed:(double)duration;
- (void) _didEditTitle;

/* To close out the activity controller and add the event to Intertwine DB. */
- (void) _create;
- (void) _done;

/* Deal with beautifully displaying friends and hiding them! */
- (void) _animateCollectionViewsIn;
- (void) _animateCollectionViewsOut:(BOOL)animated;
- (void) _hideCollectionViews;
- (NSMutableArray*) _offscreenCellsForCollectionView:(UICollectionView*)collectionView;
- (CGPoint) _offscreenPointForCell:(UICollectionViewCell*)cell;
@end

@implementation NewActivityViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    self.headerToolbar.hidden = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.headerToolbar.hidden = YES;
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.alpha = 0.95;
    
    // Do any additional setup after loading the view.
    [self.invitedCollectionView registerClass:[EventCollectionViewCell class] forCellWithReuseIdentifier:(NSString*)kCollectionIdentifier];
    [self.uninvitedCollectionView registerClass:[EventCollectionViewCell class] forCellWithReuseIdentifier:(NSString*)kCollectionIdentifier];
    
    self.uninvitedFriends = [[NSMutableArray alloc] initWithArray:self.friends];
    self.invitedFriends = [[NSMutableArray alloc] init];
    
    UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_done)];
    gesture.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:gesture];
    
    [self.view addSubview:self.headerToolbar];
    [self.view addSubview:self.titleField];
    [self.view addSubview:self.footerToolbar];
    [self.view addSubview:self.doneButton];
    [self.view addSubview:self.invitedCollectionView];
    [self.view addSubview:self.uninvitedCollectionView];
    [self.view addSubview:self.invitedLabel];
    [self.view addSubview:self.lineSeparator];
    [self.view addSubview:self.addFriendsLabel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    [self.titleField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.5];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}








#pragma mark - UICollectionView Data Source

//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    //You may want to create a divider to scale the size by the way..
//    return CGSizeMake(60.0, 90.0);
//}

//- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
//                        layout:(UICollectionViewLayout*)collectionViewLayout
//        insetForSectionAtIndex:(NSInteger)section {
//    return UIEdgeInsetsMake(0, 0, 20, 0);
//}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == self.invitedCollectionView) {
        return [self.invitedFriends count];
    }
    return [self.uninvitedFriends count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    // Attempt to get the event collection cell.
    EventCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:(NSString*)kCollectionIdentifier forIndexPath:indexPath];
    
    // Start with an empty section.
    NSMutableArray *sectionArray = nil;
    
    // Pick the section type.
    if (collectionView == self.invitedCollectionView) {
        sectionArray = self.invitedFriends;
    } else {
        sectionArray = self.uninvitedFriends;
    }
    
    // Get the account's Facebook ID.
    NSString *profileID = [[sectionArray objectAtIndex:indexPath.row] facebookID];
    
    if ((NSNull*)profileID == [NSNull null]) {
        profileID = @"0";
    }
    
    // Set the picture and name.
    cell.profilePicture.profileID = profileID;
    cell.nameLabel.text = [[sectionArray objectAtIndex:indexPath.row] first];
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(0., 40.);
}


# pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.invitedCollectionView) {
        Friend *friend = [self.invitedFriends objectAtIndex:indexPath.row];
        [self.uninvitedFriends addObject:friend];
        [self.invitedFriends removeObjectAtIndex:indexPath.row];
        
        NSUInteger size = [self.uninvitedCollectionView numberOfItemsInSection:0];
        [self.uninvitedCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:size inSection:0]]];
        [self.invitedCollectionView deleteItemsAtIndexPaths:@[indexPath]];
        
    } else if (collectionView == self.uninvitedCollectionView) {
        Friend *friend = [self.uninvitedFriends objectAtIndex:indexPath.row];
        [self.invitedFriends addObject:friend];
        [self.uninvitedFriends removeObjectAtIndex:indexPath.row];
        
        NSUInteger size = [self.invitedCollectionView numberOfItemsInSection:0];
        [self.invitedCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:size inSection:0]]];
        [self.uninvitedCollectionView deleteItemsAtIndexPaths:@[indexPath]];
    }
    
    /*
     * No matter which collection view cell item was selected,
     * both collection views need to refresh.
     */
//    [self.invitedCollectionView reloadData];
//    [self.uninvitedCollectionView reloadData];
    
    if ([self.invitedCollectionView numberOfItemsInSection:0] == 0) {
        self.addFriendsLabel.hidden = NO;
    } else {
        self.addFriendsLabel.hidden = YES;
    }
}



#pragma mark - Friend Selection Display / Animate

- (void) _animateCollectionViewsIn {
    [UIView animateWithDuration:1.0
                     animations:^{
                         self.invitedLabel.hidden = NO;
                         self.lineSeparator.hidden = NO;
                         for (OffscreenCell *offscreenCell in self.offscreenUninvitedCells) {
                             EventCollectionViewCell *cell = offscreenCell.cell;
                             cell.center = offscreenCell.onscreenPoint;
                             cell.alpha = 1.0;
                         }
                         for (OffscreenCell *offscreenCell in self.offscreenInvitedCells) {
                             EventCollectionViewCell *cell = offscreenCell.cell;
                             cell.center = offscreenCell.onscreenPoint;
                             cell.alpha = 1.0;
                         }
                         if ([self.invitedCollectionView numberOfItemsInSection:0] == 0) {
                             self.addFriendsLabel.hidden = NO;
                         }
                     } completion:^(BOOL finished) {
                         self.invitedCollectionView.hidden = NO;
                         self.uninvitedCollectionView.hidden = NO;
                         for (OffscreenCell *offscreenCell in self.offscreenUninvitedCells) {
                             EventCollectionViewCell *cell = offscreenCell.cell;
                             [cell removeFromSuperview];
                             cell = nil;
                         }
                         for (OffscreenCell *offscreenCell in self.offscreenInvitedCells) {
                             EventCollectionViewCell *cell = offscreenCell.cell;
                             [cell removeFromSuperview];
                             cell = nil;
                         }
                         [self.offscreenInvitedCells removeAllObjects];
                         [self.offscreenUninvitedCells removeAllObjects];
                     }];
}

- (void) _animateCollectionViewsOut:(BOOL)animated {
    [self.offscreenInvitedCells removeAllObjects];
    [self.offscreenUninvitedCells removeAllObjects];
    
    self.offscreenUninvitedCells = [self _offscreenCellsForCollectionView:self.uninvitedCollectionView];
    self.offscreenInvitedCells = [self _offscreenCellsForCollectionView:self.invitedCollectionView];
    
    self.invitedCollectionView.hidden = YES;
    self.uninvitedCollectionView.hidden = YES;
    
    self.addFriendsLabel.hidden = YES;
    
    void (^animations)(void) = ^{
        for (OffscreenCell *offscreenCell in self.offscreenUninvitedCells) {
            EventCollectionViewCell *cell = offscreenCell.cell;
            cell.center = [self _offscreenPointForCell:cell];
            cell.alpha = 0.3;
        }
        for (OffscreenCell *offscreenCell in self.offscreenInvitedCells) {
            EventCollectionViewCell *cell = offscreenCell.cell;
            cell.center = [self _offscreenPointForCell:cell];
            cell.alpha = 0.3;
        }
        self.invitedLabel.hidden = YES;
        self.lineSeparator.hidden = YES;
    };
    
    if (animated) {
    [UIView animateWithDuration:1.0
                     animations:animations
                     completion:nil];
    } else {
        animations();
    }
}

- (void) _hideCollectionViews {
    [self _animateCollectionViewsOut:YES];
}

- (NSMutableArray*) _offscreenCellsForCollectionView:(UICollectionView*)collectionView {
    if (collectionView == nil) {
        return nil;
    }
    NSUInteger section = 0;
    NSInteger size = [collectionView numberOfItemsInSection:section];
    NSMutableArray *animatableCells = [[NSMutableArray alloc] initWithCapacity:size];
    /* Iterate through the cells. We want to create an array of cells. O(n) */
    for (unsigned i=0; i < size; i++){
        EventCollectionViewCell *cell = (EventCollectionViewCell*)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:section]];
        
        if (cell.nameLabel == nil) {
            continue;
        }
        
        CGPoint cellCenter = [self.view convertPoint:cell.center fromView:collectionView];
        
        EventCollectionViewCell *animatableCell = [[EventCollectionViewCell alloc] initWithFrame:[cell frame]];
        animatableCell.center = cellCenter;
        
        animatableCell.profilePicture.profileID = cell.profilePicture.profileID;
        animatableCell.nameLabel.text = cell.nameLabel.text;
        
        /* Add an offscreen cell object to the array. */
        OffscreenCell *offscreenCell = [[OffscreenCell alloc] init];
        offscreenCell.cell = animatableCell;
        offscreenCell.onscreenPoint = cellCenter;
        [animatableCells addObject:offscreenCell];
        
        [self.view addSubview:animatableCell];
    }
    
    return animatableCells;
}

- (CGPoint) _offscreenPointForCell:(UICollectionViewCell*)cell {
    CGPoint startingPoint = [cell center];
    CGPoint screenCenterPoint = CGPointMake(SCREEN_MIDDLE_X, SCREEN_MIDDLE_Y);
    
    CGFloat xDiff = screenCenterPoint.x - startingPoint.x;
    CGFloat yDiff = screenCenterPoint.y - startingPoint.y;
    
    CGFloat theta = atanf(xDiff / yDiff);
    CGFloat d = sqrtf(powf(xDiff, 2) + powf(yDiff, 2));
 
    CGFloat travelDistance = distanceCellsMoveOffscreen - d;
    
    CGFloat xNewDiff = travelDistance * sinf(theta);
    CGFloat yNewDiff = travelDistance * cosf(theta);
    
    /* Flip everything below the screen center point. */
    if (yDiff < 0) {
        yNewDiff *= -1;
        xNewDiff *= -1;
    }
    
    return CGPointMake(startingPoint.x - xNewDiff, startingPoint.y - yNewDiff);
}


#pragma mark - Navigational Buttons

- (void)_done {
    [self.delegate closeEventCreation];
}

- (void)_create {
    NSString *title = self.titleField.text;
    if ([title isEqualToString:@""] || !title) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Enter a title for the event."
                                                       delegate:nil
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    if ([self.invitedFriends count] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Invite at least one friend, first."
                                                       delegate:nil
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    [IntertwineManager createEvent:title withFriends:self.invitedFriends withResponse:^(id json, NSError *error, NSURLResponse *response) {
        if (error) {
            NSLog(@"An error has occurred trying to create an event!\n%@", error);
            return;
        }
        [self.delegate closeEventCreation];
    }];
    [self _done];
}

#pragma mark - Edit Title

- (void) _titleEditMode:(BOOL)isEditing animationSpeed:(double)duration{
    
    CGRect frame = self.headerToolbar.frame;
    UIColor *titleColor = [UIColor whiteColor];
    
    if (isEditing) {
        if (frame.origin.y < 0) {
            return;
        }
        frame.origin.y -= frame.size.height;
        titleColor = [UIColor blackColor];
    } else {
        if (frame.origin.y == 0) {
            return;
        }
        frame.origin.y += frame.size.height;
    }

    /* Animate the blue background off or on screen. */
    [UIView animateWithDuration:duration animations:^{
        self.headerToolbar.frame = frame;
        self.titleField.textColor = titleColor;
    }];
}

- (void) _didEditTitle {
    [self.titleField resignFirstResponder];
}


#pragma mark - Keyboard Notifications

- (void) _keyboardWillShow:(NSNotification*)notif {
    NSDictionary *userInfo = [notif userInfo];
    if ([self.titleField isFirstResponder]) {
        /* Hide the friends. */
        
        double animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        [self _titleEditMode:YES animationSpeed:animationDuration];
    }
}

- (void) _keyboardWillHide:(NSNotification*)notif {
    NSDictionary *userInfo = [notif userInfo];
    if ([self.titleField isFirstResponder]) {
        /* Show the friends. */
        [self _animateCollectionViewsIn];
        
        double animationDuration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        [self _titleEditMode:NO animationSpeed:animationDuration];
    }
}


#pragma mark - Lazy Element Loading

- (UIView*) headerToolbar {
    if (!_headerToolbar) {
        _headerToolbar = [[UIView alloc] initWithFrame:HEADER_TOOLBAR_FRAME];
        _headerToolbar.backgroundColor = IntertwineColorBlue;
    }
    return _headerToolbar;
}

- (UITextField*) titleField {
    if (!_titleField) {
        _titleField = [[UITextField alloc] initWithFrame:HEADER_TOOLBAR_FRAME];
        _titleField.backgroundColor = [UIColor clearColor];
        _titleField.textColor = [UIColor whiteColor];
        _titleField.font = [UIFont fontWithName:@"HelveticaNeue" size:titleFontSize];
        _titleField.text = @"Example Activity";
        _titleField.textAlignment = NSTextAlignmentCenter;
        _titleField.returnKeyType = UIReturnKeyDone;
        [_titleField addTarget:self action:@selector(_didEditTitle) forControlEvents:UIControlEventEditingDidEndOnExit];
        [_titleField addTarget:self action:@selector(_hideCollectionViews) forControlEvents:UIControlEventEditingDidBegin];
    }
    return _titleField;
}

- (UIView*) footerToolbar {
    if (!_footerToolbar) {
        _footerToolbar = [[UIView alloc] initWithFrame:FOOTER_TOOLBAR_FRAME];
        _footerToolbar.backgroundColor = IntertwineColorOffWhite;
        _footerToolbar.layer.borderColor = [IntertwineColorDarkGray CGColor];
        _footerToolbar.layer.borderWidth = 1.0;
    }
    return _footerToolbar;
}

- (UIButton*)doneButton {
    if (!_doneButton) {
        _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_doneButton setTitle:@"Done" forState:UIControlStateNormal];
        [_doneButton setTitleColor:IntertwineColorBlue forState:UIControlStateNormal];
        [_doneButton addTarget:self action:@selector(_create) forControlEvents:UIControlEventTouchUpInside];
        _doneButton.frame = FOOTER_TOOLBAR_FRAME;
//        _doneButton.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:22.0];
    }
    return _doneButton;
}

- (UICollectionViewFlowLayout*) uninvitedCollectionViewLayout {
    if (!_uninvitedCollectionViewLayout) {
        _uninvitedCollectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        [_uninvitedCollectionViewLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        [_uninvitedCollectionViewLayout setMinimumInteritemSpacing:collectionCellInteritemSpacing];
        [_uninvitedCollectionViewLayout setMinimumLineSpacing:collectionCellLineSpacing];
        [_uninvitedCollectionViewLayout setItemSize:CGSizeMake([EventCollectionViewCell cellWidth], [EventCollectionViewCell cellHeight])];
    }
    return _uninvitedCollectionViewLayout;
}

- (UICollectionViewFlowLayout*) invitedCollectionViewLayout {
    if (!_invitedCollectionViewLayout) {
        _invitedCollectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        [_invitedCollectionViewLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        [_invitedCollectionViewLayout setMinimumInteritemSpacing:collectionCellInteritemSpacing];
        [_invitedCollectionViewLayout setMinimumLineSpacing:collectionCellLineSpacing];
        [_invitedCollectionViewLayout setItemSize:CGSizeMake([EventCollectionViewCell cellWidth], [EventCollectionViewCell cellHeight])];
    }
    return _invitedCollectionViewLayout;
}

//TODO: Make the collection view heights dynamic; causes bug on iPhone 6 Plus at the moment.
- (UICollectionView*) invitedCollectionView {
    if (!_invitedCollectionView) {
        CGFloat width = CGRectGetWidth([[UIScreen mainScreen] bounds]);
        _invitedCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 100, width, 200) collectionViewLayout:self.invitedCollectionViewLayout]; //TODO: Change the height.
        _invitedCollectionView.delegate = self;
        _invitedCollectionView.dataSource = self;
        _invitedCollectionView.backgroundColor = [UIColor clearColor];
        _invitedCollectionView.showsHorizontalScrollIndicator = NO;
    }
    return _invitedCollectionView;
}

- (UICollectionView*) uninvitedCollectionView {
    if (!_uninvitedCollectionView) {
        CGFloat width = CGRectGetWidth([[UIScreen mainScreen] bounds]);
        _uninvitedCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 370, width, 200) collectionViewLayout:self.uninvitedCollectionViewLayout]; //TODO: Change the height.
        _uninvitedCollectionView.delegate = self;
        _uninvitedCollectionView.dataSource = self;
        _uninvitedCollectionView.backgroundColor = [UIColor clearColor];
        _uninvitedCollectionView.showsHorizontalScrollIndicator = NO;
    }
    return _uninvitedCollectionView;
}

- (UILabel*) invitedLabel {
    if (!_invitedLabel) {
        _invitedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, headerToolbarHeight, SCREEN_WIDTH, invitedLabelHeight)];
        _invitedLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:invitedLabelFontSize];
        _invitedLabel.text = @"Invited";
        _invitedLabel.textColor = IntertwineColorDarkGray;
        _invitedLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _invitedLabel;
}

- (UIView*) lineSeparator {
    if (!_lineSeparator) {
        _lineSeparator = [[UIView alloc] initWithFrame:LINE_SEPARATOR_FRAME];
        _lineSeparator.backgroundColor = IntertwineColorDarkGray;
        _lineSeparator.userInteractionEnabled = NO;
    }
    return _lineSeparator;
}

- (UILabel*) addFriendsLabel {
    if (!_addFriendsLabel) {
        CGFloat width = 180.0;
        CGFloat height = 50.0;
        _addFriendsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        _addFriendsLabel.center = self.invitedCollectionView.center;
        _addFriendsLabel.text = @"Tap on a friend below to add them!";
        _addFriendsLabel.numberOfLines = 2;
        _addFriendsLabel.textAlignment = NSTextAlignmentCenter;
        _addFriendsLabel.backgroundColor = [UIColor clearColor];
        _addFriendsLabel.hidden = YES;
        _addFriendsLabel.font = [UIFont systemFontOfSize:20.0];
    }
    return _addFriendsLabel;
}

@end
