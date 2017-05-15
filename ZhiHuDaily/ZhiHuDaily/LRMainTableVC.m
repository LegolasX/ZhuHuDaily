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

@interface LRMainTableVC () <UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate>

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
//@property (nonatomic) NSManagedObjectModel *managedObjectModel;
////@property (nonatomic) NSManagedObjectContext *
//@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
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
    
//    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CoreDataTryout" withExtension:@"momd"];
//    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
//    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
//    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"CoreDataTryout.sqlite"];
//    
//    
//    
//    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
    
//    }

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

//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
//    NSLog(@"this %@ %@",[gestureRecognizer class],[gestureRecognizer.view class]);
//    NSLog(@"other %@ %@",[otherGestureRecognizer class],[otherGestureRecognizer.view class]);
//    if ([[otherGestureRecognizer.view class] isSubclassOfClass:[UIView class]]) {
//        return NO;
//    }
//    if( [[otherGestureRecognizer.view class] isSubclassOfClass:[UITableViewCell class]] ||
//       [NSStringFromClass([otherGestureRecognizer.view class]) isEqualToString:@"UITableViewCellScrollView"] ||
//       [NSStringFromClass([otherGestureRecognizer.view class]) isEqualToString:@"UITableViewWrapperView"]) {
//        
//        return YES;
//    }
//    return YES;
//}
//
//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
//{
//    // 打印touch到的视图
//    NSLog(@"%@", NSStringFromClass([touch.view class]));
//    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]&&!_leftShow) {
//        printf("tap");
//        return NO;
//    }
//    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
//        printf("pan");
//    }
//    // 如果视图为UITableViewCellContentView（即点击tableViewCell），则不截获Touch事件
//    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"]) {
//        return NO;
//    }
//    return  YES;
//}

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
    cell.tag = [story.storyID integerValue];
    [cell.imageView sd_setImageWithURL:url];
    
    return cell;
}

//- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
//    return false;
//}

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
        NSString *ID = [NSString stringWithFormat:@"%d", cell.tag];
        dvc.storyID = ID;
    }
}


@end
