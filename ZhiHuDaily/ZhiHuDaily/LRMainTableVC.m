//
//  LRMainTableVC.m
//  ZhiHuDaily
//
//  Created by Legolas.Invoker on 2017/4/10.
//  Copyright © 2017年 Chang.Jing. All rights reserved.
//

#import "LRMainTableVC.h"
#import "AFNetworking.h"
#import "MJExtension.h"
#import "LRZhiHuModel.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "LRWebViewController.h"
#import "LRTableVContentCell.h"
#import <CoreData/CoreData.h>
static CGFloat const leftShowWidth = 187.f;
//static CGFloat const leftScale = 0.8f;
//static CGFloat const leftDragbleWidth = 80.f;
//static CGFloat const leftMinDragLength = 100.f;



@interface LRMainTableVC () <UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate,StoryChangedProtocol>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) NSMutableArray *model;
@property (nonatomic) UIViewController *leftVC;
@property (nonatomic) UIView *leftView;
@property (nonatomic) CGAffineTransform transform;
@property (nonatomic) CGSize screenSize;
@property (nonatomic) BOOL leftShow;
@property (nonatomic) CGPoint lastPoint;
@property (nonatomic) CGAffineTransform originLeftVCTrans;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property (nonatomic) CGAffineTransform originMainVCTrans;
//@property (nonatomic) NSMutableArray *grayArray;
@end



@implementation LRMainTableVC
@synthesize model;

- (void)viewDidLoad {
    NSLog(@"viewDidLoad called");
    [super viewDidLoad];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor lightGrayColor];
    
    _screenSize = UIScreen.mainScreen.bounds.size;
    
    //加载左侧栏
    _leftVC = [self.storyboard instantiateViewControllerWithIdentifier:@"LeftVC"];
    [self addChildViewController:_leftVC];
    _leftView = _leftVC.view;
    _leftView.frame = CGRectMake(-_screenSize.width*0.5, 0, _screenSize.width*0.5, _screenSize.height);
    _leftView.backgroundColor = [[UIColor alloc]initWithRed:0.14 green:0.16 blue:0.19 alpha:1];
    _leftShow = false;
    [self.view addSubview:_leftView];
    
    //添加手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showMiddle)];
    [self.view addGestureRecognizer:tapGesture];
    tapGesture.delegate = self;
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizer:)];
    [self.view addGestureRecognizer:panGesture];
    
    //添加下拉刷新动画
    UIRefreshControl *control = [[UIRefreshControl alloc] init];
    self.tableView.refreshControl = control;
    [control addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    
    //备份初始transform
    _originLeftVCTrans = _leftView.transform;
    _originMainVCTrans = _tableView.transform;
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [manager GET:@"http://news-at.zhihu.com/api/4/news/latest" parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
#pragma mark important! 将下载好的JSON格式的数据转换为model的方法写在了每个model类里
        model = [[NSMutableArray alloc]init];
        
        [model addObject:[LRZhiHuModel mj_objectWithKeyValues:responseObject]];
        [self.tableView reloadData];
        [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
    
    self.activity.hidesWhenStopped = true;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:false];
    NSLog(@"viewWillAppear called");
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    NSArray *array = [user arrayForKey:@"gery"];
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:[obj integerValue] inSection:1];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:path, nil] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - gesture handle
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:self.view];
    //    NSLog(@"x = %f y = %f %d",point.x,point.y,_leftShow);
    //如果是tapGuesture 而且leftShow为false 那么说明画面在中间  或者leftshow 为真 且按压的点在左侧 那么tapGesture不应该接管
    if (([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]&&!_leftShow)||(_leftShow&&point.x<_leftView.frame.size.width)) {
        return false;
    }
    return true;
}


- (void) showLeft {
    [UIView animateWithDuration:0.3 animations:^{
        _leftView.transform = CGAffineTransformTranslate(_originLeftVCTrans,leftShowWidth, 0);
        _tableView.transform = CGAffineTransformTranslate(_originMainVCTrans,leftShowWidth, 0);
    }];
}

- (void) showMiddle {
    [UIView animateWithDuration:0.3 animations:^{
        _leftView.transform = CGAffineTransformInvert(_originLeftVCTrans);
        _tableView.transform = CGAffineTransformInvert(_originMainVCTrans);
    }];
    _leftShow = false;
}

- (void) panGestureRecognizer:(UIPanGestureRecognizer *)panGesture {
    CGPoint newPoint = [panGesture locationInView:self.view];
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan:
            _lastPoint = [panGesture locationInView:self.view];
            break;
        case UIGestureRecognizerStateChanged:{
            CGFloat x = newPoint.x - _lastPoint.x;
            if ((_tableView.transform.tx==0&&x>0)||_tableView.transform.tx>0) {
                [UIView animateWithDuration:0 animations:^{
                    _leftView.transform = CGAffineTransformTranslate(_leftView.transform,x, 0);
                    _tableView.transform = CGAffineTransformTranslate(_tableView.transform,x, 0);
                }];
            }
            
            _lastPoint = newPoint;
            //            NSLog(@"changed");
            break;}
        case UIGestureRecognizerStateEnded:
            if (_tableView.transform.tx>100) {
                [self showLeft];
                _leftShow = true;
            } else {
                NSLog(@"before showMiddle:%d",_leftShow);
                [self showMiddle];
                _leftShow = false;
                NSLog(@"now trans = %f",_tableView.transform.ty);
            }
            break;
        default:
            break;
    }
}

- (void)refresh:(id)paramSender {
    
    [_tableView reloadData];
# pragma mark - IMPORTANT! 测试用 记得删除
    [NSUserDefaults resetStandardUserDefaults];
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    [user removeObjectForKey:@"grey"];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:false block:^(NSTimer * _Nonnull timer) {
        [self.tableView.refreshControl endRefreshing];
    }];
}

#pragma mark - Table view data source and delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 0;
    return ((LRZhiHuModel *)model[0]).stories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"cellForRowAtIndexPath called");
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"contentCell" forIndexPath:indexPath];
    LRModelStory *story = ((LRZhiHuModel *)model[0]).stories[indexPath.row];
    cell.textLabel.text = story.title;
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    NSArray *array = [user arrayForKey:@"grey"];
    if ([array containsObject:[NSNumber numberWithInteger:indexPath.row]]) {
        cell.textLabel.textColor = [UIColor grayColor];
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
    }
    NSURL *url = story.imageURLs[0];
    [cell.imageView sd_setImageWithURL:url];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    CATransform3D rotation;//3D旋转初始化对象
    rotation = CATransform3DMakeRotation( (90.0*M_PI)/180, 0.0, 0.7, 0.4);//角度控制
    
    //逆时针旋转
    rotation.m34 = 1.0/ -600;
    
    cell.layer.shadowColor = [[UIColor blackColor]CGColor];
    cell.layer.shadowOffset = CGSizeMake(10, 10);
    cell.alpha = 0;
    
    cell.layer.transform = rotation;
    
    [UIView beginAnimations:@"rotation"context:NULL];
    //旋转时间
    [UIView setAnimationDuration:0.8];
    cell.layer.transform = CATransform3DIdentity;
    cell.alpha = 1;
    cell.layer.shadowOffset = CGSizeMake(0, 0);
    [UIView commitAnimations];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    NSMutableArray *array = [[NSMutableArray alloc]initWithArray:[user arrayForKey:@"grey"]];
    NSNumber *number = [NSNumber numberWithInteger:indexPath.row];
    if (![array containsObject:number]) {
        [array addObject:number];
    }
    [user setObject:array forKey:@"grey"];
    //    [_grayArray addObject:[NSNumber numberWithInteger:indexPath.row]];
    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationLeft];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark - scroll view

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {


    CGFloat actualHeight = scrollView.contentOffset.y + UIScreen.mainScreen.bounds.size.height + scrollView.contentInset.top;
    if (scrollView.contentSize.height>20 && actualHeight > scrollView.contentSize.height + 30) {
        [self.activity startAnimating];

        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
        NSMutableString *string = [[NSMutableString alloc]initWithString:@"https://news-at.zhihu.com/api/4/news/before/"];
        NSString *newDate = [((LRZhiHuModel *)model[0]) getYesterday];
        [string appendString:newDate];
        ((LRZhiHuModel *)model[0]).date = newDate;
        __weak __typeof__(self) weakSelf = self;
        [manager GET:string parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
#pragma mark important! 将下载好的JSON格式的数据转换为model的方法写在了每个model类里
            LRZhiHuModel *newModel = [LRZhiHuModel mj_objectWithKeyValues:responseObject];
            [((LRZhiHuModel *)model[0]) addStories:newModel.stories];
            [weakSelf.tableView reloadData];
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];

    } else {
        [self.activity stopAnimating];
    }
    
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"webView"]) {
        LRWebViewController *dvc = [segue destinationViewController];
        LRTableVContentCell *cell =(LRTableVContentCell *)sender;
        
        NSIndexPath *path = [self.tableView indexPathForCell:cell];
        LRModelStory *story = ((LRZhiHuModel *)model[0]).stories[path.row];
        dvc.storyID = story.storyID;//传递ID
        dvc.storyChangedDelegate = self; //设置得到storyid的delegate
    }
}

#pragma mark - storyChangedDelegate

- (void)testGetStoryID:(NSString *)oldStoryID isLast:(BOOL)isLast complection:(void (^)(NSString *newID))blockName {
    __block NSString  *newIDString = nil;
    __block NSUInteger ID;
    [((LRZhiHuModel *)model[0]).stories enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj storyID]==oldStoryID) {
            if (isLast) {//拿到上一个ID
                if (idx - 1 != -1) {
                    newIDString = [((LRZhiHuModel *)model[0]).stories[idx-1] storyID];
                    ID = idx - 1;
                }
            } else {//拿到下一个ID
                if (idx+1 != ((LRZhiHuModel *)model[0]).stories.count) {
                    newIDString = [((LRZhiHuModel *)model[0]).stories[idx+1] storyID];
                    ID = idx + 1;
                }
            }
        }
    }];
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    NSMutableArray *array = [[NSMutableArray alloc]initWithArray:[user arrayForKey:@"grey"]];
    NSNumber *number = [NSNumber numberWithInteger:ID];
    if (![array containsObject:number]) {
        [array addObject:number];
    }
    [user setObject:array forKey:@"grey"];
    NSIndexPath *path = [NSIndexPath indexPathForRow:ID inSection:1];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:path, nil] withRowAnimation:UITableViewRowAnimationAutomatic];
    blockName(newIDString);
}

@end
