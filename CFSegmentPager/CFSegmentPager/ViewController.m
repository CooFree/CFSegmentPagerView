//
//  ViewController.m
//  CFSegmentPager
//
//  Created by YF on 2017/8/21.
//  Copyright © 2017年 CooFree. All rights reserved.
//

#import "ViewController.h"
#import "MXSegmentedPager.h"

#import "CoreRefreshEntry.h"
#import "UIScrollView+Extension.h"

@interface ViewController ()<MXSegmentedPagerDelegate,MXSegmentedPagerDataSource,UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UIImageView            * cover;
@property (nonatomic, strong) MXSegmentedPager  * segmentedPager;
@property (nonatomic, strong) UITableView       * tableView;
@property (nonatomic, strong) UITableView       * tableView2;
@property (nonatomic, strong) UITableView       * tableView3;

@property (nonatomic,strong) NSMutableArray *dataList;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    
    [self.view addSubview:self.segmentedPager];
    
    
    NSMutableArray *dataListM=[NSMutableArray array];
    
    for (NSInteger i=0; i<20; i++) {
        NSString *str=[NSString stringWithFormat:@"初始数据：%i",i];
        [dataListM addObject:str];
    }
    
    self.dataList=dataListM;
    
    [self.tableView reloadData];
    
    [self refreshWidgetPrepare];
    
    //会自动刷新一次
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self.tableView headerSetState:CoreHeaderViewRefreshStateRefreshing];
    });
    
    // Parallax Header
        self.segmentedPager.parallaxHeader.view = self.cover;
        self.segmentedPager.parallaxHeader.mode = MXParallaxHeaderModeBottom;
        self.segmentedPager.parallaxHeader.height = 150;
        self.segmentedPager.parallaxHeader.minimumHeight = 0;
    
    // Segmented Control customization
    //    self.segmentedPager.segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
    //    self.segmentedPager.segmentedControl.backgroundColor = [UIColor whiteColor];
    //    self.segmentedPager.segmentedControl.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor blackColor],NSFontAttributeName:[UIFont systemFontOfSize:14]};
    //    self.segmentedPager.segmentedControl.selectedTitleTextAttributes = @{NSForegroundColorAttributeName : [UIColor orangeColor],NSFontAttributeName:[UIFont systemFontOfSize:17]};
    //    self.segmentedPager.segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe;
    //    self.segmentedPager.segmentedControl.selectionIndicatorColor = [UIColor orangeColor];
    
    //    self.segmentedPager.segmentedControlEdgeInsets = UIEdgeInsetsMake(0, 30, 0, 30);
}
#pragma mark  刷新控件准备
-(void)refreshWidgetPrepare{
    
    //添加顶部刷新控件
    [self.tableView addHeaderWithTarget:self action:@selector(headerRefresh)];
    
    
    //添加底部刷新
    [self.tableView addFooterWithTarget:self action:@selector(foorterRefresh)];
}
#pragma mark 刷新专区

#pragma mark  顶部刷新
-(void)headerRefresh{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSMutableArray *dataListM=[NSMutableArray array];
        
        for (NSInteger i=0; i<20; i++) {
            NSString *str=[NSString stringWithFormat:@"初始数据：%i",i];
            [dataListM addObject:str];
        }
        [self.dataList removeAllObjects];
        [self.dataList addObjectsFromArray:dataListM];
        [self.tableView reloadData];
        [self.tableView headerSetState:CoreHeaderViewRefreshStateSuccessedResultDataShowing];
        [self.tableView footerSetState:CoreFooterViewRefreshStateNormalForContinueDragUp];
        
    });
}


#pragma mark  底部刷新
-(void)foorterRefresh{
    NSLog(@"底部刷新");
    //保存旧数据
    NSMutableArray *oldArrayM=[NSMutableArray arrayWithArray:self.dataList];
    NSInteger count=oldArrayM.count;
    
    if(count<=66){
        for (NSInteger i=count; i<count+20; i++) {
            NSString *str=[NSString stringWithFormat:@"上拉刷新的新数据：%i",i];
            [oldArrayM addObject:str];
        }
        
        self.dataList=oldArrayM;
        
        [self.tableView reloadData];
        [self.tableView footerSetState:CoreFooterViewRefreshStateSuccessedResultDataShowing];
    }else{
        [self.tableView footerSetState:CoreFooterViewRefreshStateSuccessedResultNoMoreData];
    }
    
}

- (void)viewWillLayoutSubviews {
    self.segmentedPager.frame = (CGRect){
        .origin = CGPointMake(0, 64),
        .size   = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height-64)
    };
    [super viewWillLayoutSubviews];
}

#pragma mark Properties

- (UIImageView *)cover {
    if (!_cover) {
        // Set a cover on the top of the view
        
        //        _cover = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 150)];
        UIImageView *img = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 150)];
        img.image = [UIImage imageNamed:@"WechatIMG1.jpeg"];
        _cover = img;
        //        [_cover addSubview:img];
                _cover.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }
    return _cover;
}

- (MXSegmentedPager *)segmentedPager {
    if (!_segmentedPager) {
        
        // Set a segmented pager below the cover
        _segmentedPager = [[MXSegmentedPager alloc] init];
        _segmentedPager.delegate    = self;
        _segmentedPager.dataSource  = self;
    }
    return _segmentedPager;
}

- (UITableView *)tableView {
    if (!_tableView) {
        //Add a table page
        _tableView = [[UITableView alloc] init];
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}
- (UITableView *)tableView2 {
    if (!_tableView2) {
        //Add a table page
        _tableView2 = [[UITableView alloc] init];
        _tableView2.delegate = self;
        _tableView2.dataSource = self;
    }
    return _tableView2;
}
- (UITableView *)tableView3 {
    if (!_tableView3) {
        //Add a table page
        _tableView3 = [[UITableView alloc] init];
        _tableView3.delegate = self;
        _tableView3.dataSource = self;
    }
    return _tableView3;
}

#pragma mark <MXSegmentedPagerDelegate>

- (CGFloat)heightForSegmentedControlInSegmentedPager:(MXSegmentedPager *)segmentedPager {
    return 40.f;
}

- (void)segmentedPager:(MXSegmentedPager *)segmentedPager didSelectViewWithTitle:(NSString *)title {
    NSLog(@"%@ page selected.", title);
}

- (void)segmentedPager:(MXSegmentedPager *)segmentedPager didScrollWithParallaxHeader:(MXParallaxHeader *)parallaxHeader {
    NSLog(@"progress %f", parallaxHeader.progress);
}

#pragma mark <MXSegmentedPagerDataSource>

- (NSInteger)numberOfPagesInSegmentedPager:(MXSegmentedPager *)segmentedPager {
    return 3;
}

- (NSString *)segmentedPager:(MXSegmentedPager *)segmentedPager titleForSectionAtIndex:(NSInteger)index {
    return @[@"关注",@"粉丝", @"动态"][index];
}

- (UIView *)segmentedPager:(MXSegmentedPager *)segmentedPager viewForPageAtIndex:(NSInteger)index {
    return @[self.tableView,self.tableView2, self.tableView3][index];
}

#pragma mark <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger index = (indexPath.row % 2) + 1;
    [self.segmentedPager.pager showPageAtIndex:index animated:YES];
}

#pragma mark <UITableViewDataSource>

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"第%zd行",indexPath.row];
    
    return cell;
}



@end
