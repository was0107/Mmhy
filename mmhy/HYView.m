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

@implementation HYView {
    MColor *_color;
}
- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.imageHandler = [[MImageHandler alloc] init];

    return self;
}

- (void) setImage:(UIImage *)image {
    [super setImage:image];
    self.imageHandler.sourceImage = image;
}

- (void) drawAtPoint:(CGPoint) point {
    
    if(!_color) {
        _color = [MColor newColors:@"FF0000,00FF00,0000FF" locations:@"0.15,0.85,1" type:0 name:@"1"];
    }
    
    [self.imageHandler drawAtPoint:point
                             color:_color
                             block:^(UIImage *image) {
        self.image = image;
    }];
}


@end
