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
#import <WebKit/WebKit.h>
@interface LRWebViewController () <WKUIDelegate,WKNavigationDelegate,UIGestureRecognizerDelegate,UIScrollViewDelegate>
@property (strong,nonatomic)WKWebView *webView;
@property (nonatomic) LRWebModel *model;
@property (strong,nonatomic) UIView *flexibleView;
//@property (strong,nonatomic) UIScrollView *mainScrollView;

//- (void)loadWebview;
@end
@interface UIImage(resizedImage)
- (UIImage*) resizedImageWith:(CGSize)size;
@end

@implementation UIImage(resizedImage)

- (UIImage *)resizedImageWith:(CGSize)size  {
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    UIGraphicsBeginImageContext(size);
    // 绘制改变大小的图片
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    //使当前的context出堆栈
    UIGraphicsEndImageContext();
    // 返回新的改变大小后的图片
    return scaledImage;
}

@end

@implementation LRWebViewController
@synthesize webView;
@synthesize storyID;
@synthesize flexibleView;
@synthesize model;
//@synthesize mainScrollView;
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = true;
//    self.navigationItem.hidesBackButton = true;
    [self.navigationController.interactivePopGestureRecognizer setEnabled:true];
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
//    self.webView.scrollView.delegate = self;
    CGRect rect = UIScreen.mainScreen.bounds;
    [self.view setFrame:rect];
//    mainScrollView = [[UIScrollView alloc]initWithFrame:rect];
//    mainScrollView.delegate = self;
    webView = [[WKWebView alloc] initWithFrame:rect];
    webView.UIDelegate = self;
//    [webView.scrollView setScrollEnabled:false];
//    [mainScrollView setScrollEnabled:true];
    webView.navigationDelegate = self;
//    [self.view insertSubview:mainScrollView atIndex:0];
//    mainScrollView.clipsToBounds = true;
    webView.scrollView.delegate = self;
    [self.view addSubview:webView];
    [self loadWebView];
    
}
- (void)loadWebView {
    NSString *basicString = @"http://news-at.zhihu.com/api/4/news/";
    NSLog(@"%@",storyID);
    NSString *URLString = [basicString stringByAppendingString: storyID];
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@"get all my setup OK~");
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [manager GET:URLString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        model = [LRWebModel mj_objectWithKeyValues:responseObject];
        NSLog(@"title = %@",model.title);
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.width)];
        flexibleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 375, 220)];
        flexibleView.clipsToBounds = true;
        [flexibleView addSubview:imageView];
        [flexibleView setContentMode:UIViewContentModeCenter];
        [imageView setContentMode:UIViewContentModeScaleToFill];
        [imageView sd_setImageWithURL:model.imageURL];
        
        [webView.scrollView addSubview:flexibleView];
        NSString *html = [NSString stringWithFormat:@"<html><head><meta name='viewport' content='initial-scale=1.0,user-scalable=no' /><link type='text/css' rel='stylesheet' href = 'http://news-at.zhihu.com/css/news_qa.auto.css?v=4b3e3' ></link></head><body>%@</body></html>",model.body];
        [webView loadHTMLString:html baseURL:nil];

    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (IBAction)changeFrame:(UIBarButtonItem *)sender{
    NSLog(@"change!");
    [flexibleView setFrame:CGRectMake(0, 0, 375, 375)];
    [flexibleView setNeedsDisplay];
}
- (IBAction)changeF1:(UIBarButtonItem *)sender {
    NSLog(@"change!");
    [flexibleView setFrame:CGRectMake(0, 0, 375, 300)];
    [self.webView.scrollView setContentOffset:CGPointMake(0, -80)];
//    [flexibleView setNeedsDisplay];

}
- (IBAction)change2:(UIBarButtonItem *)sender {
    [flexibleView setFrame:CGRectMake(0, 0, 375, 300)];
    [self.webView.scrollView setContentOffset:CGPointMake(0, -40)];
}
- (IBAction)change3:(UIBarButtonItem *)sender {
    [self.webView.scrollView setContentOffset:CGPointMake(0, -40)];
}



- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGFloat offset = scrollView.contentOffset.y;
    NSLog(@"current offset = %f",offset);
    if (offset<0.f&&offset>-80.f) {
        [flexibleView setFrame:CGRectMake(0, 0, 375, 220+1*(-offset))];
        
        NSString *js = [NSString stringWithFormat:@"var array = document.getElementsByClassName(\"img-place-holder\" );array = [].slice.call(array);array.forEach(function(child){child.style.height=\"%0.0fpx\";});",220-1*offset];
//        [webView.scrollView setContentOffset:CGPointMake(0, -1*offset) animated:false];
        [webView evaluateJavaScript:js completionHandler:^(id item, NSError * _Nullable error) {
            if (error!=NULL) {
                NSLog(@"%@",error);
            }
        }];
    }else if (offset<-80.f) {
        [webView.scrollView setContentOffset:CGPointMake(0, -80.f)];
    }
//    else if (offset>0&&offset<220.f) {
//        webView.scrollView.clipsToBounds = NO;
//    }else {
//        webView.scrollView.clipsToBounds = YES;
//    }
    
    
    
//    if (offset<0.f&&offset>-40.f) {
//        [flexibleView setFrame:CGRectMake(0, 0, 375, 220+2*(-offset))];
//        [webView.scrollView setContentOffset:CGPointMake(0, 2*offset)];
//    }else if (offset<-40.f) {
//        [webView.scrollView setContentOffset:CGPointMake(0, -80.f)];
//    }
//    else if (offset>0&&offset<220.f) {
//        webView.scrollView.clipsToBounds = NO;
//    }else {
//        webView.scrollView.clipsToBounds = YES;
//    }
}

//- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
//        mainScrollView.contentSize = CGSizeMake(375, self.webView.bounds.size.height+200.f);
//}
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    
//    [self.webView evaluateJavaScript:@"document.body.scrollHeight"completionHandler:^(id _Nullable data, NSError * _Nullable error) {
////        webView.height = [data floatValue];
//        
//        mainScrollView.contentSize = CGSizeMake(375, [data floatValue]+200.f);
////        [_placeHolderView removeFromSuperview];
//    }];
}
- (IBAction)changeFrame2:(id)sender {
}

- (void)viewDidAppear:(BOOL)animated {
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
