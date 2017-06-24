//
//  LRMainTableVC.h
//  ZhiHuDaily
//
//  Created by Legolas.Invoker on 2017/4/10.
//  Copyright © 2017年 Chang.Jing. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LRMainTableVC : UIViewController

@end

@protocol StoryChangedProtocol<NSObject>
@required
- (NSString *)getStoryID:(NSString *)oldStoryID isLast:(BOOL)isLast;
@end
