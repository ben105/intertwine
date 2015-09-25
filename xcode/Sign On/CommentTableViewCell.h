//
//  CommentTableViewCell.h
//  CommentsViewController
//
//  Created by Ben Rooke on 7/2/15.
//  Copyright (c) 2015 Ben Rooke. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FBProfilePictureView;

@interface CommentTableViewCell : UITableViewCell

@property (nonatomic, strong) FBProfilePictureView *profilePicture;
@property (nonatomic, strong) UIView *commentBubble;
@property (nonatomic, strong) UILabel *commentLabel;
@property (nonatomic, strong) UILabel *nameLabel;

- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier andProfileID:(NSString*)profileID isSelf:(BOOL)isSelf;

/* Resize the cell before presenting. */
- (void) resizeCell;

- (void) hideProfilePicture;

@property BOOL isSelf;

+ (CGFloat) cellHeightForLabel:(UILabel*)label;
+ (CGSize) sizeForLabel:(UILabel*)label;

/* Measuring the widths of the comment bubbles in the cells. */
+ (CGFloat) commentBubbleWidth;
+ (CGFloat) commentWidth;

@end
