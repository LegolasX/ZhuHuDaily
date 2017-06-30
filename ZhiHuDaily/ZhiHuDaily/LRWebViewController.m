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
typedef NS_ENUM(int,PanGestureDirection) {
    PanGestureDirectionLeft,
    PanGestureDirectionRight
};
#ifdef DEBUG
#define NSLog(FORMAT, ...) fprintf(stderr,"%s\n",[[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define NSLog(...)
#endif
@interface LRWebViewController () <WKUIDelegate,WKNavigationDelegate,UIGestureRecognizerDelegate,UIScrollViewDelegate>
@property (strong,nonatomic)WKWebView *webView;
@property (nonatomic) LRWebModel *model;
@property (strong,nonatomic) UIView *flexibleView;
@property (nonatomic) UIStatusBarStyle statusBarStyle;
@property (strong,nonatomic) UIView *statusBarView;
@property (nonatomic) CGFloat lastX;
@property (nonatomic) CGFloat last2X;
@property (nonatomic) CGFloat startPointX;
@property (nonatomic) UIView *leftView;
@property (nonatomic) UIView *rightView;
@property (nonatomic) CGAffineTransform originWebviewTrans;
@property (nonatomic) PanGestureDirection swipeDirection;

@end


@implementation LRWebViewController
@synthesize webView;
@synthesize storyID;
@synthesize flexibleView;
@synthesize model;
@synthesize statusBarStyle;
@synthesize  statusBarView;
@synthesize storyChangedDelegate;
#pragma mark - start
- (void)viewDidLoad {
    [super viewDidLoad];
    //隐藏默认的导航栏并保留原有的左滑返回手势
    self.navigationController.navigationBarHidden = true;
    [self.navigationController.interactivePopGestureRecognizer setEnabled:true];
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    
    //设置webView
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = [[WKUserContentController alloc] init];
    webView = [[WKWebView alloc] initWithFrame:UIScreen.mainScreen.bounds configuration:config];
    webView.UIDelegate = self;
    webView.navigationDelegate = self;
    webView.scrollView.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:webView];
    [self loadWebView];
    
    //更改初始状态栏样式
    statusBarStyle = UIStatusBarStyleLightContent;
    [self setNeedsStatusBarAppearanceUpdate];
    //添加状态栏view，用以改变状态栏颜色
    statusBarView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 375, 20)];
    statusBarView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:statusBarView];
    
    //添加PanGesture
    UIPanGestureRecognizer *swipe = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(swipeByPan:)];
    [self.webView addGestureRecognizer:swipe];
    
    //设置layer的操作，进行美化
    //    self.view.layer.cornerRadius = 15;
    //    self.view.layer.borderWidth = 15;
    self.view.clipsToBounds = true;
    
    
    _leftView = [[UIView alloc] init];
    _rightView = [[UIView alloc] init];
    
    _originWebviewTrans = self.webView.transform;
    
    [self.webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    
}
- (void)loadWebView {
    NSString *basicString = @"http://news-at.zhihu.com/api/4/news/";
    //    NSLog(@"%@",storyID);
    NSString *URLString = [basicString stringByAppendingString: storyID];
    // Do any additional setup after loading the view, typically from a nib.
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [manager GET:URLString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        //从得到的JSON转为model
        model = [LRWebModel mj_objectWithKeyValues:responseObject];
        //        NSLog(@"title = %@",model.title);
        [self initFlexibleView];
        [self initImageView];
        [self initLabel];
        NSString *html = [NSString stringWithFormat:@"<html><head><meta name='viewport' content='initial-scale=1.0,user-scalable=no' /><link type='text/css' rel='stylesheet' href = 'http://news-at.zhihu.com/css/news_qa.auto.css?v=4b3e3' ></link></head><body>%@</body></html>",model.body];
        [webView loadHTMLString:html baseURL:nil];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)dealloc {
    [self.webView removeObserver:self forKeyPath:@"loading"];
}

#pragma mark - init views
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

#pragma mark - gesture handle

/**
 处理所有的手势操作

 @param direction 移动方向
 @param startX 最初触摸点X
 @param movedPixel 上一帧和这一帧之间移动的距离
 @param finalX 最终触摸点X
 @param finished 是否是结束动画
 */
- (void)swipeTo:(PanGestureDirection)direction forStartX:(CGFloat)startX movedPixel:(CGFloat)movedPixel finalPointX:(CGFloat)finalX isFinished:(BOOL)finished   {
    CGFloat pixelToMove = 0;
    NSTimeInterval time;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    typedef NS_ENUM (int,SwipeState) {
        move,
        left,
        middle,
        right
    };
    SwipeState state = move;
    if (!finished) {//如果不是final动画，那么需要移动的距离就只是movedPixel
        time = 0;
        pixelToMove = movedPixel;
    } else {//底下的几个判断，因为有冲突，优先级是依次增高的
        //首先，如果方向是左右，那么可能就是在左右滑动
        if (direction==PanGestureDirectionLeft) {
            state = left;
            pixelToMove = screenWidth - (startX - finalX);
        }
        if (direction==PanGestureDirectionRight) {
            state = right;
            pixelToMove = screenWidth - (finalX - startX);
        }
        //其次，如果是最终速度太慢了，可能是原地不动 因此是middle
        if (movedPixel<5&&movedPixel>-5) {
            state = middle;
            pixelToMove = startX - finalX;
        }
        //但是如果是滑动超过了屏幕一半距离，那么可以忽视速度，直接根据起始点和终止点距离差来定方向
        if (finalX - startX > screenWidth / 2) {
            state = right;
            pixelToMove = screenWidth - (finalX - startX);
        }
        if (startX - finalX > screenWidth / 2) {
            state = left;
            pixelToMove = screenWidth - (startX - finalX);
        }
        time = fabs(pixelToMove/screenWidth * 0.5);//根据要移动的距离计算动画时间
    }
//    if (state != move) {
//        NSLog(@"time used:%f pixel Moved:%f",time,pixelToMove);
//    }
    switch (state) {
        case move:{
            [UIView animateWithDuration:0 animations:^{
                self.webView.transform = CGAffineTransformTranslate(self.webView.transform, pixelToMove, 0);
            }];
            break;}
        case left:{
            if ([self.storyChangedDelegate respondsToSelector:@selector(getStoryID:isLast:)]) {
                self.storyID = [self.storyChangedDelegate getStoryID:self.storyID isLast:true];
            }
            [UIView animateWithDuration:time animations:^{
                self.webView.transform = CGAffineTransformTranslate(self.originWebviewTrans, -screenWidth, 0);
            } completion:^(BOOL finished) {
                [self loadWebView];
            }];
            break;}
        case middle:{
            [UIView animateWithDuration:time animations:^{
                self.webView.transform = CGAffineTransformInvert(self.originWebviewTrans);
            }];
            break;}
        case right:{
            if ([self.storyChangedDelegate respondsToSelector:@selector(getStoryID:isLast:)]) {
                self.storyID = [self.storyChangedDelegate getStoryID:self.storyID isLast:false];
            }
            [UIView animateWithDuration:time animations:^{
                self.webView.transform = CGAffineTransformTranslate(self.originWebviewTrans, screenWidth, 0);
            } completion:^(BOOL finished) {
                [self loadWebView];
            }];
            break;}
        default:
            break;
    }
    
}

- (void)swipeByPan:(UISwipeGestureRecognizer *)swipe {
    //整个手势识别过程中，一共记录了四个点 startPointX，last2X，lastX，newX
    //其中，startPointX是初始点，last2X和lastX分别是倒数第二和倒数第一个点，newX是最新的点
    //通过newX-lastX 来算出坐标差 newX-startPointX来算总共移动距离
    //因为在最后一个recognized状态前，传入的点的坐标没有改变 因此用newX-last2X算距离
    CGFloat newX = [swipe locationInView:self.view].x;
    switch (swipe.state) {
        case UIGestureRecognizerStateBegan:{
            //手势开始时记录上一个点的位置
            _startPointX = newX;
            _lastX = newX;
            
            //当一个手势开始时，就给左右加上图层，利用的是当前屏幕截图。同时加上一层遮罩
            self.leftView = [self.view snapshotViewAfterScreenUpdates:false];
            self.rightView = [self.view snapshotViewAfterScreenUpdates:false];
            CGRect frame = self.webView.frame;
            UIVisualEffectView *eView1 = [[UIVisualEffectView alloc]initWithFrame:frame];
            UIVisualEffectView *eView2 = [[UIVisualEffectView alloc]initWithFrame:frame];
            [eView1 setEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
            [eView2 setEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
            [self.leftView addSubview:eView1];
            [self.rightView addSubview:eView2];
            frame.origin.x -= frame.size.width;
            [self.leftView setFrame:frame];
            [self.webView addSubview:self.leftView];
            frame.origin.x = frame.size.width;
            [self.rightView setFrame:frame];
            [self.webView addSubview:self.rightView];
            
            break;}
        case UIGestureRecognizerStateChanged:{
            CGFloat movedPixel = newX - _lastX;
            _swipeDirection = movedPixel > 0 ? PanGestureDirectionRight : PanGestureDirectionLeft;
            //根据两次触碰点算出方向
            [self swipeTo:_swipeDirection forStartX:_startPointX movedPixel:movedPixel finalPointX:newX isFinished:false];
            _last2X = _lastX;
            _lastX = newX;
            break;
        }
        case UIGestureRecognizerStateEnded:
//            NSLog(@"recongnized%f", _lastX - _last2X);
            [self swipeTo:_swipeDirection forStartX:_startPointX movedPixel:_lastX - _last2X finalPointX:newX isFinished:true];
            break;
            //
        default:
            break;
    }
}
#pragma mark 利用navigation提供的左滑缓速返回时会产生动画冲突--已解决
//通过这样来允许两个相似的手势的同时识别，因此会导致左滑时出现问题
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return  YES;
}

//当两个手势同时要被识别时，这里可以动态的判断，gestureRecognizer要不要被另一个手势otherGestureRecognizer阻断
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
//    NSLog(@"2----this--%@ that--%@",[gestureRecognizer class],[otherGestureRecognizer class]);
    //本来应当判断哪个手势是哪个，但是根据实际log，一般gestureRecognizer都是UIScreenEdge，就不进行判断了
    if ([otherGestureRecognizer class]==[UIPanGestureRecognizer class]) {
        return YES;
    }
    return NO;
}

#pragma mark - scrollView scroll handle
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGFloat offset = scrollView.contentOffset.y;
    //    NSLog(@"current offset = %f",offset);
    
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

//此处监控的是self.webView.loading 通过判断loading为false来去掉左右两个遮罩，
#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    id x = [change valueForKey:NSKeyValueChangeNewKey];
    NSString *y = [NSString stringWithFormat:@"%@",x];
    if ([y isEqual: @"0"]) {
        [self.leftView removeFromSuperview];
        [self.rightView removeFromSuperview];
        [UIView animateWithDuration:0 animations:^{
            self.webView.transform = CGAffineTransformInvert(self.originWebviewTrans);
        }];
    }
}

#pragma mark - statusBarStyle
- (UIStatusBarStyle)preferredStatusBarStyle {
    return statusBarStyle;
}

#pragma mark - webview delegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        decisionHandler(WKNavigationActionPolicyCancel);
    }
    //禁止链接的跳转
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
