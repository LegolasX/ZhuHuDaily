//
//  LRMainTableVC.m
//  ZhiHuDaily
//
//  Created by Legolas.Invoker on 2017/4/10.
//  Copyright © 2017年 Chang.Jing. All rights reserved.
//

#import "LRMainTableVC.h"
#import "AFNetWorking.h"
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
@property (nonatomic) LRZhiHuModel *model;
@property (nonatomic) UIViewController *leftVC;
@property (nonatomic) UIView *leftView;
@property (nonatomic) CGAffineTransform transform;
@property (nonatomic) CGSize screenSize;
@property (nonatomic) BOOL leftShow;
@property (nonatomic) CGPoint lastPoint;
@property (nonatomic) CGAffineTransform originLeftVCTrans;
@property (nonatomic) CGAffineTransform originMainVCTrans;
@property (nonatomic) NSMutableArray *grayArray;
@end



@implementation LRMainTableVC
@synthesize model;

- (void)viewDidLoad {
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
    
    //初始化浏览后变灰数组
    _grayArray = [[NSMutableArray alloc]init];
    
    //备份初始transform
    _originLeftVCTrans = _leftView.transform;
    _originMainVCTrans = _tableView.transform;
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [manager GET:@"http://news-at.zhihu.com/api/4/news/latest" parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        #pragma mark important! 将下载好的JSON格式的数据转换为model的方法写在了每个model类里
        model = [LRZhiHuModel mj_objectWithKeyValues:responseObject];
        [self.tableView reloadData];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
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

- (void) refresh:(id)paramSender {
    
        [_tableView reloadData];
//        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:false block:^(NSTimer * _Nonnull timer) {
//            [self.tableView.refreshControl endRefreshing];
//        }];
}

#pragma mark - Table view data source and delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 0;
    return model.stories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"contentCell" forIndexPath:indexPath];
    LRModelStory *story = model.stories[indexPath.row];
    cell.textLabel.text = story.title;
    if ([_grayArray containsObject:[NSNumber numberWithInteger:indexPath.row]]) {
        cell.textLabel.textColor = [UIColor grayColor];
    }
    NSURL *url = story.imageURLs[0];
    
    cell.tag = indexPath.row;
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
    [_grayArray addObject:[NSNumber numberWithInteger:indexPath.row]];
    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationLeft];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"webView"]) {
        LRWebViewController *dvc = [segue destinationViewController];
        LRTableVContentCell *cell = sender;
        LRModelStory *story = model.stories[cell.tag];
        dvc.storyID = story.storyID;//传递ID
        dvc.storyChangedDelegate = self; //设置得到storyid的delegate
    }
}

#pragma mark - storyChangedDelegate
- (NSString *)getStoryID:(NSString *)oldStoryID isLast:(BOOL) isLast {
    __block NSString  *newID = [[NSString alloc]init];
    [model.stories enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj storyID]==oldStoryID) {
            if (isLast) {//拿到上一个ID
                newID = [model.stories[idx-1==-1 ? idx : idx-1 ] storyID];
            } else {//拿到下一个ID
                newID = [model.stories[idx==model.stories.count-1 ? idx : idx+1 ] storyID];
            }
        }
    }];
    return newID;
}

@end
