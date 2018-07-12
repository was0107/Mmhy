//
//  HYView.m
//  mmhy
//
//  Created by Micker on 16/4/23.
//  Copyright © 2016年 micker. All rights reserved.
//

#import "HYView.h"

#define Mask8(x) ( (x) & 0xFF )// Un masque est défini
#define R(x) ( Mask8(x) )// Pour accèder au canal rouge il faut masquer les 8 premiers bits
#define G(x) ( Mask8(x >> 8 ) ) // Pour le vert, effectuer un décalage de 8 bits et masquer
#define B(x) ( Mask8(x >> 16) ) // Pour le bleu, effectuer un décalage de 16 bits et masquer
#define A(x) ( Mask8(x >> 24) ) // L'élément A est ajouté aux paramètres RGBA, avec un masquage des 24 premiers bits (pour obtenir au total 32 bits)
#define RGBAMake(r, g, b, a) ( Mask8(r) | Mask8(g) << 8 | Mask8(b) << 16 | Mask8(a) << 24 )


@interface HYView()
@property (nonatomic, strong) NSMutableArray *xStack;
@property (nonatomic, strong) NSMutableArray *yStack;

@end

@implementation HYView {
    NSMutableData *_data;
    NSMutableDictionary *_path;
    NSUInteger width,height;
    UInt32 * pixels;
    UInt32 * _originPixels;
    UIImage *_originImage;
    NSLock *_lock;
    NSUInteger MINX, MAXX, MINY, MAXY;
}

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.xStack = [NSMutableArray arrayWithCapacity:10];
    self.yStack = [NSMutableArray arrayWithCapacity:10];
    self.backgroundColor = [UIColor greenColor];
    self.userInteractionEnabled = YES;
    self.contentMode = UIViewContentModeCenter;
    _lock = [[NSLock alloc] init];
    return self;
}

- (void) setImage:(UIImage *)image {
    [super setImage:image];
    if (!_originImage) {
        _originImage = image;
    }
    if (image) {
        CGImageRef inputCGImage = [image CGImage];
        width  = CGImageGetWidth(inputCGImage) ;
        height = CGImageGetHeight(inputCGImage) ;

    }

}

- (void) drawOnPoint:(CGPoint) point {
    __weak typeof(self) weakSelf = self;
    static int x = 255;
    NSInteger pointx = point.x/4 * 4;
    NSInteger pointy = point.y/4 * 4;
    if (pointy > height || pointx > width) {
        NSLog(@"wroing aera!");
        return;
    }
    UIImage *tmpImage = self.image;
    dispatch_async(dispatch_queue_create("my.concurrent.queue", DISPATCH_QUEUE_CONCURRENT), ^{
        
        [_lock lock];
        CGImageRef inputCGImage = [tmpImage CGImage];

        // 2.
        NSUInteger bytesPerPixel = 4;
        NSUInteger bytesPerRow = bytesPerPixel * width;
        NSUInteger bitsPerComponent = 8;
        
        pixels = (UInt32 *) calloc(height * width, sizeof(UInt32));
        _originPixels = (UInt32 *) calloc(height * width, sizeof(UInt32));
        
        // 3.
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(pixels, width , height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGContextRef originContext = CGBitmapContextCreate(_originPixels, width , height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGColorSpaceRelease(colorSpace);
        
        // 4.
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), inputCGImage);
        CGContextDrawImage(originContext, CGRectMake(0, 0, width, height), [_originImage CGImage]);

        UInt32 *currentPixel = pixels + pointx + pointy * width;
        UInt32 *originCurrentPixel = _originPixels + pointx + pointy * width;

        for (int i = 0 ; i < 1; i++) {
            @autoreleasepool{
                [self doGetRectWithFloodFillScanLineWithStack:pointx y:pointy newColor:RGBAMake(x, 255-x, 255-x, 255) oldColor:*originCurrentPixel];
                [self floodFillScanLineWithStack:pointx y:pointy newColor:RGBAMake(x, 255-x, 255-x, 255) oldColor:*currentPixel];
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
        free(pixels);
        pixels = NULL;
        free(_originPixels);
        _originPixels = NULL;
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.image = image;
            [_lock unlock];
        });
    });   
}

- (void) gesture:(UIGestureRecognizer *) recognizer {
    CGPoint point = [recognizer locationInView:self.superview];
    [self drawOnPoint:point];
}

- (void) floodFill4:(NSInteger) x y:(NSInteger)y newColor:(UInt32) newColor oldColor:(UInt32) oldColor {
    if(oldColor == newColor) {
        printf("do nothing !!!, filled area!!");
        return;
    }
    
    if(x >= 0 &&
       x < width &&
       y >= 0 &&
       y < height &&
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
    
    if(x >= 0 &&
       x < width &&
       y >= 0 &&
       y < height &&
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


- (UInt32) roundColorX:(NSInteger)x y:(NSInteger)y color:(UInt32) color pixels:(UInt32 *) pix {
    
    static int radius = 0;
    int colorR=R(color), colorG=G(color),colorB=B(color), size = 1;
    for (int i = -radius; i < radius; i++) {
        for (int j = -radius; j < radius; j++) {
            if((x+i >= 0 && x+i < width) &&
               (y+j >= 0 && y+j < height) &&
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

    MINX = width, MINY = height;
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
        
        while(y1 < height && [self compare:[self getColorX:x y:y1 pixels:_originPixels] old:roundColor])
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
            
            if(!spanRight && x < width - 1 && [self compare:[self getColorX:x+1 y:y1 pixels:_originPixels] old:roundColor]) // just keep right line once in the stack
            {
                [self pushX:x+1 y:y1];
                spanRight = true;
            }
            else if(spanRight && x < width - 1 && ![self compare:[self getColorX:x+1 y:y1 pixels:_originPixels] old:roundColor])
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
    
    UInt32 roundColor = [self roundColorX:x y:y color:oldColor pixels:pixels];
    
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
        
        while(y1 >= 0 && [self compare:[self getColorX:x y:y1] old:roundColor])
            y1--; // go to line top/bottom
        
        y1++; // start from line starting point pixel
        spanLeft = spanRight = false;
        
        while(y1 < height && [self compare:[self getColorX:x y:y1] old:roundColor])
        {
            [self setColorX:x y:y1 color:newColor];
            if(!spanLeft && x > 0 && [self compare:[self getColorX:x-1 y:y1] old:roundColor])// just keep left line once in the stack
            {
                [self pushX:x-1 y:y1];
                spanLeft = true;
            }
            else if(spanLeft && x > 0 && ![self compare:[self getColorX:x-1 y:y1] old:roundColor])
            {
                spanLeft = false;
            }
            
            if(!spanRight && x < width - 1 && [self compare:[self getColorX:x+1 y:y1] old:roundColor]) // just keep right line once in the stack
            {
                [self pushX:x+1 y:y1];
                spanRight = true;
            }
            else if(spanRight && x < width - 1 && ![self compare:[self getColorX:x+1 y:y1] old:roundColor])
            {
                spanRight = false;
            }
            y1++;
            
        }
    }
}

- (BOOL) compare:(UInt32) new old:(UInt32) old {
    static float eff = 18.0f;
    if(fabs(1.0f * R(old) - R(new)) < eff &&
       fabs(1.0f * G(old) - G(new)) < eff &&
       fabs(1.0f * B(old) - B(new)) < eff)
        return YES;
    return NO;
}

- (UInt32) getColorX:(NSInteger) x y:(NSInteger)y {
    return [self getColorX:x y:y pixels:pixels];
}

- (UInt32) getColorX:(NSInteger) x y:(NSInteger)y pixels:(UInt32 *) pix{
    UInt32 *currentPixel = pix + x + y * width;
    return *currentPixel;
}

- (void) setColorX:(NSInteger) x y:(NSInteger)y color:(UInt32) color {
    [self setColorX:x y:y color:color pixels:pixels];
}

- (void) setColorX:(NSInteger) x y:(NSInteger)y color:(UInt32) color  pixels:(UInt32 *) pix {
    UInt32 *currentPixel = pix + x + y * width;
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
