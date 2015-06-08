//
//  EventTableViewCell.m
//  Intertwine
//
//  Created by Ben Rooke on 4/1/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "EventTableViewCell.h"
#import "Friend.h"
#import <FacebookSDK/FacebookSDK.h>
#import <QuartzCore/QuartzCore.h>

@interface EventTableViewCell ()

@property (nonatomic, strong) NSMutableArray *_attendees;
@property (nonatomic, strong) UIImageView *_openSign;
@property (nonatomic, strong) FBProfilePictureView *_creatorThumbnail;
@property (nonatomic, strong) UIButton *_comment;

@end

CGFloat outterCellHeight = 120;

CGFloat creatorDimensions = 60.0;
CGFloat spacer = 10.0;

@implementation EventTableViewCell

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    return [self initWithStyle:style reuseIdentifier:reuseIdentifier indentLength:0];
}

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier indentLength:(CGFloat)indent {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
//        self.selectionStyle = UITableViewCellSelectionStyleNone;

        UIView *container = self.contentView;
        if (indent > 0) {
            CGFloat width = CGRectGetWidth([[UIScreen mainScreen] bounds]) - (indent * 2.0);
            CGFloat height = outterCellHeight - indent;
            CGRect frame = CGRectMake(indent, indent / 2.0, width, height);
            container = [[UIView alloc] initWithFrame:frame];
            container.backgroundColor = [UIColor whiteColor];
            container.alpha = 0.95;
            container.layer.cornerRadius = 3.0;
            [self.contentView addSubview:container];
        }
        
        CGFloat leftBuffer = 20.0;
        
        UIImage *commentImage = [UIImage imageNamed:@"comment.png"];
        self._comment = [UIButton buttonWithType:UIButtonTypeCustom];
        [self._comment setBackgroundImage:commentImage forState:UIControlStateNormal];
//        [self._comment addTarget:self action:@selector(presentComment) forControlEvents:UIControlEventTouchUpInside];
        self._comment.frame = CGRectMake(320, 80, commentImage.size.width, commentImage.size.height);
        
        self.commentLabel = [[UILabel alloc] initWithFrame:CGRectMake(300, 78, 20, commentImage.size.height)];
        self.commentLabel.backgroundColor = [UIColor clearColor];
        self.commentLabel.textColor = [UIColor grayColor];
        self.commentLabel.text = @"0";
        
//        self.backgroundColor = [UIColor clearColor];
//        self.contentView.backgroundColor = [UIColor clearColor];
        self._creatorThumbnail = [[FBProfilePictureView alloc] initWithProfileID:@"0" pictureCropping:FBProfilePictureCroppingSquare];
        self._creatorThumbnail.frame = CGRectMake(leftBuffer , 20 + spacer, creatorDimensions, creatorDimensions);
        self._creatorThumbnail.layer.cornerRadius = CGRectGetWidth(self._creatorThumbnail.frame)/2;

        
        self.eventLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftBuffer  + creatorDimensions + spacer, 20 + spacer, 200, 20)];
        [self.eventLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Regular" size:20]];
        self.eventLabel.textColor = [UIColor blackColor];
        self.eventLabel.backgroundColor = [UIColor clearColor];
        
        self.friendsLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftBuffer  + creatorDimensions + spacer,
                                                                      20 + spacer + 20 + 5,
                                                                      200,
                                                                      20)];
        [self.friendsLabel setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:14]];
        self.friendsLabel.textColor = [UIColor blackColor];
        self.friendsLabel.backgroundColor = [UIColor clearColor];
        self.friendsLabel.numberOfLines = 0;
        [self setAttendeeCount:0];
        
        // Add the thumbnail to the view
        [container addSubview:self.eventLabel];
        [container addSubview:self.friendsLabel];
        [container addSubview:self._creatorThumbnail];
        [container addSubview:self._comment];
        [container addSubview:self.commentLabel];
    }
    return self;
}

- (void) presentComment {
    [self.delegate presentCommentsWithEvent:self.event];
}

- (void) setAttendees:(NSArray*)attendees {
    NSMutableArray *names = [[NSMutableArray alloc] init];
    for (Friend *attendee in attendees) {
        [names addObject:attendee.fullName];
    }
    self.friendsLabel.text = [names componentsJoinedByString:@", "];
    [self.friendsLabel sizeToFit];
}

- (void) setAttendeeCount:(NSUInteger)count {
    self.friendsLabel.text = [NSString stringWithFormat:@"%lu friends", count];
}

- (void) setCreatorThumbnailWithID:(NSString*)profileID facebook:(BOOL)isFacebook {
    if (isFacebook) {
        self._creatorThumbnail.profileID = profileID;
    }
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
