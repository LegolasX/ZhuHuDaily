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
@interface LRMainTableVC ()
@property (nonatomic) NSArray *tempData;
@property (nonatomic) LRZhiHuModel *model;
//@property (nonatomic) NSArray *tempData;
@end


@implementation LRMainTableVC
@synthesize model;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    _tempData = [[NSArray alloc]init];
    //JSON数据到model转换之前的设置。
    [self setUpKeyBindingForJsonToModelTranslation];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [manager GET:@"http://news-at.zhihu.com/api/4/news/latest" parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        model = [LRZhiHuModel mj_objectWithKeyValues:responseObject];
//        [model printAllModels];
        [self.tableView reloadData];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];

    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Incomplete implementation, return the number of sections
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return model.stories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"contentCell" forIndexPath:indexPath];
//    cell.textLabel.text = (LRModelStory)
    LRModelStory *story = model.stories[indexPath.row];
    cell.textLabel.text = story.title;
    NSURL *url = story.imageURLs[0];
    cell.tag = [story.storyID integerValue];
    [cell.imageView sd_setImageWithURL:url];
    
//    [cell.imageView setImageWithURL:url];
//    NSURLRequest *request = [NSURLRequest requestWithURL:url];
//    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
//    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
//    AFImageDownloader *downloader = [[self class] sharedImageDownloader];
//    downloader.
//    [manager GET:@"https://pic3.zhimg.com/v2-ae523a09ebac794ac6e580517c54db2a.jpg" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        NSLog(@"%@",responseObject);
//        NSData *data = responseObject;
//        UIImage *image = [UIImage imageWithData:data];
//        cell.imageView.image = image;
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        NSLog(@"%@",error);
//    }];
    // Configure the cell...
    
    return cell;
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
        NSLog(@"i give you this:%@",ID);
        dvc.storyID = ID;
        
    }
}


@end
