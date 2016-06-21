//
//  PaintViewController.m
//  mmhy
//
//  Created by Micker on 16/6/22.
//  Copyright © 2016年 micker. All rights reserved.
//

#import "PaintViewController.h"
#import "HYView.h"

@interface PaintViewController ()<UIScrollViewDelegate>
@property (nonatomic, strong) HYView *hyView;
@property (nonatomic, strong) UIScrollView *scrollView;
@end

@implementation PaintViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"详情";
    self.view.backgroundColor = [UIColor whiteColor];
    self.hyView = [[HYView alloc] initWithFrame:CGRectMake(0, 0, 300, 400)];
    self.hyView.image = [UIImage imageNamed:self.imageName];
    CGImageRef inputCGImage = [self.hyView.image CGImage];
    NSUInteger width  = CGImageGetWidth(inputCGImage);
    NSUInteger height = CGImageGetHeight(inputCGImage);
    self.hyView.frame = CGRectMake(self.hyView.frame.origin.x, 0, width, height);
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)-64)];
    self.scrollView.contentSize = self.hyView.bounds.size;
    self.scrollView.delegate = self;
    [self.scrollView addSubview:self.hyView];
    [self.scrollView setMaximumZoomScale:5.0f];
    CGFloat scale = self.view.bounds.size.width/width;
    [self.scrollView setMinimumZoomScale:scale];
    [self.scrollView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gesture:)]];
    [self.view addSubview:self.scrollView];
    [self.scrollView setZoomScale:scale animated:YES] ;
    // Do any additional setup after loading the view, typically from a nib.
}

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.hyView;
}

- (void) gesture:(UIGestureRecognizer *) recognizer {
    CGPoint point = [recognizer locationInView:self.scrollView];
    point = CGPointMake(point.x/self.scrollView.zoomScale, point.y/self.scrollView.zoomScale);
    [self.hyView drawOnPoint:point];
}

@end
