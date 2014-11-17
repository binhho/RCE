// UIImage+Resize.m
// Created by Trevor Harmon on 8/5/09.
// Free for personal or commercial use, with or without modification.
// No warranty is expressed or implied.

#import "UIImage+Resize.h"
#import <QuartzCore/QuartzCore.h>
#import <ImageIO/ImageIO.h>

static inline double radians(double degrees) {
    return degrees * M_PI / 180;
}


@implementation UIImage (Additions)

// Returns a copy of this image that is cropped to the given bounds.
// The bounds will be adjusted using CGRectIntegral.
// This method ignores the image's imageOrientation setting.
- (UIImage *)croppedImage:(CGRect)bounds {
    CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], bounds);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return croppedImage;
}

// Returns a copy of this image that is squared to the thumbnail size.
// If transparentBorder is non-zero, a transparent border of the given size will be added around the edges of the thumbnail. (Adding a transparent border of at least one pixel in size has the side-effect of antialiasing the edges of the image when rotating it using Core Animation.)
- (UIImage *)thumbnailImage:(NSInteger)thumbnailSize
          transparentBorder:(NSUInteger)borderSize
               cornerRadius:(NSUInteger)cornerRadius
       interpolationQuality:(CGInterpolationQuality)quality {
    UIImage *resizedImage = [self resizedImageWithContentMode:UIViewContentModeScaleAspectFill
                                                       bounds:CGSizeMake(thumbnailSize, thumbnailSize)
                                         interpolationQuality:quality];
    
    // Crop out any part of the image that's larger than the thumbnail size
    // The cropped rect must be centered on the resized image
    // Round the origin points so that the size isn't altered when CGRectIntegral is later invoked
    CGRect cropRect = CGRectMake(round((resizedImage.size.width - thumbnailSize) / 2),
                                 round((resizedImage.size.height - thumbnailSize) / 2),
                                 thumbnailSize,
                                 thumbnailSize);
    UIImage *croppedImage = [resizedImage croppedImage:cropRect];
    
    return croppedImage;
    //UIImage *transparentBorderImage = borderSize ? [croppedImage transparentBorderImage:borderSize] : croppedImage;
    
    //return [transparentBorderImage roundedCornerImage:cornerRadius borderSize:borderSize];
}

// Returns a rescaled copy of the image, taking into account its orientation
// The image will be scaled disproportionately if necessary to fit the bounds specified by the parameter
- (UIImage *)resizedImage:(CGSize)newSize interpolationQuality:(CGInterpolationQuality)quality {
    BOOL drawTransposed;
    
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            drawTransposed = YES;
            break;
            
        default:
            drawTransposed = NO;
    }
    
    return [self resizedImage:newSize
                    transform:[self transformForOrientation:newSize]
               drawTransposed:drawTransposed
         interpolationQuality:quality];
}

// Resizes the image according to the given content mode, taking into account the image's orientation
- (UIImage *)resizedImageWithContentMode:(UIViewContentMode)contentMode
                                  bounds:(CGSize)bounds
                    interpolationQuality:(CGInterpolationQuality)quality {
    CGFloat horizontalRatio = bounds.width / self.size.width;
    CGFloat verticalRatio = bounds.height / self.size.height;
    CGFloat ratio;
    
    switch (contentMode) {
        case UIViewContentModeScaleAspectFill:
            ratio = MAX(horizontalRatio, verticalRatio);
            break;
            
        case UIViewContentModeScaleAspectFit:
            ratio = MIN(horizontalRatio, verticalRatio);
            break;
            
        default:
            [NSException raise:NSInvalidArgumentException format:@"Unsupported content mode: %ld", (long)contentMode];
    }
    
    CGSize newSize = CGSizeMake(self.size.width * ratio, self.size.height * ratio);
    
    return [self resizedImage:newSize interpolationQuality:quality];
}

#pragma mark -
#pragma mark Private helper methods

// Returns a copy of the image that has been transformed using the given affine transform and scaled to the new size
// The new image's orientation will be UIImageOrientationUp, regardless of the current image's orientation
// If the new size is not integral, it will be rounded up
- (UIImage *)resizedImage:(CGSize)newSize
                transform:(CGAffineTransform)transform
           drawTransposed:(BOOL)transpose
     interpolationQuality:(CGInterpolationQuality)quality {
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGRect transposedRect = CGRectMake(0, 0, newRect.size.height, newRect.size.width);
    CGImageRef imageRef = self.CGImage;
    
    // Build a context that's the same dimensions as the new size
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                newRect.size.width,
                                                newRect.size.height,
                                                CGImageGetBitsPerComponent(imageRef),
                                                0,
                                                CGImageGetColorSpace(imageRef),
                                                CGImageGetBitmapInfo(imageRef));
    
    // Rotate and/or flip the image if required by its orientation
    CGContextConcatCTM(bitmap, transform);
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(bitmap, quality);
    
    // Draw into the context; this scales the image
    CGContextDrawImage(bitmap, transpose ? transposedRect : newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    // Clean up
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);
    
    return newImage;
}

// Returns an affine transform that takes into account the image orientation when drawing a scaled image
- (CGAffineTransform)transformForOrientation:(CGSize)newSize {
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
        case UIImageOrientationDown:           // EXIF = 3
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, newSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:           // EXIF = 6
        case UIImageOrientationLeftMirrored:   // EXIF = 5
            transform = CGAffineTransformTranslate(transform, newSize.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:          // EXIF = 8
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, 0, newSize.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
            
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:     // EXIF = 2
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:   // EXIF = 5
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, newSize.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    return transform;
}

+ (void)beginImageContextWithSize:(CGSize)size {
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        if ([[UIScreen mainScreen] scale] == 2.0) {
            UIGraphicsBeginImageContextWithOptions(size, NO, 2.0);
        } else {
            UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
        }
    } else {
        UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    }
}

+ (void)endImageContext {
    UIGraphicsEndImageContext();
}

- (UIImage *)crop:(CGRect)rect {
    if (self.scale > 1.0f) {
        rect = CGRectMake(rect.origin.x * self.scale,
                          rect.origin.y * self.scale,
                          rect.size.width * self.scale,
                          rect.size.height * self.scale);
    }
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    return result;
}

- (BOOL)isSquare {
    return self.size.height == self.size.width;
}

+ (UIImage *)imageWithView:(UIView *)view
{
    CGFloat scale = [UIScreen mainScreen].scale;
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

+ (UIImage *)imageFromView:(UIView *)view scaledToSize:(CGSize)newSize {
    UIImage *image = [self imageWithView:view];
    if ([view bounds].size.width != newSize.width ||
        [view bounds].size.height != newSize.height) {
        image = [self imageWithImage:image scaledToSize:newSize];
    }
    return image;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    [self beginImageContextWithSize:newSize];
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    [self endImageContext];
    return newImage;
}

+ (UIImage *)threadSafeResize:(UIImage *)image toSize:(CGSize)size {
    // Create the bitmap context
    CGContextRef context = NULL;
    void *bitmapData;
    int bitmapByteCount;
    int bitmapBytesPerRow;
    
    // Get image width, height. We'll use the entire image.
    int width = size.width;
    int height = size.height;
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow   = (width * 4);
    bitmapByteCount     = (bitmapBytesPerRow * height);
    
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    bitmapData = malloc(bitmapByteCount);
    if (bitmapData == NULL) {
        return nil;
    }
    
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
    // per component. Regardless of what the source image format is
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    CGColorSpaceRef colorspace = CGImageGetColorSpace(image.CGImage);
    context = CGBitmapContextCreate(bitmapData, width, height, 8, bitmapBytesPerRow,
                                    colorspace, kCGImageAlphaNoneSkipLast);
    CGColorSpaceRelease(colorspace);
    
    if (context == NULL)
        // error creating context
        return nil;
    
    // Draw the image to the bitmap context. Once we draw, the memory
    // allocated for the context for rendering will then contain the
    // raw image data in the specified color space.
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image.CGImage);
    
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    free(bitmapData);
    
    UIImage *resizedImage = [UIImage imageWithCGImage:imgRef scale:image.scale orientation:image.imageOrientation];
    CFRelease(imgRef);
    
    return resizedImage;
}

- (UIImage *)compositeImage:(UIImage *)image atRect:(CGRect)rect; {
    // Create the bitmap context
    CGContextRef context = NULL;
    void *bitmapData;
    int bitmapByteCount;
    int bitmapBytesPerRow;
    
    // Get image width, height. We'll use the entire image.
    int width = self.size.width;
    int height = self.size.height;
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow   = (width * 4);
    bitmapByteCount     = (bitmapBytesPerRow * height);
    
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    bitmapData = malloc(bitmapByteCount);
    if (bitmapData == NULL) {
        return nil;
    }
    
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
    // per component. Regardless of what the source image format is
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    CGColorSpaceRef colorspace = CGImageGetColorSpace(self.CGImage);
    context = CGBitmapContextCreate(bitmapData, width, height, 8, bitmapBytesPerRow,
                                    colorspace, kCGImageAlphaNoneSkipLast);
    CGColorSpaceRelease(colorspace);
    
    if (context == NULL)
        // error creating context
        return nil;
    
    // Draw the image to the bitmap context. Once we draw, the memory
    // allocated for the context for rendering will then contain the
    // raw image data in the specified color space.
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), self.CGImage);
    
    //    if(image.imageOrientation != UIImageOrientationUp && image.imageOrientation != UIImageOrientationUpMirrored) {
    //
    //        CGContextTranslateCTM(context, 0, height);
    //        CGContextRotateCTM(context, -M_PI_2);
    //    }
    
    CGContextDrawImage(context, CGRectMake(rect.origin.x, height - rect.origin.y - rect.size.height, rect.size.width, rect.size.height), image.CGImage);
    
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    free(bitmapData);
    
    UIImage *resizedImage = [UIImage imageWithCGImage:imgRef scale:self.scale orientation:self.imageOrientation];
    CFRelease(imgRef);
    
    return resizedImage;
}

void RotateContextBasedOnImageOrientation(CGContextRef context, UIImageOrientation orientation, CGSize canvasSize) {
    switch (orientation) {
        case UIImageOrientationRight:
            CGContextRotateCTM(context, radians(-90));
            CGContextTranslateCTM(context, canvasSize.width, 0);
            break;
        case UIImageOrientationLeft:
            CGContextRotateCTM(context, radians(-90));
            CGContextTranslateCTM(context, canvasSize.width, 0);
            break;
        case UIImageOrientationDown:
            CGContextTranslateCTM(context, canvasSize.width, canvasSize.height);
            CGContextRotateCTM(context, radians(-180.));
            break;
        case UIImageOrientationUp:
            break;
            
        default:
            break;
    }
}

- (UIImage *)normalizedImage {
    if (self.imageOrientation == UIImageOrientationUp) return self;
    
    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    [self drawInRect:(CGRect) {0, 0, self.size }];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}

- (UIImage *)coloredImageWithColor:(UIColor *)color {
    
    float scale = [UIScreen mainScreen].scale;
    
    UIGraphicsBeginImageContextWithOptions(self.size, NO, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, 0, self.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextDrawImage(context, rect, self.CGImage);
    CGContextClipToMask(context, rect, self.CGImage);
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    [color setFill];
    CGContextFillRect(context, rect);
    
    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return coloredImage;
}

- (UIImage *)tintedImageWithColor:(UIColor *)color {
    
    float scale = [UIScreen mainScreen].scale;
    
    UIGraphicsBeginImageContextWithOptions(self.size, NO, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, 0, self.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextDrawImage(context, rect, self.CGImage);
    CGContextClipToMask(context, rect, self.CGImage);
    
    CGContextSetBlendMode(context, kCGBlendModeMultiply);
    [color setFill];
    CGContextFillRect(context, rect);
    
    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return coloredImage;
}

+(CGSize)scaledSizeFromSize:(CGSize)fromSize toWidth:(CGFloat)width {
    
    CGFloat scale = fromSize.width / width;
    return CGSizeMake(width, (int)ceilf(fromSize.height/scale));
}

+(CGSize)scaledSizeFromSize:(CGSize)fromSize toHeight:(CGFloat)height {
    
    CGFloat scale = fromSize.height / height;
    return CGSizeMake((int)ceilf(fromSize.width/scale), height);
}

- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize
{
    UIImage *sourceImage = self;
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO)
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor)
        {
            scaleFactor = widthFactor; // scale to fit height
        }
        else
        {
            scaleFactor = heightFactor; // scale to fit width
        }
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else
        {
            if (widthFactor < heightFactor)
            {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
        }
    }
    
    UIGraphicsBeginImageContextWithOptions(targetSize, YES, 0.0); // this will crop
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    if(newImage == nil)
    {
        NSLog(@"could not scale image");
    }
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIImage*)rotate:(UIImage*) src andOrientation:(UIImageOrientation)orientation {
    
    
    CGContextRef context=(UIGraphicsGetCurrentContext());
    
    if (orientation == UIImageOrientationRight) {
        CGContextRotateCTM (context, 90/180*M_PI) ;
    } else if (orientation == UIImageOrientationLeft) {
        CGContextRotateCTM (context, -90/180*M_PI);
    } else if (orientation == UIImageOrientationDown) {
        // NOTHING
    } else if (orientation == UIImageOrientationUp) {
        CGContextRotateCTM (context, 90/180*M_PI);
    }
    
    [src drawAtPoint:CGPointMake(0, 0)];
    UIImage *img=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}


+ (UIImage *) cropNormalizeAndScaleImageWithData:(NSData *)imageData cropRect:(CGRect)cropRect flipVertically:(BOOL) flipVertically {
    
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)(imageData), NULL);
    
    //Image Properties
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@NO, (NSString *)kCGImageSourceShouldCache, nil];
    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
    
    NSNumber *width = (NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
    NSNumber *height = (NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
    
    CGSize imageSize = CGSizeMake(width.floatValue, height.floatValue);
    
    CFRelease(imageProperties);
    
    CGSize scaledSize;
    
    if(imageSize.width > imageSize.height) {
        
        scaledSize = [self scaledSizeFromSize:imageSize toHeight:cropRect.size.height];
    }
    else {
        
        scaledSize = [self scaledSizeFromSize:imageSize toWidth:cropRect.size.width];
    }
    
    CGFloat maxPixelSize = MAX(scaledSize.width, scaledSize.height);
    
    NSDictionary *thumbnailOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                      (id)kCFBooleanTrue, kCGImageSourceCreateThumbnailWithTransform,
                                      kCFBooleanTrue, kCGImageSourceCreateThumbnailFromImageAlways,
                                      @(maxPixelSize), kCGImageSourceThumbnailMaxPixelSize,
                                      nil];
    
    CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)thumbnailOptions);
    CFRelease(imageSource);
    
    CGSize thumbnailSize = CGSizeMake(CGImageGetWidth(thumbnail), CGImageGetHeight(thumbnail));
    
    //check if we need to scale up the image to meet the crop rect
    
    if(thumbnailSize.width < cropRect.size.width) {
        
        thumbnailSize = [self scaledSizeFromSize:thumbnailSize toWidth:cropRect.size.width];
    }
    
    if(thumbnailSize.height < cropRect.size.height) {
        
        thumbnailSize = [self scaledSizeFromSize:thumbnailSize toHeight:cropRect.size.height];
    }
    
    CGRect drawRect = CGRectMake(-cropRect.origin.x, -cropRect.origin.y, thumbnailSize.width, thumbnailSize.height);
    
    //drawing
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmap = CGBitmapContextCreate(NULL, cropRect.size.width, cropRect.size.height, 8, cropRect.size.width * 4, colorspace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    if(flipVertically) {
        CGAffineTransform verticalFlip = CGAffineTransformMakeScale(-1.0, 1.0);
        CGContextConcatCTM(bitmap, verticalFlip);
        drawRect = CGRectApplyAffineTransform(drawRect, verticalFlip);
    }
    
    CGContextSetInterpolationQuality(bitmap, kCGInterpolationHigh);
    
    CGContextSetFillColorWithColor(bitmap, [UIColor whiteColor].CGColor);
    CGContextFillRect(bitmap, CGRectMake(0, 0, cropRect.size.width, cropRect.size.height));
    
    CGContextDrawImage(bitmap, drawRect, thumbnail);
    
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);
    CGImageRelease(thumbnail);
    CGColorSpaceRelease(colorspace);
    
    return newImage;
    
}


+ (UIImage *)cropAndNormalizeImageWithImageAtURL:(NSURL *)url rect:(CGRect)cropRect resizeToSize:(CGSize)size {
    
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)(url), NULL);
    
    return [self cropAndNormalizeImageWithImageSourceRef:imageSource rect:cropRect resizeToSize:size];
};


+ (UIImage *)cropAndNormalizeImageWithImageSourceRef:(CGImageSourceRef)imageSource rect:(CGRect)cropRect resizeToSize:(CGSize)size {
    
    //Image Properties
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@NO, (NSString *)kCGImageSourceShouldCache, nil];
    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
    
    NSNumber *width = (NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
    NSNumber *height = (NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    NSNumber *orientation = (NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyOrientation);
    
    UIImageOrientation imageOrientation = [UIImage imageOrientationFromEXIFOrientation:orientation.integerValue];
    
    CGSize imageSize = CGSizeMake(width.floatValue, height.floatValue);
    
    CFRelease(imageProperties);
    
    CGFloat scale = 1.0;
    
    if(cropRect.size.width > cropRect.size.height) {
        
        scale = size.width/cropRect.size.width;
    }
    else {
        
        scale = size.height/cropRect.size.height;
    }
    
    // Build a context that's the same dimensions as the new size
    CGContextRef bitmap = CGBitmapContextCreate(NULL, size.width, size.height, 8, size.width * 4, colorspace, kCGImageAlphaNoneSkipLast | 5);
    
    
    
    float scaleFactor = cropRect.size.width/size.width;
    
    CGSize scaledSize;
    
    if(imageSize.width > imageSize.height) {
        
        switch (imageOrientation) {
            case UIImageOrientationUp:
            case UIImageOrientationUpMirrored:
            case UIImageOrientationDown:
            case UIImageOrientationDownMirrored:
                scaledSize = [self scaledSizeFromSize:imageSize toWidth:size.width]; //good
                break;
            case UIImageOrientationLeft:
            case UIImageOrientationLeftMirrored:
            case UIImageOrientationRight:
            case UIImageOrientationRightMirrored:
                scaledSize = [self scaledSizeFromSize:imageSize toHeight:size.width]; //good
                break;
                
            default:
                break;
        }
        
    }
    else {
        
        switch (imageOrientation) {
            case UIImageOrientationUp:
            case UIImageOrientationUpMirrored:
            case UIImageOrientationDown:
            case UIImageOrientationDownMirrored:
                scaledSize = [self scaledSizeFromSize:imageSize toWidth:size.width]; //good
                break;
            case UIImageOrientationLeft:
            case UIImageOrientationLeftMirrored:
            case UIImageOrientationRight:
            case UIImageOrientationRightMirrored:
                scaledSize = [self scaledSizeFromSize:imageSize toHeight:size.width]; //seems good
                break;
                
            default:
                break;
        }
    }
    
    CGFloat maxPixelSize = 0;
    
    if(scaleFactor < 1.0) {
        
        maxPixelSize = MAX(scaledSize.width / scaleFactor, scaledSize.height / scaleFactor);
    }
    else {
        
        maxPixelSize = MAX(scaledSize.width * scaleFactor, scaledSize.height *scaleFactor);
    }
    
    
    NSDictionary *thumbnailOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                      (id)kCFBooleanTrue, kCGImageSourceCreateThumbnailWithTransform,
                                      kCFBooleanTrue, kCGImageSourceCreateThumbnailFromImageAlways,
                                      @(maxPixelSize), kCGImageSourceThumbnailMaxPixelSize,
                                      nil];
    
    CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)thumbnailOptions);
    
    CFRelease(imageSource);
    
    //CGSize thumbnailSize = CGSizeMake(CGImageGetWidth(thumbnail), CGImageGetHeight(thumbnail));
    
    switch (imageOrientation) {
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            imageSize = CGSizeMake(imageSize.height, imageSize.width);
            break;
            
        default:
            break;
    }
    
    CGRect drawRect = CGRectMake(-cropRect.origin.x, -cropRect.origin.y, imageSize.width, imageSize.height);
    drawRect = CGRectApplyAffineTransform(drawRect, CGAffineTransformMakeScale(scale, scale));
    CGAffineTransform rectTransform = CGAffineTransformConcat(CGAffineTransformMakeScale(1.0, -1.0), CGAffineTransformMakeTranslation(0, size.height));
    drawRect = CGRectApplyAffineTransform(drawRect, rectTransform);
    drawRect = CGRectIntegral(drawRect);
    
    if(size.width - drawRect.size.width > 0) {
        drawRect.origin.x+= (size.width - drawRect.size.width)/2;
    }
    
    if(size.height - drawRect.size.height > 0) {
        drawRect.origin.y-= (size.height - drawRect.size.height)/2;
    }
    
    CGContextSetFillColorWithColor(bitmap, [UIColor whiteColor].CGColor);
    CGContextFillRect(bitmap, CGRectMake(0, 0, size.width, size.height));
    CGContextDrawImage(bitmap, drawRect, thumbnail);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    // Clean up
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);
    CGImageRelease(thumbnail);
    CGColorSpaceRelease(colorspace);
    
    return newImage;
}


+ (UIImageOrientation)imageOrientationFromEXIFOrientation:(NSInteger)orienation {
    
    switch (orienation) {
        case 1:
            return UIImageOrientationUp;
            break;
        case 2:
            return UIImageOrientationUpMirrored;
            break;
        case 3:
            return UIImageOrientationDown;
            break;
        case 4:
            return UIImageOrientationDownMirrored;
            break;
        case 5:
            return UIImageOrientationLeftMirrored;
            break;
        case 6:
            return UIImageOrientationRight;
            break;
        case 7:
            return UIImageOrientationRightMirrored;
            break;
        case 8:
            return UIImageOrientationLeft;
            break;
        default:
            break;
    }
    
    return UIImageOrientationUp;
}


@end
