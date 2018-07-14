//
//  MImageHandler.m
//  mmhy
//
//  Created by Micker on 2018/7/12.
//  Copyright © 2018年 micker. All rights reserved.
//

#define Mask8(x) ( (x) & 0xFF ) // Un masque est défini
#define R(x) ( Mask8(x) )       // Pour accèder au canal rouge il faut masquer les 8 premiers bits
#define G(x) ( Mask8(x >> 8 ) ) // Pour le vert, effectuer un décalage de 8 bits et masquer
#define B(x) ( Mask8(x >> 16) ) // Pour le bleu, effectuer un décalage de 16 bits et masquer
#define A(x) ( Mask8(x >> 24) ) // L'élément A est ajouté aux paramètres RGBA, avec un masquage des 24 premiers bits (pour obtenir au total 32 bits)
#define RGBAMake(r, g, b, a) ( Mask8(r) | Mask8(g) << 8 | Mask8(b) << 16 | Mask8(a) << 24 )


#import "MImageHandler.h"

@implementation MColor

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
    int ldis = 1 - dis, rdis = dis;
    return RGBAMake(ar * ldis + br * rdis,
                    ag * ldis + bg * rdis,
                    ab * ldis + bb * rdis,
                    aa * ldis + ba * rdis);
}

- (UInt32) colorAtX:(NSInteger)x y:(NSInteger)y  min:(CGPoint) min max:(CGPoint)max{
    UInt32 result = 0;
    if ([self.locations count] == 0) {
        return [self getColorAtIndex:0];
    }
    NSInteger width = (max.x - min.x);
//    NSInteger hegith = (max.y - min.y);
//    NSInteger round = MAX(width,hegith);
    NSUInteger count = [self.locations count];
    switch (self.gradientType) {
        case MGradientTypeH: {
            CGFloat dis = (x - min.x) / width;
            int index = -1;
            for (int i = 0; i< count; i++) {
                if ([self.locations[i] floatValue] > dis) {
                    index = i;
                    break;
                }
            }
            if (-1 == index) {
                return [self getColorAtIndex:0];
            } else {
                UInt32 beforeColor = [self getColorAtIndex:index];
                UInt32 afterColor = [self getColorAtIndex:index +1];
                float bf = [self.locations[index] floatValue];
                float af = (index+1 >= [self.locations count]-1)?1.0f:[self.locations[index+1] floatValue];
                return [self gradientColorA:beforeColor B:afterColor dis:(dis-bf)/(af-bf)];
            }
            
        }
            break;
            
        case MGradientTypeV:
            
            break;
            
        case MGradientTypeC:
            
            break;
            
        default:
            break;
    }
    
    
    
    return result;
}

@end

@interface MImageHandler()
@property (nonatomic, strong) NSLock *imageLock;
@property (nonatomic, strong) UIImage *originImage;
@property (nonatomic, strong) NSMutableArray *xStack;
@property (nonatomic, strong) NSMutableArray *yStack;
@property (nonatomic, copy) NSArray *colors;
@property (nonatomic, copy) NSArray *locations;
@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@end

@implementation MImageHandler {
    UInt32 * _pixels;
    UInt32 * _originPixels;
    NSUInteger MINX, MAXX, MINY, MAXY;
    MColor *_color;

}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.xStack = [NSMutableArray arrayWithCapacity:10];
        self.yStack = [NSMutableArray arrayWithCapacity:10];
        _color = [[MColor alloc] init];
        _color.colors = @[(__bridge id)[UIColor redColor].CGColor,
                          (__bridge id)[UIColor whiteColor].CGColor];
        _color.locations = @[@(0.25)];
    }
    return self;
}


- (void) setSourceImage:(UIImage *)sourceImage {
    _sourceImage = sourceImage;
    if (!self.originImage) {
        self.originImage = sourceImage;
        CGImageRef inputCGImage = [_sourceImage CGImage];
        self.width  = CGImageGetWidth(inputCGImage) ;
        self.height = CGImageGetHeight(inputCGImage) ;
    }
}

- (NSLock *) imageLock {
    if (!_imageLock) {
        _imageLock = [[NSLock alloc] init];
    }
    return _imageLock;
}


- (void) drawAtPoint:(CGPoint) point colors:(NSArray *)colors locations:(NSArray *)locations  block:(void(^)(UIImage *image)) block{
    __weak typeof(self) weakSelf = self;
    static int x = 255;
    NSInteger pointx = point.x/4 * 4;
    NSInteger pointy = point.y/4 * 4;
    if (pointy > _height || pointx > _width) {
        NSLog(@"wroing aera!");
        return;
    }
    
    self.colors = colors;
    self.locations = locations;
    
    UIImage *tmpImage = self.sourceImage;
    dispatch_async(dispatch_queue_create("my.concurrent.queue", DISPATCH_QUEUE_CONCURRENT), ^{
        
        [weakSelf.imageLock lock];
        CGImageRef inputCGImage = [tmpImage CGImage];
        
        // 2.
        NSUInteger bytesPerPixel = 4;
        NSUInteger bytesPerRow = bytesPerPixel * weakSelf.width;
        NSUInteger bitsPerComponent = 8;
        
        self->_pixels = (UInt32 *) calloc(weakSelf.height * weakSelf.width, sizeof(UInt32));
        
        // 3.
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(self->_pixels, weakSelf.width , weakSelf.height,
                                                     bitsPerComponent,
                                                     bytesPerRow,
                                                     colorSpace,
                                                     kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGContextDrawImage(context, CGRectMake(0, 0, weakSelf.width, weakSelf.height), inputCGImage);

        self->_originPixels = (UInt32 *) calloc(weakSelf.height * weakSelf.width, sizeof(UInt32));
        CGContextRef originContext = CGBitmapContextCreate(self->_originPixels, weakSelf.width , weakSelf.height,
                                                           bitsPerComponent,
                                                           bytesPerRow,
                                                           colorSpace,
                                                           kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGContextDrawImage(originContext, CGRectMake(0, 0, weakSelf.width, weakSelf.height), [weakSelf.originImage CGImage]);
        UInt32 *originCurrentPixel = self->_originPixels + pointx + pointy * weakSelf.width;
        CGColorSpaceRelease(colorSpace);
        
        for (int i = 0 ; i < 1; i++) {
            @autoreleasepool{
                [self doGetRectWithFloodFillScanLineWithStack:pointx
                                                            y:pointy
                                                     newColor:RGBAMake(x, 255-x, 255-x, 255)
                                                     oldColor:*originCurrentPixel];
                
                CGContextDrawImage(originContext, CGRectMake(0, 0, weakSelf.width, weakSelf.height), [weakSelf.originImage CGImage]);
                
                [self floodFillScanLineWithStack:pointx
                                               y:pointy
                                        newColor:RGBAMake(x, 255-x, 255-x, 255)
                                        oldColor:*originCurrentPixel];
                
                x-= 40;
                if (x<0) {
                    x = 255;
                }
                //    [self floodFill4:(int)(point.x) y:(int)(point.y) newColor:RGBAMake(255, 0, 0, 255) oldColor:*currentPixel];
                //    [self floodFill8:(int)(point.x) y:(int)(point.y) newColor:RGBAMake(255, 0, 0, 255) oldColor:*currentPixel];
            }
        }
        
        CGImageRef processedCGImage = CGBitmapContextCreateImage(context);
        UIImage *image = [UIImage imageWithCGImage:processedCGImage];
        CGContextRelease(context);
        CGContextRelease(originContext);
        CGImageRelease(processedCGImage);
        [self freePoint:self->_pixels];
        [self freePoint:self->_originPixels];
        dispatch_async(dispatch_get_main_queue(), ^{
            !block?:block(image);
            [weakSelf.imageLock unlock];
        });
    });
}

- (void) freePoint:(UInt32*) point {
    if (point) {
        free(point);
        point = NULL;
    }
}


#pragma mark -- algraum

- (UInt32) roundColorX:(NSInteger)x y:(NSInteger)y color:(UInt32) color pixels:(UInt32 *) pix {
    
    static int radius = 0;
    int colorR=R(color), colorG=G(color),colorB=B(color), size = 1;
    for (int i = -radius; i < radius; i++) {
        for (int j = -radius; j < radius; j++) {
            if((x+i >= 0 && x+i < _width) &&
               (y+j >= 0 && y+j < _height) &&
               [self compare:[self getColorX:x+i y:y+j pixels:pix] old:color]) {
                UInt32 color = [self getColorX:x+i y:y+j pixels:pix];
                colorR+=R(color);
                colorG+=G(color);
                colorB+=B(color);
                size++;
            }
        }
    }
    return RGBAMake(colorR/size, colorG/size, colorB/size,A(color));
}

- (void) doGetRectWithFloodFillScanLineWithStack:(NSInteger) x y:(NSInteger)y newColor:(UInt32) newColor oldColor:(UInt32) oldColor {
    
    NSInteger originX = x, originY = y;
    UInt32 roundColor = [self roundColorX:x y:y color:oldColor pixels:_originPixels];
    NSInteger y1;
    BOOL spanLeft, spanRight;
    
    MINX = _width;
    MINY = _height;
    MAXX = MAXY = 0;
    
    [self.xStack removeAllObjects];
    [self.yStack removeAllObjects];
    
    [self pushX:originX y:originY];
    
    while(true)
    {
        x = [self popX];
        if(x == -1)
            break;
        y = [self popY];
        
        y1 = y;
        while(y1 >= 0 && [self compare:[self getColorX:x y:y1 pixels:_originPixels] old:roundColor])
            y1--; // go to line top/bottom
        
        y1++; // start from line starting point pixel
        spanLeft = spanRight = false;
        MINY = MIN(y1,MINY);
        
        while(y1 < _height && [self compare:[self getColorX:x y:y1 pixels:_originPixels] old:roundColor])
        {
            [self setColorX:x y:y1 color:newColor pixels:_originPixels];
            
            if(!spanLeft && x > 0 && [self compare:[self getColorX:x-1 y:y1 pixels:_originPixels] old:roundColor])// just keep left line once in the stack
            {
                [self pushX:x-1 y:y1];
                spanLeft = true;
            }
            else if(spanLeft && x > 0 && ![self compare:[self getColorX:x-1 y:y1 pixels:_originPixels] old:roundColor])
            {
                spanLeft = false;
            }
            
            if(!spanRight && x < _width - 1 && [self compare:[self getColorX:x+1 y:y1 pixels:_originPixels] old:roundColor]) // just keep right line once in the stack
            {
                [self pushX:x+1 y:y1];
                spanRight = true;
            }
            else if(spanRight && x < _width - 1 && ![self compare:[self getColorX:x+1 y:y1 pixels:_originPixels] old:roundColor])
            {
                spanRight = false;
            }
            y1++;
            
        }
        MINX = MIN(x,MINX);
        MAXX = MAX(x,MAXX);
        MAXY = MAX(y1,MAXY);
    }
    NSLog(@"MINX, MAXX, MINY,MAXY= %ld, %ld,%ld, %ld",MINX, MAXX, MINY,MAXY);
}

- (void) floodFillScanLineWithStack:(NSInteger) x y:(NSInteger)y newColor:(UInt32) newColor oldColor:(UInt32) oldColor
{
    if(newColor == oldColor) {
        printf("do nothing !!!, filled area!!");
        return;
    }
    NSInteger originX = x, originY = y;
    NSInteger y1;
    BOOL spanLeft, spanRight;
    
    UInt32 roundColor = [self roundColorX:x y:y color:oldColor pixels:_originPixels];
    
    [self.xStack removeAllObjects];
    [self.yStack removeAllObjects];
    [self pushX:originX y:originY];
    
    while(true)
    {
        x = [self popX];
        if(x == -1)
            break;
        y = [self popY];
        
        y1 = y;
        
        while(y1 >= 0 && [self compare:[self getColorX:x y:y1 pixels:_originPixels] old:roundColor])
            y1--; // go to line top/bottom
        
        y1++; // start from line starting point pixel
        spanLeft = spanRight = false;
        
        while(y1 < _height && [self compare:[self getColorX:x y:y1 pixels:_originPixels] old:roundColor])
        {
            [self setColorX:x y:y1 color:newColor  pixels:_originPixels];
//            if (x < MAXX/2 && y1 < MAXY/2) {
//                [self setColorX:x y:y1 color:RGBAMake(124,255,124,255)  pixels:_pixels];
//            } else {
//                [self setColorX:x y:y1 color:newColor  pixels:_pixels];
//            }
            
            UInt32 neColor = [_color colorAtX:x y:y1 min:CGPointMake(MINX, MINY) max:CGPointMake(MAXX, MAXY)];
            [self setColorX:x y:y1 color:neColor  pixels:_pixels];
            
            if(!spanLeft && x > 0 && [self compare:[self getColorX:x-1 y:y1 pixels:_originPixels] old:roundColor])// just keep left line once in the stack
            {
                [self pushX:x-1 y:y1];
                spanLeft = true;
            }
            else if(spanLeft && x > 0 && ![self compare:[self getColorX:x-1 y:y1 pixels:_originPixels] old:roundColor])
            {
                spanLeft = false;
            }
            
            if(!spanRight && x < _width - 1 && [self compare:[self getColorX:x+1 y:y1 pixels:_originPixels] old:roundColor]) // just keep right line once in the stack
            {
                [self pushX:x+1 y:y1];
                spanRight = true;
            }
            else if(spanRight && x < _width - 1 && ![self compare:[self getColorX:x+1 y:y1 pixels:_originPixels] old:roundColor])
            {
                spanRight = false;
            }
            y1++;
            
        }
    }
}

- (void) floodFill4:(NSInteger) x y:(NSInteger)y newColor:(UInt32) newColor oldColor:(UInt32) oldColor {
    if(oldColor == newColor) {
        printf("do nothing !!!, filled area!!");
        return;
    }
    
    if(x >= 0 && x < _width &&
       y >= 0 && y < _height &&
       [self compare:[self getColorX:x y:y] old:oldColor])
    {
        [self setColorX:x y:y color:newColor];
        
        [self floodFill4:x+1 y:y newColor:newColor oldColor:oldColor];
        [self floodFill4:x-1 y:y newColor:newColor oldColor:oldColor];
        [self floodFill4:x y:y+1 newColor:newColor oldColor:oldColor];
        [self floodFill4:x y:y-1 newColor:newColor oldColor:oldColor];
    }
}

- (void) floodFill8:(NSInteger) x y:(NSInteger)y newColor:(UInt32) newColor oldColor:(UInt32) oldColor {
    //    if(oldColor == newColor) {
    //        printf("do nothing !!!, filled area!!");
    //        return;
    //    }
    
    if(x >= 0 && x < _width &&
       y >= 0 && y < _height &&
       [self compare:[self getColorX:x y:y] old:oldColor])
    {
        [self setColorX:x y:y color:newColor];
        [self floodFill8:x+1 y:y newColor:newColor oldColor:oldColor];
        [self floodFill8:x-1 y:y newColor:newColor oldColor:oldColor];
        [self floodFill8:x y:y+1 newColor:newColor oldColor:oldColor];
        [self floodFill8:x y:y-1 newColor:newColor oldColor:oldColor];
        
        
        [self floodFill8:x+1 y:y+1 newColor:newColor oldColor:oldColor];
        [self floodFill8:x-1 y:y+1 newColor:newColor oldColor:oldColor];
        [self floodFill8:x+1 y:y-1 newColor:newColor oldColor:oldColor];
        [self floodFill8:x-1 y:y-1 newColor:newColor oldColor:oldColor];
    }
}
- (BOOL) compare:(UInt32) new old:(UInt32) old {
    static float eff = 5.0f;
    if(fabs(1.0f * R(old) - R(new)) < eff &&
       fabs(1.0f * G(old) - G(new)) < eff &&
       fabs(1.0f * B(old) - B(new)) < eff)
        return YES;
    return NO;
}

- (UInt32) getColorX:(NSInteger) x y:(NSInteger)y {
    return [self getColorX:x y:y pixels:_pixels];
}

- (UInt32) getColorX:(NSInteger) x y:(NSInteger)y pixels:(UInt32 *) pix {
    UInt32 *currentPixel = pix + x + y * _width;
    return *currentPixel;
}

- (void) setColorX:(NSInteger) x y:(NSInteger)y color:(UInt32) color {
    [self setColorX:x y:y color:color pixels:_pixels];
}

- (void) setColorX:(NSInteger) x y:(NSInteger)y color:(UInt32) color  pixels:(UInt32 *) pix {
    UInt32 *currentPixel = pix + x + y * _width;
    *currentPixel = color;
}

- (NSInteger) popX {
    if ([self.xStack count] == 0) {
        return -1;
    }
    NSNumber *number = [self.xStack lastObject];
    [self.xStack removeObjectAtIndex:[self.xStack count] -1];
    return [number integerValue];
}

- (NSInteger) popY {
    if ([self.yStack count] == 0) {
        return -1;
    }
    NSNumber *number = [self.yStack lastObject];
    [self.yStack removeObjectAtIndex:[self.yStack count] -1];
    return [number integerValue];
}

- (void) pushX:(NSInteger) x y:(NSInteger) y {
    [self.xStack addObject:@(x)];
    [self.yStack addObject:@(y)];
    //    NSLog(@"x = %d, y = %d", x, y);
}



@end
