//
//  ICGRulerView.m
//  ICGVideoTrimmer
//
//  Created by Huong Do on 1/25/15.
//  Copyright (c) 2015 ichigo. All rights reserved.
//

#import "ICGRulerView.h"

@implementation ICGRulerView

- (instancetype)initWithFrame:(CGRect)frame widthPerSecond:(CGFloat)width rulerColor:(UIColor *)color
{
    self = [super initWithFrame:frame];
    if (self) {
        _widthPerSecond = width;
        _rulerColor = color;
    }
    self.opaque = NO;

    return self;
}


- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    // Tranparent ruler
    CGContextClearRect(context, rect);

    CGFloat leftMargin = 10;
    CGFloat topMargin = 0;
    CGFloat height = CGRectGetHeight(self.frame);
    CGFloat width = CGRectGetWidth(self.frame);
    CGFloat minorTickSpace = self.widthPerSecond;
    NSInteger multiple = 5;
    CGFloat majorTickLength = 16;
    CGFloat minorTickLength = 8;
    int multiple = 5;

    CGFloat baseY = topMargin + height;
    CGFloat minorY = baseY - minorTickLength;
    CGFloat majorY = baseY - majorTickLength;

    NSInteger step = 0;
    for (CGFloat x = leftMargin; x <= (leftMargin + width); x += minorTickSpace) {
        CGContextMoveToPoint(context, x, baseY);

        CGContextSetFillColorWithColor(context, self.rulerColor.CGColor);
        if (step % multiple == 0) {
            CGContextFillRect(context, CGRectMake(x, majorY, 2.0, majorTickLength));

            UIFont *font = [UIFont fontWithName:@"ProximaNova-Semibold" size:12];
            UIColor *textColor = self.rulerColor;
            NSDictionary *stringAttrs = @{NSFontAttributeName:font, NSForegroundColorAttributeName:textColor};

            NSInteger minutes = step / 60;
            NSInteger seconds = step % 60;

            NSAttributedString* attrStr;

            if (minutes > 0) {
                attrStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld:%02ld", (long) minutes, (long) seconds] attributes:stringAttrs];
            }
            else {
                attrStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@":%02ld", (long) seconds] attributes:stringAttrs];
            }

            [attrStr drawAtPoint:CGPointMake(x-7, majorY - 15)];


        } else {
            CGContextFillRect(context, CGRectMake(x, minorY, 1.0, minorTickLength));
        }

        step++;
    }

}

@end
