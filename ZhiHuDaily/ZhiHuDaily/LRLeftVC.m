//
//  LRLeftVC.m
//  ZhiHuDaily
//
//  Created by Legolas.Invoker on 2017/5/12.
//  Copyright © 2017年 Chang.Jing. All rights reserved.
//

#import "LRLeftVC.h"
#import "AFNetworking.h"
#import "LRThemesModel.h"
#import "MJExtension.h"
@interface LRLeftVC () <UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) LRThemesModel *model;
@end

@implementation LRLeftVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.backgroundColor = [[UIColor alloc]initWithRed:0.14 green:0.16 blue:0.19 alpha:1];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    [manager GET:@"http://news-at.zhihu.com/api/4/themes" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
         _model = [LRThemesModel mj_objectWithKeyValues:responseObject];
        [_tableView reloadData];
        [_model printAllModels];
        [[AFNetworkReachabilityManager sharedManager] stopMonitoring];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@", error.description);
    }];
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma tableView datasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _model.others.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.backgroundColor = [[UIColor alloc]initWithRed:0.14 green:0.16 blue:0.19 alpha:1];
    LRThemesOther *other = _model.others[indexPath.row];
    cell.textLabel.text = other.name;
    cell.textLabel.textColor = [UIColor whiteColor];
    return cell;
    
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
