//
//  MImageHandler.h
//  mmhy
//
//  Created by Micker on 2018/7/12.
//  Copyright © 2018年 micker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, MGradientType) {
    MGradientTypeH,
    MGradientTypeV,
    MGradientTypeC,
};

@interface MColor : NSObject
@property(nullable, copy) NSArray *colors;
@property(nullable, copy) NSArray<NSNumber *> *locations;
@property MGradientType gradientType;
@property(copy) NSString *name;

- (void) setMin:(CGPoint) min max:(CGPoint)max;
- (UInt32) colorAtX:(NSInteger)x y:(NSInteger)y;
@end


@interface MImageHandler : NSObject

@property (nonatomic, strong) UIImage *sourceImage;
@property (nonatomic, assign, readonly) NSInteger width;
@property (nonatomic, assign, readonly) NSInteger height;

- (void) drawAtPoint:(CGPoint) point
              colors:(NSArray *)colors
           locations:(NSArray *)locations
               block:(void(^)(UIImage *image)) block;

@end
