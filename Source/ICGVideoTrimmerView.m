//
//  ICGVideoTrimmerView.m
//  ICGVideoTrimmer
//
//  Created by Huong Do on 1/18/15.
//  Copyright (c) 2015 ichigo. All rights reserved.
//

#import "ICGVideoTrimmerView.h"
#import "ICGThumbView.h"
#import "ICGRulerView.h"

@interface ICGVideoTrimmerView() <UIScrollViewDelegate>

@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) UIView *frameView;
@property (strong, nonatomic) UIView *playHeadView;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) AVAssetImageGenerator *imageGenerator;

@property (strong, nonatomic) UIView *leftOverlayView;
@property (strong, nonatomic) UIView *rightOverlayView;
@property (strong, nonatomic) ICGThumbView *leftThumbView;
@property (strong, nonatomic) ICGThumbView *rightThumbView;

@property (strong, nonatomic) UIView *topBorder;
@property (strong, nonatomic) UIView *bottomBorder;

@property (nonatomic) Float64 duration;

@property (nonatomic) CGFloat widthPerSecond;

@property (nonatomic) CGPoint leftStartPoint;
@property (nonatomic) CGPoint rightStartPoint;
@property (nonatomic) CGFloat overlayWidth;

// Persist this value so we can reset subviews and preserve scroll time
@property (nonatomic) CGFloat scrollTime;


@end

@implementation ICGVideoTrimmerView

#pragma mark - Initiation

- (instancetype)initWithAsset:(AVAsset *)asset
{
    self = [super init];
    if (self) {
        _asset = asset;
        [self resetSubviews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame asset:(AVAsset *)asset
{
    self = [super initWithFrame:frame];
    if (self) {
        _asset = asset;
        [self resetSubviews];
    }
    return self;
}


#pragma mark - Private methods

- (void)resetSubviews
{
    // Fixes issue when transitioning to modal view controller
    self.clipsToBounds = YES;

    if (self.maxLength == 0) {
        self.maxLength = 15;
    }

    if (self.minLength == 0) {
        self.minLength = 3;
    }

    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
    [self addSubview:self.scrollView];
    [self.scrollView setDelegate:self];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];

    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.scrollView.frame))];
    [self.scrollView setContentSize:self.contentView.frame.size];
    [self.scrollView addSubview:self.contentView];

    CGFloat ratio = (self.showsRulerView && !self.overlayRulerView) ? 0.58 : 1.0;
    // NOTE: frameView is reset during addFrames
    CGRect frameViewFrame = CGRectMake(15 + self.thumbPadding, 2, CGRectGetWidth(self.contentView.frame) - (15 * 2), CGRectGetHeight(self.contentView.frame) * ratio - 4);
    self.frameView = [[UIView alloc] initWithFrame:frameViewFrame];
    [self.frameView.layer setMasksToBounds:YES];
    [self.contentView addSubview:self.frameView];

    [self addFrames];

    if (self.showsRulerView) {
        CGFloat rulerWidth = CGRectGetWidth(self.contentView.frame) - self.thumbPadding;
        // round to nearest second and always add enough space to show next time offset
        rulerWidth = (ceilf(rulerWidth / self.widthPerSecond) * self.widthPerSecond) + self.widthPerSecond / 2;

        // Always show at least 15 seconds
        CGFloat minRulerWidth = CGRectGetWidth(self.frame) - (self.thumbPadding * 2) - 15 + self.widthPerSecond / 2;
        if (rulerWidth < CGRectGetWidth(self.frame) - self.thumbPadding + 15)
            rulerWidth = minRulerWidth;

        CGRect rulerFrame;
        ICGRulerView *rulerView;
        if (self.overlayRulerView) {
            rulerFrame = CGRectMake(self.thumbPadding, 2, rulerWidth, CGRectGetHeight(self.contentView.frame) - 4);
            rulerView = [[ICGRulerView alloc] initWithFrame:rulerFrame widthPerSecond:self.widthPerSecond rulerColor:[UIColor whiteColor] compact:YES];

        } else {
            rulerFrame = CGRectMake(self.thumbPadding, CGRectGetHeight(self.contentView.frame) * ratio, rulerWidth, CGRectGetHeight(self.contentView.frame) * (1 - ratio));
            rulerView = [[ICGRulerView alloc] initWithFrame:rulerFrame widthPerSecond:self.widthPerSecond rulerColor:self.rulerColor compact:NO];
        }

        [self.contentView addSubview:rulerView];
    }

    // add borders
    self.topBorder = [[UIView alloc] init];
    [self.topBorder setBackgroundColor:self.trimmerColor];
    [self addSubview:self.topBorder];

    self.bottomBorder = [[UIView alloc] init];
    [self.bottomBorder setBackgroundColor:self.trimmerColor];
    [self addSubview:self.bottomBorder];

    // width for left and right overlay views. Just use the wh
    self.overlayWidth = CGRectGetWidth(self.frame);

    // add left overlay view
    CGRect leftViewFrame = CGRectMake(self.thumbPadding + 15 - self.overlayWidth, 2, self.overlayWidth, CGRectGetHeight(self.frameView.frame));

    self.leftOverlayView = [[UIView alloc] initWithFrame:leftViewFrame];
    CGRect leftThumbFrame = CGRectMake(self.overlayWidth - 15, 0, 15, CGRectGetHeight(self.frameView.frame));
    if (self.leftThumbImage) {
        self.leftThumbView = [[ICGThumbView alloc] initWithFrame:leftThumbFrame thumbImage:self.leftThumbImage];
    } else {
        self.leftThumbView = [[ICGThumbView alloc] initWithFrame:leftThumbFrame color:self.trimmerColor right:NO];
    }
    [self.leftThumbView.layer setMasksToBounds:YES];
    [self.leftOverlayView addSubview:self.leftThumbView];
    [self.leftOverlayView setUserInteractionEnabled:YES];
    UIPanGestureRecognizer *leftPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveLeftOverlayView:)];
    [self.leftOverlayView addGestureRecognizer:leftPanGestureRecognizer];
    [self.leftOverlayView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.6]];
    [self addSubview:self.leftOverlayView];

    // add right overlay view
    CGFloat rightViewFrameX = CGRectGetMaxX(self.frameView.frame);
    if (rightViewFrameX > (CGRectGetWidth(self.frame) - 15 - self.thumbPadding)) {
        rightViewFrameX = CGRectGetWidth(self.frame) - 15 - self.thumbPadding;
    }

    self.rightOverlayView = [[UIView alloc] initWithFrame:CGRectMake(rightViewFrameX, 2, self.overlayWidth, CGRectGetHeight(self.frameView.frame))];
    if (self.rightThumbImage) {
        self.rightThumbView = [[ICGThumbView alloc] initWithFrame:CGRectMake(0, 0, 15, CGRectGetHeight(self.frameView.frame)) thumbImage:self.rightThumbImage];
    } else {
        self.rightThumbView = [[ICGThumbView alloc] initWithFrame:CGRectMake(0, 0, 15, CGRectGetHeight(self.frameView.frame)) color:self.trimmerColor right:YES];
    }
    [self.rightThumbView.layer setMasksToBounds:YES];
    [self.rightOverlayView addSubview:self.rightThumbView];
    [self.rightOverlayView setUserInteractionEnabled:YES];
    UIPanGestureRecognizer *rightPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveRightOverlayView:)];
    [self.rightOverlayView addGestureRecognizer:rightPanGestureRecognizer];
    [self.rightOverlayView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.6]];
    [self addSubview:self.rightOverlayView];

    // Need to add playHeadView on top of everything else
    self.playHeadView = [[UIView alloc] init];
    self.playHeadView.backgroundColor = [UIColor whiteColor];
    self.playHeadView.alpha = 0.0;
    [self addSubview:self.playHeadView];


    // Preserve scroll, start and end times when resetting subviews
    if (self.scrollTime > 0) {
        CGFloat scrollXOffset = self.scrollTime * self.widthPerSecond;
        // Don't fire scrollViewDidScroll callback.
        [self.scrollView setDelegate:nil];
        [self.scrollView setContentOffset:CGPointMake(scrollXOffset, 0)];
        [self.scrollView setDelegate:self];
    }

    if (self.startTime > 0) {
        CGFloat leftXOffset = (self.startTime - self.scrollTime) * self.widthPerSecond  + self.thumbPadding + 15 - self.overlayWidth;
        self.leftOverlayView.frame = CGRectMake(leftXOffset, 2, self.overlayWidth, CGRectGetHeight(self.frameView.frame));
    }

    if (self.endTime > 0) {
        CGFloat rightXOffset = (self.endTime - self.scrollTime) * self.widthPerSecond + self.thumbPadding + 15;
        self.rightOverlayView.frame = CGRectMake(rightXOffset, 2, self.overlayWidth, CGRectGetHeight(self.frameView.frame));
    }

    [self updateBorderFrames];

    // Only call notifyDelegateScrolled at first initialization
    if (self.scrollTime == 0 && self.startTime == 0 && self.endTime == 0) {
        [self notifyDelegateScrolled:YES movedLeftHandle:NO movedRightHandle:NO];
    }
}

- (void)updatePlayHead:(CMTime)time
{
    Float64 timeSeconds = CMTimeGetSeconds(time);
    CGFloat offsetX = (timeSeconds * self.widthPerSecond)
                    - self.scrollView.contentOffset.x
                    + self.thumbPadding + 15;
    // In case we reset subviews while playing
    if (self.playHeadView.alpha == 0.0) {
        self.playHeadView.alpha = 1.0;
    }
    [self.playHeadView setFrame:CGRectMake(offsetX, 0, 2.0, CGRectGetHeight(self.frameView.frame) + 4.0)];
}

- (void)hidePlayHeadAnimated:(BOOL)animated
{
    void (^animationBlock)() = ^{ self.playHeadView.alpha = 0.0; };
    if (animated) {
        [UIView animateWithDuration:0.2 animations:animationBlock];
    } else {
        animationBlock();
    }
}

- (void)showPlayHeadAnimated:(BOOL)animated
{
    void (^animationBlock)() = ^{ self.playHeadView.alpha = 1.0; };
    if (animated) {
        [UIView animateWithDuration:0.2 animations:animationBlock];
    } else {
        animationBlock();
    }
}


- (void)updateBorderFrames
{
    CGFloat height = self.borderWidth ? self.borderWidth : 1;
    [self.topBorder setFrame:CGRectMake(CGRectGetMaxX(self.leftOverlayView.frame), 2, CGRectGetMinX(self.rightOverlayView.frame)-CGRectGetMaxX(self.leftOverlayView.frame), height)];
    [self.bottomBorder setFrame:CGRectMake(CGRectGetMaxX(self.leftOverlayView.frame), CGRectGetHeight(self.frameView.frame)-height+2, CGRectGetMinX(self.rightOverlayView.frame)-CGRectGetMaxX(self.leftOverlayView.frame), height)];
}

- (void)moveLeftOverlayView:(UIPanGestureRecognizer *)gesture
{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            self.leftStartPoint = [gesture locationInView:self];
            [self.delegate trimmerViewWillBeginDraggingWithScroll:NO movedLeftHandle:YES movedRightHandle:NO];
            break;

        case UIGestureRecognizerStateChanged:
        {
            CGPoint point = [gesture locationInView:self];

            int deltaX = point.x - self.leftStartPoint.x;

            CGPoint center = self.leftOverlayView.center;

            CGFloat newLeftViewMidX = center.x += deltaX;;
            CGFloat maxWidth = CGRectGetMinX(self.rightOverlayView.frame) - (self.minLength * self.widthPerSecond);
            CGFloat newLeftViewMinX = newLeftViewMidX - self.overlayWidth/2;
            if (newLeftViewMinX < self.thumbPadding + 15 - self.overlayWidth) {
                newLeftViewMidX = self.thumbPadding + 15 - self.overlayWidth + self.overlayWidth/2;
            } else if (newLeftViewMinX + self.overlayWidth > maxWidth) {
                newLeftViewMidX = maxWidth - self.overlayWidth / 2;
            }

            self.leftOverlayView.center = CGPointMake(newLeftViewMidX, self.leftOverlayView.center.y);
            self.leftStartPoint = point;
            [self updateBorderFrames];
            [self notifyDelegateScrolled:NO movedLeftHandle:YES movedRightHandle:NO];

            break;
        }

        case UIGestureRecognizerStateEnded:
            [self.delegate trimmerViewDidEndDraggingWithScroll:NO movedLeftHandle:YES movedRightHandle:NO];
            break;

        default:
            break;
    }


}

- (void)moveRightOverlayView:(UIPanGestureRecognizer *)gesture
{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            self.rightStartPoint = [gesture locationInView:self];
            [self.delegate trimmerViewWillBeginDraggingWithScroll:NO movedLeftHandle:NO movedRightHandle:YES];
            break;

        case UIGestureRecognizerStateChanged:
        {
            CGPoint point = [gesture locationInView:self];

            int deltaX = point.x - self.rightStartPoint.x;

            CGPoint center = self.rightOverlayView.center;

            CGFloat newRightViewMidX = center.x += deltaX;
            CGFloat minX = CGRectGetMaxX(self.leftOverlayView.frame) + (self.minLength * self.widthPerSecond);
            CGFloat maxX = CGRectGetWidth(self.frame) - 15 - self.thumbPadding;

            if (maxX > CGRectGetMaxX(self.frameView.frame)) {
                maxX = CGRectGetMaxX(self.frameView.frame);
            }

            if (newRightViewMidX - self.overlayWidth / 2 < minX) {
                newRightViewMidX = minX + self.overlayWidth / 2;
            } else if (newRightViewMidX - self.overlayWidth / 2 > maxX) {
                newRightViewMidX = maxX + self.overlayWidth / 2;
            }

            self.rightOverlayView.center = CGPointMake(newRightViewMidX, self.rightOverlayView.center.y);
            self.rightStartPoint = point;
            [self updateBorderFrames];
            [self notifyDelegateScrolled:NO movedLeftHandle:NO movedRightHandle:YES];

            break;
        }

        case UIGestureRecognizerStateEnded:
            [self.delegate trimmerViewDidEndDraggingWithScroll:NO movedLeftHandle:NO movedRightHandle:YES];
            break;

        default:
            break;
    }
}

- (void)notifyDelegateScrolled:(BOOL)scrolled movedLeftHandle:(BOOL)leftHandle movedRightHandle:(BOOL)rightHandle
{
    CGFloat previousStartTime = self.startTime;
    CGFloat previousEndTime = self.endTime;

    self.scrollTime = (self.scrollView.contentOffset.x) / self.widthPerSecond;

    self.startTime = self.scrollTime + (CGRectGetMaxX(self.leftOverlayView.frame) - self.thumbPadding - 15) / self.widthPerSecond;
    self.endTime = self.scrollTime + (CGRectGetMinX(self.rightOverlayView.frame) - self.thumbPadding - 15) / self.widthPerSecond;

    if (self.startTime < 0.0) {
        self.endTime += self.startTime * -1;
        self.startTime = 0.0;
    }
    if (self.endTime > _duration) {
        self.startTime -= self.endTime - _duration;
        self.endTime = _duration;
    }
    if (self.startTime < 0.0) self.startTime = 0.0;

    // Calculate CMTime values
    UInt64 startTimeFrame = (UInt64)(self.startTime * 600);
    UInt64 endTimeFrame = (UInt64)(self.endTime * 600);
    self.startCMTime = CMTimeMake(startTimeFrame, 600);
    self.endCMTime = CMTimeMake(endTimeFrame, 600);

    // Only notify delegate if there was a change
    if (fabs(self.startTime - previousStartTime) > FLT_EPSILON || fabs(self.endTime - previousEndTime) > FLT_EPSILON) {
        //NSLog(@"start time: %f, end time: %f", self.startTime, self.endTime);

        [self.delegate trimmerView:self didChangeRangeWithScroll:scrolled movedLeftHandle:leftHandle movedRightHandle:rightHandle];
    }
}

- (void)addFrames
{
    self.imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.asset];
    self.imageGenerator.appliesPreferredTrackTransform = YES;

    CGFloat maxHeight = CGRectGetHeight(self.frameView.frame);
    CGFloat maxWidth  = CGRectGetWidth(self.frameView.frame);

    CGFloat frameWidth = maxHeight * 4/3;

    if ([self isRetina]){
        self.imageGenerator.maximumSize = CGSizeMake(maxWidth * 2, maxHeight * 2);
    } else {
        self.imageGenerator.maximumSize = CGSizeMake(maxWidth, maxHeight);
    }

    CGFloat picWidth = 0;

    // First image
    NSError *error;
    CMTime actualTime;
    CGImageRef halfWayImage = [self.imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:&actualTime error:&error];
    UIImage *videoScreen;
    if ([self isRetina]){
        videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage scale:2.0 orientation:UIImageOrientationUp];
    } else {
        videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage];
    }
    if (halfWayImage != NULL) {
        UIImageView *tmp = [[UIImageView alloc] initWithImage:videoScreen];
        CGRect rect = tmp.frame;
        rect.size.width = videoScreen.size.width;
        tmp.frame = rect;
        [self.frameView addSubview:tmp];
        picWidth = tmp.frame.size.width;
        CGImageRelease(halfWayImage);

        // We generate frames with a bigger width, but successive frames will overlap.
        if (picWidth < frameWidth) {
            frameWidth = picWidth;
        }
    }

    _duration = CMTimeGetSeconds([self.asset duration]);
    // Calculate screen width minus width of thumb views + padding
    CGFloat screenWidth = CGRectGetWidth(self.frame) - (15 * 2) - (self.thumbPadding * 2);
    NSInteger actualFramesNeeded;

    CGFloat frameViewFrameWidth = (_duration / self.maxLength) * screenWidth;
    [self.frameView setFrame:CGRectMake(15 + self.thumbPadding, 2, frameViewFrameWidth, CGRectGetHeight(self.frameView.frame))];
    CGFloat contentViewFrameWidth = frameViewFrameWidth + (15 * 2) + (self.thumbPadding * 2);

    [self.contentView setFrame:CGRectMake(0, 0, contentViewFrameWidth, CGRectGetHeight(self.contentView.frame))];
    [self.scrollView setContentSize:self.contentView.frame.size];
    NSInteger minFramesNeeded = screenWidth / frameWidth + 1;
    actualFramesNeeded = ((_duration / self.maxLength) * minFramesNeeded) + 1;

    Float64 durationPerFrame = _duration / (actualFramesNeeded*1.0);
    self.widthPerSecond = frameViewFrameWidth / _duration;

    int preferredWidth = 0;
    NSMutableArray *times = [[NSMutableArray alloc] init];
    for (int i = 1; i < actualFramesNeeded; i++){

        CMTime time = CMTimeMakeWithSeconds(i * durationPerFrame, 600);
        [times addObject:[NSValue valueWithCMTime:time]];

        UIImageView *tmp = [[UIImageView alloc] initWithImage:videoScreen];
        tmp.tag = i;

        CGRect currentFrame = tmp.frame;
        currentFrame.origin.x = i * frameWidth;

        currentFrame.size.width = frameWidth;
        preferredWidth += currentFrame.size.width;

        if( i == actualFramesNeeded-1){
            currentFrame.size.width-=6;
        }
        tmp.frame = currentFrame;

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.frameView addSubview:tmp];
        });
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i=1; i<=[times count]; i++) {
            CMTime time = [((NSValue *)[times objectAtIndex:i-1]) CMTimeValue];

            CGImageRef halfWayImage = [self.imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];

            UIImage *videoScreen;
            if ([self isRetina]){
                videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage scale:2.0 orientation:UIImageOrientationUp];
            } else {
                videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage];
            }

            CGImageRelease(halfWayImage);
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImageView *imageView = (UIImageView *)[self.frameView viewWithTag:i];
                [imageView setImage:videoScreen];
            });
        }
    });
}

- (BOOL)isRetina
{
    return ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
            ([UIScreen mainScreen].scale == 2.0));
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self notifyDelegateScrolled:YES movedLeftHandle:NO movedRightHandle:NO];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.delegate trimmerViewWillBeginDraggingWithScroll:YES movedLeftHandle:NO movedRightHandle:NO];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self.delegate trimmerViewDidEndDraggingWithScroll:YES movedLeftHandle:NO movedRightHandle:NO];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self.delegate trimmerViewDidEndDraggingWithScroll:YES movedLeftHandle:NO movedRightHandle:NO];
}

@end
