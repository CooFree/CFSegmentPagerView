//
//  如遇到问题或有更好方案，请通过以下方式进行联系
//      QQ：1357127436
//      Email：kingsic@126.com
//      GitHub：https://github.com/kingsic/SGPagingView.git
//
//  SGPageTitleView.m
//  SGPagingViewExample
//
//  Created by kingsic on 17/4/10.
//  Copyright © 2017年 kingsic. All rights reserved.
//

#import "SGPageTitleView.h"
#import "SGPageTitleButton.h"
#import "UIView+Frame.h"

#define SGPageTitleViewWidth self.frame.size.width
#define SGPageTitleViewHeight self.frame.size.height

@interface SGPageTitleView ()
/// SGPageTitleViewDelegate
@property (nonatomic, weak) id<SGPageTitleViewDelegate> delegatePageTitleView;
/// 保存外界传递过来的标题数组
@property (nonatomic, strong) NSArray *titleArr;
/// scrollView
@property (nonatomic, strong) UIScrollView *scrollView;
/// 指示器
@property (nonatomic, strong) UIView *indicatorView;
/// 底部分割线
@property (nonatomic, strong) UIView *bottomSeparator;
/// 存储标题按钮的数组
@property (nonatomic, strong) NSMutableArray *btnMArr;
/// tempBtn
@property (nonatomic, strong) UIButton *tempBtn;
/// 记录所有按钮文字宽度
@property (nonatomic, assign) CGFloat allBtnTextWidth;
/// 记录所有子控件的宽度
@property (nonatomic, assign) CGFloat allBtnWidth;

/// 开始颜色, 取值范围 0~1
@property (nonatomic, assign) CGFloat startR;
@property (nonatomic, assign) CGFloat startG;
@property (nonatomic, assign) CGFloat startB;
/// 完成颜色, 取值范围 0~1
@property (nonatomic, assign) CGFloat endR;
@property (nonatomic, assign) CGFloat endG;
@property (nonatomic, assign) CGFloat endB;

@end

@implementation SGPageTitleView

/// 按钮之间的间距
static CGFloat const SGPageTitleViewBtnMargin = 20;
/// 指示器样式为 SGIndicatorTypeSpecial 时, 指示器长度多于按钮文字宽度的值
static CGFloat const SGIndicatorTypeSpecialMultipleLength = 20;
/// 标题文字大小
static CGFloat const SGPageTitleViewTextFont = 16;

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<SGPageTitleViewDelegate>)delegate titleNames:(NSArray *)titleNames {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.77];
        self.delegatePageTitleView = delegate;
        self.titleArr = titleNames;
        
        [self initialization];
        [self setupSubviews];
    }
    return self;
}

+ (instancetype)pageTitleViewWithFrame:(CGRect)frame delegate:(id<SGPageTitleViewDelegate>)delegate titleNames:(NSArray *)titleNames {
    return [[self alloc] initWithFrame:frame delegate:delegate titleNames:titleNames];
}

- (void)initialization {
    _isTitleGradientEffect = YES;
    _isOpenTitleTextZoom = NO;
    _isShowIndicator = YES;
    _isNeedBounces = YES;
    _isShowBottomSeparator = YES;
    _indicatorScrollStyle = SGIndicatorScrollStyleDefault;

    _selectedIndex = 0;
    _titleTextScaling = 0.1;
    _indicatorAnimationTime = 0.1;
    _indicatorHeight = 2;
}

- (void)setupSubviews {
    // 1、添加 UIScrollView
    [self addSubview:self.scrollView];
    
    // 2、添加标题按钮
    [self setupTitleButtons];
    
    // 3、添加底部分割线
    [self addSubview:self.bottomSeparator];
    
    // 4、添加指示器长度样式
    self.indicatorLengthStyle = SGIndicatorLengthStyleDefault;
}

#pragma mark - - - layoutSubviews
- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 选中按钮下标初始值
    UIButton *lastBtn = self.btnMArr.lastObject;
    if (lastBtn.tag >= _selectedIndex && _selectedIndex >= 0) {
        [self btnAction:self.btnMArr[_selectedIndex]];
        _selectedIndex = -1; // 说明：这里的 -1；随便设或者大于 lastBtn 的 tag 值也可
    } else {
        return;
    }
}

#pragma mark - - - 懒加载
- (NSArray *)titleArr {
    if (!_titleArr) {
        _titleArr = [NSArray array];
    }
    return _titleArr;
}

- (NSMutableArray *)btnMArr {
    if (!_btnMArr) {
        _btnMArr = [NSMutableArray array];
    }
    return _btnMArr;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.alwaysBounceHorizontal = YES;
        _scrollView.frame = CGRectMake(0, 0, SGPageTitleViewWidth, SGPageTitleViewHeight);
    }
    return _scrollView;
}

- (UIView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIView alloc] init];
        _indicatorView.backgroundColor = [UIColor redColor];
    }
    return _indicatorView;
}

- (UIView *)bottomSeparator {
    if (!_bottomSeparator) {
        _bottomSeparator = [[UIView alloc] init];
        CGFloat bottomSeparatorW = self.frame.size.width;
        CGFloat bottomSeparatorH = 0.5;
        CGFloat bottomSeparatorX = 0;
        CGFloat bottomSeparatorY = self.frame.size.height - bottomSeparatorH;
        _bottomSeparator.frame = CGRectMake(bottomSeparatorX, bottomSeparatorY, bottomSeparatorW, bottomSeparatorH);
        _bottomSeparator.backgroundColor = [UIColor lightGrayColor];
    }
    return _bottomSeparator;
}

/// 计算字符串宽度
- (CGFloat)widthWithString:(NSString *)string font:(UIFont *)font {
    NSDictionary *attrs = @{NSFontAttributeName : font};
    return [string boundingRectWithSize:CGSizeMake(0, 0) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size.width;
}

#pragma mark - - - 添加标题按钮
- (void)setupTitleButtons {
    // 计算所有按钮的文字宽度
    [self.titleArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat tempWidth = [self widthWithString:obj font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]];
        self.allBtnTextWidth += tempWidth;
    }];
    // 所有按钮文字宽度 ＋ 按钮之间的间隔
    self.allBtnWidth = SGPageTitleViewBtnMargin * (self.titleArr.count + 1) + self.allBtnTextWidth;
    self.allBtnWidth = ceilf(self.allBtnWidth);
    
    NSInteger titleCount = self.titleArr.count;
    if (self.allBtnWidth <= self.bounds.size.width) { /// SGPageTitleView 不可滚动
        CGFloat btnY = 0;
        CGFloat btnW = SGPageTitleViewWidth / self.titleArr.count;
        CGFloat btnH = SGPageTitleViewHeight - self.indicatorHeight;
        for (NSInteger index = 0; index < titleCount; index++) {
            //UIButton *btn = [UIButton buttonWithType:(UIButtonTypeCustom)];
            
            SGPageTitleButton *btn = [[SGPageTitleButton alloc] init];
            CGFloat btnX = btnW * index;
            btn.frame = CGRectMake(btnX, btnY, btnW, btnH);
            btn.tag = index;
            btn.titleLabel.font = [UIFont systemFontOfSize:SGPageTitleViewTextFont];
            [btn setTitle:self.titleArr[index] forState:(UIControlStateNormal)];
            [btn setTitleColor:[UIColor blackColor] forState:(UIControlStateNormal)];
            [btn setTitleColor:[UIColor redColor] forState:(UIControlStateSelected)];
            [btn addTarget:self action:@selector(btnAction:) forControlEvents:(UIControlEventTouchUpInside)];
            [self.btnMArr addObject:btn];
            [self.scrollView addSubview:btn];
        }
        self.scrollView.contentSize = CGSizeMake(SGPageTitleViewWidth, SGPageTitleViewHeight);
        
    } else { /// SGPageTitleView 可滚动
        CGFloat btnX = 0;
        CGFloat btnY = 0;
        CGFloat btnH = SGPageTitleViewHeight - self.indicatorHeight;
        for (NSInteger index = 0; index < titleCount; index++) {
            UIButton *btn = [UIButton buttonWithType:(UIButtonTypeCustom)];
            CGFloat btnW = [self widthWithString:self.titleArr[index] font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]] + SGPageTitleViewBtnMargin;
            btn.frame = CGRectMake(btnX, btnY, btnW, btnH);
            btnX = btnX + btnW;
            btn.tag = index;
            btn.titleLabel.font = [UIFont systemFontOfSize:SGPageTitleViewTextFont];
            [btn setTitle:self.titleArr[index] forState:(UIControlStateNormal)];
            [btn setTitleColor:[UIColor blackColor] forState:(UIControlStateNormal)];
            [btn setTitleColor:[UIColor redColor] forState:(UIControlStateSelected)];
            [btn addTarget:self action:@selector(btnAction:) forControlEvents:(UIControlEventTouchUpInside)];
            [self.btnMArr addObject:btn];
            [self.scrollView addSubview:btn];
        }
        CGFloat scrollViewWidth = CGRectGetMaxX(self.scrollView.subviews.lastObject.frame);
        self.scrollView.contentSize = CGSizeMake(scrollViewWidth, SGPageTitleViewHeight);
    }
}

/// 标题按钮的点击事件
- (void)btnAction:(UIButton *)button {
    
    // 1、改变按钮的选择状态
    [self changeSelectedButton:button];
    
    // 2、滚动标题选中居中
    if (self.allBtnWidth > SGPageTitleViewWidth) {
        [self selectedBtnCenter:button];
    }
    
    // 3、改变指示器的位置
    [self changeIndicatorViewLocationWithButton:button];
    
    // 4、pageTitleViewDelegate
    if ([self.delegatePageTitleView respondsToSelector:@selector(pageTitleView:selectedIndex:)]) {
        [self.delegatePageTitleView pageTitleView:self selectedIndex:button.tag];
    }
}

/// 改变按钮的选择状态
- (void)changeSelectedButton:(UIButton *)button {
    if (self.tempBtn == nil) {
        button.selected = YES;
        self.tempBtn = button;
    } else if (self.tempBtn != nil && self.tempBtn == button){
        button.selected = YES;
    } else if (self.tempBtn != button && self.tempBtn != nil){
        self.tempBtn.selected = NO;
        button.selected = YES;
        self.tempBtn = button;
    }
    
    // 标题文字缩放属性
    if (self.isOpenTitleTextZoom) {
        [self.btnMArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UIButton *btn = obj;
            btn.transform = CGAffineTransformMakeScale(1, 1);
        }];
        button.transform = CGAffineTransformMakeScale(1 + self.titleTextScaling, 1 + self.titleTextScaling);
    }
}

/// 滚动标题选中居中
- (void)selectedBtnCenter:(UIButton *)centerBtn {
    // 计算偏移量
    CGFloat offsetX = centerBtn.center.x - SGPageTitleViewWidth * 0.5;
    
    if (offsetX < 0) offsetX = 0;
    
    // 获取最大滚动范围
    CGFloat maxOffsetX = self.scrollView.contentSize.width - SGPageTitleViewWidth;
    
    if (offsetX > maxOffsetX) offsetX = maxOffsetX;
    
    // 滚动标题滚动条
    [self.scrollView setContentOffset:CGPointMake(offsetX, 0) animated:YES];
}

/// 改变指示器的位置
- (void)changeIndicatorViewLocationWithButton:(UIButton *)button {
    if (self.allBtnWidth <= self.bounds.size.width) { /// SGPageTitleView 不可滚动
        [UIView animateWithDuration:_indicatorAnimationTime animations:^{
            if (self.indicatorLengthStyle == SGIndicatorLengthStyleEqual) {
                self.indicatorView.width = [self widthWithString:button.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]];
                
            } else if (self.indicatorLengthStyle == SGIndicatorLengthStyleSpecial) {
                self.indicatorView.width = [self widthWithString:button.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]] + SGIndicatorTypeSpecialMultipleLength;
                
            } else {
                self.indicatorView.width = button.width;
            }
            self.indicatorView.centerX = button.centerX;
        }];
        
    } else { /// SGPageTitleView 可滚动
        [UIView animateWithDuration:_indicatorAnimationTime animations:^{
            if (self.indicatorLengthStyle == SGIndicatorLengthStyleEqual) {
                self.indicatorView.width = button.width - SGPageTitleViewBtnMargin;
                
            } else {
                self.indicatorView.width = button.width;
            }
            self.indicatorView.centerX = button.centerX;
        }];
    }
}

/// 给外界提供的方法
- (void)setPageTitleViewWithProgress:(CGFloat)progress originalIndex:(NSInteger)originalIndex targetIndex:(NSInteger)targetIndex {
    // 1、取出 originalBtn／targetBtn
    UIButton *originalBtn = self.btnMArr[originalIndex];
    UIButton *targetBtn = self.btnMArr[targetIndex];
    
    // 2、 滚动标题选中居中
    [self selectedBtnCenter:targetBtn];
    
    // 3、处理指示器的逻辑
    if (self.allBtnWidth <= self.bounds.size.width) { /// SGPageTitleView 不可滚动
        if (self.indicatorScrollStyle == SGIndicatorScrollStyleHalf) {
            [self smallIndicatorScrollStyleHalfEndWithProgress:progress originalBtn:originalBtn targetBtn:targetBtn];
            
        } else if (self.indicatorScrollStyle == SGIndicatorScrollStyleEnd) {
            [self smallIndicatorScrollStyleHalfEndWithProgress:progress originalBtn:originalBtn targetBtn:targetBtn];
            
        } else {
            [self smallIndicatorScrollStyleDefaultWithProgress:progress originalBtn:originalBtn targetBtn:targetBtn];
        }

    } else { /// SGPageTitleView 可滚动
        if (self.indicatorScrollStyle == SGIndicatorScrollStyleHalf) {
            [self indicatorScrollStyleHalfEndWithProgress:progress originalBtn:originalBtn targetBtn:targetBtn];
            
        } else if (self.indicatorScrollStyle == SGIndicatorScrollStyleEnd) {
            [self indicatorScrollStyleHalfEndWithProgress:progress originalBtn:originalBtn targetBtn:targetBtn];
            
        } else {
            [self indicatorScrollStyleDefaultWithProgress:progress originalBtn:originalBtn targetBtn:targetBtn];
        }
    }
    
    // 4、颜色的渐变(复杂)
    if (self.isTitleGradientEffect) {
        [self isTitleGradientEffectWithProgress:progress originalBtn:originalBtn targetBtn:targetBtn];
    }
    
    // 5 、标题文字缩放属性
    if (self.isOpenTitleTextZoom) {
        // 左边缩放
        originalBtn.transform = CGAffineTransformMakeScale((1 - progress) * self.titleTextScaling + 1, (1 - progress) * self.titleTextScaling + 1);
        // 右边缩放
        targetBtn.transform = CGAffineTransformMakeScale(progress * self.titleTextScaling + 1, progress * self.titleTextScaling + 1);
    }
}

/// SGPageTitleView 不可滚动
- (void)smallIndicatorScrollStyleDefaultWithProgress:(CGFloat)progress originalBtn:(UIButton *)originalBtn targetBtn:(UIButton *)targetBtn {
    // 1、改变按钮的选择状态
    if (progress >= 0.8) { /// 此处取 >= 0.8 而不是 1.0 为的是防止用户滚动过快而按钮的选中状态并没有改变
        [self changeSelectedButton:targetBtn];
    }
    
    if (self.indicatorLengthStyle == SGIndicatorLengthStyleEqual) {
        /// 计算 targetBtn／originalBtn 之间的距离
        CGFloat targetBtnX = CGRectGetMaxX(targetBtn.frame) - [self widthWithString:targetBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]] - 0.5 * (self.width / self.titleArr.count - [self widthWithString:targetBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]]);
        CGFloat originalBtnX = CGRectGetMaxX(originalBtn.frame) - [self widthWithString:originalBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]] - 0.5 * (self.width / self.titleArr.count - [self widthWithString:originalBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]]);
        CGFloat totalOffsetX = targetBtnX - originalBtnX;
        
        /// 计算 targetBtn／originalBtn 宽度的差值
        CGFloat targetBtnDistance = (CGRectGetMaxX(targetBtn.frame) - 0.5 * (self.width / self.titleArr.count - [self widthWithString:targetBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]]));
        CGFloat originalBtnDistance = (CGRectGetMaxX(originalBtn.frame) - 0.5 * (self.width / self.titleArr.count - [self widthWithString:originalBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]]));
        CGFloat totalDistance = targetBtnDistance - originalBtnDistance;
        
        /// 计算 indicatorView 滚动时 X 的偏移量
        CGFloat offsetX;
        /// 计算 indicatorView 滚动时宽度的偏移量
        CGFloat distance;
        offsetX = totalOffsetX * progress;
        distance = progress * (totalDistance - totalOffsetX);
        
        /// 计算 indicatorView 新的 frame
        self.indicatorView.x = originalBtnX + offsetX;
        self.indicatorView.width = [self widthWithString:originalBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]] + distance;
        
    } else if (self.indicatorLengthStyle == SGIndicatorLengthStyleSpecial) {
        CGFloat targetBtnX = CGRectGetMaxX(targetBtn.frame) - [self widthWithString:targetBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]] - 0.5 * (self.width / self.titleArr.count - [self widthWithString:targetBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]] + SGIndicatorTypeSpecialMultipleLength);
        CGFloat originalBtnX = CGRectGetMaxX(originalBtn.frame) - [self widthWithString:originalBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]] - 0.5 * (self.width / self.titleArr.count - [self widthWithString:originalBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]] + SGIndicatorTypeSpecialMultipleLength);
        CGFloat totalOffsetX = targetBtnX - originalBtnX;
        
        /// 计算 targetBtn／originalBtn 宽度的差值
        CGFloat targetBtnDistance = (CGRectGetMaxX(targetBtn.frame) - 0.5 * (self.width / self.titleArr.count - [self widthWithString:targetBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]]));
        CGFloat originalBtnDistance = (CGRectGetMaxX(originalBtn.frame) - 0.5 * (self.width / self.titleArr.count - [self widthWithString:originalBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]]));
        CGFloat totalDistance = targetBtnDistance - originalBtnDistance;
        
        /// 计算 indicatorView 滚动时 X 的偏移量
        CGFloat offsetX;
        /// 计算 indicatorView 滚动时宽度的偏移量
        CGFloat distance;
        offsetX = totalOffsetX * progress;
        distance = progress * (totalDistance - totalOffsetX);
        
        /// 计算 indicatorView 新的 frame
        self.indicatorView.x = originalBtnX + offsetX;
        self.indicatorView.width = [self widthWithString:originalBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]] + distance + SGIndicatorTypeSpecialMultipleLength;
        
    } else {
        // 3、处理指示器的逻辑
        CGFloat moveTotalX = targetBtn.origin.x - originalBtn.origin.x;
        CGFloat moveX = moveTotalX * progress;
        self.indicatorView.centerX = originalBtn.centerX + moveX;
    }
}
/// SGPageTitleView 不可滚动
- (void)smallIndicatorScrollStyleHalfEndWithProgress:(CGFloat)progress originalBtn:(UIButton *)originalBtn targetBtn:(UIButton *)targetBtn {
    if (self.indicatorScrollStyle == SGIndicatorScrollStyleHalf) {
        if (progress >= 0.5) {
            [UIView animateWithDuration:_indicatorAnimationTime animations:^{
                if (self.indicatorLengthStyle == SGIndicatorLengthStyleEqual) {
                    self.indicatorView.width = [self widthWithString:targetBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]];
                } else if (self.indicatorLengthStyle == SGIndicatorLengthStyleSpecial) {
                    self.indicatorView.width = [self widthWithString:targetBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]] + SGIndicatorTypeSpecialMultipleLength;
                } else {
                    self.indicatorView.width = targetBtn.width;
                }
                self.indicatorView.centerX = targetBtn.centerX;
            }];
            
            [self changeSelectedButton:targetBtn];
        } else {
            [UIView animateWithDuration:_indicatorAnimationTime animations:^{
                if (self.indicatorLengthStyle == SGIndicatorLengthStyleEqual) {
                    self.indicatorView.width = [self widthWithString:originalBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]];
                } else if (self.indicatorLengthStyle == SGIndicatorLengthStyleSpecial) {
                    self.indicatorView.width = [self widthWithString:originalBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]] + SGIndicatorTypeSpecialMultipleLength;
                } else {
                    self.indicatorView.width = originalBtn.width;
                }
                self.indicatorView.centerX = originalBtn.centerX;
            }];
            
            [self changeSelectedButton:originalBtn];
        }

    } else {
        if (progress == 1.0) {
            [UIView animateWithDuration:_indicatorAnimationTime animations:^{
                if (self.indicatorLengthStyle == SGIndicatorLengthStyleEqual) {
                    self.indicatorView.width = [self widthWithString:targetBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]];
                } else if (self.indicatorLengthStyle == SGIndicatorLengthStyleSpecial) {
                    self.indicatorView.width = [self widthWithString:targetBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]] + SGIndicatorTypeSpecialMultipleLength;
                } else {
                    self.indicatorView.width = targetBtn.width;
                }
                self.indicatorView.centerX = targetBtn.centerX;
            }];
            
            [self changeSelectedButton:targetBtn];
        } else {
            [UIView animateWithDuration:_indicatorAnimationTime animations:^{
                if (self.indicatorLengthStyle == SGIndicatorLengthStyleEqual) {
                    self.indicatorView.width = [self widthWithString:originalBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]];
                } else if (self.indicatorLengthStyle == SGIndicatorLengthStyleSpecial) {
                    self.indicatorView.width = [self widthWithString:originalBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]] + SGIndicatorTypeSpecialMultipleLength;
                } else {
                    self.indicatorView.width = originalBtn.width;
                }
                self.indicatorView.centerX = originalBtn.centerX;
            }];
            
            [self changeSelectedButton:originalBtn];
        }
    }
}

/// SGPageTitleView 可滚动
- (void)indicatorScrollStyleDefaultWithProgress:(CGFloat)progress originalBtn:(UIButton *)originalBtn targetBtn:(UIButton *)targetBtn {
    /// 改变按钮的选择状态
    if (progress >= 0.8) { /// 此处取 >= 0.8 而不是 1.0 为的是防止用户滚动过快而按钮的选中状态并没有改变
        [self changeSelectedButton:targetBtn];
    }
    
    /// 计算 targetBtn／originalBtn 之间的距离
    CGFloat totalOffsetX = targetBtn.origin.x - originalBtn.origin.x;
    /// 计算 targetBtn／originalBtn 宽度的差值
    CGFloat totalDistance = CGRectGetMaxX(targetBtn.frame) - CGRectGetMaxX(originalBtn.frame);
    /// 计算 indicatorView 滚动时 X 的偏移量
    CGFloat offsetX;
    /// 计算 indicatorView 滚动时宽度的偏移量
    CGFloat distance;
    if (self.indicatorLengthStyle == SGIndicatorLengthStyleEqual) {
        offsetX = totalOffsetX * progress + 0.5 * SGPageTitleViewBtnMargin;
        distance = progress * (totalDistance - totalOffsetX) - SGPageTitleViewBtnMargin;
    } else {
        offsetX = totalOffsetX * progress;
        distance = progress * (totalDistance - totalOffsetX);
    }
    /// 计算 indicatorView 新的 frame
    self.indicatorView.x = originalBtn.origin.x + offsetX;
    self.indicatorView.width = originalBtn.width + distance;
}
/// SGPageTitleView 可滚动
- (void)indicatorScrollStyleHalfEndWithProgress:(CGFloat)progress originalBtn:(UIButton *)originalBtn targetBtn:(UIButton *)targetBtn {
    if (self.indicatorScrollStyle == SGIndicatorScrollStyleHalf) {
        if (progress >= 0.5) {
            [UIView animateWithDuration:_indicatorAnimationTime animations:^{
                if (self.indicatorLengthStyle == SGIndicatorLengthStyleEqual) {
                    self.indicatorView.width = targetBtn.width - SGPageTitleViewBtnMargin;
                } else {
                    self.indicatorView.width = targetBtn.width;
                }
                self.indicatorView.centerX = targetBtn.centerX;
            }];
            
            [self changeSelectedButton:targetBtn];
        } else {
            [UIView animateWithDuration:_indicatorAnimationTime animations:^{
                if (self.indicatorLengthStyle == SGIndicatorLengthStyleEqual) {
                    self.indicatorView.width = originalBtn.width - SGPageTitleViewBtnMargin;
                } else {
                    self.indicatorView.width = originalBtn.width;
                }
                self.indicatorView.centerX = originalBtn.centerX;
            }];
            
            [self changeSelectedButton:originalBtn];
        }
    } else {
        if (progress == 1.0) {
            [UIView animateWithDuration:_indicatorAnimationTime animations:^{
                if (self.indicatorLengthStyle == SGIndicatorLengthStyleEqual) {
                    self.indicatorView.width = targetBtn.width - SGPageTitleViewBtnMargin;
                } else {
                    self.indicatorView.width = targetBtn.width;
                }
                self.indicatorView.centerX = targetBtn.centerX;
                
                [self changeSelectedButton:targetBtn];
            }];
            
        } else {
            [UIView animateWithDuration:_indicatorAnimationTime animations:^{
                if (self.indicatorLengthStyle == SGIndicatorLengthStyleEqual) {
                    self.indicatorView.width = originalBtn.width - SGPageTitleViewBtnMargin;
                } else {
                    self.indicatorView.width = originalBtn.width;
                }
                self.indicatorView.centerX = originalBtn.centerX;
                
                [self changeSelectedButton:originalBtn];
            }];
        }
    }
}

/// 颜色渐变方法抽取
- (void)isTitleGradientEffectWithProgress:(CGFloat)progress originalBtn:(UIButton *)originalBtn targetBtn:(UIButton *)targetBtn {
    if (self.titleColorStateSelected) {
        // 获取 targetProgress
        CGFloat targetProgress = progress;
        // 获取 originalProgress
        CGFloat originalProgress = 1 - targetProgress;
        
        CGFloat r = self.endR - self.startR;
        CGFloat g = self.endG - self.startG;
        CGFloat b = self.endB - self.startB;
        UIColor *originalColor = [UIColor colorWithRed:self.startR +  r * originalProgress  green:self.startG +  g * originalProgress  blue:self.startB +  b * originalProgress alpha:1];
        UIColor *targetColor = [UIColor colorWithRed:self.startR + r * targetProgress green:self.startG + g * targetProgress blue:self.startB + b * targetProgress alpha:1];
        
        // 设置文字颜色渐变
        originalBtn.titleLabel.textColor = originalColor;
        targetBtn.titleLabel.textColor = targetColor;
        
    } else {
        originalBtn.titleLabel.textColor = [UIColor colorWithRed:1 - progress green:0 blue:0 alpha:1];
        targetBtn.titleLabel.textColor = [UIColor colorWithRed:progress green:0 blue:0 alpha:1];
    }
}

#pragma mark - - - set
- (void)setIsNeedBounces:(BOOL)isNeedBounces {
    _isNeedBounces = isNeedBounces;
    if (isNeedBounces == NO) {
        self.scrollView.bounces = NO;
    }
}

- (void)setTitleColorStateNormal:(UIColor *)titleColorStateNormal {
    _titleColorStateNormal = titleColorStateNormal;
    [self.btnMArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIButton *btn = obj;
        [btn setTitleColor:titleColorStateNormal forState:(UIControlStateNormal)];
    }];
    
    [self setupStartColor:titleColorStateNormal];
}

- (void)setTitleColorStateSelected:(UIColor *)titleColorStateSelected {
    _titleColorStateSelected = titleColorStateSelected;
    [self.btnMArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIButton *btn = obj;
        [btn setTitleColor:titleColorStateSelected forState:(UIControlStateSelected)];
    }];
    
    [self setupEndColor:titleColorStateSelected];
}

- (void)setIndicatorColor:(UIColor *)indicatorColor {
    _indicatorColor = indicatorColor;
    self.indicatorView.backgroundColor = indicatorColor;
}

- (void)setIndicatorHeight:(CGFloat)indicatorHeight {
    _indicatorHeight = indicatorHeight;
    
    if (indicatorHeight) {
        _indicatorHeight = indicatorHeight;
        self.indicatorView.height = indicatorHeight;
        self.indicatorView.y = self.height - indicatorHeight;
    }
}

- (void)setIndicatorAnimationTime:(CGFloat)indicatorAnimationTime {
    _indicatorAnimationTime = indicatorAnimationTime;
    
    if (indicatorAnimationTime) {
        if (indicatorAnimationTime >= 0.3) {
            _indicatorAnimationTime = 0.3;
        } else {
            _indicatorAnimationTime = indicatorAnimationTime;
        }
    }
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    
    if (selectedIndex) {
        _selectedIndex = selectedIndex;
    }
}

- (void)setResetSelectedIndex:(NSInteger)resetSelectedIndex {
    _resetSelectedIndex = resetSelectedIndex;
    
    [self btnAction:self.btnMArr[resetSelectedIndex]];
}

- (void)setIndicatorLengthStyle:(SGIndicatorLengthStyle)indicatorLengthStyle {
    _indicatorLengthStyle = indicatorLengthStyle;
    
    // 取出第一个按钮并设置指示器对应样式的宽度
    UIButton *firstBtn = self.btnMArr.firstObject;
    if (firstBtn == nil) {
        return;
    }
    
    [self.scrollView addSubview:self.indicatorView];
    
    CGFloat indicatorViewW = 0;
    CGFloat indicatorViewH = self.indicatorHeight;
    CGFloat indicatorViewX = 0;
    CGFloat indicatorViewY = self.height - indicatorViewH;
    
    if (indicatorLengthStyle == SGIndicatorLengthStyleEqual) {
        CGFloat firstBtnTextWidth = [self widthWithString:firstBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]];
        indicatorViewW = firstBtnTextWidth;
        indicatorViewX = 0.5 * (firstBtn.width - firstBtnTextWidth);
    } else if (indicatorLengthStyle == SGIndicatorLengthStyleSpecial) {
        CGFloat firstBtnIndicatorWidth = [self widthWithString:firstBtn.currentTitle font:[UIFont systemFontOfSize:SGPageTitleViewTextFont]] + SGIndicatorTypeSpecialMultipleLength;
        indicatorViewW = firstBtnIndicatorWidth;
        indicatorViewX = 0.5 * (firstBtn.width - firstBtnIndicatorWidth);
    } else {
        indicatorViewW = firstBtn.width;
        indicatorViewX = firstBtn.x;
    }
    
    _indicatorView.frame = CGRectMake(indicatorViewX, indicatorViewY, indicatorViewW, indicatorViewH);
}

- (void)setIndicatorScrollStyle:(SGIndicatorScrollStyle)indicatorScrollStyle {
    _indicatorScrollStyle = indicatorScrollStyle;
}

- (void)setIsTitleGradientEffect:(BOOL)isTitleGradientEffect {
    _isTitleGradientEffect = isTitleGradientEffect;
}

- (void)setIsOpenTitleTextZoom:(BOOL)isOpenTitleTextZoom {
    _isOpenTitleTextZoom = isOpenTitleTextZoom;
}

- (void)setTitleTextScaling:(CGFloat)titleTextScaling {
    _titleTextScaling = titleTextScaling;
    
    if (titleTextScaling) {
        if (titleTextScaling >= 0.3) {
            _titleTextScaling = 0.3;
        } else {
            _titleTextScaling = 0.1;
        }
    }
}

- (void)setIsShowIndicator:(BOOL)isShowIndicator {
    _isShowIndicator = isShowIndicator;
    if (isShowIndicator == NO) {
        [self.indicatorView removeFromSuperview];
        self.indicatorView = nil;
    }
}

- (void)setIsShowBottomSeparator:(BOOL)isShowBottomSeparator {
    _isShowBottomSeparator = isShowBottomSeparator;
    if (isShowBottomSeparator) {
        
    } else {
        [self.bottomSeparator removeFromSuperview];
        self.bottomSeparator = nil;
    }
}

/**
 *  根据下标修改标题文字
 *
 *  @param index 标题所对应的下标
 *  @param title 新标题名
 */
- (void)resetTitleWithIndex:(NSInteger)index newTitle:(NSString *)title {
    if (index < self.btnMArr.count) {
        UIButton *button = (UIButton *)self.btnMArr[index];
        [button setTitle:title forState:UIControlStateNormal];
        [self setIndicatorLengthStyle:self.indicatorLengthStyle];
    }
}

#pragma mark - - - 颜色设置的计算
/// 开始颜色设置
- (void)setupStartColor:(UIColor *)color {
    CGFloat components[3];
    [self getRGBComponents:components forColor:color];
    self.startR = components[0];
    self.startG = components[1];
    self.startB = components[2];
}

/// 结束颜色设置
- (void)setupEndColor:(UIColor *)color {
    CGFloat components[3];
    [self getRGBComponents:components forColor:color];
    self.endR = components[0];
    self.endG = components[1];
    self.endB = components[2];
}

/**
 *  指定颜色，获取颜色的RGB值
 *
 *  @param components RGB数组
 *  @param color      颜色
 */
- (void)getRGBComponents:(CGFloat [3])components forColor:(UIColor *)color {
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char resultingPixel[4];
    CGContextRef context = CGBitmapContextCreate(&resultingPixel, 1, 1, 8, 4, rgbColorSpace, 1);
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, CGRectMake(0, 0, 1, 1));
    CGContextRelease(context);
    CGColorSpaceRelease(rgbColorSpace);
    for (int component = 0; component < 3; component++) {
        components[component] = resultingPixel[component] / 255.0f;
    }
}


@end

