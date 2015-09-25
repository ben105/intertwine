//
//  ButtonBarView.m
//  Intertwine
//
//  Created by Ben Rooke on 9/22/15.
//  Copyright © 2015 Intertwine. All rights reserved.
//

#import "ButtonBarView.h"
#import "UILabel+DynamicHeight.h"

const CGFloat buttonImageWidth = 25.0;
const CGFloat detailLabelWidth = 100.0;
const CGFloat spaceBetween = 10.0;
const CGFloat intertwineButtonWidth = buttonImageWidth + detailLabelWidth + spaceBetween;


@implementation IntertwineButton

@synthesize imageView = _imageView;

-(instancetype)initWithDetail:(NSString *)detail andImage:(UIImage *)image {
    self = [super initWithFrame:CGRectMake(0, 0, intertwineButtonWidth, buttonImageWidth)];
    if (self) {
        self.detailLabel.text = detail;
        self.imageView.image = image;
        
        CGSize trueLabelSize = [self.detailLabel sizeOfMultiLineLabel];
        CGRect buttonFrame = self.frame;
        buttonFrame.size.width = trueLabelSize.width + spaceBetween + buttonImageWidth;
        self.frame = buttonFrame;
        
        [self addSubview:self.detailLabel];
        [self addSubview:self.imageView];
    }
    return self;
}

-(UIImageView*)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, buttonImageWidth, buttonImageWidth)];
    }
    return _imageView;
}

-(UILabel*)detailLabel {
    if (!_detailLabel) {
        _detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(buttonImageWidth + spaceBetween, 0, detailLabelWidth, buttonImageWidth)];
        _detailLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
        _detailLabel.textColor = [UIColor colorWithRed:8.0/255.0 green:41.0/255.0 blue:64.0/255.0 alpha:1.0];
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
    
    [_buttons makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _buttons = buttons;
    
    /* Let's place these buttons along the button view. */
    NSUInteger count = [self.buttons count];
    CGFloat spacing = CGRectGetWidth(self.frame) / (float)count;
    CGFloat y = CGRectGetHeight(self.frame) / 2.0;
    for (int i=0; i<[buttons count]; i++) {
        UIButton *button = [self.buttons objectAtIndex:i];
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
