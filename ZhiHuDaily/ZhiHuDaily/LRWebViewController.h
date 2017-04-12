//
//  ViewController.h
//  ZhiHuDaily
//
//  Created by Legolas.Invoker on 2017/4/10.
//  Copyright © 2017年 Chang.Jing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LRWebModel.h"

@interface LRWebViewController : UIViewController <UIGestureRecognizerDelegate,UIScrollViewDelegate>
@property (nonatomic,copy) NSString *storyID;


@end

