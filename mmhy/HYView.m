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
    NSUInteger width,height;
    UInt32 * pixels;
}

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.xStack = [NSMutableArray arrayWithCapacity:10];
    self.yStack = [NSMutableArray arrayWithCapacity:10];
    self.backgroundColor = [UIColor greenColor];
    self.userInteractionEnabled = YES;
    self.contentMode = UIViewContentModeCenter;
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gesture:)]];
    
    return self;
}

- (void) setImage:(UIImage *)image {
    [super setImage:image];
    if (image) {
       
        CGImageRef inputCGImage = [image CGImage];
        NSUInteger width  = CGImageGetWidth(inputCGImage);
        NSUInteger height = CGImageGetHeight(inputCGImage);
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, height);
    }

}

- (void) gesture:(UIGestureRecognizer *) recognizer {
    CGPoint point = [recognizer locationInView:self];
    NSLog(@"%@", NSStringFromCGPoint(point));
    
//    UIImage *beginImage = [UIImage imageWithData:UIImagePNGRepresentation(self.image)];
    
    CGImageRef inputCGImage = [self.image CGImage];
    float scaleFactor = 1.0f;//[[UIScreen mainScreen] scale];
     width  = CGImageGetWidth(inputCGImage) * scaleFactor;
     height = CGImageGetHeight(inputCGImage) * scaleFactor;
    
    // 2.
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;

    pixels = (UInt32 *) calloc(height * width,sizeof(UInt32));
    
    // 3.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, width , height, bitsPerComponent, bytesPerRow, colorSpace,     kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);

    // 4.
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), inputCGImage);
    
    UInt32 *currentPixel = pixels + (int)(point.x) + (int)(point.y) * width;

    [self floodFillScanLineWithStack:(int)(point.x) y:(int)(point.y) newColor:RGBAMake(255, 0, 0, 255) oldColor:*currentPixel];
//    [self floodFill4:(int)(point.x) y:(int)(point.y) newColor:RGBAMake(255, 0, 0, 255) oldColor:*currentPixel];
//    [self floodFill8:(int)(point.x) y:(int)(point.y) newColor:RGBAMake(255, 0, 0, 255) oldColor:*currentPixel];

    // 5. Cleanup

    CGImageRef processedCGImage = CGBitmapContextCreateImage(context);
    self.image = [UIImage imageWithCGImage:processedCGImage];
    CGContextRelease(context);
    CGImageRelease(processedCGImage);
    free(pixels);
    pixels = NULL;
}
- (void) floodFill4:(NSInteger) x y:(NSInteger)y newColor:(UInt32) newColor oldColor:(UInt32) oldColor {
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
//        for (int i = -10 ; i < 10; i++) {
//            for (int j = -10; j < 10; j++) {
                [self setColorX:x y:y color:newColor];
//            }
//        }
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

- (void) floodFillScanLineWithStack:(NSInteger) x y:(NSInteger)y newColor:(UInt32) newColor oldColor:(UInt32) oldColor
{
    if(oldColor == newColor) {
        printf("do nothing !!!, filled area!!");
        return;
    }
    [self.yStack removeAllObjects];
    
    NSInteger y1;
    BOOL spanLeft, spanRight;
    [self pushX:x y:y];
    
    while(true)
    {
        x = [self popX];
        if(x == -1)
            break;
        y = [self popY];
        
        y1 = y;
        while(y1 >= 0 && [self compare:[self getColorX:x y:y1] old:oldColor])
            y1--; // go to line top/bottom
        y1++; // start from line starting point pixel
        spanLeft = spanRight = false;
        
        
        while(y1 < height && [self compare:[self getColorX:x y:y1] old:oldColor])
        {
            [self setColorX:x y:y1 color:newColor];
            
            if(!spanLeft && x > 0 && [self compare:[self getColorX:x-1 y:y1] old:oldColor])// just keep left line once in the stack
            {
                [self pushX:x-1 y:y1];
                spanLeft = true;
            }
            if(spanLeft && x > 0 && ![self compare:[self getColorX:x-1 y:y1] old:oldColor])
            {
                spanLeft = false;
            }
            
            if(!spanRight && x < width - 1 && [self compare:[self getColorX:x+1 y:y1] old:oldColor]) // just keep right line once in the stack
            {
                [self pushX:x+1 y:y1];
                spanRight = true;
            }
            else if(spanRight && x < width - 1 && ![self compare:[self getColorX:x+1 y:y1] old:oldColor])
            {
                spanRight = false;
            }
            y1++;
        }
    }
}

- (BOOL) compare:(UInt32) new old:(UInt32) old {
    
//    return new == old;
    
    static int eff = 5;
    if(fabs(R(new) - R(old)) < eff &&
       fabs(G(new) - G(old)) < eff &&
       fabs(B(new) - B(old)) < eff)
        return YES;
    return NO;
}

- (UInt32) getColorX:(NSInteger) x y:(NSInteger)y {
    UInt32 *currentPixel = pixels + x + y * width;
    return *currentPixel;
}
- (void) setColorX:(NSInteger) x y:(NSInteger)y color:(UInt32) color {
    UInt32 *currentPixel = pixels + x + y * width;
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
