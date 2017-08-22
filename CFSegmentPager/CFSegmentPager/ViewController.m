//
//  ViewController.m
//  CFSegmentPager
//
//  Created by YF on 2017/8/21.
//  Copyright © 2017年 CooFree. All rights reserved.
//

#import "ViewController.h"
#import "MXSegmentedPager.h"

@interface ViewController ()<MXSegmentedPagerDelegate,MXSegmentedPagerDataSource,UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UIView            * cover;
@property (nonatomic, strong) MXSegmentedPager  * segmentedPager;
@property (nonatomic, strong) UITableView       * tableView;
@property (nonatomic, strong) UITableView       * tableView2;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;

    [self.view addSubview:self.segmentedPager];

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

- (void)viewWillLayoutSubviews {
    self.segmentedPager.frame = (CGRect){
        .origin = CGPointMake(0, 64),
        .size   = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height-64)
    };
    [super viewWillLayoutSubviews];
}

#pragma mark Properties

- (UIView *)cover {
    if (!_cover) {
        // Set a cover on the top of the view

        _cover = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 150)];
        _cover.backgroundColor = [UIColor lightGrayColor];
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
    return 2;
}

- (NSString *)segmentedPager:(MXSegmentedPager *)segmentedPager titleForSectionAtIndex:(NSInteger)index {
    return @[@"Table", @"Web"][index];
}

- (UIView *)segmentedPager:(MXSegmentedPager *)segmentedPager viewForPageAtIndex:(NSInteger)index {
    return @[self.tableView, self.tableView2][index];
}

#pragma mark <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSInteger index = (indexPath.row % 2) + 1;
    [self.segmentedPager.pager showPageAtIndex:index animated:YES];
}

#pragma mark <UITableViewDataSource>

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = (indexPath.row % 2)? @"Text" : @"Web";

    return cell;
}



@end
