// UIImage+Resize.h
// Created by Trevor Harmon on 8/5/09.
// Free for personal or commercial use, with or without modification.
// No warranty is expressed or implied.

// Extends the UIImage class to support resizing/cropping

#import <UIKit/UIKit.h>

@interface UIImage (Additions)
- (UIImage *)croppedImage:(CGRect)bounds;
- (UIImage *)thumbnailImage:(NSInteger)thumbnailSize
          transparentBorder:(NSUInteger)borderSize
               cornerRadius:(NSUInteger)cornerRadius
       interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage *)resizedImage:(CGSize)newSize
     interpolationQuality:(CGInterpolationQuality)quality;
- (UIImage *)resizedImageWithContentMode:(UIViewContentMode)contentMode
                                  bounds:(CGSize)bounds
                    interpolationQuality:(CGInterpolationQuality)quality;

- (BOOL)isSquare;
- (UIImage *)crop:(CGRect)rect;
+ (UIImage *)imageWithView:(UIView *)view;
+ (UIImage *)imageFromView:(UIView *)view scaledToSize:(CGSize)newSize;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

+ (UIImage *)threadSafeResize:(UIImage *)image toSize:(CGSize)size;
- (UIImage *)compositeImage:(UIImage *)image atRect:(CGRect)rect;
- (UIImage *)normalizedImage;

- (UIImage *)coloredImageWithColor:(UIColor *)color;
- (UIImage *)tintedImageWithColor:(UIColor *)color;

+ (CGSize)scaledSizeFromSize:(CGSize)fromSize toWidth:(CGFloat)width;
+ (CGSize)scaledSizeFromSize:(CGSize)fromSize toHeight:(CGFloat)height;
- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize;

//image rotation
+ (UIImage*)rotate:(UIImage*) src andOrientation:(UIImageOrientation)orientation;

+ (UIImage *)cropNormalizeAndScaleImageWithData:(NSData *)imageData cropRect:(CGRect)cropRect flipVertically:(BOOL) flipVertically;

+ (UIImage *)cropAndNormalizeImageWithImageAtURL:(NSURL *)url rect:(CGRect)cropRect resizeToSize:(CGSize)size;

+ (UIImageOrientation)imageOrientationFromEXIFOrientation:(NSInteger)orienation;

@end
