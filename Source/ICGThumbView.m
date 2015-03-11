//
//  ICGVideoTrimmerLeftOverlay.m
//  ICGVideoTrimmer
//
//  Created by Huong Do on 1/19/15.
//  Copyright (c) 2015 ichigo. All rights reserved.
//

#import "ICGThumbView.h"

@interface ICGThumbView()

@property (nonatomic) BOOL isRight;
@property (strong, nonatomic) UIImage *thumbImage;

@end

@implementation ICGThumbView

- (instancetype)initWithFrame:(CGRect)frame color:(UIColor *)color right:(BOOL)flag
{
    self = [super initWithFrame:frame];
    if (self) {
        _color = color;
        _isRight = flag;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame thumbImage:(UIImage *)image
{
    self = [super initWithFrame:frame];
    if (self) {
        self.thumbImage = image;
    }
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect relativeFrame = self.bounds;
    UIEdgeInsets hitTestEdgeInsets = UIEdgeInsetsMake(0, -30, 0, -30);
    CGRect hitFrame = UIEdgeInsetsInsetRect(relativeFrame, hitTestEdgeInsets);
    return CGRectContainsPoint(hitFrame, point);
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    
    if (self.thumbImage) {
        [self.thumbImage drawInRect:rect];
        
    } else {
        //// Frames
        CGRect bubbleFrame = self.bounds;
        
        //// Square Rectangle Drawing
        CGRect thumbRect = CGRectMake(CGRectGetMinX(bubbleFrame), CGRectGetMinY(bubbleFrame), CGRectGetWidth(bubbleFrame), CGRectGetHeight(bubbleFrame));
        CGContextRef context = UIGraphicsGetCurrentContext();
        [self.color setFill];
        CGContextFillRect(context, thumbRect);
        
        
        // Draw Handles
        [[UIColor colorWithWhite:0 alpha:0.2] setFill];
        CGRect handleRect = CGRectMake(CGRectGetMinX(bubbleFrame)+CGRectGetWidth(bubbleFrame)/2.5 - 1, CGRectGetMinY(bubbleFrame)+CGRectGetHeight(bubbleFrame)/2 - 4.5, 1.1, 10);
        CGContextFillRect(context, handleRect);
        
        handleRect = CGRectMake(CGRectGetMinX(bubbleFrame)+CGRectGetWidth(bubbleFrame)/2.5 + 2.3, CGRectGetMinY(bubbleFrame)+CGRectGetHeight(bubbleFrame)/2 - 4.5, 1.1, 10);
        CGContextFillRect(context, handleRect);
    }
}


@end
