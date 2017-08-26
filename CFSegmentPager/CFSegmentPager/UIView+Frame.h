//
//  UIView+Frame.h
//  CFSegmentPager
//
//  Created by YF on 2017/8/26.
//  Copyright © 2017年 CooFree. All rights reserved.
//

typedef enum {

    LeftToRight = 0,
    TopToBottom,

} ColorDirection;

#import <UIKit/UIKit.h>

@interface UIView (Frame)
/** Get the left point of a view. */
@property (nonatomic) CGFloat left;

/** Get the top point of a view. */
@property (nonatomic) CGFloat top;

/** Get the right point of a view. */
@property (nonatomic) CGFloat right;

/** Get the bottom point of a view. */
@property (nonatomic) CGFloat bottom;


@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat centerX;
@property (nonatomic, assign) CGFloat centerY;
@property (nonatomic, assign) CGSize  size;
@property (nonatomic, assign) CGPoint origin;


/**  设置渐变色*/
- (void)setGradientColors:(NSArray *)colors direction:(ColorDirection)direction;

/**  移除所以子控件*/
- (void)removeAllSubviews;

@end
