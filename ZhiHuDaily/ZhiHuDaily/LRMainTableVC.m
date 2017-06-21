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
static CGFloat const leftScale = 0.8f;
static CGFloat const leftDragbleWidth = 80.f;
static CGFloat const leftMinDragLength = 100.f;



@interface LRMainTableVC () <UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate,StoryChangedProtocol>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

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
    _screenSize = UIScreen.mainScreen.bounds.size;
    _leftShow = false;
    
    _leftVC = [self.storyboard instantiateViewControllerWithIdentifier:@"LeftVC"];
    [self addChildViewController:_leftVC];
    _leftView = _leftVC.view;
    _leftView.frame = CGRectMake(-_screenSize.width*0.5, 0, _screenSize.width*0.5, _screenSize.height);
    _leftView.backgroundColor = [[UIColor alloc]initWithRed:0.14 green:0.16 blue:0.19 alpha:1];
    [self.view addSubview:_leftView];
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    UIRefreshControl *control = [[UIRefreshControl alloc] init];
    self.tableView.refreshControl = control;
    [control addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    //JSON数据到model转换之前的设置。
    [self setUpKeyBindingForJsonToModelTranslation];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [manager GET:@"http://news-at.zhihu.com/api/4/news/latest" parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        model = [LRZhiHuModel mj_objectWithKeyValues:responseObject];
        [self.tableView reloadData];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showMiddle)];
    [self.view addGestureRecognizer:tapGesture];
    tapGesture.delegate = self;
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizer:)];
    [self.view addGestureRecognizer:panGesture];

    
    _originLeftVCTrans = _leftView.transform;
    _originMainVCTrans = _tableView.transform;
    
    _grayArray = [[NSMutableArray alloc]init];
    
}



- (void)setUpKeyBindingForJsonToModelTranslation {
    //使用MJExtension库 参见https://github.com/CoderMJLee/MJExtension
    //参见GitHub教程里 Model name - JSON key mapping【模型中的属性名和字典中的key不相同(或者需要多级映射)】的部分
    //由于得到的json里面的数据的key和模型不一样 所以需要先设置一个映射 下三个同
    [LRModelTopStory mj_setupReplacedKeyFromPropertyName:^NSDictionary *{
        return @{
                 @"imageURL" : @"image",
                 @"storyID" : @"id"
                 };
    }];
    [LRZhiHuModel mj_setupReplacedKeyFromPropertyName:^NSDictionary *{
        return@{
                @"topStories" : @"top_stories"
                };
    }];
    //由于json的数据里面还有数组的嵌套，因此要告诉这个数组嵌套的具体是什么类
    //参见GitHub教程里 Model contains model-array【模型中有个数组属性，数组里面又要装着其他模型】】的部分
    [LRZhiHuModel mj_setupObjectClassInArray:^NSDictionary *{
        return @{
                 @"stories" : @"LRModelStory",
                 @"topStories" : @"LRModelTopStory"
                 };
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:self.view];
    NSLog(@"x = %f y = %f %d",point.x,point.y,_leftShow);
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]&&!_leftShow) {
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
            NSLog(@"began");
            _lastPoint = [panGesture locationInView:self.view];
            break;
        case UIGestureRecognizerStateChanged:{
            CGFloat x = newPoint.x - _lastPoint.x;
//            NSLog(@"%f",_tableView.transform.tx);
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
            NSLog(@"ended");
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
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:false block:^(NSTimer * _Nonnull timer) {
            [self.tableView.refreshControl endRefreshing];
        }];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
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


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"webView"]) {
        LRWebViewController *dvc = [segue destinationViewController];
        LRTableVContentCell *cell = sender;
        LRModelStory *story = model.stories[cell.tag];
        NSString *ID = story.storyID;
        dvc.storyID = ID;
        dvc.storyChangedDelegate = self; // storyChangedDelegate = self;
    }
}

#pragma mark - storyChangedDelegate
- (NSString *)getLastStoryID:(NSString *)oldStoryID {
    __block NSString  *newID = [[NSString alloc]init];
    [model.stories enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj storyID]==oldStoryID) {
            newID = [model.stories[idx-1==0 ? idx : idx-1 ] storyID];
        }
    }];
    return newID;
}


@end
