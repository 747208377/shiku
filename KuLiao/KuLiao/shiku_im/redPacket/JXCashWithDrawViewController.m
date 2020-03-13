//
//  JXCashWithDrawViewController.m
//  shiku_im
//
//  Created by 1 on 17/10/27.
//  Copyright © 2017年 Reese. All rights reserved.
//

#import "JXCashWithDrawViewController.h"
#import "UIImage+Color.h"
#import "WXApi.h"
#import "WXApiManager.h"
#import "JXVerifyPayVC.h"
#import "JXPayPasswordVC.h"
#import <AlipaySDK/AlipaySDK.h>

#define drawMarginX 25
#define bgWidth JX_SCREEN_WIDTH-15*2
#define drawHei 60

@interface JXCashWithDrawViewController ()<UITextFieldDelegate>

@property (nonatomic, strong) UIButton * helpButton;

@property (nonatomic, strong) UIControl * hideControl;
@property (nonatomic, strong) UIControl * bgView;
@property (nonatomic, strong) UIView * targetView;
@property (nonatomic, strong) UIView * inputView;
@property (nonatomic, strong) UIView * balanceView;

@property (nonatomic, strong) UIButton * cardButton;
@property (nonatomic, strong) UITextField * countTextField;

@property (nonatomic, strong) UILabel * balanceLabel;
@property (nonatomic, strong) UIButton * drawAllBtn;
@property (nonatomic, strong) UIButton * withdrawalsBtn;
@property (nonatomic, strong) UIButton * aliwithdrawalsBtn;
@property (nonatomic, strong) ATMHud *loading;
@property (nonatomic, strong) JXVerifyPayVC *verVC;
@property (nonatomic, strong) NSString *payPassword;
@property (nonatomic, assign) BOOL isAlipay;
@property (nonatomic, strong) NSString *aliUserId;

@end

@implementation JXCashWithDrawViewController

-(instancetype)init{
    if (self = [super init]) {
        self.heightHeader = JX_SCREEN_TOP;
        self.heightFooter = 0;
        self.isGotoBack = YES;
        self.title = Localized(@"JXMoney_withdrawals");
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.frame = CGRectMake(JX_SCREEN_WIDTH, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT);
    
    [self createHeadAndFoot];
    self.tableBody.backgroundColor = HEXCOLOR(0xefeff4);
    
//    [self.tableHeader addSubview:self.helpButton];
    
    [self.tableBody addSubview:self.hideControl];
    [self.tableBody addSubview:self.bgView];
    
//    [self.bgView addSubview:self.targetView];
    [self.bgView addSubview:self.inputView];
    [self.bgView addSubview:self.balanceView];
    self.bgView.frame = CGRectMake(15, 20, bgWidth, CGRectGetMaxY(_balanceView.frame));
    
    _loading = [[ATMHud alloc] init];
    
    [g_notify addObserver:self selector:@selector(authRespNotification:) name:kWxSendAuthRespNotification object:nil];
}


-(UIButton *)helpButton{
    if(!_helpButton){
        _helpButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _helpButton.frame = CGRectMake(JX_SCREEN_WIDTH - 40, JX_SCREEN_TOP - 34, 24, 24);
        NSString *image = THESIMPLESTYLE ? @"im_003_more_button_black" : @"im_003_more_button_normal";
        [_helpButton setImage:[UIImage imageNamed:image] forState:UIControlStateNormal];
        [_helpButton setImage:[UIImage imageNamed:image] forState:UIControlStateHighlighted];
        [_helpButton addTarget:self action:@selector(helpButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _helpButton;
}

-(UIControl *)hideControl{
    if (!_hideControl) {
        _hideControl = [[UIControl alloc] init];
        _hideControl.frame = self.tableBody.bounds;
        [_hideControl addTarget:self action:@selector(hideControlAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _hideControl;
}

-(UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIControl alloc] init];
        _bgView.frame = CGRectMake(15, 20, bgWidth, 400);
        _bgView.backgroundColor = [UIColor whiteColor];
        _bgView.layer.cornerRadius = 5;
        _bgView.clipsToBounds = YES;
    }
    return _bgView;
}

-(UIView *)targetView{
    if (!_targetView) {
        _targetView = [[UIView alloc] init];
        _targetView.frame = CGRectMake(0, 0, bgWidth, drawHei);
        _targetView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
        
        UILabel * targetLabel = [UIFactory createLabelWith:CGRectMake(drawMarginX, 0, 120, drawHei) text:Localized(@"JXMoney_withDrawalsTarget")];
        [_targetView addSubview:targetLabel];
        
        CGRect btnFrame = CGRectMake(CGRectGetMaxX(targetLabel.frame)+20, 0, bgWidth-CGRectGetMaxX(targetLabel.frame)-20-drawMarginX, drawHei);
        _cardButton = [UIFactory createButtonWithRect:btnFrame title:@"微信号(8868)" titleFont:g_factory.font15 titleColor:HEXCOLOR(0x576b95) normal:nil selected:nil selector:@selector(cardButtonAction:) target:self];
        [_targetView addSubview:_cardButton];
    }
    return _targetView;
}

-(UIView *)inputView{
    if (!_inputView) {
        _inputView = [[UIView alloc] init];
        _inputView.frame = CGRectMake(0, 0, bgWidth, 126);
        _inputView.backgroundColor = [UIColor whiteColor];
        
        UILabel * cashTitle = [UIFactory createLabelWith:CGRectMake(drawMarginX, 0, 120, drawHei) text:Localized(@"JXMoney_withDAmount")];
        [_inputView addSubview:cashTitle];
        
        UILabel * rmbLabel = [UIFactory createLabelWith:CGRectMake(drawMarginX, CGRectGetMaxY(cashTitle.frame), 35, 35) text:@"¥"];
        rmbLabel.font = g_factory.font28b;
        rmbLabel.textAlignment = NSTextAlignmentLeft;
        [_inputView addSubview:rmbLabel];
        
        _countTextField = [UIFactory createTextFieldWithRect:CGRectMake(CGRectGetMaxX(rmbLabel.frame), CGRectGetMinY(rmbLabel.frame), bgWidth-CGRectGetMaxX(rmbLabel.frame)-drawMarginX, drawHei) keyboardType:UIKeyboardTypeDecimalPad secure:NO placeholder:nil font:[UIFont boldSystemFontOfSize:45] color:[UIColor blackColor] delegate:self];
        _countTextField.borderStyle = UITextBorderStyleNone;
        [_inputView addSubview:_countTextField];
        
        UIView * line = [[UIView alloc] init];
        line.frame = CGRectMake(drawMarginX, CGRectGetMaxY(_countTextField.frame)+5, bgWidth-drawMarginX*2, 0.8);
        line.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.5];
        [_inputView addSubview:line];
        
    }
    return _inputView;
}

-(UIView *)balanceView{
    if (!_balanceView) {
        _balanceView = [[UIView alloc] init];
        _balanceView.frame = CGRectMake(0, CGRectGetMaxY(_inputView.frame), bgWidth, 185+60);
        _balanceView.backgroundColor = [UIColor whiteColor];

        NSString * moneyStr = [NSString stringWithFormat:@"%@¥%.2f，",Localized(@"JXMoney_blance"),g_App.myMoney];
        
        _balanceLabel = [UIFactory createLabelWith:CGRectZero text:moneyStr font:g_factory.font14 textColor:[UIColor lightGrayColor] backgroundColor:nil];
        CGFloat blanceWidth = [moneyStr sizeWithAttributes:@{NSFontAttributeName:_balanceLabel.font}].width;
        _balanceLabel.frame = CGRectMake(drawMarginX, 0, blanceWidth, drawHei);
        [_balanceView addSubview:_balanceLabel];
        
        _drawAllBtn = [UIFactory createButtonWithRect:CGRectZero title:Localized(@"JXMoney_withDAll") titleFont:_balanceLabel.font titleColor:HEXCOLOR(0x576b95) normal:nil selected:nil selector:@selector(drawAllBtnAction) target:self];
        CGFloat drawWidth = [_drawAllBtn.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:_drawAllBtn.titleLabel.font}].width;
        _drawAllBtn.frame = CGRectMake(CGRectGetMaxX(_balanceLabel.frame)+10, CGRectGetMinY(_balanceLabel.frame), drawWidth, drawHei);
        [_balanceView addSubview:_drawAllBtn];
        
        _withdrawalsBtn = [UIFactory createButtonWithRect:CGRectZero title:Localized(@"JXMoney_wechatWithdrawals") titleFont:g_factory.font17 titleColor:[UIColor whiteColor] normal:nil selected:nil selector:@selector(withdrawalsBtnAction:) target:self];
        _withdrawalsBtn.tag = 1000;
        _withdrawalsBtn.frame = CGRectMake(drawMarginX, CGRectGetMaxY(_balanceLabel.frame)+20, bgWidth-drawMarginX*2, 50);
        [_withdrawalsBtn setBackgroundImage:[UIImage createImageWithColor:HEXCOLOR(0x1aad19)] forState:UIControlStateNormal];
        [_withdrawalsBtn setBackgroundImage:[UIImage createImageWithColor:HEXCOLOR(0xa2dea3)] forState:UIControlStateDisabled];
        _withdrawalsBtn .layer.cornerRadius = 5;
        _withdrawalsBtn.clipsToBounds = YES;
        
        [_balanceView addSubview:_withdrawalsBtn];
        
        
        _aliwithdrawalsBtn = [UIFactory createButtonWithRect:CGRectZero title:Localized(@"JXMoney_Aliwithdrawals") titleFont:g_factory.font17 titleColor:[UIColor whiteColor] normal:nil selected:nil selector:@selector(withdrawalsBtnAction:) target:self];
        _aliwithdrawalsBtn.tag = 1011;
        _aliwithdrawalsBtn.frame = CGRectMake(drawMarginX, CGRectGetMaxY(_balanceLabel.frame)+20+60, bgWidth-drawMarginX*2, 50);
        [_aliwithdrawalsBtn setBackgroundImage:[UIImage createImageWithColor:HEXCOLOR(0x1aad19)] forState:UIControlStateNormal];
        [_aliwithdrawalsBtn setBackgroundImage:[UIImage createImageWithColor:HEXCOLOR(0xa2dea3)] forState:UIControlStateDisabled];
        _aliwithdrawalsBtn .layer.cornerRadius = 5;
        _aliwithdrawalsBtn.clipsToBounds = YES;
        
        [_balanceView addSubview:_aliwithdrawalsBtn];

        
        UILabel *noticeLabel = [UIFactory createLabelWith:CGRectMake(drawMarginX, CGRectGetMaxY(_withdrawalsBtn.frame)+10+60, bgWidth-drawMarginX*2, 30) text:Localized(@"JXMoney_withDNotice") font:g_factory.font14 textColor:[UIColor lightGrayColor] backgroundColor:nil];
        noticeLabel.textAlignment = NSTextAlignmentCenter;
        [_balanceView addSubview:noticeLabel];
    }
    return _balanceView;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark TextField Delegate

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if (textField == _countTextField) {
        NSString *toString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        if (toString.length > 0) {
            NSString *stringRegex = @"(([0]|(0[.]\\d{0,2}))|([1-9]\\d{0,4}(([.]\\d{0,2})?)))?";
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", stringRegex];
            if (![predicate evaluateWithObject:toString]) {
                return NO;
            }
        }
    }
    return YES;
}


#pragma mark Action

-(void)cardButtonAction:(UIButton *)button{
    
}

-(void)drawAllBtnAction{
    NSString * allMoney = [NSString stringWithFormat:@"%.2f",g_App.myMoney];
    _countTextField.text = allMoney;
}

-(void)withdrawalsBtnAction:(UIButton *)button{
    
    if ([_countTextField.text doubleValue] < 0.5) {
        [g_App showAlert:Localized(@"JX_Least0.5")];
        return;
    }
    if ([_countTextField.text doubleValue] > g_App.myMoney) {
        [g_App showAlert:@"余额不足"];
        return;
    }
    if ([g_server.myself.isPayPassword boolValue]) {
        self.isAlipay = button.tag == 1011;
        self.verVC = [JXVerifyPayVC alloc];
        self.verVC.type = JXVerifyTypeWithdrawal;
        self.verVC.RMB = self.countTextField.text;
        self.verVC.delegate = self;
        self.verVC.didDismissVC = @selector(dismissVerifyPayVC);
        self.verVC.didVerifyPay = @selector(didVerifyPay:);
        self.verVC = [self.verVC init];
        
        [self.view addSubview:self.verVC.view];
    } else {
        JXPayPasswordVC *payPswVC = [JXPayPasswordVC alloc];
        payPswVC.type = JXPayTypeSetupPassword;
        payPswVC.enterType = JXEnterTypeWithdrawal;
        payPswVC = [payPswVC init];
        [g_navigation pushViewController:payPswVC animated:YES];
    }
//    // 绑定微信
//    SendAuthReq* req = [[SendAuthReq alloc] init];
//    req.scope = @"snsapi_message,snsapi_userinfo,snsapi_friend,snsapi_contact";
//    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
//    // app名称
//    NSString *titleStr = [infoDictionary objectForKey:@"CFBundleDisplayName"];
//    req.state = titleStr;
//    req.openID = AppleId;
//    
//    [WXApi sendAuthReq:req
//        viewController:self
//              delegate:[WXApiManager sharedManager]];
    
}

- (void)didVerifyPay:(NSString *)sender {
    self.payPassword = [NSString stringWithString:sender];

    if (self.isAlipay) {
        [g_server getAliPayAuthInfoToView:self];
    }else {
        // 绑定微信
        SendAuthReq* req = [[SendAuthReq alloc] init];
        req.scope = @"snsapi_message,snsapi_userinfo,snsapi_friend,snsapi_contact";
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        // app名称
        NSString *titleStr = [infoDictionary objectForKey:@"CFBundleDisplayName"];
        req.state = titleStr;
        req.openID = g_App.config.appleId;

        [WXApi sendAuthReq:req
            viewController:self
                  delegate:[WXApiManager sharedManager]];
    }
}

- (void)dismissVerifyPayVC {
    [self.verVC.view removeFromSuperview];
}

- (void)authRespNotification:(NSNotification *)notif {
    SendAuthResp *resp = notif.object;
    [self getWeChatTokenThenGetUserInfoWithCode:resp.code];
}

// 用户绑定微信，获取openid
- (void)getWeChatTokenThenGetUserInfoWithCode:(NSString *)code {

    [_loading start];
    [g_server userBindWXCodeWithCode:code toView:self];
}

-(void)hideControlAction{
    [_countTextField resignFirstResponder];
}

-(void)actionQuit{
    [_countTextField resignFirstResponder];
    [super actionQuit];
}
-(void)helpButtonAction{
    
}


- (void)alipayGetUserId:(NSNotification *)noti {
    [g_server aliPayUserId:noti.object toView:self];
}


- (void)didServerResultSucces:(JXConnection *)aDownload dict:(NSDictionary *)dict array:(NSArray *)array1{
//    [_wait stop];
    if ([aDownload.action isEqualToString:act_UserBindWXCode]) {
        
        NSString *amount = [NSString stringWithFormat:@"%d",(int)([_countTextField.text doubleValue] * 100)];
        long time = (long)[[NSDate date] timeIntervalSince1970];

        NSString *secret = [self secretEncryption:dict[@"openid"] amount:amount time:time payPassword:self.payPassword];
        [g_server transferWXPayWithAmount:amount secret:secret time:[NSNumber numberWithLong:time] toView:self];

    }else if ([aDownload.action isEqualToString:act_TransferWXPay]) {
        [_loading stop];
        [self dismissVerifyPayVC];  // 销毁支付密码界面
        [g_App showAlert:Localized(@"JX_WithdrawalSuccess")];
        _countTextField.text = nil;
        [g_server getUserMoenyToView:self];
    }
    if ([aDownload.action isEqualToString:act_getUserMoeny]) {
        g_App.myMoney = [dict[@"balance"] doubleValue];
        _balanceLabel.text = [NSString stringWithFormat:@"%@¥%.2f，",Localized(@"JXMoney_blance"),g_App.myMoney];
        [g_notify postNotificationName:kUpdateUserNotifaction object:nil];
    }
    if ([aDownload.action isEqualToString:act_aliPayUserId]) {
        long time = (long)[[NSDate date] timeIntervalSince1970];
        NSString *secret = [self secretEncryption:self.aliUserId amount:_countTextField.text time:time payPassword:self.payPassword];
        [g_server alipayTransfer:self.countTextField.text secret:secret time:@(time) toView:self];
    }
    if ([aDownload.action isEqualToString:act_alipayTransfer]) {
        [g_server showMsg:Localized(@"JX_WithdrawalSuccess")];
        [g_navigation dismissViewController:self animated:YES];
    }

    if ([aDownload.action isEqualToString:act_getAliPayAuthInfo]) {
        NSString *aliId = [dict objectForKey:@"aliUserId"];
        NSString *authInfo = [dict objectForKey:@"authInfo"];
        if (IsStringNull(aliId)) {
            NSString *appScheme = @"shikuimapp";
            [[AlipaySDK defaultService] auth_V2WithInfo:authInfo
                                             fromScheme:appScheme
                                               callback:^(NSDictionary *resultDic) {
                                                   NSLog(@"result = %@",resultDic);
                                                   // 解析 auth code
                                                   NSString *result = resultDic[@"result"];
                                                   if (result.length>0) {
                                                       NSArray *resultArr = [result componentsSeparatedByString:@"&"];
                                                       for (NSString *subResult in resultArr) {
                                                           if (subResult.length > 10 && [subResult hasPrefix:@"user_id="]) {
                                                               self.aliUserId = [subResult substringFromIndex:8];
                                                               [g_server aliPayUserId:self.aliUserId toView:self];
                                                               break;
                                                           }
                                                       }
                                                   }
                                               }];

        }else {
            long time = (long)[[NSDate date] timeIntervalSince1970];
            NSString *secret = [self secretEncryption:aliId amount:_countTextField.text time:time payPassword:self.payPassword];
            [g_server alipayTransfer:self.countTextField.text secret:secret time:@(time) toView:self];
        }
    }

}

- (int)didServerResultFailed:(JXConnection *)aDownload dict:(NSDictionary *)dict{
    [_loading stop];
    if ([aDownload.action isEqualToString:act_alipayTransfer]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.verVC clearUpPassword];
        });
    }
    return show_error;
}

- (int)didServerConnectError:(JXConnection *)aDownload error:(NSError *)error{
    [_loading stop];
    return hide_error;
}

- (NSString *)secretEncryption:(NSString *)openId amount:(NSString *)amount time:(long)time payPassword:(NSString *)payPassword {
    NSString *secret = [NSString string];
    
    NSMutableString *str1 = [NSMutableString string];
    [str1 appendString:APIKEY];
    [str1 appendString:openId];
    [str1 appendString:MY_USER_ID];
    
    NSMutableString *str2 = [NSMutableString string];
    [str2 appendString:g_server.access_token];
    [str2 appendString:amount];
    [str2 appendString:[NSString stringWithFormat:@"%ld",time]];
    str2 = [[g_server getMD5String:str2] mutableCopy];
    
    [str1 appendString:str2];
    NSMutableString *str3 = [NSMutableString string];
    str3 = [[g_server getMD5String:payPassword] mutableCopy];
    [str1 appendString:str3];
    
    secret = [g_server getMD5String:str1];
    
    return secret;
}

-(void) didServerConnectStart:(JXConnection*)aDownload{
//    [_wait start];
}

@end
