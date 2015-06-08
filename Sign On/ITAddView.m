//
//  ITAddView.m
//  Dynamic Banner
//
//  Created by Ben Rooke on 5/23/15.
//  Copyright (c) 2015 Intertwine. All rights reserved.
//

#import "ITAddView.h"

@interface ITAddView()

@property (nonatomic, strong) UIView *controlView;
@property (nonatomic, strong) UIImageView *addEventView;
@property (nonatomic, strong) UIImageView *randomEventView;
@property (nonatomic, strong) UIImageView *categoryView;

- (void) _expand;

/* To animate things back into place, and to cancel delay performs. */
- (void) _cleanUp;

@end


const CGFloat AddViewAnimationDuration = 0.3;

/* These constants will determine the layout of this
 * view in the toolbar. */
const CGFloat addViewWidth = 160.0;
const CGFloat addViewHeight = 124.0;
const CGFloat smallBallWidth = 25.0;
const CGFloat largeBallWidth = 32.0;
const CGFloat expandedBallWidth = 42.0;

/* Position all the subviews with these coordinates. */
const CGPoint addEventViewCenter = { 79, 102 };
const CGPoint expandedAddEventViewCenter = { 79, 29 };
#define ADD_EVENT_EXPANDED_FRAME CGRectMake( \
    expandedAddEventViewCenter.x - (expandedBallWidth / 2.0), \
    expandedAddEventViewCenter.y - (expandedBallWidth / 2.0), \
    expandedBallWidth, \
    expandedBallWidth)
#define ADD_EVENT_COLLAPSED_FRAME CGRectMake( \
    addEventViewCenter.x - (largeBallWidth / 2.0), \
    addEventViewCenter.y - (largeBallWidth / 2.0), \
    largeBallWidth, \
    largeBallWidth)

const CGPoint randomEventViewCenter = { 71, 102 };
const CGPoint expandedRandomEventViewCenter = { 24, 45 };
#define RANDOM_EVENT_EXPANDED_FRAME CGRectMake( \
    expandedRandomEventViewCenter.x - (expandedBallWidth / 2.0), \
    expandedRandomEventViewCenter.y - (expandedBallWidth / 2.0), \
    expandedBallWidth, \
    expandedBallWidth)
#define RANDOM_EVENT_COLLAPSED_FRAME CGRectMake( \
    randomEventViewCenter.x - (smallBallWidth / 2.0), \
    randomEventViewCenter.y - (smallBallWidth / 2.0), \
    smallBallWidth, \
    smallBallWidth)

const CGPoint categoryViewCenter = { 87, 102 };
const CGPoint expandedCategoryViewCenter = { 135, 45 };
#define CATEGORY_EXPANDED_FRAME CGRectMake( \
    expandedCategoryViewCenter.x - (expandedBallWidth / 2.0), \
    expandedCategoryViewCenter.y - (expandedBallWidth / 2.0), \
    expandedBallWidth, \
    expandedBallWidth)
#define CATEGORY_COLLAPSED_FRAME CGRectMake( \
    categoryViewCenter.x - (smallBallWidth / 2.0), \
    categoryViewCenter.y - (smallBallWidth / 2.0), \
    smallBallWidth, \
    smallBallWidth)


/* These values are for the contact control view. */
const CGFloat controlViewHeight = 44.0;
const CGFloat controlViewWidth = 58.0;
const CGPoint controlViewCenter = { 79, 102 };


@implementation ITAddView

#pragma mark - Class methods

+ (NSString*)selectionDescription:(AddViewSelection)selection {
    NSString *selectionString = @"";
    NSString *reason = @"No selection type was found, and no valid description could be matched to it.";
    NSException *exception = [NSException exceptionWithName:@"Invalid Argument"
                                                     reason:reason
                                                   userInfo:nil];
    switch (selection) {
        case AddEvent:
            selectionString = @"Create Event";
            break;
        case CategoryEvent:
            selectionString = @"Event Categories";
            break;
        case RandomEvent:
            selectionString = @"Random Event";
            break;
        default:
            [exception raise];
            break;
    }
    return selectionString;
}

#pragma mark - Touch Handling

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self performSelector:@selector(_expand) withObject:nil afterDelay:0.2];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.isExpanded) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_expand) object:nil];
    } else {
        
        UITouch *touch = [[event allTouches] anyObject];
        CGPoint location = [touch locationInView:self];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(fingerOverSelection:)]) {
            if (CGRectContainsPoint(ADD_EVENT_EXPANDED_FRAME, location)) {
                [self.delegate fingerOverSelection:AddEvent];
            } else if (CGRectContainsPoint(CATEGORY_EXPANDED_FRAME, location)) {
                [self.delegate fingerOverSelection:CategoryEvent];
            } else if (CGRectContainsPoint(RANDOM_EVENT_EXPANDED_FRAME, location)) {
                [self.delegate fingerOverSelection:RandomEvent];
            }
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(fingerOffSelection)]) {
            if (!CGRectContainsPoint(ADD_EVENT_EXPANDED_FRAME, location) &&
                !CGRectContainsPoint(CATEGORY_EXPANDED_FRAME, location) &&
                !CGRectContainsPoint(RANDOM_EVENT_EXPANDED_FRAME, location)) {
                [self.delegate fingerOffSelection];
            }
        }
    }
    
    [self _expand];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.isExpanded) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didMakeSelection:)]) {
            UITouch *touch = [[event allTouches] anyObject];
            CGPoint location = [touch locationInView:self];
            
            if (CGRectContainsPoint(ADD_EVENT_EXPANDED_FRAME, location)) {
                [self.delegate didMakeSelection:AddEvent];
            } else if (CGRectContainsPoint(CATEGORY_EXPANDED_FRAME, location)) {
                [self.delegate didMakeSelection:CategoryEvent];
            } else if (CGRectContainsPoint(RANDOM_EVENT_EXPANDED_FRAME, location)) {
                [self.delegate didMakeSelection:RandomEvent];
            }
        }
    }
    
    /* Clean up the view. 
     * (move things back into position. */
    [self _cleanUp];
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self _cleanUp];
}

- (void) _cleanUp {
    if (!self.isExpanded) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_expand) object:nil];
    } else {
        [self collapseAnimated:YES];
    }
}

#pragma mark - Expansion Logic

- (void) _expand {
    [self expandAnimated:YES];
}

- (void) expandAnimated:(BOOL)animated {
    if (self.isExpanded) {
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(willExpand)]) {
        [self.delegate willExpand];
    }
    if (!animated) {
        self.addEventView.frame = ADD_EVENT_EXPANDED_FRAME;
        self.randomEventView.frame = RANDOM_EVENT_EXPANDED_FRAME;
        self.categoryView.frame = CATEGORY_EXPANDED_FRAME;
    } else {
        [UIView animateWithDuration:AddViewAnimationDuration
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.addEventView.frame = ADD_EVENT_EXPANDED_FRAME;
                             self.randomEventView.frame = RANDOM_EVENT_EXPANDED_FRAME;
                             self.categoryView.frame = CATEGORY_EXPANDED_FRAME;
                         }
                         completion:nil];
    }
    self.isExpanded = YES;
}

- (void) collapseAnimated:(BOOL)animated {
    if (!self.isExpanded) {
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(willCollapse)]) {
        [self.delegate willCollapse];
    }
    if (!animated) {
        self.addEventView.frame = ADD_EVENT_COLLAPSED_FRAME;
        self.randomEventView.frame = RANDOM_EVENT_COLLAPSED_FRAME;
        self.categoryView.frame = CATEGORY_COLLAPSED_FRAME;
    } else {
        [UIView animateWithDuration:AddViewAnimationDuration
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.addEventView.frame = ADD_EVENT_COLLAPSED_FRAME;
                             self.randomEventView.frame = RANDOM_EVENT_COLLAPSED_FRAME;
                             self.categoryView.frame = CATEGORY_COLLAPSED_FRAME;
                         }
                         completion:nil];
    }
    self.isExpanded = NO;
}


#pragma mark - Initialization

-(id) init {
    self = [super initWithFrame:CGRectMake(0, 0, addViewWidth, addViewHeight)];
    if (self) {
        
        self.isExpanded = NO;
        
        self.userInteractionEnabled = YES;
        self.clipsToBounds = NO;
        // Put the views inside of the collapsed views.
        [self addSubview:self.randomEventView];
        [self addSubview:self.categoryView];
        [self addSubview:self.addEventView];
        [self addSubview:self.controlView];
    }
    return self;
}


#pragma mark - UI Elements

- (UIImageView*) addEventView {
    if (!_addEventView) {
        _addEventView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Add.png"]];
        _addEventView.contentMode = UIViewContentModeScaleAspectFit;
        _addEventView.frame = CGRectMake(0, 0, largeBallWidth, largeBallWidth);
        _addEventView.center = addEventViewCenter;
        _addEventView.layer.cornerRadius = CGRectGetWidth(_addEventView.frame) / 2.0;
    }
    return _addEventView;
}

- (UIImageView*) randomEventView {
    if (!_randomEventView) {
        _randomEventView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Dice.png"]];
        _randomEventView.contentMode = UIViewContentModeScaleAspectFit;
        _randomEventView.frame = CGRectMake(0, 0, smallBallWidth, smallBallWidth);
        _randomEventView.center = randomEventViewCenter;
        _randomEventView.layer.cornerRadius = CGRectGetWidth(_randomEventView.frame) / 2.0;
    }
    return _randomEventView;
}

- (UIImageView*) categoryView {
    if (!_categoryView) {
        _categoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Categories.png"]];
        _categoryView.contentMode = UIViewContentModeScaleAspectFit;
        _categoryView.frame = CGRectMake(0, 0, smallBallWidth, smallBallWidth);
        _categoryView.center = categoryViewCenter;
        _categoryView.layer.cornerRadius = CGRectGetWidth(_categoryView.frame) / 2.0;
    }
    return _categoryView;
}

- (UIView *) controlView {
    if (!_controlView) {
        _controlView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, controlViewWidth, controlViewHeight)];
        _controlView.center = controlViewCenter;
        _controlView.userInteractionEnabled = YES;
    }
    return _controlView;
}



@end
