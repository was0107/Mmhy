//
//  MSkeletonImageHandler.m
//  mmhy
//
//  Created by Micker on 2018/7/25.
//  Copyright © 2018年 micker. All rights reserved.
//

#import "MSkeletonImageHandler.h"

@interface MSkeletonImageHandler()
@property (nonatomic, strong) NSLock *imageLock;
@property (nonatomic, strong) UIImage *originImage;
@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, copy) ImageBlock block;

@end

@implementation MSkeletonImageHandler {
    UInt32 * _originPixels;
    UInt32 * _middlePixels;
    UInt32 * _targetPixels;
    UInt32 * _template;
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

- (void) doSetSourceImage:(UIImage *) source
                    block:(ImageBlock) block {
    self.sourceImage = source;
    self.block = block;
    [self doHandleSkeleton];
}

- (void) doHandleSkeleton {
    if (!self.sourceImage) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;

    UIImage *tmpImage = self.sourceImage;

    dispatch_async(dispatch_queue_create("skeleton.concurrent.queue", DISPATCH_QUEUE_CONCURRENT), ^{
        
        [weakSelf.imageLock lock];
        CGImageRef inputCGImage = [tmpImage CGImage];
        NSUInteger bytesPerPixel = 4;
        NSUInteger bytesPerRow = bytesPerPixel * weakSelf.width;
        NSUInteger bitsPerComponent = 8;
        
        //origin
        self->_originPixels = (UInt32 *) calloc(weakSelf.height * weakSelf.width, sizeof(UInt32));
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(self->_originPixels, weakSelf.width , weakSelf.height,
                                                     bitsPerComponent,
                                                     bytesPerRow,
                                                     colorSpace,
                                                     kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGContextDrawImage(context, CGRectMake(0, 0, weakSelf.width, weakSelf.height), inputCGImage);
        
        CGContextRef originContext = NULL;

        self->_middlePixels = (UInt32 *) calloc(weakSelf.height * weakSelf.width, sizeof(UInt32));
        originContext = CGBitmapContextCreate(self->_middlePixels, weakSelf.width , weakSelf.height,
                                              bitsPerComponent,
                                              bytesPerRow,
                                              colorSpace,
                                              kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGContextDrawImage(originContext, CGRectMake(0, 0, weakSelf.width, weakSelf.height), inputCGImage);
        
        //target
        self->_targetPixels = (UInt32 *) calloc(weakSelf.height * weakSelf.width, sizeof(UInt32));
        originContext = CGBitmapContextCreate(self->_targetPixels, weakSelf.width , weakSelf.height,
                                              bitsPerComponent,
                                              bytesPerRow,
                                              colorSpace,
                                              kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGContextDrawImage(originContext, CGRectMake(0, 0, weakSelf.width, weakSelf.height), inputCGImage);
        CGColorSpaceRelease(colorSpace);
        
        
        [self doGaulseAnd2Value];
        [self doSkeleton];
    
        
        UIImage *image = [self currentImageInContext:originContext];
        dispatch_async(dispatch_get_main_queue(), ^{
            !weakSelf.block?:weakSelf.block(image);
            [weakSelf.imageLock unlock];
        });
        CGContextRelease(context);
        CGContextRelease(originContext);
        [self freePoint:self->_targetPixels];
        [self freePoint:self->_middlePixels];
        [self freePoint:self->_originPixels];
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


- (void) doGaulseAnd2Value {
    
    UInt32 template[3][3]={{1,1,1},{1,1,1},{1,1,1}};
    for (int i = 1; i < self.width - 1; i++) {
        for (int j = 1; j < self.height - 1; j++) {
            UInt32 value = 0;
            for (int h = 0; h < 2 ; h++) {
                for (int k = 0; k < 2; k++) {
                    UInt32 curentValue = [self getColorX:h + i - 1 y:k + j -1 pixels:_originPixels];
                    value += R(curentValue) * template[h][k];
                    value += G(curentValue) * template[h][k];
                    value += B(curentValue) * template[h][k];
                }
            }
            value /=27;
            [self setColorX:i y:j color:RGBAMake(value, value, value, 255) pixels:_middlePixels];
        }
    }
}



- (void) doSkeleton {

    UInt32 template[3][3]={{1,1,1},{1,-8,1},{1,1,1}};
    for (int i = 1; i < self.width - 1; i++) {
        for (int j = 1; j < self.height - 1; j++) {
            UInt32 value = 0;
            for (int h = 0; h < 2 ; h++) {
                for (int k = 0; k < 2; k++) {
                    UInt32 curentValue = [self getColorX:h + i - 1 y:k + j -1 pixels:_middlePixels];
                    value += R(curentValue) * template[h][k];
                    value += G(curentValue) * template[h][k];
                    value += B(curentValue) * template[h][k];
                }
            }
            value = value/3 >=125 ? 255 : 0;
            [self setColorX:i y:j color:RGBAMake(value, value, value, 255) pixels:_targetPixels];
        }
    }
}


- (UInt32) getColorX:(NSInteger) x y:(NSInteger)y pixels:(UInt32 *) pix {
    UInt32 *currentPixel = pix + x + y * _width;
    return *currentPixel;
}

- (void) setColorX:(NSInteger) x y:(NSInteger)y color:(UInt32) color  pixels:(UInt32 *) pix {
    UInt32 *currentPixel = pix + x + y * _width;
    *currentPixel = color;
}


@end
