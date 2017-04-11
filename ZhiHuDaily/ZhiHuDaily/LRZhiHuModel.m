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

@end

@implementation LRZhiHuModel
@synthesize date;
@synthesize stories;

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
@end
