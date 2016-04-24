//
//  RootViewController.m
//  mmhy
//
//  Created by Micker on 16/4/24.
//  Copyright © 2016年 micker. All rights reserved.
//

#import "RootViewController.h"
#import "ViewController.h"
@interface  RootViewController()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;


@end

static NSString *images[] = {
    @"fgjx.png",
    @"rect",
    @"hy.png",
    @"long.jpg",
    @"lyltm.png",
    @"mdh.jpg",
    @"mn.jpg",
    @"xnqyl.png",
    @"yjx.png",
    @"ylxt.png",
    @"zbpa.jpg"};//

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"列表";
    [self.view addSubview:self.tableView];
    [self.tableView reloadData];
    // Do any additional setup after loading the view, typically from a nib.
}

- (UITableView *) tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"bulabula"];
    }
    return _tableView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ViewController *controller = [[ViewController alloc] init];
    controller.imageName = images[indexPath.row];
    [self.navigationController pushViewController:controller animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 11;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bulabula"];
    cell.textLabel.text = images[indexPath.row];
    return cell;
}
@end
