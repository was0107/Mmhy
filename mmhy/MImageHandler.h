//
//  MImageHandler.h
//  mmhy
//
//  Created by Micker on 2018/7/12.
//  Copyright © 2018年 micker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MColor.h"

typedef void (^ImageBlock)(UIImage *image);


@interface MImageHandler : NSObject

@property (nonatomic, strong) UIImage *sourceImage;
@property (nonatomic, assign, readonly) NSInteger width;
@property (nonatomic, assign, readonly) NSInteger height;

- (void) drawAtPoint:(CGPoint) point
               color:(MColor *)color
               block:(ImageBlock) block;

@end
