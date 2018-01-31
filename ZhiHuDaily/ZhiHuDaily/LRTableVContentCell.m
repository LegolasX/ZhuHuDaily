//
//  LRTableVCellContent.m
//  ZhiHuDaily
//
//  Created by Legolas.Invoker on 2017/4/11.
//  Copyright © 2017年 Chang.Jing. All rights reserved.
//

#import "LRTableVContentCell.h"

@interface LRTableVContentCell()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;


@end
@implementation LRTableVContentCell
@synthesize imageView;
@synthesize textLabel;


- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor lightGrayColor];
    UIView *bkView = [[UIView alloc]initWithFrame:self.frame];
    bkView.backgroundColor = [UIColor whiteColor];
    CALayer *layer = bkView.layer;
    layer.cornerRadius = 15;
    layer.borderWidth = 2;
    layer.borderColor = [[UIColor lightGrayColor] CGColor];
    [self setBackgroundView:bkView];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
