//
//  ButtonBarView.h
//  Intertwine
//
//  Created by Ben Rooke on 9/22/15.
//  Copyright © 2015 Intertwine. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IntertwineButton : UIButton
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIImageView *imageView;
-(instancetype)initWithDetail:(NSString*)detail andImage:(UIImage*)image;
@end


@interface ButtonBarView : UIView
@property (nonatomic, strong) NSArray *buttons;
-(instancetype)initWithFrame:(CGRect)frame buttonArray:(NSArray*)buttonArray;
@end
