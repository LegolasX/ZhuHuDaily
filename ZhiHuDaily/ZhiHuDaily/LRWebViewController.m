//
//  ViewController.m
//  ZhiHuDaily
//
//  Created by Legolas.Invoker on 2017/4/10.
//  Copyright © 2017年 Chang.Jing. All rights reserved.
//

#import "LRWebViewController.h"
#import "AFNetWorking.h"
#import "MJExtension.h"
#import <SDWebImage/UIImageView+WebCache.h>
@interface LRWebViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic) LRWebModel *model;

@end

@implementation LRWebViewController
@synthesize webView;
@synthesize storyID;
@synthesize model;
- (void)viewDidLoad {
    [super viewDidLoad];
    }
- (void)viewDidAppear:(BOOL)animated {
    NSString *basicString = @"http://news-at.zhihu.com/api/4/news/";
    NSLog(@"%@",storyID);
    NSString *URLString = [basicString stringByAppendingString: storyID];
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@"get all my setup OK~");
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [manager GET:URLString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        model = [LRWebModel mj_objectWithKeyValues:responseObject];
        NSLog(@"%@",responseObject);
        NSLog(@"title = %@",model.title);
        NSMutableString *bodyHTML = [[NSMutableString alloc] initWithString:@"<link rel = \"stylesheet\" type=\"text/css\" href=\""];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 223)];
        [imageView sd_setImageWithURL:model.imageURL];
        [webView.scrollView addSubview:imageView];
        [bodyHTML appendString:model.css[0]];
        [bodyHTML appendString:@"\"> </link>\n"];
        [bodyHTML appendString:model.body];
        NSLog(@"%@",bodyHTML);
        [webView loadHTMLString:bodyHTML baseURL:nil];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
