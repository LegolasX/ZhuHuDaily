//
//  LRWebModel.h
//  ZhiHuDaily
//
//  Created by Legolas.Invoker on 2017/4/11.
//  Copyright © 2017年 Chang.Jing. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LRWebModel : NSObject
@property (nonatomic,copy) NSString *body;
@property (nonatomic,copy) NSString *imageSource;//not equal
@property (nonatomic,copy) NSString *title;
@property (nonatomic,copy) NSString *imageURL;//not equal
@property (nonatomic,copy) NSString *shareURL;//not equal
@property (nonatomic) NSString *js;//may not be string
@property (nonatomic) NSInteger *type;
@property (nonatomic,copy) NSString *storyID;//not equal
@property (nonatomic) NSArray *css;

-(void) printAll;
@end
