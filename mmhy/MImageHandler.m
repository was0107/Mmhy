//
//  MImageHandler.m
//  mmhy
//
//  Created by Micker on 2018/7/12.
//  Copyright © 2018年 micker. All rights reserved.
//

#import "MImageHandler.h"
#import "MColorDefine.h"
#import "UIImage+Extend.h"

@interface MImageHandler()
@property (nonatomic, strong) NSLock *imageLock;
@property (nonatomic, strong) UIImage *originImage;
@property (nonatomic, strong) NSMutableArray *xStack;
@property (nonatomic, strong) NSMutableArray *yStack;
@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, strong) MColor *color;
@property (nonatomic, copy) ImageBlock block;
@end

@implementation MImageHandler {
    UInt32 * _pixels;
    UInt32 * _originPixels;
    NSUInteger MINX, MAXX, MINY, MAXY;
    NSUInteger _lineCount ;

}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.xStack = [NSMutableArray arrayWithCapacity:10];
        self.yStack = [NSMutableArray arrayWithCapacity:10];//
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

- (void) setWenliImage:(UIImage *)wenliImage {
    if (!self.sourceImage) {
        return;
    }
    _wenliImage = [wenliImage imageByScalingProportionallyToSize:CGSizeMake(self.width, self.height)];
}


- (NSLock *) imageLock {
    if (!_imageLock) {
        _imageLock = [[NSLock alloc] init];
    }
    return _imageLock;
}

- (void) drawAtPoint:(CGPoint) point
               color:(MColor *)color
               block:(ImageBlock) block{
    __weak typeof(self) weakSelf = self;
    static int x = 255;
    NSInteger pointx = point.x/4 * 4;
    NSInteger pointy = point.y/4 * 4;
    if (pointy > _height || pointx > _width) {
        NSLog(@"wroing aera!");
        return;
    }

    self.color = color;
    UIImage *tmpImage = self.sourceImage;
    self.block = block;
    dispatch_async(dispatch_queue_create("micker.concurrent.queue", DISPATCH_QUEUE_CONCURRENT), ^{
        
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

        CGContextRef originContext = NULL;
        if (self->_color.isGradientColor) {
            
            self->_originPixels = (UInt32 *) calloc(weakSelf.height * weakSelf.width, sizeof(UInt32));
            originContext = CGBitmapContextCreate(self->_originPixels, weakSelf.width , weakSelf.height,
                                               bitsPerComponent,
                                               bytesPerRow,
                                               colorSpace,
                                               kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
            CGContextDrawImage(originContext, CGRectMake(0, 0, weakSelf.width, weakSelf.height), [weakSelf.originImage CGImage]);
            CGColorSpaceRelease(colorSpace);
            
        } else {
            self->_originPixels = self->_pixels;
        }
        
        UInt32 *originCurrentPixel = self->_originPixels + pointx + pointy * weakSelf.width;

        for (int i = 0 ; i < 1; i++) {
            @autoreleasepool{
                self->_lineCount = 0;
                UInt32 newColor = RGBAMake(x, 255-x, 255-x, 255);
                if (self->_color.isGradientColor) {
                    [self doGetRectWithFloodFillScanLineWithStack:pointx
                                                                y:pointy
                                                         newColor:newColor
                                                         oldColor:*originCurrentPixel];
                    
                    CGContextDrawImage(originContext, CGRectMake(0, 0, weakSelf.width, weakSelf.height), [weakSelf.originImage CGImage]);
                    
                    [weakSelf.color setMin:CGPointMake(self->MINX, self->MINY)
                                       max:CGPointMake(self->MAXX, self->MAXY)
                                    center:CGPointMake(pointx, pointy)];
                }
                else {
                    newColor = [self->_color getColorAtIndex:0];
                }
                
                [self floodFillScanLineWithStack:pointx
                                               y:pointy
                                        newColor:newColor
                                        oldColor:*originCurrentPixel
                                         context:context];
                
//                [self floodFill4:pointx y:pointy newColor:RGBAMake(x, 255-x, 255-x, 255) oldColor:*originCurrentPixel context:context];
//                [self floodFill8:(int)(point.x) y:(int)(point.y) newColor:RGBAMake(255, 0, 0, 255) oldColor:*originCurrentPixel];
                
                x-= 40;
                if (x<0) {x = 255;}
            }
        }
        
        UIImage *image = [self currentImageInContext:context];
        dispatch_async(dispatch_get_main_queue(), ^{
            !block?:block(image);
            [weakSelf.imageLock unlock];
        });
        CGContextRelease(context);
        CGContextRelease(originContext);
        [self freePoint:self->_pixels];
        !self.color.isGradientColor?:[self freePoint:self->_originPixels];
    });
}

- (void) printCurrentImage:(CGContextRef) context {
    UIImage *image = [self currentImageInContext:context];
    dispatch_async(dispatch_get_main_queue(), ^{
        !self.block?:self.block(image);
    });
}

- (UIImage *) currentImageInContext:(CGContextRef) context {
    CGImageRef processedCGImage = CGBitmapContextCreateImage(context);
    UIImage *image = [UIImage imageWithCGImage:processedCGImage];
    CGImageRelease(processedCGImage);
    return image;
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
//    NSLog(@"MINX, MAXX, MINY,MAXY= %ld, %ld,%ld, %ld",MINX, MAXX, MINY,MAXY);
}

- (void) floodFillScanLineWithStack:(NSInteger) x y:(NSInteger)y newColor:(UInt32) newColor oldColor:(UInt32) oldColor context:(CGContextRef) context
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
            !self.color.isGradientColor?:[self setColorX:x y:y1 color:[_color colorAtX:x y:y1 ]  pixels:_pixels];
            
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
        
        /**** Animate image
        if (self.animated && ++_lineCount %50 == 0) {
            [self printCurrentImage:context];
        }
        *****/
    }
}

- (void) floodFill4:(NSInteger) x y:(NSInteger)y newColor:(UInt32) newColor oldColor:(UInt32) oldColor context:(CGContextRef) context{
    if(oldColor == newColor) {
        printf("do nothing !!!, filled area!!");
        return;
    }
    
    if(x >= 0 && x < _width &&
       y >= 0 && y < _height &&
       [self compare:[self getColorX:x y:y pixels:_originPixels] old:oldColor])
    {
        [self setColorX:x y:y color:newColor pixels:_originPixels];
        [self setColorX:x y:y color:[_color colorAtX:x y:y ] pixels:_pixels];
        
        /**** Animate image
         if (self.animated && ++_lineCount %50 == 0) {
         [self printCurrentImage:context];
         }
         *****/
        [self floodFill4:x+1 y:y newColor:newColor oldColor:oldColor context:context];
        [self floodFill4:x-1 y:y newColor:newColor oldColor:oldColor context:context];
        [self floodFill4:x y:y+1 newColor:newColor oldColor:oldColor context:context];
        [self floodFill4:x y:y-1 newColor:newColor oldColor:oldColor context:context];
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
