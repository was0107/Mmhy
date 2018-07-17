//
//  MColor.h
//  mmhy
//
//  Created by Micker on 2018/7/17.
//  Copyright © 2018年 micker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, MGradientType) {
    MGradientTypeH,
    MGradientTypeV,
    MGradientTypeC,
    MGradientTypeClear,
    MGradientTypeCount,
};

@interface MColor : NSObject
@property(nullable, copy) NSArray *colors;
@property(nullable, copy) NSArray<NSNumber *> *locations;
@property MGradientType gradientType;
@property(copy) NSString *name;

+ (instancetype) newColors:(NSString *) colors locations:(NSString *)locations type:(int)type name:(NSString *)name;

- (void) setMin:(CGPoint) min max:(CGPoint)max;

- (UInt32) colorAtX:(NSInteger)x y:(NSInteger)y;

@end
