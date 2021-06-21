//
//  HYView.h
//  mmhy
//
//  Created by Micker on 16/4/23.
//  Copyright © 2016年 micker. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, MDrawableType) {
    MDrawableTypeColor,
    MDrawableTypeWenli,
    MDrawableTypeShadow,
    MDrawableTypeCount,
};

@interface HYView : UIImageView
@property int type;
@property MDrawableType drawableType;

- (void) drawAtPoint:(CGPoint) point;

@end
