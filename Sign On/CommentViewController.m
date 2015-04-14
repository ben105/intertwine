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
#import "CommentObject.h"
#import "IntertwineManager+Events.h"
#import <FacebookSDK/FacebookSDK.h>


const NSString *kCommentCollectionIdentifier = @"commentvc_attendee";

@interface CommentViewController ()
- (void)_registerForKeyboardNotifications;
- (void)_keyboardWasShown:(NSNotification*)aNotification;
- (void)_keyboardWillBeHidden:(NSNotification*)aNotification;

- (void)_loadDismissControl;
- (BOOL)_checkCommentLimit;
- (void)_loadComments;
@end

@implementation CommentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.titleLabel.text = self.event.eventTitle;
    self.comments = [[NSMutableArray alloc] init];
    
    [self.attendeesCollectionView registerClass:[EventCollectionViewCell class] forCellWithReuseIdentifier:(NSString*)kCommentCollectionIdentifier];
    [self _loadDismissControl];
    [self _registerForKeyboardNotifications];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self _loadComments];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) _loadDismissControl {
    CGFloat textFieldHeight = CGRectGetHeight(self.commentTextField.frame);
    CGFloat controlHeight = CGRectGetHeight([[UIScreen mainScreen] bounds]) - textFieldHeight;
    CGFloat controlWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    self.dismissControlView = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, controlWidth, controlHeight)];
    [self.dismissControlView addTarget:self.commentTextField action:@selector(resignFirstResponder) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Post Comment

- (IBAction) postComment {
    BOOL success = [self _checkCommentLimit];
    if (!success)
        return;
    [IntertwineManager addComment:self.commentTextField.text forEvent:self.event.eventID withResponse:^(id json, NSError *error, NSURLResponse *response) {
        if (error) {
            NSLog(@"Error posting comment!");
            [self performSelector:@selector(_loadComments) withObject:nil afterDelay:1.0];
        }
    }];
}

- (BOOL)_checkCommentLimit {
    NSUInteger length = [self.commentTextField.text length];
    if (length > 499) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:[NSString stringWithFormat:@"Comment is too large. (%lu/500) characters.",(unsigned long)length]
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


- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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



#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.comments count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    CommentObject *comment = [self.comments objectAtIndex:indexPath.row];
    NSString *text = [NSString stringWithFormat:@"%@: %@", comment.commentator.first, comment.comment];
    cell.textLabel.text = text;
    cell.textLabel.numberOfLines = 0;
    return cell;
}





#pragma mark - UICollectionView Data Source

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //You may want to create a divider to scale the size by the way..
    return CGSizeMake(60.0, 70.0);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 20, 0);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.event.attendees count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    // Attempt to get the event collection cell.
    EventCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:(NSString*)kCommentCollectionIdentifier forIndexPath:indexPath];
    
    // Pick the section type.
    // Get the account's Facebook ID.
    NSString *profileID = [[self.event.attendees objectAtIndex:indexPath.row] facebookID];
    
    if ((NSNull*)profileID == [NSNull null]) {
        profileID = @"0";
    }
    
    // Set the picture and name.
    cell.profilePicture.profileID = profileID;
    cell.nameLabel.text = [[self.event.attendees objectAtIndex:indexPath.row] first];
    cell.nameLabel.textColor = [UIColor blackColor];
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


# pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}





@end
