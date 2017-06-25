//
//  LRZhiHuModel.m
//  ZhiHuDaily
//
//  Created by Legolas.Invoker on 2017/4/11.
//  Copyright © 2017年 Chang.Jing. All rights reserved.
//
#ifdef DEBUG
#define NSLog(FORMAT, ...) fprintf(stderr,"%s\n",[[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define NSLog(...)
#endif
#import "LRZhiHuModel.h"
#import "MJExtension.h"
@implementation LRModelStory

@synthesize title;
@synthesize imageURLs;
@synthesize storyID;

- (instancetype)init
{
    self = [super init];
    if (self) {
        //使用MJExtension库 参见https://github.com/CoderMJLee/MJExtension
        //参见GitHub教程里 Model name - JSON key mapping【模型中的属性名和字典中的key不相同(或者需要多级映射)】的部分
        //由于得到的json里面的数据的key和模型不一样 所以需要先设置一个映射 下三个同
        
        [LRModelStory mj_setupReplacedKeyFromPropertyName:^NSDictionary *{
            return @{
                     @"imageURLs" : @"images",
                     @"storyID" : @"id"
                     };
        }];
        [LRModelStory mj_setupObjectClassInArray:^NSDictionary *{
            return @{
                     @"imageURLs" : @"NSURL"
                     };
        }];

    }
    return self;
}
@end

@implementation LRModelTopStory

@synthesize title;
@synthesize imageURL;
@synthesize storyID;

- (instancetype)init {
    self = [super init];
    if (self) {
        [LRModelTopStory mj_setupReplacedKeyFromPropertyName:^NSDictionary *{
            return @{
                     @"imageURL" : @"image",
                     @"storyID" : @"id"
                     };
        }];
    }
    return self;
}
@end

@implementation LRZhiHuModel
@synthesize date;
@synthesize stories;

- (instancetype)init
{
    self = [super init];
    if (self) {
        //由于json的数据里面还有数组的嵌套，因此要告诉这个数组嵌套的具体是什么类
        //    //参见GitHub教程里 Model contains model-array【模型中有个数组属性，数组里面又要装着其他模型】】的部分
        [LRZhiHuModel mj_setupReplacedKeyFromPropertyName:^NSDictionary *{
            return@{
                    @"topStories" : @"top_stories"
                    };
        }];
        
        [LRZhiHuModel mj_setupObjectClassInArray:^NSDictionary *{
            return @{
                     @"stories" : @"LRModelStory",
                     @"topStories" : @"LRModelTopStory"
                     };
        }];
    }
    return self;
}

-(void)printAllModels {
    NSLog(@"dete =n%@",self.date);
    NSLog(@"story = {");
    for (LRModelStory *story in self.stories) {
        NSLog(@" title = %@\n,url = %@\n,storyID = %@",story.title,story.imageURLs[0],story.storyID);
    }
    NSLog(@"}");
    NSLog(@"top_stories = {");
    for (LRModelTopStory *story in self.topStories) {
        NSLog(@"title = %@\n,url = %@\n,storyID = %@",story.title,story.imageURL,story.storyID);
    }
    NSLog(@"}");

}

- (void)addStories:(NSArray *)newStories {
    self.stories = [self.stories arrayByAddingObjectsFromArray:newStories];
}
@end
