#import <QuartzCore/QuartzCore.h>
#import "NSWindow+ShakeAnimation.h"


@implementation NSWindow (ShakeAnimation)

- (void)performShakeAnimation {
    // Stolen from: http://stackoverflow.com/questions/10517386
    static int numberOfShakes = 2;
    static float durationOfShake = 0.3f;
    static float vigourOfShake = 0.015f;
    
    CGRect frame = self.frame;
    CAKeyframeAnimation *shakeAnimation = CAKeyframeAnimation.animation;
    
    CGMutablePathRef shakePath = CGPathCreateMutable();
    CGPathMoveToPoint(shakePath, NULL, NSMinX(frame), NSMinY(frame));
    for (NSInteger index = 0; index < numberOfShakes; index++){
        CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) - frame.size.width * vigourOfShake, NSMinY(frame));
        CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) + frame.size.width * vigourOfShake, NSMinY(frame));
    }
    CGPathCloseSubpath(shakePath);
    shakeAnimation.path = shakePath;
    shakeAnimation.duration = durationOfShake;
    
    self.animations = @{@"frameOrigin": shakeAnimation};
    [self.animator setFrameOrigin:self.frame.origin];
    
    CGPathRelease(shakePath);
}

@end
