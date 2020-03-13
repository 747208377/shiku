//
//  JXImageView.h
//  textScr
//
//  Created by JK PENG on 11-8-17.
//  Copyright 2011年 Devdiv. All rights reserved.
//

#import <UIKit/UIKit.h>

#define JXImageView_Animation_None 0 //无动画
#define JXImageView_Animation_Line 1 //渐变
#define JXImageView_Animation_More 2 //多变



@interface JXImageView : UIImageView {
    int         _oldAlpha;
    BOOL        _canChange;
}
//为了先获取图片Size,后设置JXImageview大小，专设的变量
@property (nonatomic) CGSize imageSize;

@property (nonatomic, weak) NSObject* delegate;
@property (nonatomic, assign) SEL		didTouch;
@property (nonatomic, assign) SEL		didDragout;
@property (nonatomic, assign) BOOL      changeAlpha;
@property (nonatomic, assign) BOOL      selected;
@property (nonatomic, assign) BOOL      enabled;
@property (nonatomic, assign) int       animationType;//动画类型，0:没有；1:渐变；2:多变

@end
