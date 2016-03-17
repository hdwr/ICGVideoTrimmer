//
//  ICGRulerView.m
//  ICGVideoTrimmer
//
//  Created by Huong Do on 1/25/15.
//  Copyright (c) 2015 ichigo. All rights reserved.
//

#import "ICGRulerView.h"

@implementation ICGRulerView

- (instancetype)initWithFrame:(CGRect)frame widthPerSecond:(CGFloat)width themeColor:(UIColor *)color compact:(BOOL)compact
{
    self = [super initWithFrame:frame];
    if (self) {
        _widthPerSecond = width;
        _themeColor = color;
        _compact = compact;
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

    CGFloat leftMargin = 15;

    CGFloat topMargin = 0;
    CGFloat height = CGRectGetHeight(self.frame);
    CGFloat width = CGRectGetWidth(self.frame);
    CGFloat minorTickSpace = self.widthPerSecond;

    NSInteger multiple = 5;
    CGFloat majorTickLength;
    CGFloat minorTickLength;
    CGFloat majorTickWidth;
    CGFloat minorTickWidth;

    if (self.compact) {
        majorTickLength = 10;
        minorTickLength = 6;
        majorTickWidth = 1.0;
        minorTickWidth = 1.0;
    } else {
        majorTickLength = 16;
        minorTickLength = 8;
        majorTickWidth = 2.0;
        minorTickWidth = 1.0;
    }

    CGFloat baseY = topMargin + height;
    CGFloat minorY = baseY - minorTickLength;
    CGFloat majorY = baseY - majorTickLength;

    NSInteger step = 0;
    for (CGFloat x = leftMargin; x <= (leftMargin + width); x += minorTickSpace) {
        CGContextMoveToPoint(context, x, baseY);

        CGContextSetFillColorWithColor(context, self.themeColor.CGColor);
        if (step % multiple == 0) {
            CGContextFillRect(context, CGRectMake(x, majorY, majorTickWidth, majorTickLength));

            // Don't show numbers when compact
            if (!self.compact) {

                UIFont *font = [UIFont fontWithName:@"ProximaNova-Semibold" size:12];
                UIColor *textColor = self.themeColor;
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
            }

        } else {
            CGContextFillRect(context, CGRectMake(x, minorY, minorTickWidth, minorTickLength));
        }

        step++;
    }

}

@end
