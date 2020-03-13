//
//  JXWebLoginVC.m
//  shiku_im
//
//  Created by p on 2019/5/28.
//  Copyright © 2019年 Reese. All rights reserved.
//

#import "JXWebLoginVC.h"

@interface JXWebLoginVC ()

@end

@implementation JXWebLoginVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.heightFooter = 0;
    self.heightHeader = JX_SCREEN_TOP;

    self.title = @"登录";
    self.isGotoBack = YES;
    
    [self createHeadAndFoot];
    self.tableBody.backgroundColor = [UIColor whiteColor];
    
    //酷聊icon
    UIImageView * kuliaoIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"酷聊120"]];
    kuliaoIconView.frame = CGRectMake((JX_SCREEN_WIDTH-95)/2, 50, 95, 95);
    [self.tableBody addSubview:kuliaoIconView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(kuliaoIconView.frame) + 20, JX_SCREEN_WIDTH, 20)];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = app_name;
    label.font = [UIFont systemFontOfSize:16.0];
    [self.tableBody addSubview:label];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(50, CGRectGetMaxY(label.frame) + 80, JX_SCREEN_WIDTH, 20)];
    label.text = g_myself.userNickname;
    label.font = [UIFont systemFontOfSize:16.0];
    [self.tableBody addSubview:label];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(50, CGRectGetMaxY(label.frame) + 20, JX_SCREEN_WIDTH, 20)];
    label.text = g_myself.telephone;
    label.font = [UIFont systemFontOfSize:14.0];
    label.textColor = [UIColor lightGrayColor];
    [self.tableBody addSubview:label];
    
    UIImageView *userIcon = [[UIImageView alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH - 100, CGRectGetMaxY(label.frame) - 55, 50, 50)];
    userIcon.layer.cornerRadius = 50 / 2;
    userIcon.layer.masksToBounds = YES;
    [g_server getHeadImageLarge:g_myself.userId userName:g_myself.userNickname imageView:userIcon];
    [self.tableBody addSubview:userIcon];
    
    
    UIButton *btn = [UIFactory createCommonButton:@"确认登录" target:self action:@selector(onLogin)];
    [btn setBackgroundImage:nil forState:UIControlStateHighlighted];
    btn.custom_acceptEventInterval = 1.f;
    btn.frame = CGRectMake(INSETS,CGRectGetMaxY(label.frame) + 50, WIDTH, 50);
    [btn setBackgroundImage:nil forState:UIControlStateNormal];
    btn.backgroundColor = THEMECOLOR;
    [self.tableBody addSubview:btn];
    
}

- (void)actionQuit {
 
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onLogin {
    
    if (self.isQRLogin) {
        if ([self.delegate respondsToSelector:@selector(webLoginSuccess)]) {
            [self.delegate webLoginSuccess];
            [super actionQuit];
        }
    }else {
        NSString *url = [NSString stringWithFormat:@"%@?data=%@",self.callbackUrl,[self getData]];
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (NSString *)getData {
    NSDictionary *dic = @{
                           @"accessToken" : g_server.access_token,
                           @"telephone" : g_myself.telephone,
                           @"password" : [g_default objectForKey:kMY_USER_PASSWORD]
                           };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *json =  [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *key = [g_server getMD5String:APIKEY];
    NSString *encrypted = [DESUtil encryptDESStr:json key:key];
    NSString *encodedString = (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                              (CFStringRef)encrypted,
                                                              NULL,
                                                              (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                              kCFStringEncodingUTF8));
    return encodedString;
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
