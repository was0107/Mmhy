//
//  MSkeletonImageHandler.h
//  mmhy
//
//  Created by Micker on 2018/7/25.
//  Copyright © 2018年 micker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MColor.h"
#import "MColorDefine.h"

@interface MSkeletonImageHandler : NSObject

@property (nonatomic, strong) UIImage *sourceImage;
@property (nonatomic, assign, readonly) NSInteger width;
@property (nonatomic, assign, readonly) NSInteger height;


- (void) doSetSourceImage:(UIImage *) source
                    block:(ImageBlock) block;
@end
