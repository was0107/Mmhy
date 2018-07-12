//
//  HYView.m
//  mmhy
//
//  Created by Micker on 16/4/23.
//  Copyright © 2016年 micker. All rights reserved.
//

#import "HYView.h"
#import "MImageHandler.h"


@interface HYView()
@property (nonatomic, strong) NSMutableArray *xStack;
@property (nonatomic, strong) NSMutableArray *yStack;
@property (nonatomic, strong) MImageHandler *imageHandler;

@end

@implementation HYView
- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.imageHandler = [[MImageHandler alloc] init];

    return self;
}

- (void) setImage:(UIImage *)image {
    [super setImage:image];
    self.imageHandler.sourceImage = image;
}

- (void) drawOnPoint:(CGPoint) point {
//    UIColor *color = nil;
//    CAGradientLayer *layer = nil;
    [self.imageHandler drawOnPoint:point block:^(UIImage *image) {
        self.image = image;
    }];
}


@end
