//
//  LRWebModel.m
//  ZhiHuDaily
//
//  Created by Legolas.Invoker on 2017/4/11.
//  Copyright © 2017年 Chang.Jing. All rights reserved.
//

#import "LRWebModel.h"
#import "MJExtension.h"
@implementation LRWebModel
@synthesize body;
@synthesize imageSource;
@synthesize title;
@synthesize imageURL;
@synthesize shareURL;
@synthesize js;
@synthesize type;
@synthesize storyID;
@synthesize css;
- (instancetype)init
{
    NSLog(@"get all my setup OK~");
    [LRWebModel mj_setupReplacedKeyFromPropertyName:^NSDictionary *{
        return @{
                 @"imageSouce" : @"image-source",
                 @"imageURL" : @"image",
                 @"shareURL" : @"share_url",
                 @"storyID" : @"id"
                 };
    }];
    [LRWebModel mj_setupObjectClassInArray:^NSDictionary *{
        return @{
                 @"css" : @"NSString"
                 };
    }];
    self = [super init];
    if (self) {
        
    }
    return self;
}
- (void)printAll {
//    NSLog(@"body")
}
@end
