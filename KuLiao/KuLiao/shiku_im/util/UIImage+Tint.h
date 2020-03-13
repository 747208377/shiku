//
//  UIImage+Tint.h
//  shiku_im
//
//  Created by 1 on 17/3/6.
//  Copyright © 2017年 Reese. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Tint)


-(UIImage *) imageWithTintColor:(UIColor * )tintColor;
-(UIImage *) imageWithGradientTintColor:(UIColor *)tintColor;

@end
