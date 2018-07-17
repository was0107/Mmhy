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
    CGPoint _center;
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
    return RGBAMake((int)components[0]*255,(int)components[1]*255,(int)components[2]*255,(int)components[3]*255);
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
    UInt8 ar = R(colora),  ag = G(colora), ab = B(colora), aa = A(colora);
    UInt8 br = R(colorb),  bg = G(colorb), bb = B(colorb), ba = A(colorb);
    float ldis = 1 - dis, rdis = dis;
    return RGBAMake((UInt8)(ar * ldis + br * rdis),
                    (UInt8)(ag * ldis + bg * rdis),
                    (UInt8)(ab * ldis + bb * rdis),
                    (UInt8)(aa * ldis + ba * rdis));
}

- (void) setMin:(CGPoint) min max:(CGPoint)max {
    
    if ([self.locations count] != [self.locations count]) {
        NSLog(@"Error config");
    }
    _min = min;
    _max = max;
    NSUInteger count = [self.locations count];
    if (_newPixels != NULL) {
        free(_newPixels);
        _newPixels = NULL;
    }
    NSInteger targentLength = 0;
    switch (self.gradientType) {
        case MGradientTypeH: {
            targentLength = (max.x - min.x);
        }
            break;
            
        case MGradientTypeV:
            targentLength = (max.y - min.y);
            break;
            
        case MGradientTypeC: {
            int xRound = (max.x - min.x)/2 + 1;
            int yRound = (max.y - min.y)/2 + 1;
            targentLength = (int)(sqrt( xRound*xRound + yRound*yRound) + 1);
            _center = CGPointMake((_max.x - _min.x)/2, (_max.y - _min.y)/2);
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
        if (dis <= self.locations[0].floatValue) {
            color =  [self getColorAtIndex:0];
            
        } else if (dis >= self.locations[count-1].floatValue) {
            color =  [self getColorAtIndex:count-1];
        } else {
            int index = 0;
            for (int j = 0; j< count; j++) {
                if ([self.locations[j] floatValue] >= dis) {
                    index = j;
                    break;
                }
            }
            UInt32 beforeColor = [self getColorAtIndex:index-1];
            UInt32 afterColor = [self getColorAtIndex:index];
            float bf = [self.locations[index-1] floatValue];
            float af = (index >= [self.locations count]-1)?1.0f:[self.locations[index] floatValue];
            color =  [self gradientColorA:beforeColor B:afterColor dis:(dis-bf)/(af-bf)];
        }
        *currentPixel = color;
    }
}

- (UInt32) colorAtX:(NSInteger)x y:(NSInteger)y{
    
    switch (self.gradientType) {
        case MGradientTypeH:
            return (UInt32)*(_newPixels + x);
        case MGradientTypeV:
            return (UInt32)*(_newPixels + y);
        case MGradientTypeC: {
            return (UInt32)*(_newPixels + (int)(sqrt((x-_center.x)*(x-_center.x) + (y-_center.y)*(y-_center.y))));
        }default: {
            return 0;
        }
    }
}

@end
