//
//  UIColor+Extend.h
//  DealExtreme
//
//  Created by micker on 10-8-30.
//  Copyright 2010 epro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*!
 *  UIColor(Extend)
 */
@interface UIColor(Extend)

/*!
 *	从十六进的字符串中获取对应的颜色,透明度为1
 *
 *	@param hexColor
 *
 *	@return color
 *  @see getColor:alpha:
 */
+ (UIColor *)getColor:(NSString *) hexColor;

/*!
 *	从十六进的字符串中获取对应的颜色,
 *
 *	@param hexColor 颜色值
 *	@param alpha    透明度
 *
 *	@return color
 *  @see getColor:
 */
+ (UIColor *)getColor:(NSString *) hexColor alpha:(CGFloat)alpha;

//red,green,blue : [0, 255]
//alpha: [0, 1]
+ (UIColor *) getColor:(NSUInteger)red :(NSUInteger)green :(NSUInteger)blue;
+ (UIColor *) getColor:(NSUInteger)red :(NSUInteger)green :(NSUInteger)blue alpha:(CGFloat)alpha;

@end
