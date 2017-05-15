//
//  LRThemesModel.h
//  ZhiHuDaily
//
//  Created by Legolas.Invoker on 2017/5/12.
//  Copyright © 2017年 Chang.Jing. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LRThemesOther : NSObject

@property (nonatomic) NSURL *thumbnail;
@property (nonatomic) NSInteger idNumber;//not equal
@property (nonatomic,copy) NSString *name;

@end

@interface LRThemesModel : NSObject

@property (nonatomic) NSArray *others;

- (void) printAllModels;
@end
