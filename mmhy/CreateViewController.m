//
//  CreateViewController.m
//  mmhy
//
//  Created by Micker on 2018/7/25.
//  Copyright © 2018年 micker. All rights reserved.
//

#import "CreateViewController.h"
#import "MSkeletonImageHandler.h"

@interface CreateViewController ()

@property (nonatomic, strong)MSkeletonImageHandler *imageHandler;

@end

@implementation CreateViewController {
    UIImageView *_imageView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doAction:)];
    [self.navigationItem setRightBarButtonItem:barItem];
    
    
    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    _imageView.image = [UIImage imageNamed:@"5.jpg"];
    _imageView.contentMode = UIViewContentModeCenter;
    [self.view addSubview:_imageView];
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doAction:(id)sender {
    if (!self.imageHandler) {
        self.imageHandler = [[MSkeletonImageHandler alloc] init];
    }
    
    [self.imageHandler doSetSourceImage:_imageView.image block:^(UIImage *image) {
       
        self->_imageView.image = image;
    }];
}

@end
