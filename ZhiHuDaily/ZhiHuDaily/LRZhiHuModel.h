//
//  LRZhiHuModel.h
//  ZhiHuDaily
//
//  Created by Legolas.Invoker on 2017/4/11.
//  Copyright © 2017年 Chang.Jing. All rights reserved.
//

#import <Foundation/Foundation.h>
//api里的sotries
@interface LRModelStory : NSObject
@property (nonatomic,copy) NSString *title;
@property (nonatomic,copy) NSArray *imageURLs;
@property (nonatomic) NSString *storyID;
@end

@interface LRModelTopStory : NSObject
@property (nonatomic,copy) NSString *title;
@property (nonatomic) NSURL *imageURL;
@property (nonatomic,copy) NSString *storyID;
@end

@interface LRZhiHuModel : NSObject
@property (nonatomic,copy) NSString *date;
@property (nonatomic,copy) NSArray *stories;
@property (nonatomic,copy) NSArray *topStories;

- (void)printAllModels;
- (void)addStories:(NSArray *)newStories;
- (NSString *)getYesterday;
@end

