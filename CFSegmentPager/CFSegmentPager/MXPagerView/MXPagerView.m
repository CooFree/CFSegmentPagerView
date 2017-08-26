// MXPagerView.m
//
// Copyright (c) 2017 Maxime Epain
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <objc/runtime.h>
#import "MXPagerView.h"

@interface MXPagerViewDelegateForwarder : NSObject <UIScrollViewDelegate>
@property (nonatomic, weak) MXPagerView *pagerView;
@property (nonatomic, weak) id<MXPagerViewDelegate> delegate;
@end

@interface MXPagerView () <UIScrollViewDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIView *> *pages;

@property (nonatomic, strong) NSMutableDictionary   *registration;
@property (nonatomic, strong) NSMutableArray        *reuseQueue;

/// 记录刚开始时的偏移量
@property (nonatomic, assign) NSInteger startOffsetX;
/// 标记按钮是否点击
@property (nonatomic, assign) BOOL isClickBtn;
@end

@implementation MXPagerView {
    CGFloat     _index;
    NSInteger   _count;
    
    MXPagerViewDelegateForwarder *_forwarder;
}

@dynamic delegate;

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    _forwarder = [[MXPagerViewDelegateForwarder alloc] init];
    _forwarder.pagerView = self;
    
    super.delegate = _forwarder;
    self.pagingEnabled = YES;
    self.scrollsToTop = NO;
    self.bounces = NO;

    self.directionalLockEnabled = YES;
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    
    self.pages = [NSMutableDictionary dictionary];
    self.registration = [NSMutableDictionary dictionary];
    self.reuseQueue = [NSMutableArray array];

    self.startOffsetX = 0;

}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (_count <= 0) {
        [self reloadData];
    }
    
    CGSize size = self.bounds.size;
    size.width = size.width * _count;
    
    if (!CGSizeEqualToSize(size, self.contentSize)) {
        self.contentSize = size;
        
        CGFloat x = self.bounds.size.width * _index;
        [super setContentOffset:CGPointMake(x, 0) animated:NO];
        
        //Layout loaded pages
        CGRect frame = CGRectZero;
        frame.size = self.bounds.size;
        for (NSNumber *key in self.pages) {
            UIView *page = self.pages[key];
            frame.origin.x = frame.size.width * [key integerValue];
            page.frame = frame;
        }
    }
}

- (void)reloadData {
    
    // Removes all current pages.
    for (NSNumber *key in self.pages) {
        UIView *page = self.pages[key];
        [page removeFromSuperview];
    }
    [self.pages removeAllObjects];
    
    //Updates index and loads the current selected page
    if ( (_count = [self.dataSource numberOfPagesInPagerView:self]) > 0) {
        _index = MIN(_index, _count - 1);
        [self loadPageAtIndex:_index];
        [self setNeedsLayout];
    }
}

- (void)showPageAtIndex:(NSInteger)index animated:(BOOL)animated {
    self.isClickBtn = YES;
    if (index >= 0 && index < _count && index != _index) {
        //The tab behavior disable animation
        animated = (self.transitionStyle == MXPagerViewTransitionStyleTab)? NO : animated;
        
        CGFloat x = self.bounds.size.width * index;
        [self setContentOffset:CGPointMake(x, 0) animated:animated];
    }
}

- (UIView *)pageAtIndex:(NSInteger)index {
    NSNumber *key = [NSNumber numberWithInteger:index];
    return self.pages[key];
}

#pragma mark Reusable Pages

- (void)registerNib:(UINib *)nib forPageReuseIdentifier:(NSString *)identifier {
    [self.registration setValue:nib forKey:identifier];
}

- (void)registerClass:(Class)pageClass forPageReuseIdentifier:(NSString *)identifier {
    [self.registration setValue:NSStringFromClass(pageClass) forKey:identifier];
}

- (UIView *)dequeueReusablePageWithIdentifier:(NSString *)identifier {
    
    UIView *page = nil;
    
    for (UIView *reuse in self.reuseQueue) {
        if ([reuse.reuseIdentifier isEqualToString:identifier]) {
            page = reuse;
            break;
        }
    }
    
    if (!page) {
        id builder = self.registration[identifier];
        NSAssert(builder, @"unable to dequeue a page with identifier %@ - must register a nib or a class for the identifier", identifier);
        
        if ([builder isKindOfClass:[UINib class]]) {
            page = [[(UINib *)builder instantiateWithOwner:nil options:nil] firstObject];
        } else if ([builder isKindOfClass:[NSString class]]) {
            page = [[NSClassFromString(builder) alloc] init];
        } else {
            page = [UIView new];
        }
        
        objc_setAssociatedObject(page, @selector(reuseIdentifier), identifier, OBJC_ASSOCIATION_COPY);
    } else {
        [self.reuseQueue removeObject:page];
        [page prepareForReuse];
    }
    
    return page;
}

#pragma mark Properties

- (id<MXPagerViewDelegate>)delegate {
    return _forwarder.delegate;
}

- (void)setDelegate:(id<MXPagerViewDelegate>)delegate {
    super.delegate = nil;
    _forwarder.delegate = delegate;
    super.delegate = _forwarder;
}

- (UIView *)selectedPage {
    NSNumber *key = [NSNumber numberWithInteger:_index];
    return self.pages[key];
}

- (NSInteger)indexForSelectedPage {
    return _index;
}

- (void)setTransitionStyle:(MXPagerViewTransitionStyle)transitionStyle {
    _transitionStyle = transitionStyle;
    //the tab behavior disable the scroll
    self.scrollEnabled = (transitionStyle != MXPagerViewTransitionStyleTab);
}

- (void)setGutterWidth:(CGFloat)gutterWidth {
    _gutterWidth = gutterWidth;
    [self setNeedsLayout];
}

- (NSArray<UIView *> *)loadedPages {
    return [self.pages allValues];
}

- (CGFloat)progress {
    CGFloat position  = self.contentOffset.x;
    CGFloat width     = self.bounds.size.width;
    
    return position / width;
}

#pragma mark Private Methods

- (void)willMovePageToIndex:(NSInteger)index {
    [self loadPageAtIndex:index];
    
    if ([self.delegate respondsToSelector:@selector(pagerView:willMoveToPage:atIndex:)]) {
        UIView *page = self.pages[@(index)];
        [self.delegate pagerView:self willMoveToPage:page atIndex:index];
    }
}

- (void)didMovePageToIndex:(NSInteger)index {
    if ([self.delegate respondsToSelector:@selector(pagerView:didMoveToPage:atIndex:)]) {
        UIView *page = self.pages[@(index)];
        [self.delegate pagerView:self didMoveToPage:page atIndex:index];
    }
    
    //The page did change, now unload hidden pages
    [self unLoadHiddenPages];
}

- (void)loadPageAtIndex:(NSInteger)index {
    
    void(^loadPage)(NSInteger index) = ^(NSInteger index) {
        
        if (!self.pages[@(index)] && (index >= 0) && (index < _count)) {
            
            //Load page
            UIView *page = [self.dataSource pagerView:self viewForPageAtIndex:index];
            
            //Layout page
            CGRect frame = CGRectZero;
            frame.size = self.bounds.size;
            frame.origin = CGPointMake(frame.size.width * index, 0);
            page.frame = frame;
            
            if ([self.delegate respondsToSelector:@selector(pagerView:willDisplayPage:atIndex:)]) {
                [self.delegate pagerView:self willDisplayPage:page atIndex:index];
            }
            
            [self addSubview:page];
            [self setNeedsLayout];
            
            //Save page
            self.pages[@(index)] = page;
        }
    };
    
    loadPage(index);
    
    //In  case of slide behavior, its loads the neighbors as well.
    if (self.transitionStyle == MXPagerViewTransitionStyleScroll) {
        loadPage(index - 1);
        loadPage(index + 1);
    }
}

- (void)unLoadHiddenPages {
    
    NSMutableArray *toUnLoad = [NSMutableArray array];
    
    for (NSNumber *key in self.pages) {
        NSInteger index = [key integerValue];
        
        if (index != _index) {
            
            //In case if slide behavior, it keeps the neighbors, otherwise it unloads all hidden pages.
            if ((self.transitionStyle == MXPagerViewTransitionStyleTab) ||
                ( (index != _index-1) && (index != _index+1) )) {
                
                UIView *page = self.pages[key];
                
                [page removeFromSuperview];
                [toUnLoad addObject:key];
                
                if (page.reuseIdentifier) {
                    [self.reuseQueue addObject:page];
                }
                
                if ([self.delegate respondsToSelector:@selector(pagerView:didEndDisplayingPage:atIndex:)]) {
                    [self.delegate pagerView:self didEndDisplayingPage:page atIndex:index];
                }
            }
        }
    }
    [self.pages removeObjectsForKeys:toUnLoad];
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
    
    if (!fmod(contentOffset.x, self.bounds.size.width)) {
        NSInteger index = contentOffset.x /self.bounds.size.width;
        
        [self willMovePageToIndex:index];
        [super setContentOffset:contentOffset animated:animated];
        
        _index = index;
        
        if(!animated) {
            [self didMovePageToIndex:index];
        }
        
    } else {
        [super setContentOffset:contentOffset animated:animated];
    }
}

#pragma mark <UIScrollViewDelegate>
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.isClickBtn = NO;
    self.startOffsetX = scrollView.contentOffset.x;
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.isClickBtn == YES) {
        return;
    }
    // 1、定义获取需要的数据
    CGFloat progress = 0;
    NSInteger originalIndex = 0;
    NSInteger targetIndex = 0;
    // 2、判断是左滑还是右滑
    CGFloat currentOffsetX = scrollView.contentOffset.x;
    CGFloat scrollViewW = scrollView.bounds.size.width;
    if (currentOffsetX > self.startOffsetX) { // 左滑
        // 1、计算 progress
        progress = currentOffsetX / scrollViewW - floor(currentOffsetX / scrollViewW);
        // 2、计算 originalIndex
        originalIndex = currentOffsetX / scrollViewW;
        // 3、计算 targetIndex
        targetIndex = originalIndex + 1;
        if (targetIndex >= _count) {
            progress = 1;
            targetIndex = originalIndex;
        }
        // 4、如果完全划过去
        if (currentOffsetX - self.startOffsetX == scrollViewW) {
            progress = 1;
            targetIndex = originalIndex;
        }
    } else { // 右滑
        // 1、计算 progress
        progress = 1 - (currentOffsetX / scrollViewW - floor(currentOffsetX / scrollViewW));
        // 2、计算 targetIndex
        targetIndex = currentOffsetX / scrollViewW;
        // 3、计算 originalIndex
        originalIndex = targetIndex + 1;
        if (originalIndex >= _count) {
            originalIndex = _count - 1;
        }
    }
    // 3、pageContentViewDelegare; 将 progress／sourceIndex／targetIndex 传递给 SGPageTitleView
    if (self.delegate && [self.delegate respondsToSelector:@selector(pageContentView:progress:originalIndex:targetIndex:)]) {
        [self.delegate pageContentView:self progress:progress originalIndex:originalIndex targetIndex:targetIndex];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger position  = scrollView.contentOffset.x;
    NSInteger width     = scrollView.bounds.size.width;
    
    _index = position / width;
    [self didMovePageToIndex:_index];
    
    if ([self.delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [self.delegate scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
    NSInteger position  = targetContentOffset->x;
    NSInteger width     = scrollView.bounds.size.width;
    
    NSInteger index = position / width;
    [self willMovePageToIndex:index];
    
    if ([self.delegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) {
        [self.delegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self didMovePageToIndex:_index];
    
    if ([self.delegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
        [self.delegate scrollViewDidEndScrollingAnimation:scrollView];
    }
}

#pragma mark <UIGestureRecognizerDelegate>

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        CGPoint velocity = [(UIPanGestureRecognizer*)gestureRecognizer velocityInView:self];
        
        //Lock vertical pan gesture.
        if (fabs(velocity.x) < fabs(velocity.y)) {
            return NO;
        }
    }
    return YES;
}

@end

@implementation UIView (ReuseIdentifier)

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [self init]) {
        objc_setAssociatedObject(self, @selector(reuseIdentifier), reuseIdentifier, OBJC_ASSOCIATION_COPY);
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [self initWithFrame:frame]) {
        objc_setAssociatedObject(self, @selector(reuseIdentifier), reuseIdentifier, OBJC_ASSOCIATION_COPY);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [self initWithCoder:aDecoder]) {
        objc_setAssociatedObject(self, @selector(reuseIdentifier), reuseIdentifier, OBJC_ASSOCIATION_COPY);
    }
    return self;
}

- (NSString *)reuseIdentifier {
    return objc_getAssociatedObject(self, @selector(reuseIdentifier));
}

- (void)prepareForReuse {
    
}

@end

@implementation MXPagerViewDelegateForwarder

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([self.pagerView respondsToSelector:aSelector]) {
        return self.pagerView;
    }
    if ([self.delegate respondsToSelector:aSelector]) {
        return self.delegate;
    }
    return [super forwardingTargetForSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([self.pagerView respondsToSelector:aSelector]) {
        return YES;
    }
    if ([self.delegate respondsToSelector:aSelector]) {
        return YES;
    }
    return [super respondsToSelector:aSelector];
}
@end
