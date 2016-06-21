//
//  MainCollectionViewCell.m
//  mmhy
//
//  Created by Micker on 16/6/22.
//  Copyright © 2016年 micker. All rights reserved.
//

#import "MainCollectionViewCell.h"

#define KScreenWidth        ([[UIScreen mainScreen] bounds].size.width)

@interface MainCollectionViewCell()

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation MainCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.imageView];
        [self __setup];
    }
    return self;
}

- (void) __setup {
    
}


- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.layer.masksToBounds = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.backgroundColor = [UIColor redColor];
    }
    return _imageView;
}


- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) doSetContentData:(id) content {
    self.imageView.image = [UIImage imageNamed:content];
}
@end
