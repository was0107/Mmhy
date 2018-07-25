//
//  MainViewController.m
//  mmhy
//
//  Created by Micker on 16/6/22.
//  Copyright © 2016年 micker. All rights reserved.
//

#import "MainViewController.h"
#import "MainCollectionViewCell.h"
#import "PaintViewController.h"
#import "CreateViewController.h"

@interface MainViewController ()<UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;

@end

@implementation MainViewController {
    NSArray *_datas;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _datas = @[@"1.jpg",
               @"rect",
               @"fgjx.png",
               @"mdh.jpg"];
    
    [self.view addSubview:self.collectionView];
    self.view.backgroundColor = [UIColor blackColor];
    [self.collectionView reloadData];
    
    UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithTitle:@"C" style:UIBarButtonItemStylePlain target:self action:@selector(doShowCreate:)];
    [self.navigationItem setRightBarButtonItem:barItem];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UICollectionView *) collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)-64) collectionViewLayout:self.flowLayout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.pagingEnabled = YES;
        _collectionView.showsHorizontalScrollIndicator = NO;
        [_collectionView registerClass:[MainCollectionViewCell class] forCellWithReuseIdentifier:@"MainCollectionViewCell"];

    }
    return _collectionView;
}

- (UICollectionViewFlowLayout *) flowLayout {
    if (!_flowLayout) {
        _flowLayout = [[UICollectionViewFlowLayout alloc] init];
        _flowLayout.minimumLineSpacing = 10.0f;
        _flowLayout.minimumInteritemSpacing = 10.0f;
        _flowLayout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
        _flowLayout.itemSize = CGSizeMake(CGRectGetWidth(self.view.bounds)/2-15.5f, CGRectGetWidth(self.view.bounds)/2-10);
        _flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    }
    return _flowLayout;
}


#pragma mark -- UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_datas count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    MainCollectionViewCell *cell = (MainCollectionViewCell *)
    [collectionView dequeueReusableCellWithReuseIdentifier:@"MainCollectionViewCell"
                                              forIndexPath:indexPath];
    [cell doSetContentData:[_datas objectAtIndex:indexPath.row]];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    PaintViewController *controller = [[PaintViewController alloc] init];
    controller.imageName = _datas[indexPath.row];
    [self.navigationController pushViewController:controller animated:YES];
}


#pragma mark --
- (IBAction)doShowCreate:(id)sender {
    CreateViewController *controller = [[CreateViewController alloc] init];
    controller.title = @"Skeleton";
    [self.navigationController pushViewController:controller animated:YES];
}


@end
