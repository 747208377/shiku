//
//  JXRechargeViewController.m
//  shiku_im
//
//  Created by 1 on 17/10/30.
//  Copyright © 2017年 Reese. All rights reserved.
//

#import "JXRechargeViewController.h"
#import "JXRechargeCell.h"
#import "UIImage+Color.h"
#import <AlipaySDK/AlipaySDK.h>

@interface JXRechargeViewController ()<UIAlertViewDelegate>
@property (nonatomic, assign) NSInteger checkIndex;
@property (atomic, assign) NSInteger payType;


//@property (nonatomic, strong) NSArray * rechargeArray;
@property (nonatomic, strong) NSArray * rechargeMoneyArray;


@property (nonatomic, strong) UILabel * totalMoney;
@property (nonatomic, strong) UIButton * wxPayBtn;
@property (nonatomic, strong) UIButton * aliPayBtn;

@end

static NSString * JXRechargeCellID = @"JXRechargeCellID";

@implementation JXRechargeViewController

-(instancetype)init{
    if (self = [super init]) {
        self.heightHeader = JX_SCREEN_TOP;
        self.heightFooter = 0;
        self.isGotoBack = YES;
        self.title = Localized(@"JXLiveVC_Recharge");
        [self makeData];
        _checkIndex = -1;
        
        [g_notify addObserver:self selector:@selector(receiveWXPayFinishNotification:) name:kWxPayFinishNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createHeadAndFoot];
    self.isShowHeaderPull = NO;
    self.isShowFooterPull = NO;
    _table.backgroundColor = HEXCOLOR(0xefeff4);
    [_table registerClass:[JXRechargeCell class] forCellReuseIdentifier:JXRechargeCellID];
    _table.showsVerticalScrollIndicator = NO;
    _table.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
}

-(void)dealloc{
    [g_notify removeObserver:self];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _rechargeMoneyArray.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 65;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    JXRechargeCell * cell = [tableView dequeueReusableCellWithIdentifier:JXRechargeCellID forIndexPath:indexPath];
    NSString * money = [NSString stringWithFormat:@"%@%@",_rechargeMoneyArray[indexPath.row],Localized(@"JX_ChinaMoney")];
    cell.textLabel.text = money;
    if(_checkIndex == indexPath.row){
        cell.checkButton.selected = YES;
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    _checkIndex = indexPath.row;
    NSString * money = [NSString stringWithFormat:@"%@",_rechargeMoneyArray[indexPath.row]];
    [self setTotalMoneyText:money];
    NSArray * cellArray = [tableView visibleCells];
    for (JXRechargeCell * cell in cellArray) {
        cell.checkButton.selected = NO;
    }
    
    JXRechargeCell * selCell = [tableView cellForRowAtIndexPath:indexPath];
    selCell.checkButton.selected = YES;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 200;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    UIView * paySelView = [[UIView alloc] init];
    paySelView.backgroundColor = HEXCOLOR(0xefeff4);
    UILabel * payStyleLabel = [UIFactory createLabelWith:CGRectMake(20, 0, JX_SCREEN_WIDTH-20*2, 40) text:Localized(@"JXMoney_choosePayType") font:g_factory.font14 textColor:[UIColor lightGrayColor] backgroundColor:[UIColor clearColor]];
    [paySelView addSubview:payStyleLabel];
    
    UIView * whiteView = [[UIView alloc] init];
    whiteView.backgroundColor = [UIColor whiteColor];
    whiteView.frame = CGRectMake(0, CGRectGetMaxY(payStyleLabel.frame), JX_SCREEN_WIDTH, 200-CGRectGetMaxY(payStyleLabel.frame));
    [paySelView addSubview:whiteView];
    
    UILabel * totalTitle = [UIFactory createLabelWith:CGRectZero text:nil font:g_factory.font14 textColor:[UIColor lightGrayColor] backgroundColor:[UIColor clearColor]];
    NSString * totalStr = Localized(@"JXMoney_total");
    CGFloat totalWidth = [totalStr sizeWithAttributes:@{NSFontAttributeName:totalTitle.font}].width;
    totalTitle.frame = CGRectMake(20, 20, totalWidth+5, 18);
    totalTitle.text = totalStr;
    [whiteView addSubview:totalTitle];
    
    
    _totalMoney = [UIFactory createLabelWith:CGRectZero text:nil font:g_factory.font20 textColor:[UIColor lightGrayColor] backgroundColor:[UIColor clearColor]];
    NSString * totalMoneyStr = @"¥--";
    CGFloat moneyWidth = [totalMoneyStr sizeWithAttributes:@{NSFontAttributeName:_totalMoney.font}].width;
    _totalMoney.frame = CGRectMake(CGRectGetMaxX(totalTitle.frame), 20, moneyWidth+5, 18);
    _totalMoney.text = totalMoneyStr;
    _totalMoney.textColor = [UIColor redColor];
    [whiteView addSubview:_totalMoney];
    
    _wxPayBtn = [UIFactory createButtonWithRect:CGRectZero title:Localized(@"JXMoney_wxPay") titleFont:g_factory.font17 titleColor:[UIColor whiteColor] normal:nil selected:nil selector:@selector(wxPayBtnAction:) target:self];
    _wxPayBtn.frame = CGRectMake(20, CGRectGetMaxY(_totalMoney.frame)+20, JX_SCREEN_WIDTH-20*2, 40);
    [_wxPayBtn setBackgroundImage:[UIImage createImageWithColor:HEXCOLOR(0x1aad19)] forState:UIControlStateNormal];
    [_wxPayBtn setBackgroundImage:[UIImage createImageWithColor:HEXCOLOR(0xa2dea3)] forState:UIControlStateDisabled];
    _wxPayBtn.layer.cornerRadius = 5;
    _wxPayBtn.clipsToBounds = YES;
    [whiteView addSubview:_wxPayBtn];
    

    _aliPayBtn = [UIFactory createButtonWithRect:CGRectZero title:Localized(@"JXMoney_aliPay") titleFont:g_factory.font17 titleColor:[UIColor whiteColor] normal:nil selected:nil selector:@selector(aliPayBtnAction:) target:self];
    _aliPayBtn.frame = CGRectMake(20, CGRectGetMaxY(_wxPayBtn.frame)+15, JX_SCREEN_WIDTH-20*2, 40);
    [_aliPayBtn setBackgroundImage:[UIImage createImageWithColor:HEXCOLOR(0x1aad19)] forState:UIControlStateNormal];
    [_aliPayBtn setBackgroundImage:[UIImage createImageWithColor:HEXCOLOR(0xa2dea3)] forState:UIControlStateDisabled];
    _aliPayBtn.layer.cornerRadius = 5;
    _aliPayBtn.clipsToBounds = YES;
    [whiteView addSubview:_aliPayBtn];
    
    
    return paySelView;
}

-(void)setTotalMoneyText:(NSString *)money{
    NSString * totalMoneyStr = [NSString stringWithFormat:@"¥%@",money];
    CGFloat moneyWidth = [totalMoneyStr sizeWithAttributes:@{NSFontAttributeName:_totalMoney.font}].width;
    CGRect frame = _totalMoney.frame;
    frame.size.width = moneyWidth;
    _totalMoney.frame = frame;
    _totalMoney.text = totalMoneyStr;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)makeData{
//    self.rechargeArray = @[@"10元",
//                           @"50元",
//                           @"100元",
//                           @"500元",
//                           @"1000元",
//                           @"5000元",
//                           @"10000元"];
    
    self.rechargeMoneyArray = @[@0.01,
                                @1,
                                @10,
                                @50,
                                @100,
                                @500,
                                @1000,
                                @5000,
                                @10000];
}


#pragma mark Action

-(void)wxPayBtnAction:(UIButton *)button{
    if (_checkIndex >=0 && _checkIndex <_rechargeMoneyArray.count) {
        NSString * money = [NSString stringWithFormat:@"%@",_rechargeMoneyArray[_checkIndex]];
        _payType = 2;
        [g_server getSign:money payType:2 toView:self];
    }
}

-(void)aliPayBtnAction:(UIButton *)button{
    if (_checkIndex >=0 && _checkIndex <_rechargeMoneyArray.count) {
        NSString * money = [NSString stringWithFormat:@"%@",_rechargeMoneyArray[_checkIndex]];
        _payType = 1;
        [g_server getSign:money payType:1 toView:self];
    }
}

-(void)tuningWxWith:(NSDictionary *)dict{
    PayReq *req = [[PayReq alloc] init];
    req.partnerId = [dict objectForKey:@"partnerId"];
    req.prepayId = [dict objectForKey:@"prepayId"];
    req.nonceStr = [dict objectForKey:@"nonceStr"];
    req.timeStamp = [[dict objectForKey:@"timeStamp"] intValue];
    req.package = @"Sign=WXPay";//[dict objectForKey:@"package"];
    req.sign = [dict objectForKey:@"sign"];
    [WXApi sendReq:req];
}

- (void)tuningAlipayWithOrder:(NSString *)signedString {
    // NOTE: 如果加签成功，则继续执行支付
    if (signedString != nil) {
        //应用注册scheme,在AliSDKDemo-Info.plist定义URL types
        NSString *appScheme = @"shikuimapp";
        // NOTE: 调用支付结果开始支付
        [[AlipaySDK defaultService] payOrder:signedString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
            NSLog(@"reslut = %@",resultDic);
        }];
    }

}

-(void)receiveWXPayFinishNotification:(NSNotification *)notifi{
    PayResp *resp = notifi.object;
    switch (resp.errCode) {
        case WXSuccess:{
            [g_App showAlert:Localized(@"JXMoney_PaySuccess") delegate:self tag:1001 onlyConfirm:YES];
            if (self.rechargeDelegate && [self.rechargeDelegate respondsToSelector:@selector(rechargeSuccessed)]) {
                [self.rechargeDelegate performSelector:@selector(rechargeSuccessed)];
            }
            if (_isQuitAfterSuccess) {
                [self actionQuit];
            }
            break;
        }
        case WXErrCodeUserCancel:{
            //取消了支付
            break;
        }
        default:{
            //支付错误
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"支付失败！retcode = %d, retstr = %@", resp.errCode,resp.errStr] message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            break;
        }
    }
    
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag == 1001) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [g_server getUserMoenyToView:self];
        });
    }
}


- (void)didServerResultSucces:(JXConnection *)aDownload dict:(NSDictionary *)dict array:(NSArray *)array1{
    [_wait stop];
    if ([aDownload.action isEqualToString:act_getSign]) {
        if ([[dict objectForKey:@"package"] isEqualToString:@"Sign=WXPay"]) {
            [self tuningWxWith:dict];
        }else {
            [self tuningAlipayWithOrder:[dict objectForKey:@"orderInfo"]];
        }
    }else if ([aDownload.action isEqualToString:act_getUserMoeny]) {
        g_App.myMoney = [dict[@"balance"] doubleValue];
        [g_notify postNotificationName:kUpdateUserNotifaction object:nil];
        [self actionQuit];
    }
}

- (int)didServerResultFailed:(JXConnection *)aDownload dict:(NSDictionary *)dict{
    [_wait stop];
    //    if ([aDownload.action isEqualToString:]) {
    //        return hide_error
    //    }
    return show_error;
}

- (int)didServerConnectError:(JXConnection *)aDownload error:(NSError *)error{
    [_wait stop];
    //    if ([aDownload.action isEqualToString:]) {
    //        [self refreshAfterConnectError];
    //    }
    return hide_error;
}

-(void) didServerConnectStart:(JXConnection*)aDownload{
    [_wait start];
}

@end
