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
@property (nonatomic) UIStatusBarStyle statusBarStyle;
@property (strong,nonatomic) UIView *statusBarView;
@end


@implementation LRWebViewController
@synthesize webView;
@synthesize storyID;
@synthesize flexibleView;
@synthesize model;
@synthesize statusBarStyle;
@synthesize  statusBarView;
- (void)viewDidLoad {
    [super viewDidLoad];
    //隐藏默认的导航栏并保留原有的左滑返回手势
    self.navigationController.navigationBarHidden = true;
    [self.navigationController.interactivePopGestureRecognizer setEnabled:true];
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    
    //更改初始状态栏样式
    statusBarStyle = UIStatusBarStyleLightContent;
    [self setNeedsStatusBarAppearanceUpdate];
    
    CGRect rect = UIScreen.mainScreen.bounds;
    //设置webView
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = [[WKUserContentController alloc] init];
    NSString *js = @"";//var views = document.getElementsByClassName('view-more'); views = [].slice.call(views); views.forEach(function(child){child.style.display='none';}); var questions = document.getElementsByClassName('question'); questions[questions.length-1].style.display = 'none'; document.getElementsByClassName('question')[0].style.display = 'none'";

    WKUserScript *script = [[WKUserScript alloc] initWithSource:js injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:false];
    [config.userContentController addUserScript:script];
    
    webView = [[WKWebView alloc] initWithFrame:rect configuration:config];
    webView.UIDelegate = self;
    webView.navigationDelegate = self;
    webView.scrollView.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:webView];
    
    statusBarView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 375, 20)];
    statusBarView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:statusBarView];
    
    [self loadWebView];
    
}
- (void)loadWebView {
    NSString *basicString = @"http://news-at.zhihu.com/api/4/news/";
    NSLog(@"%@",storyID);
    NSString *URLString = [basicString stringByAppendingString: storyID];
    // Do any additional setup after loading the view, typically from a nib.
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [manager GET:URLString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        //从得到的JSON转为model
        model = [LRWebModel mj_objectWithKeyValues:responseObject];
        NSLog(@"title = %@",model.title);
        
        [self initViews];
       
        
        NSString *html = [NSString stringWithFormat:@"<html><head><meta name='viewport' content='initial-scale=1.0,user-scalable=no' /><link type='text/css' rel='stylesheet' href = 'http://news-at.zhihu.com/css/news_qa.auto.css?v=4b3e3' ></link></head><body>%@</body></html>",model.body];
//        NSLog(@"%@",html);
        
        [webView loadHTMLString:html baseURL:nil];
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)initViews {
    [self initFlexibleView];
    [self initImageView];
    [self initLabel];
}

- (void)initFlexibleView {
    flexibleView = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 375, 200)];
        flexibleView.translatesAutoresizingMaskIntoConstraints = false;
        view.clipsToBounds = true;
        view;
    });
    [webView.scrollView addSubview:flexibleView];
    // align flexibleView from the left and right
    [webView.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[flexibleView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(flexibleView)]];
    // align flexibleView from the top
    [webView.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[flexibleView]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(flexibleView)]];
    // height constraint
    [webView.scrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[flexibleView(==200)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(flexibleView)]];
}

- (void)initImageView {
    UIImageView *imageView = ({
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, -87.5, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.width)];
        [imageView setContentMode:UIViewContentModeScaleToFill];
        [imageView sd_setImageWithURL:model.imageURL];
        imageView.translatesAutoresizingMaskIntoConstraints = false;
        imageView;
    });
    
    [flexibleView addSubview:imageView];
    // center imageView horizontally in flexibleView
    [flexibleView addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:flexibleView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    // center imageView vertically in flexibleView
    [flexibleView addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:flexibleView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    // width constraint
    [flexibleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[imageView(==375)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(imageView)]];
    // height constraint
    [flexibleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[imageView(==375)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(imageView)]];
    
    //为了防止imageView上面的字和图片颜色冲突，需要给整个imageView上覆盖一个不透明的遮罩，并用AutoLayout固定住，使它一直和imageView一样大
    UIView *blurView =({
        UIView *view = [[UIView alloc]initWithFrame:imageView.frame];
        UIColor *blurColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        [view setBackgroundColor:blurColor];
        view.translatesAutoresizingMaskIntoConstraints = false;
        view;
    });
    [imageView addSubview:blurView];
    // align blurView from the left and right
    [imageView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[blurView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(blurView)]];
    // align blurView from the top and bottom
    [imageView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[blurView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(blurView)]];
    
}

- (void)initLabel {

    UILabel *label = ({
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 170, 375, 80)];
        label.numberOfLines = 0;
        label.text = model.title;
        label.textColor = [UIColor whiteColor];
        label.translatesAutoresizingMaskIntoConstraints = false;
        label.font = [UIFont systemFontOfSize:20];
        label;
    });
    [flexibleView addSubview:label]; // center label horizontally in flexibleView
    [flexibleView addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:flexibleView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    // align label from the left and right
    [flexibleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[label]-10-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
    // align label from the bottom
    [flexibleView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[label]-20-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
}



- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGFloat offset = scrollView.contentOffset.y;
    NSLog(@"current offset = %f",offset);
    
    //上滑动画的原理是： imageView是基础图层 是一个375*375的正方形 flexibleView是一个宽度375 高度随着offset从200到280变化的遮罩
    //imageView是flexibleView的subview，同时是居中显示的
    //所有的上滑动画都是在offset在0-40之间发生的，根据offset的不同 每一个view都有不同的frame的改变，而flexibleView变大，imageView居中，那么就有了imageView既向上动，又向下动的动画效果
    
    //上滑范围在0到40的时候
    if (offset<0.f&&offset>-40.f) {
        statusBarStyle = UIStatusBarStyleLightContent;
        [statusBarView setBackgroundColor:[UIColor clearColor]];
        //将flexibleView上调offset，以抵消scrollView下滑带来的空隙；同时把高度增加两个offset，使可视范围增大两个offset，同时配合下面的imageView的frame的变化来达成动画的效果
        [flexibleView setFrame:CGRectMake(0, offset , 375, 200+2*(-offset))];
        //原HTML里是为这个首页大图留下了一个gap 通过下面啊的JS代码把这个gap调大一点，来适应页面
        NSString *js = [NSString stringWithFormat:@"var array = document.getElementsByClassName(\"img-place-holder\" );array = [].slice.call(array);array.forEach(function(child){child.style.height=\"%0.0fpx\";});",200-1*offset];
        //
        [webView evaluateJavaScript:js completionHandler:^(id item, NSError * _Nullable error) {
            if (error!=NULL) {
                NSLog(@"%@",error);
            }
        }];
    }else if (offset<=-40.f) {
        [statusBarView setBackgroundColor:[UIColor clearColor]];
        statusBarStyle = UIStatusBarStyleLightContent;
        //当用户想要继续上滑时，不应该继续上滑 但是滑动速度过快的时候 offset的值经常会突破40 动画会跳来跳去 因此在大于等于40的时候把上面的所有值都写死 从而使动画流畅
        [webView.scrollView setContentOffset:CGPointMake(0, -40.f)];
        [flexibleView setFrame:CGRectMake(0, -40 , 375, 280)];
        NSString *js = [NSString stringWithFormat:@"var array = document.getElementsByClassName(\"img-place-holder\" );array = [].slice.call(array);array.forEach(function(child){child.style.height=\"240px\";});"];
        [webView evaluateJavaScript:js completionHandler:^(id item, NSError * _Nullable error) {
            if (error!=NULL) {
                NSLog(@"%@",error);
            }
        }];
        //上滑过了图的范围的时候就改变状态栏样式
    } else if (offset>=185.f) {
        statusBarStyle = UIStatusBarStyleDefault;
        [statusBarView setBackgroundColor:[UIColor whiteColor]];
    } else {
        [statusBarView setBackgroundColor:[UIColor clearColor]];
        statusBarStyle = UIStatusBarStyleLightContent;
    }
    [self setNeedsStatusBarAppearanceUpdate];
    
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return statusBarStyle;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        decisionHandler(WKNavigationActionPolicyCancel);
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}


- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    self.webView.scrollView.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
