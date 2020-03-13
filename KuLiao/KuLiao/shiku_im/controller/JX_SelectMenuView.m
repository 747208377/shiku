//
//  JX_SelectMenuView.m
//  shiku_im
//
//  Created by Apple on 16/9/12.
//  Copyright © 2016年 Reese. All rights reserved.
//

#import "JX_SelectMenuView.h"
#import "UIImage+Color.h"


#define INSET_INT 17    //   左右间隔

@implementation JX_SelectMenuView


- (instancetype)initWithTitle:(NSArray *)titleArr image:(NSArray *)images cellHeight:(int)height {
    self = [super init];
    if (self) {
        int topHeight = 12;
        // 获取当前最长的字符串
        NSString *currentStr = titleArr[0];
        for (NSString *str in titleArr) {
            if (currentStr.length < str.length) {
                currentStr = str;
            }
        }
        CGSize size = [currentStr boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:SYSFONT(16)} context:nil].size;
        
        //顶部尖角高度topHeight
        //每格高度heigth
        //大小
        self.frame = CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT);
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.7];
        UITapGestureRecognizer *bigTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideMenuView)];
        [self addGestureRecognizer:bigTap];
        UIView *bigView = [[UIView alloc] init];
        CGPoint point;
        if (images.count > 0) {  // 有图标
            point = CGPointMake(JX_SCREEN_WIDTH - (size.width + INSET_INT*4) - 5, JX_SCREEN_TOP);
            bigView.frame = CGRectMake(point.x, point.y+3 , size.width+INSET_INT*4, titleArr.count *height+topHeight);
        } else {  // 无图标
            point = CGPointMake(JX_SCREEN_WIDTH - (size.width + INSET_INT*2) - 5, JX_SCREEN_TOP);
            bigView.frame = CGRectMake(point.x, point.y+3 , size.width+INSET_INT*2, titleArr.count*height+topHeight);
        }
        [self addSubview:bigView];
        //背景图片
        UIImageView * bgImage = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, bigView.frame.size.width, bigView.frame.size.height)];
        bgImage.userInteractionEnabled = NO;
        UIImage *image = [[UIImage imageNamed:@"Haircircleoffriends_white"] resizableImageWithCapInsets:UIEdgeInsetsMake(25, 10, 25, 10) resizingMode:UIImageResizingModeStretch];
        bgImage.image = image;
        [bigView addSubview:bgImage];
        //动态设置
        for (int i = 0; i < [titleArr count]; i++) {
            UIView *baseView = [[UIView alloc] initWithFrame:CGRectMake(0, topHeight + height *i, bigView.frame.size.width, height)];
            baseView.tag = i;
            [bigView addSubview:baseView];
            
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didMenuViewCell:)];
            [baseView addGestureRecognizer:tap];
            //添加分割线
            if (i < [titleArr count]-1) {
                UIView * lineView = [[UIView alloc]initWithFrame:CGRectMake(INSET_INT, baseView.frame.size.height-0.5, baseView.frame.size.width-INSET_INT*2, 0.5)];
                lineView.backgroundColor = [HEXCOLOR(0xd8d8d8) colorWithAlphaComponent:0.3];
                [baseView addSubview:lineView];
            }
            
            UILabel * titleLabel = [[UILabel alloc]init];
            UIImageView *imageView;
            if (images.count > 0 && i < images.count) { // 有图标
                imageView = [[UIImageView alloc] initWithFrame:CGRectMake(INSET_INT, height/2-10, 20, 20)];
                imageView.image = [UIImage imageNamed:images[i]];
                imageView.backgroundColor = [UIColor clearColor];
                [baseView addSubview:imageView];
                titleLabel.frame = CGRectMake(CGRectGetMaxX(imageView.frame)+INSET_INT, 0, baseView.frame.size.width-INSET_INT*3, height - 0.5);
                titleLabel.textAlignment = NSTextAlignmentLeft;
            } else {  // 无图标
                titleLabel.frame = CGRectMake(INSET_INT, 0, baseView.frame.size.width-INSET_INT*2, height - 0.5);
                titleLabel.textAlignment = NSTextAlignmentCenter;
            }
            //设置标题
            titleLabel.text = titleArr[i];
            titleLabel.textColor = [UIColor blackColor];
            titleLabel.font = SYSFONT(16);
            titleLabel.userInteractionEnabled = NO;
            [baseView addSubview:titleLabel];
            
            
        }
    }
        return self;
}

- (void)didMenuViewCell:(UITapGestureRecognizer *)tap {
    if (self.delegate &&[self.delegate respondsToSelector:@selector(didMenuView:WithIndex:)]) {
        [self.delegate didMenuView:self WithIndex:tap.view.tag];
        [self hide];
    }
}

- (void)hideMenuView {
    [self hide];
}


- (void)hide {
    if (self) {
        [self removeFromSuperview];
    }
}

@end
