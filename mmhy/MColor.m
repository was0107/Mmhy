//
//  MColor.m
//  mmhy
//
//  Created by Micker on 2018/7/17.
//  Copyright © 2018年 micker. All rights reserved.
//

#import "MColor.h"
#import "MColorDefine.h"
#import "UIColor+Extend.h"

@implementation MColor {
    UInt32 * _newPixels;
    CGPoint _min,_max;
    CGPoint _originCenter;
}


+ (instancetype) newColors:(NSString *) colors locations:(NSString *)locations type:(int)type name:(NSString *)name {
    MColor *color = [[MColor alloc] init];
    color.gradientType = type;
    color.name = name;
    [color setColorString:colors];
    [color setLocationString:locations];
    return color;
}

- (id) setColorString:(NSString *)stringColor {
    NSArray *temp = [stringColor componentsSeparatedByString:@","];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[temp count]];
    [temp enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [result addObject: (__bridge id)[UIColor getColor:obj].CGColor];
    }];
    self.colors = [result copy];
    self.isGradientColor = [self.colors count] > 1;
    return self;
}

- (id) setLocationString:(NSString *)stringLocation {
    NSArray *temp = [stringLocation componentsSeparatedByString:@","];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[temp count]];
    [temp enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [result addObject:@([obj floatValue])];
    }];
    self.locations = result;
    return self;
}

- (void)dealloc{
    if (_newPixels != NULL) {
        free(_newPixels);
        _newPixels = NULL;
    }
}

- (UInt32) getRGBFromColor:(CGColorRef ) colorRef {
    const CGFloat *components = CGColorGetComponents(colorRef);
    return RGBAMake((UInt8)(components[0]*255),(UInt8)(components[1]*255),(UInt8)(components[2]*255),(UInt8)(components[3]*255));
}

- (UInt32) getColorAtIndex:(NSInteger) index {
    CGColorRef colorRef = (__bridge CGColorRef)([self.colors objectAtIndex:index]);
    return [self getRGBFromColor:colorRef];
}

- (UInt32) gradientColorA:(UInt32) colora B:(UInt32) colorb dis:(CGFloat)dis {
    if (dis<0) {
        return colora;
    }
    if (dis>1) {
        return colorb;
    }
    UInt8 ar = R(colora),  ag = G(colora), ab = B(colora);//, aa = A(colora);
    UInt8 br = R(colorb),  bg = G(colorb), bb = B(colorb);//, ba = A(colorb);
    float ldis = 1.0 - dis, rdis = dis;
    return RGBAMake((UInt8)(ar * ldis + br * rdis),
                    (UInt8)(ag * ldis + bg * rdis),
                    (UInt8)(ab * ldis + bb * rdis),
                    255);
//    (UInt8)(aa * ldis + ba * rdis));
}

- (void) setMin:(CGPoint) min max:(CGPoint)max  center:(CGPoint)center{
    
    if ([self.locations count] != [self.locations count]) {
        NSLog(@"Error config");
    }
    _min = min;
    _max = max;
    _originCenter = center;

    NSUInteger count = [self.locations count];
    if (_newPixels != NULL) {
        free(_newPixels);
        _newPixels = NULL;
    }
    NSArray *tmpLocations = self.locations;
    NSInteger targentLength = 0;
    switch (self.gradientType) {
        case MGradientTypeH: {
            targentLength = MAX(fabs(center.x-min.x), fabs(center.x-max.x)) + 1;
        }
            break;
            
        case MGradientTypeV: {
            targentLength = (MAX(fabs(center.y-min.y), fabs(center.y-max.y))) + 1;
        }
            break;
            
        case MGradientTypeC: {
            int xRound = MAX(fabs(center.x-min.x), fabs(center.x-max.x)) + 1;
            int yRound = (MAX(fabs(center.y-min.y), fabs(center.y-max.y))) + 1;
            targentLength = (int)(sqrt( xRound*xRound + yRound*yRound) + 1);
        }
            break;
            
        default:
            break;
    }
    
    _newPixels = (UInt32 *) calloc(targentLength+1, sizeof(UInt32));
    for (int i =0 ; i<targentLength; i++) {
        UInt32 *currentPixel = _newPixels + i;
        CGFloat dis = 1.0f*i / targentLength;
        UInt32 color = 0;
        if (dis <= [tmpLocations[0] floatValue]) {
            color =  [self getColorAtIndex:0];
            
        } else if (dis >= [tmpLocations[count-1] floatValue]) {
            color =  [self getColorAtIndex:count-1];
        } else {
            int index = 0;
            for (int j = 0; j< count; j++) {
                if ([tmpLocations[j] floatValue] >= dis) {
                    index = j;
                    break;
                }
            }
            UInt32 beforeColor = [self getColorAtIndex:index-1];
            UInt32 afterColor = [self getColorAtIndex:index];
            float bf = [tmpLocations[index-1] floatValue];
            float af = (index >= count-1)?1.0f:[tmpLocations[index] floatValue];
            color =  [self gradientColorA:beforeColor B:afterColor dis:(dis-bf)/(af-bf)];
        }
        *currentPixel = color;
    }
}

- (UInt32) colorAtX:(NSInteger)x y:(NSInteger)y{
    
    switch (self.gradientType) {
        case MGradientTypeH:
            return (UInt32)*(_newPixels + (int)(fabs(x-_originCenter.x)));
        case MGradientTypeV:
            return (UInt32)*(_newPixels + (int)(fabs(y-_originCenter.y)));
        case MGradientTypeC: {
            int xRound = (x-_originCenter.x);
            int yRound = (y-_originCenter.y);
            return (UInt32)*(_newPixels + (int)(sqrt(xRound*xRound + yRound*yRound)));
        }default: {
            return 0;
        }
    }
}
@end
