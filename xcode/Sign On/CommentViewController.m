//
//  CommentViewController.m
//  Intertwine
//
//  Created by Ben Rooke on 4/11/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "CommentViewController.h"
#import "EventCollectionViewCell.h"
#import "EventObject.h"
#import "CommentTableViewCell.h"
#import "IntertwineManager+Events.h"
#import <FacebookSDK/FacebookSDK.h>


const NSString *kCommentCollectionIdentifier = @"commentvc_attendee";




@interface CommentObject : NSObject

@property (nonatomic, copy) NSString *comment;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) NSNumber *eventID;
@property (nonatomic, strong) Friend *commentator;

-(id)initWithUser:(Friend*)user comment:(NSString*)comment;

@end

@implementation CommentObject

-(id)initWithUser:(Friend*)user comment:(NSString*)comment {
    self = [super init];
    if (self) {
        self.commentator = user;
        self.comment = comment;
        self.textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [CommentTableViewCell commentWidth], 0)];
        self.textLabel.text = comment;
    }
    return self;
}

@end












@interface CommentViewController ()

@property (nonatomic, strong) UIControl *backgroundExit;
@property (nonatomic, strong) UIControl *dismissControlView;

@property (nonatomic, strong) UIView *splashScreen;
@property (nonatomic, strong) UILabel *commentCountLabel;
@property (nonatomic, strong) UITableView *commentsTableView;

@property (nonatomic, strong) UIView *commentBottomBox;
@property (nonatomic, strong) UIButton *postButton;

- (void)_registerForKeyboardNotifications;
- (void)_keyboardWasShown:(NSNotification*)aNotification;
- (void)_keyboardWillBeHidden:(NSNotification*)aNotification;

- (BOOL)_checkCommentLimit;
- (void)_loadComments;

- (void)_dismiss;
@end

@implementation CommentViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    // Do any additional setup after loading the view.
    self.comments = [[NSMutableArray alloc] init];

    [self.view addSubview:self.backgroundExit];
    [self.view addSubview:self.splashScreen];
    [self.view addSubview:self.commentBottomBox];
    
    [self _registerForKeyboardNotifications];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"Event title: %@", self.event.eventTitle);

    self.titleLabel.text = self.event.eventTitle;
    NSLog(@"Title label text: %@", self.titleLabel.text);
    NSLog(@"Title label frame = %@", NSStringFromCGRect(self.titleLabel.frame));
    self.commentCountLabel.text = @"0 comments";
    [self _loadComments];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Post Comment

- (void) postComment {
    BOOL success = [self _checkCommentLimit];
    if (!success)
        return;
    [IntertwineManager addComment:self.commentTextField.text forEvent:self.titleLabel.text eventNumber:self.event.eventID withResponse:nil];
    [self performSelector:@selector(_loadComments) withObject:nil afterDelay:1.0];
    self.commentTextField.text = @"";
}

- (BOOL)_checkCommentLimit {
    NSUInteger length = [self.commentTextField.text length];
    if (length > 200) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:[NSString stringWithFormat:@"Comment is too large. (%lu/200) characters.",(unsigned long)length]
                                                       delegate:nil
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
        [alert show];
        return NO;
    }
    return YES;
}


#pragma mark - Load Comments

- (void) _loadComments {
    [IntertwineManager getCommentsForEvent:self.event.eventID withReponse:^(id json, NSError *error, NSURLResponse *response) {
        if (error) {
            NSLog(@"Error occured trying to load the comments for event: %@", self.event.eventTitle);
            return;
        }
        [self.comments removeAllObjects];
        for (NSMutableDictionary *commentJSON in json) {
            /*
             * Establish the commentator first.
             * TODO: Only instantiate another friend object if the person hasn't 
             *       appeared already in the list.
             */
            NSMutableDictionary *commentatorJSON = [commentJSON objectForKey:@"user"];
            Friend *commentator = [[Friend alloc] init];
            commentator.accountID = [commentatorJSON objectForKey:@"id"];
            commentator.first = [commentatorJSON objectForKey:@"first"];
            commentator.last = [commentatorJSON objectForKey:@"last"];
            commentator.emailAddress = [commentatorJSON objectForKey:@"email"];
            commentator.facebookID = [commentatorJSON objectForKey:@"facebook_id"];

            /* Initiate the actual comment. */
            CommentObject *comment = [[CommentObject alloc] init];
            comment.comment = [commentJSON objectForKey:@"comment"];
            comment.eventID = [commentJSON objectForKey:@"event_id"];
            comment.commentator = commentator;
            
            [self.comments addObject:comment];
        }
        [self.commentsTableView reloadData];
    }];
}


#pragma mark -


- (void)_dismiss {
    if ([self.delegate respondsToSelector:@selector(shouldDismissCommentView)]) {
        [self.delegate shouldDismissCommentView];
    }
}



- (void)_registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}



#pragma mark - Keyboard Notifications

- (void)_keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    NSNumber *animationDurationNumber = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    double animationDuration = [animationDurationNumber doubleValue];
    
    [UIView animateWithDuration:animationDuration animations:^{
        CGFloat width = CGRectGetWidth(self.view.frame);
        CGFloat height = CGRectGetHeight(self.view.frame);
        self.view.frame = CGRectMake(0, 0 - kbSize.height, width, height);
    } completion:^(BOOL finished) {
        [self.view addSubview:self.dismissControlView];
    }];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)_keyboardWillBeHidden:(NSNotification*)aNotification
{
    [self.dismissControlView removeFromSuperview];
    NSNumber *animationDurationNumber = [[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    double animationDuration = [animationDurationNumber doubleValue];
    
    [UIView animateWithDuration:animationDuration animations:^{
        CGFloat width = CGRectGetWidth(self.view.frame);
        CGFloat height = CGRectGetHeight(self.view.frame);
        self.view.frame = CGRectMake(0, 0, width, height);
    }];
}







#pragma mark - Complete

- (IBAction)markCompleted:(id)sender {
    [IntertwineManager completeEvent:self.event.eventID withTitle:self.event.eventTitle withResponse:^(id json, NSError *error, NSURLResponse *response) {
        if (error) {
            NSLog(@"Error occured when trying to mark an event complete!\n%@", error);
        }
    }];
}







#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [CommentTableViewCell cellHeightForLabel:[[self.comments objectAtIndex:indexPath.row] textLabel]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.comments count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Friend *user = [(CommentObject*)[self.comments objectAtIndex:indexPath.row] commentator];
    BOOL isSelf = [user.accountID isEqualToString:[IntertwineManager getAccountID]];
    
    static NSString *identifier = @"cell";
    CommentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[CommentTableViewCell alloc] initWithReuseIdentifier:identifier andProfileID:user.facebookID isSelf:isSelf];
    }
    
    NSString *name = user.first;
    NSString *comment = [(CommentObject*)[self.comments objectAtIndex:indexPath.row] comment];
    
    cell.isSelf = isSelf;
    cell.profilePicture.profileID = user.facebookID;
    cell.nameLabel.text = name;
    cell.commentLabel.text = comment;
    
    [cell resizeCell];
    
    return cell;
}


#pragma mark - Lazy Loading

- (UIControl*)dismissControlView {
    if (!_dismissControlView) {
        CGFloat textFieldHeight = CGRectGetHeight(self.commentTextField.frame);
        CGFloat controlHeight = CGRectGetHeight([[UIScreen mainScreen] bounds]) - textFieldHeight;
        CGFloat controlWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
        _dismissControlView = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, controlWidth, controlHeight)];
        [_dismissControlView addTarget:self.commentTextField action:@selector(resignFirstResponder) forControlEvents:UIControlEventTouchUpInside];
    }
    return _dismissControlView;
}

- (UIControl*)backgroundExit {
    if (!_backgroundExit) {
        _backgroundExit = [[UIControl alloc] initWithFrame:self.view.frame];
        CGRect frame = _backgroundExit.frame;
        frame.origin.x = 0;
        frame.origin.y = 0;
        _backgroundExit.frame = frame;
        _backgroundExit.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.55];
        [_backgroundExit addTarget:self action:@selector(_dismiss) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backgroundExit;
}

- (UIView*)splashScreen {
    if (!_splashScreen) {
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        CGFloat splashWidth = CGRectGetWidth(screenBounds) - 20;
        CGFloat splashHeight = CGRectGetHeight(screenBounds) * 3.0/4.0;
        _splashScreen = [[UIView alloc] initWithFrame:CGRectMake(0, 0, splashWidth, splashHeight)];
        CGPoint center = CGPointMake(CGRectGetMidX(screenBounds), CGRectGetMidY(screenBounds));
        _splashScreen.center = center;
        _splashScreen.backgroundColor = [UIColor colorWithRed:236.0/255.0 green:244.0/255.0 blue:247.0/255.0 alpha:.9];
        _splashScreen.layer.cornerRadius = 5.0;
        _splashScreen.layer.borderWidth = 2.0;
        _splashScreen.layer.borderColor = [[UIColor blackColor] CGColor];
        [_splashScreen addSubview:self.titleLabel];
        [_splashScreen addSubview:self.commentCountLabel];
        [_splashScreen addSubview:self.commentsTableView];
    }
    return _splashScreen;
}

- (UITableView*)commentsTableView {
    if (!_commentsTableView) {
        _commentsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.commentCountLabel.frame) + 10, CGRectGetWidth(self.splashScreen.frame), CGRectGetHeight(self.splashScreen.frame) - CGRectGetMaxY(self.commentCountLabel.frame) - 10)];
        _commentsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _commentsTableView.backgroundColor = [UIColor clearColor];
        _commentsTableView.delegate = self;
        _commentsTableView.dataSource = self;
    }
    return _commentsTableView;
}

- (UILabel*)commentCountLabel {
    if (!_commentCountLabel) {
        _commentCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.titleLabel.frame), CGRectGetWidth(self.splashScreen.frame), 12)];
        _commentCountLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        _commentCountLabel.textAlignment = NSTextAlignmentCenter;
        _commentCountLabel.backgroundColor = [UIColor clearColor];
        _commentCountLabel.textColor = [UIColor colorWithRed:92.0/255.0 green:109.0/255.0 blue:120.0/255.0 alpha:1];
    }
    return _commentCountLabel;
}

- (UILabel*)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, CGRectGetWidth(self.splashScreen.frame), 40)];
        _titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:22];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = [UIColor colorWithRed:8.0/255.0 green:41.0/255.0 blue:64.0/255.0 alpha:1];
    }
    return _titleLabel;
}

- (UITextField*)commentTextField {
    if (!_commentTextField) {
        CGFloat width = CGRectGetWidth(self.commentBottomBox.frame) - CGRectGetWidth(self.postButton.frame) - 20;
        _commentTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, width, CGRectGetHeight(self.commentBottomBox.frame) - 20)];
        _commentTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _commentTextField.borderStyle = UITextBorderStyleRoundedRect;
        _commentTextField.layer.borderColor = [[UIColor blackColor] CGColor];
        _commentTextField.layer.borderWidth = 1.0;
    }
    return _commentTextField;
}

- (UIView*)commentBottomBox {
    if (!_commentBottomBox) {
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        _commentBottomBox = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(screenBounds) - 50, CGRectGetWidth(screenBounds), 50)];
        _commentBottomBox.backgroundColor = [UIColor colorWithRed:236.0/255.0 green:244.0/255.0 blue:247.0/255.0 alpha:.9];
        [_commentBottomBox addSubview:self.postButton];
        [_commentBottomBox addSubview:self.commentTextField];
    }
    return _commentBottomBox;
}

- (UIButton*)postButton {
    if (!_postButton) {
        _postButton = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat width = 55.0;
        _postButton.frame = CGRectMake(CGRectGetWidth(self.commentBottomBox.frame) - width, 5, width, CGRectGetHeight(self.commentBottomBox.frame) - 10);
        [_postButton setTitle:@"Post" forState:UIControlStateNormal];
        [_postButton setTitleColor:[UIColor colorWithRed:92.0/255.0 green:109.0/255.0 blue:120.0/255.0 alpha:1] forState:UIControlStateNormal];
        [_postButton addTarget:self action:@selector(postComment) forControlEvents:UIControlEventTouchUpInside];
        _postButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
    }
    return _postButton;
}

@end
