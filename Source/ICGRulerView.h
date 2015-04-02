//
//  ICGRulerView.h
//  ICGVideoTrimmer
//
//  Created by Huong Do on 1/25/15.
//  Copyright (c) 2015 ichigo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ICGRulerView : UIView

@property (assign, nonatomic) CGFloat widthPerSecond;
@property (strong, nonatomic) UIColor *rulerColor;
@property (assign, nonatomic) BOOL compact;

- (instancetype)initWithFrame:(CGRect)frame widthPerSecond:(CGFloat)width rulerColor:(UIColor *)color compact:(BOOL)compact;

@end
