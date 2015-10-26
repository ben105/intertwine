//
//  ButtonBarView.m
//  Intertwine
//
//  Created by Ben Rooke on 9/22/15.
//  Copyright © 2015 Intertwine. All rights reserved.
//

#import "ButtonBarView.h"
#import "UILabel+DynamicHeight.h"

const CGFloat buttonImageWidth = 32.0;
const CGFloat buttonBorderWidth = buttonImageWidth * 3.0/2.0;


const CGFloat detailLabelWidth = 100.0;
const CGFloat detailLabelHeight = 20.0;

const CGFloat spaceBetween = 10.0;
const CGFloat intertwineButtonWidth = buttonImageWidth + detailLabelWidth + spaceBetween;


@interface IntertwineButton ()
@property (nonatomic, strong) UIImage *image;
@end

@implementation IntertwineButton

@synthesize imageView = _imageView;

-(instancetype)initWithDetail:(NSString *)detail andImage:(UIImage *)image {
    self = [super initWithFrame:CGRectMake(0, 0, buttonBorderWidth, buttonBorderWidth)];
    if (self) {
        self.image = image;
        self.detailLabel.text = detail;
        self.imageView.image = image;
        self.clipsToBounds = NO;
        
        self.backgroundColor = [UIColor clearColor];
//        self.layer.borderColor = [[UIColor colorWithRed:20.0/255.0 green:81.0/255.0 blue:121.0/255.0 alpha:1.0] CGColor];
//        self.layer.borderWidth = 1.0;
//        self.layer.cornerRadius = CGRectGetWidth(self.frame) / 2.0;
        
        
        [self addSubview:self.detailLabel];
        [self addSubview:self.imageView];
    }
    return self;
}

-(UIImageView*)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, buttonImageWidth, buttonImageWidth)];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    }
    return _imageView;
}

-(UILabel*)detailLabel {
    if (!_detailLabel) {
        _detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(buttonBorderWidth + 4, CGRectGetMidY(self.imageView.frame), detailLabelWidth, detailLabelHeight)];
        _detailLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
//        _detailLabel.textColor = [UIColor colorWithRed:20.0/255.0 green:81.0/255.0 blue:121.0/255.0 alpha:1.0];
        _detailLabel.textColor = [UIColor whiteColor];
        _detailLabel.backgroundColor = [UIColor clearColor];
    }
    return _detailLabel;
}

@end


@implementation ButtonBarView

-(instancetype)initWithFrame:(CGRect)frame buttonArray:(NSArray *)buttonArray {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.buttons = buttonArray;
    }
    return self;
}

- (void)setButtons:(NSArray *)buttons {
    
    for (UIButton *button in _buttons) {
        if ((NSNull*)button == [NSNull null]) {
            continue;
        }
        [button removeFromSuperview];
    }
//    [_buttons makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _buttons = buttons;
    
    /* Let's place these buttons along the button view. */
    NSUInteger count = [self.buttons count];
    CGFloat spacing = CGRectGetWidth(self.frame) / (float)count;
    CGFloat y = CGRectGetHeight(self.frame) / 2.0;
    for (int i=0; i<[buttons count]; i++) {
        UIButton *button = [self.buttons objectAtIndex:i];
        if ((NSNull*)button == [NSNull null]) {
            continue;
        }
        CGFloat x = (spacing * 0.5) + ((float)i*spacing);
        button.center = CGPointMake(x, y);
        /* And finally, place it in the view. */
        [self addSubview:button];
    }

}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
