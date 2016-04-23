//
//  ViewController.m
//  mmhy
//
//  Created by Micker on 16/4/23.
//  Copyright © 2016年 micker. All rights reserved.
//

#import "ViewController.h"
#import "HYView.h"


@interface ViewController ()
@property (nonatomic, strong) HYView *hyView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.hyView = [[HYView alloc] initWithFrame:CGRectMake(0, 40, 300, 400)];
    self.hyView.image = [UIImage imageNamed:@"rect"];
    [self.view addSubview:self.hyView];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
