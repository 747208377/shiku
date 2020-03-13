//
//  JXVolumeView.m
//  shiku_im
//
//  Created by flyeagleTang on 14-7-24.
//  Copyright (c) 2014年 Reese. All rights reserved.
//

#import "JXVolumeView.h"
#import "UIImage-Extensions.h"

@interface JXVolumeView ()

@end

@implementation JXVolumeView
@synthesize volume;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 6;
        self.layer.masksToBounds = YES;
        
        UIView* v = [[UIView alloc]initWithFrame:self.bounds];
        v.backgroundColor = [UIColor blackColor];
        v.alpha = 0.6;
        [self addSubview:v];
//        [v release];
        
        //椭圆下方的托架
        _volume = [[JXImageView alloc]initWithFrame:CGRectMake(0, 0, 106/2, 192/2)];
        _volume.center = self.center;
        _volume.image = [UIImage imageNamed:@"pub_recorder"];
        [self addSubview:_volume];
//        [_volume release];
        
        //椭圆白色背景
        JXImageView * inputBackground = [[JXImageView alloc]initWithFrame:CGRectMake(9, 1, 34, 66)];//20,1,66,132
        inputBackground.image = [UIImage imageNamed:@"pub_microphone_volumeBg"];
        inputBackground.layer.cornerRadius = 17;
        inputBackground.clipsToBounds = YES;
        [_volume addSubview:inputBackground];
//        [inputBackground release];
        
        //椭圆红色背景
        _input = [[JXImageView alloc]initWithFrame:CGRectMake(-0.2, 0, 34, 70)];
        _input.image = [UIImage imageNamed:@"pub_microphone_volume"];
        [inputBackground addSubview:_input];
//        [_input release];
        
        UILabel* p = [[UILabel alloc]initWithFrame:CGRectMake(0, frame.size.height-30, frame.size.width, 30)];
        p.text = Localized(@"JXVolumeView_CancelSend");
        p.textColor = [UIColor whiteColor];
        p.numberOfLines = 0;
        p.textAlignment = NSTextAlignmentCenter;
        p.font = g_factory.font11;
        [self addSubview:p];
//        [p release];
    }
    return self;
}



-(void)setVolume:(double)value{
    volume = value;
    float n = value;
    float m = 1.0-n;
//    _input.frame  =  CGRectMake(9, 1+66*m, 34, 66*n);
    _input.frame  =  CGRectMake(-0.2, 70*m -5 , 34, 70);
    _input.image = [UIImage imageNamed:@"pub_microphone_volume"];
//    _input.contentMode = UIViewContentModeScaleAspectFill;
//    NSLog(@"n:%f  m:%f",n,m);
    
//    _input.image = [_input.image imageAtRect:CGRectMake(9, 69 * m -1 , 34, 69*n )];
//    _input.frame = CGRectMake(9, 69 * m -2 , 34, 69*n );
    
}

//截取部分图像,无用
-(UIImage*)getSubImage:(CGRect)rect
{
    CGImageRef subImageRef = CGImageCreateWithImageInRect(_input.image.CGImage, rect);
    CGRect smallBounds = CGRectMake(0, 0, CGImageGetWidth(subImageRef), CGImageGetHeight(subImageRef));
    
    UIGraphicsBeginImageContext(smallBounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, smallBounds, subImageRef);
    UIImage* smallImage = [UIImage imageWithCGImage:subImageRef];
    UIGraphicsEndImageContext();
    
    return smallImage;
}

-(void)show{
    [g_window addSubview:self];
}

-(void)hide{
    [self removeFromSuperview];
}

@end
