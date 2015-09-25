//
//  CommentTableViewCell.m
//  CommentsViewController
//
//  Created by Ben Rooke on 7/2/15.
//  Copyright (c) 2015 Ben Rooke. All rights reserved.
//

#import "CommentTableViewCell.h"
#import "UILabel+DynamicHeight.h"
#import <FacebookSDK/FacebookSDK.h>

const CGFloat commentCellInset = 5.0;
const CGFloat bubbleMembrane = 10.0;
const CGFloat cellHeight = 45.0;
const CGFloat bubbleHeight = 34.0;
const CGFloat spaceBetweenCells = 18.0;

@interface CommentTableViewCell ()
+ (CGSize) _sizeOfMultiLineLabel:(UILabel*)label;
- (void) _setProfileSize;
- (void) _setCommentSize:(CGSize)size;
@end

@implementation CommentTableViewCell

#pragma mark - Dynamic Height methods

+ (CGFloat) commentBubbleWidth {
    return CGRectGetWidth([[UIScreen mainScreen] bounds]) - 20
    
    /* Room for the profile pic */
    - (bubbleHeight +commentCellInset*3)
    
    /*commentCellInset from the surrounding border. */
    -commentCellInset*2.0;
}

+ (CGFloat) commentWidth {
    return [CommentTableViewCell commentBubbleWidth] - (bubbleMembrane * 2.0);
}

+ (CGSize) _sizeOfMultiLineLabel:(UILabel*)label {
    /* Reset the cell comment label width, because if we're using a recycled cell,
     * then the following 'sizeOfMultiLineLabel' will fail. */
    CGRect frame = label.frame;
    frame.size.width = [CommentTableViewCell commentWidth];
    label.frame = frame;
    
    return [label sizeOfMultiLineLabel];
}

+ (CGFloat) cellHeightForLabel:(UILabel*)label {
    /* Reset the cell comment label width, because if we're using a recycled cell,
     * then the following 'sizeOfMultiLineLabel' will fail. */
    CGSize size = [CommentTableViewCell _sizeOfMultiLineLabel:label];
    if (size.height < cellHeight) {
        size.height = cellHeight;
    }
    return size.height + spaceBetweenCells + (bubbleMembrane * 2.0);
}

+ (CGSize) sizeForLabel:(UILabel*)label {
    /* Reset the cell comment label width, because if we're using a recycled cell,
     * then the following 'sizeOfMultiLineLabel' will fail. */
    CGSize size = [CommentTableViewCell _sizeOfMultiLineLabel:label];
    if (size.height < bubbleHeight) {
        size.height = bubbleHeight;
    }
    return size;
}

#pragma mark - Init

- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier andProfileID:(NSString*)profileID isSelf:(BOOL)isSelf{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:(NSString *)reuseIdentifier];
    if (self) {
        
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor clearColor];
        
        self.isSelf = isSelf;
        [self.contentView addSubview:self.profilePicture];
        self.profilePicture.profileID = profileID;
        [self.contentView addSubview:self.commentBubble];
        [self.contentView addSubview:self.nameLabel];
        [self.commentBubble addSubview:self.commentLabel];
    }
    return self;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Resizing

- (void) _setProfileSize {
    if (self.isSelf) {
        CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]) - 20;
        _profilePicture.frame = CGRectMake(screenWidth -commentCellInset - bubbleHeight, 0, bubbleHeight, bubbleHeight);
        _nameLabel.frame = CGRectMake(screenWidth -commentCellInset - bubbleHeight, bubbleHeight+1, bubbleHeight, 10);
    } else {
        _profilePicture.frame = CGRectMake(commentCellInset, 0, bubbleHeight, bubbleHeight);
        _nameLabel.frame = CGRectMake(commentCellInset, bubbleHeight+1, bubbleHeight, 10);
    }
}

- (void) _setCommentSize:(CGSize)size {
    /* Resize the comment label (text) */
    CGRect commentFrame = self.commentLabel.frame;
    commentFrame.size = size;
    self.commentLabel.frame = commentFrame;
    
    /* Resize the bubble that wraps around the comment. */    
    if (self.isSelf) {
        CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]) - 20;
        self.commentBubble.frame = CGRectMake(screenWidth -commentCellInset*2.0 - bubbleHeight - size.width - (bubbleMembrane * 2.0), 0, size.width + (bubbleMembrane * 2.0), size.height + (bubbleMembrane * 2.0));
        self.commentBubble.backgroundColor = [UIColor colorWithRed:20.0/255.0 green:81.0/255.0 blue:121.0/255.0 alpha:1];
    } else {
        self.commentBubble.frame = CGRectMake(bubbleHeight +commentCellInset*2.0, 0, size.width + (bubbleMembrane * 2.0), size.height + (bubbleMembrane * 2.0));
        self.commentBubble.backgroundColor = [UIColor whiteColor];
    }
}

- (void) resizeCell {
    CGSize labelSize = [CommentTableViewCell sizeForLabel:self.commentLabel];
    [self _setCommentSize:labelSize];
    [self _setProfileSize];
}

- (void) hideProfilePicture {
    self.profilePicture.hidden = YES;
    self.nameLabel.hidden = YES;
}

#pragma mark - Lazy Loading

- (FBProfilePictureView*) profilePicture {
    if (!_profilePicture) {
        if (self.isSelf) {
            CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
            _profilePicture = [[FBProfilePictureView alloc] initWithFrame:CGRectMake(screenWidth -commentCellInset - bubbleHeight, 0, bubbleHeight, bubbleHeight)];
        } else {
            _profilePicture = [[FBProfilePictureView alloc] initWithFrame:CGRectMake(commentCellInset, 0, bubbleHeight, bubbleHeight)];
        }
        _profilePicture.layer.cornerRadius = bubbleHeight/2.0;
        _profilePicture.layer.borderColor = [[UIColor blackColor] CGColor];
        _profilePicture.layer.borderWidth = 1.0;
    }
    return _profilePicture;
}

- (UIView*) commentBubble {
    if (!_commentBubble) {
        CGFloat width = [CommentTableViewCell commentBubbleWidth];
        if (self.isSelf) {
            CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
            _commentBubble = [[UIView alloc] initWithFrame:CGRectMake(screenWidth -commentCellInset - bubbleHeight - width, 0, width, bubbleHeight)];
            _commentBubble.backgroundColor = [UIColor colorWithRed:20.0/255.0 green:81.0/255.0 blue:121.0/255.0 alpha:1];
        } else {
            _commentBubble = [[UIView alloc] initWithFrame:CGRectMake(bubbleHeight +commentCellInset*2, 0, width, bubbleHeight)];
            _commentBubble.backgroundColor = [UIColor whiteColor];
        }
        _commentBubble.layer.cornerRadius = bubbleHeight/2.0;
        _commentBubble.layer.borderWidth = 1.0;
        _commentBubble.layer.borderColor = [[UIColor blackColor] CGColor];
    }
    return _commentBubble;
}

- (UILabel*) commentLabel {
    if (!_commentLabel) {
        CGFloat width = [CommentTableViewCell commentWidth];
        _commentLabel = [[UILabel alloc] initWithFrame:CGRectMake(bubbleMembrane, bubbleMembrane, width, bubbleHeight)];
        _commentLabel.backgroundColor = [UIColor clearColor];
        _commentLabel.numberOfLines = 0;
        if (self.isSelf) {
            _commentLabel.textColor = [UIColor whiteColor];
        }
    }
    return _commentLabel;
}

- (UILabel*) nameLabel {
    if (!_nameLabel) {
        if (self.isSelf) {
            CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
            _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(screenWidth -commentCellInset - bubbleHeight, bubbleHeight+1, bubbleHeight, 10)];
        } else {
            _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(commentCellInset, bubbleHeight+1, bubbleHeight, 10)];
        }
        _nameLabel.textColor = [UIColor blackColor];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:10];
    }
    return _nameLabel;
}

@end
