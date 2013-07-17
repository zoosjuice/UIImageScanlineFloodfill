//
//  UIImage+FloodFill.m
//  ImageFloodFilleDemo
//
//  Created by chintan on 15/07/13.
//  Copyright (c) 2013 ZWT. All rights reserved.
//



#import "UIImage+FloodFill.h"

@implementation UIImage (FloodFill)

/*
    startPoint : Point from where you want to color. Generaly this is touch point.
                 This is important because color at start point will be replaced with other.
    
    newColor   : This color will be apply at point where the match on startPoint color found.
 
    tolerance  : If Tolerance is 0 than it will search for exact match of color 
                 other wise it will take range according to tolerance value.
*/
- (UIImage *) floodFillFromPoint:(CGPoint)startPoint withColor:(UIColor *)newColor andTolerance:(int)tolerance;
{
    @try
    {
        /*
            First We create rowData from UIImage.
            We require this conversation so that we can use detail at pixel like color at pixel.
            You can get some discussion about this topic here:
            http://stackoverflow.com/questions/448125/how-to-get-pixel-data-from-a-uiimage-cocoa-touch-or-cgimage-core-graphics
        */
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        CGImageRef imageRef = [self CGImage];
        
        NSUInteger width = CGImageGetWidth(imageRef);
        NSUInteger height = CGImageGetHeight(imageRef);
        
        unsigned char *imageData = malloc(height * width * 4);
        
        NSUInteger bytesPerPixel = CGImageGetBitsPerPixel(imageRef) / 8;
        NSUInteger bytesPerRow = CGImageGetBytesPerRow(imageRef);
        NSUInteger bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
        
        CGContextRef context = CGBitmapContextCreate(imageData,
                                                     width,
                                                     height,
                                                     bitsPerComponent,
                                                     bytesPerRow,
                                                     colorSpace,
                                                     CGImageGetBitmapInfo(imageRef));
        CGColorSpaceRelease(colorSpace);
        
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
        
        //Get color at start point
        unsigned int byteIndex = (bytesPerRow * startPoint.y) + startPoint.x * bytesPerPixel;
        
        unsigned int ocolor = getColorCode(byteIndex, imageData);
        
        //Convert newColor to RGBA value so we can save it to image.
        const CGFloat *components = CGColorGetComponents(newColor.CGColor);
        
        int newRed   = components[0] * 255;
        int newGreen = components[1] * 255;
        int newBlue  = components[2] * 255;
        int newAlpha = 255;
        
        if(compareColor(ocolor, ((newRed << 24) | (newGreen << 16) | (newBlue << 8) | (newAlpha)), tolerance))
        {
            return self;
        }
        
        /*
            We are using stack to store point.
            Stack is implemented by LinkList.
            To incress speed I have used NSMutableData insted of NSMutableArray.
            To see Detail Of This implementation visit following leink.
            http://iwantmyreal.name/blog/2012/09/29/a-faster-array-in-objective-c/
        */
        
        LinkedListStack *points = [[LinkedListStack alloc] initWithCapacity:500 incrementSize:500 andMultiplier:height];
        
        int x = startPoint.x;
        int y = startPoint.y;
        
        [points pushFrontX:x andY:y];
        
        /*
            This algorithem is prety simple though it llook odd in Objective C syntex.
            To get familer with this algorithm visit following link.
            http://lodev.org/cgtutor/floodfill.html
            You can read hole artical for knowledge. 
            If you are familer with flood fill than got to Scanline Floodfill Algorithm With Stack (floodFillScanlineStack)
        */
        
        int y1;
        unsigned int color;
        BOOL spanLeft,spanRight;
        
        while ([points popFront:&x andY:&y] != INVALID_NODE_CONTENT)
        {
            y1 = y;
            
            byteIndex = (bytesPerRow * y1) + x * bytesPerPixel;
            
            color = getColorCode(byteIndex, imageData);
            
            while(y1 >= 0 && compareColor(ocolor, color, tolerance))
            {
                y1--;
                
                byteIndex = (bytesPerRow * y1) + x * bytesPerPixel;
                
                color = getColorCode(byteIndex, imageData);
            }
            
            y1++;
            
            spanLeft = spanRight = NO;
            
            byteIndex = (bytesPerRow * y1) + x * bytesPerPixel;
            
            color = getColorCode(byteIndex, imageData);
            
            while (y1 < height && compareColor(ocolor, color, tolerance))
            {
                imageData[byteIndex + 0] = newRed;
                imageData[byteIndex + 1] = newGreen;
                imageData[byteIndex + 2] = newBlue;
                imageData[byteIndex + 3] = newAlpha;
                
                byteIndex = (bytesPerRow * y1) + (x - 1) * bytesPerPixel;
                
                color = getColorCode(byteIndex, imageData);
                
                if(!spanLeft && x > 0 && compareColor(ocolor, color, tolerance))
                {
                    [points pushFrontX:(x - 1) andY:y1];
                    
                    spanLeft = YES;
                }
                else if(spanLeft && x > 0 && !compareColor(ocolor, color, tolerance))
                {
                    spanLeft = NO;
                }
                
                byteIndex = (bytesPerRow * y1) + (x + 1) * bytesPerPixel;
                
                color = getColorCode(byteIndex, imageData);
                
                if(!spanRight && x < width - 1 && compareColor(ocolor, color, tolerance))
                {
                    [points pushFrontX:(x + 1) andY:y1];
                    
                    spanRight = YES;
                }
                else if(spanRight && x < width - 1 && !compareColor(ocolor, color, tolerance))
                {
                    spanRight = NO;
                }
                
                y1++;
                
                if(y1 < height)
                {
                    byteIndex = (bytesPerRow * y1) + x * bytesPerPixel;
                
                    color = getColorCode(byteIndex, imageData);
                }
            }
        }
        
        //If You dont want ot use tolerance Than remove uppor while loop and use this commented while loop.
        /*
        while ([points popFront:&x andY:&y] != INVALID_NODE_CONTENT)
        {
            y1 = y;
            
            byteIndex = (bytesPerRow * y1) + x * bytesPerPixel;
            
            color = getColorCode(byteIndex, imageData);
            
            while(y1 >= 0 && color == ocolor)
            {
                y1--;
                
                byteIndex = (bytesPerRow * y1) + x * bytesPerPixel;
        
                color = getColorCode(byteIndex, imageData);
            }
            
            y1++;
        
            spanLeft  = NO;
            spanRight = NO;
            
            byteIndex = (bytesPerRow * y1) + x * bytesPerPixel;
            
            color = getColorCode(byteIndex, imageData);
            
            while (y1 < height && color == ocolor)
            {
                imageData[byteIndex + 0] = newRed;
                imageData[byteIndex + 1] = newGreen;
                imageData[byteIndex + 2] = newBlue;
                imageData[byteIndex + 3] = newAlpha;
                
                byteIndex = (bytesPerRow * y1) + (x - 1) * bytesPerPixel;
                
                color = getColorCode(byteIndex, imageData);
                
                if(!spanLeft && x > 0 && color == ocolor)
                {
                    [points pushFrontX:(x - 1) andY:y1];
                 
                    spanLeft = YES;
                }
                else if(spanLeft && x > 0 && color != ocolor)
                {
                    spanLeft = NO;
                }
                
                byteIndex = (bytesPerRow * y1) + (x + 1) * bytesPerPixel;
                
                color = getColorCode(byteIndex, imageData);
                
                if(!spanRight && x < width - 1 && color == ocolor)
                {
                    [points pushFrontX:(x + 1) andY:y1];
              
                    spanRight = YES;
                }
                else if(spanRight && x < width - 1 && color != ocolor)
                {
                    spanRight = NO;
                }
                
                y1++;
                
                if(y1 < height)
                {
                    byteIndex = (bytesPerRow * y1) + x * bytesPerPixel;
                 
                    color = getColorCode(byteIndex, imageData);
                }
            }
        }
        */
        
        //Convert Flood filled image row data back to UIImage object.
        
        points = Nil;
        
        UIImage *result = [UIImage imageWithCGImage:CGBitmapContextCreateImage(context)];
        
        CGContextRelease(context);
    
        free(imageData);
        
        return result;
    }
    @catch (NSException *exception)
    {
        NSLog(@"Exception : %@", exception);
    }
}

/*
    I have used pure C function because it is said than C function is faster than Objective - C method in call.
    This two function are called most of time so it require that calling this work in speed.
    I have not verified this performance so I like to here comment on this.
*/

/*
    This function extract color from image and convert it to integer represent.
 
    Converting to integer make comperation easy.
*/
unsigned int getColorCode (unsigned int byteIndex, unsigned char *imageData)
{
    unsigned int red   = imageData[byteIndex];
    unsigned int green = imageData[byteIndex + 1];
    unsigned int blue  = imageData[byteIndex + 2];
    unsigned int alpha = imageData[byteIndex + 3];
    
    return (red << 24) | (green << 16) | (blue << 8) | alpha;
}

/*
    This function compare two color with counting tolerance value.
 
    If color is between tolerance rancge than it return true other wise false.
*/
bool compareColor (unsigned int color1, unsigned int color2, int tolorance)
{
    if(color1 == color2)
        return true;
        
    int red1   = ((0xff000000 & color1) >> 24);
    int green1 = ((0x00ff0000 & color1) >> 16);
    int blue1  = ((0x0000ff00 & color1) >> 8);
    int alpha1 =  (0x000000ff & color1);
    
    int red2   = ((0xff000000 & color2) >> 24);
    int green2 = ((0x00ff0000 & color2) >> 16);
    int blue2  = ((0x0000ff00 & color2) >> 8);
    int alpha2 =  (0x000000ff & color2);
    
    int diffRed   = abs(red2   - red1);
    int diffGreen = abs(green2 - green1);
    int diffBlue  = abs(blue2  - blue1);
    int diffAlpha = abs(alpha2 - alpha1);
    
    if( diffRed   > tolorance ||
        diffGreen > tolorance ||
        diffBlue  > tolorance ||
        diffAlpha > tolorance  )
    {
        return false;
    }
    
    return true;
}
@end