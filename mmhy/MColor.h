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
@property BOOL isGradientColor;
@property(copy) NSString *name;

+ (instancetype) newColors:(NSString *) colors locations:(NSString *)locations type:(int)type name:(NSString *)name;

- (id) setColorString:(NSString *)stringColor;

- (id) setLocationString:(NSString *)stringLocation;

- (void) setMin:(CGPoint) min max:(CGPoint)max center:(CGPoint)center;

- (UInt32) colorAtX:(NSInteger)x y:(NSInteger)y;

- (UInt32) getColorAtIndex:(NSInteger) index;
@end
