//
//  JXChatLogMoveVC.m
//  shiku_im
//
//  Created by p on 2019/6/5.
//  Copyright © 2019年 Reese. All rights reserved.
//

#import "JXChatLogMoveVC.h"
#import "JXChatLogMoveSelectVC.h"

@interface JXChatLogMoveVC ()

@end

@implementation JXChatLogMoveVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.isGotoBack = YES;
    self.title = Localized(@"JX_ChatLogMove");
    self.heightHeader = JX_SCREEN_TOP;
    self.heightFooter = 0;
    //self.view.frame = CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT);
    [self createHeadAndFoot];
    
    UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake((JX_SCREEN_WIDTH - 150) / 2, 100, 150, 150)];
    logo.image = [UIImage imageNamed:@"酷聊120"];
    [self.tableBody addSubview:logo];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(logo.frame) + 50, JX_SCREEN_WIDTH, 30)];
    title.font = [UIFont systemFontOfSize:20];
    title.textAlignment = NSTextAlignmentCenter;
    title.text = Localized(@"JX_ChatLogMoveToDevice");
    [self.tableBody addSubview:title];
    
    UILabel *subTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(title.frame) + 10, JX_SCREEN_WIDTH, 30)];
    subTitle.font = [UIFont systemFontOfSize:18];
    subTitle.textColor = [UIColor lightGrayColor];
    subTitle.textAlignment = NSTextAlignmentCenter;
    subTitle.text = Localized(@"JX_TwoDeviceConnectWIFI");
    [self.tableBody addSubview:subTitle];
    
    UIButton *btn = [UIFactory createCommonButton:Localized(@"JX_MoveChatRecords") target:self action:@selector(onMove)];
    [btn setBackgroundImage:nil forState:UIControlStateHighlighted];
    btn.custom_acceptEventInterval = 1.f;
    btn.frame = CGRectMake(INSETS,CGRectGetMaxY(subTitle.frame) + 100, WIDTH, 50);
    [btn setBackgroundImage:nil forState:UIControlStateNormal];
    btn.backgroundColor = THEMECOLOR;
    [self.tableBody addSubview:btn];
    
    
}

- (void)onMove {
    
    JXChatLogMoveSelectVC *vc = [[JXChatLogMoveSelectVC alloc] init];
    [g_navigation pushViewController:vc animated:YES];
    
    [self actionQuit];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
