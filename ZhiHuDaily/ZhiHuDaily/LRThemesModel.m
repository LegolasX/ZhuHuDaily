//
//  LRThemesModel.m
//  ZhiHuDaily
//
//  Created by Legolas.Invoker on 2017/5/12.
//  Copyright © 2017年 Chang.Jing. All rights reserved.
//

#import "LRThemesModel.h"
#import "MJExtension.h"
@implementation LRThemesOther

- (instancetype)init
{
    [LRThemesOther mj_setupReplacedKeyFromPropertyName:^NSDictionary *{
        return @{
                 @"idNumber" : @"id",
                 };
    }];
    
    self = [super init];
    if (self) {
        
    }
    return self;
}

@end

@implementation LRThemesModel
- (instancetype)init
{
    [LRThemesModel mj_setupObjectClassInArray:^NSDictionary *{
        return @{
                 @"others" : @"LRThemesOther"
                 };
    }];
    self = [super init];
    if (self) {
        
    }
    return self;
}
- (void)printAllModels {
    for (LRThemesOther *other in self.others) {
        NSLog(@"thumbnail = %@ id =  name = %@",other.thumbnail,other.name);
    }
}
@end
