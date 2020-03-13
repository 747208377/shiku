//
//  JXActionSheetVC.m
//  shiku_im
//
//  Created by 1 on 2018/9/3.
//  Copyright © 2018年 Reese. All rights reserved.
//

#import "JXActionSheetVC.h"

#define HEIGHT 49    // 每个成员高度，如果更改记得更改button按钮的imageEdgeInsets

@interface JXActionSheetVC ()

@property (nonatomic, strong) UIView *baseView;
@property (nonatomic, strong) NSArray *names;
@property (nonatomic, strong) NSArray *images;


@end

@implementation JXActionSheetVC

- (instancetype)initWithImages:(NSArray *)images names:(NSArray *)names {
    self = [super init];
    if (self) {
        //这句话是让控制器透明
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        self.backGroundColor = [UIColor whiteColor];
        self.names = names;
        self.images = images;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.tag = self.tag;
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    if (self.images.count > 0 || self.names.count > 0) {
        self.baseView = [[UIView alloc] init];
        self.baseView.frame = CGRectMake(0, JX_SCREEN_HEIGHT, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT);
        [self.view addSubview:self.baseView];
        [self setupViews];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [UIView animateWithDuration:.3f animations:^{
        self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        self.baseView.frame = CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT);
    }];
}

- (void)setupViews {
    // 创建一个取消按钮
    [self createButtonWithFrame:CGRectMake(0, JX_SCREEN_HEIGHT-JX_SCREEN_BOTTOM, JX_SCREEN_WIDTH, JX_SCREEN_BOTTOM) index:10000];
    for (int i = 0; i < self.names.count; i++) {
        int h = HEIGHT*(i+1);
        // 创建成员按钮
        [self createButtonWithFrame:CGRectMake(0, JX_SCREEN_HEIGHT-JX_SCREEN_BOTTOM - h-5, JX_SCREEN_WIDTH, HEIGHT) index:i];
    }
}

- (void)didButton:(UIButton *)button {
    
    //离开界面
    [self dismissViewController];
    if (button.tag >= 0 && button.tag != 10000) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(actionSheet:didButtonWithIndex:)]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.delegate actionSheet:self didButtonWithIndex:button.tag];
            });
        }
    } else {
        
    }
}

- (void)createButtonWithFrame:(CGRect)frame index:(int)index {
    UIButton *button = [[UIButton alloc] init];
    button.frame = frame;
    [button setTitle:index==10000 ? Localized(@"JX_Cencal") : self.names[index] forState:UIControlStateNormal];
    if (self.images.count > 0 && index !=10000 && index < self.images.count) {
        [button setImage:[UIImage imageNamed:self.images[index]] forState:UIControlStateNormal];
        button.imageView.contentMode = UIViewContentModeScaleAspectFit;
        // 修改button图片大小
        button.imageEdgeInsets = UIEdgeInsetsMake(14, 0, 14, 14);
    }
    button.backgroundColor = self.backGroundColor;
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    button.tag = index;
    [self.baseView addSubview:button];
    [button addTarget:self action:@selector(didButton:) forControlEvents:UIControlEventTouchUpInside];
    if (index == 10000) {
        if (THE_DEVICE_HAVE_HEAD) { // iPhoneX 字体显示上移
            button.titleEdgeInsets = UIEdgeInsetsMake(-6, 0, 6, 0);
        }
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, JX_SCREEN_HEIGHT-JX_SCREEN_BOTTOM-5, JX_SCREEN_WIDTH, 5)];
        line.backgroundColor = HEXCOLOR(0xDBDBDB);
        [self.baseView addSubview:line];
    }else {
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, button.frame.size.height-0.5, JX_SCREEN_WIDTH, 0.5)];
        line.backgroundColor = HEXCOLOR(0xDBDBDB);
        [button addSubview:line];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self dismissViewController];
}


- (void)dismissViewController {
    [UIView animateWithDuration:.3f animations:^{
        self.baseView.frame = CGRectMake(0, JX_SCREEN_HEIGHT, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT);
        self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:YES completion:nil];
        if (self) {
            [self.view removeFromSuperview];
        }
    }];
}

@end
