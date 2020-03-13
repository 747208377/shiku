//
//  JXSendRedPacketViewController.m
//  shiku_im
//
//  Created by 1 on 17/8/14.
//  Copyright © 2017年 Reese. All rights reserved.
//

#import "JXSendRedPacketViewController.h"
#import "JXTopSiftJobView.h"
#import "JXRedInputView.h"
#import "JXRechargeViewController.h"
#import "JXVerifyPayVC.h"
#import "JXPayPasswordVC.h"

#define TopHeight 40

@interface JXSendRedPacketViewController ()<UITextFieldDelegate,UIScrollViewDelegate,RechargeDelegate>
@property (nonatomic, strong) JXTopSiftJobView * topSiftView;

@property (nonatomic, strong) JXRedInputView * luckyView;
@property (nonatomic, strong) JXRedInputView * nomalView;
@property (nonatomic, strong) JXRedInputView * orderView;
@property (nonatomic, strong) JXVerifyPayVC * verVC;


@property (nonatomic, copy) NSString * moneyText;
@property (nonatomic, copy) NSString * countText;
@property (nonatomic, copy) NSString * greetText;

@property (nonatomic, assign) NSInteger indexInt;


@end

@implementation JXSendRedPacketViewController

-(instancetype)init{
    if (self = [super init]) {
        self.isGotoBack = YES;
        self.heightHeader = JX_SCREEN_TOP + TopHeight;
        self.heightFooter = 0;
        
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent]; 
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createHeadAndFoot];
    self.title = Localized(@"JX_SendGift");
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(endEdit:)];
    [self.tableBody addGestureRecognizer:tap];
//
    if (_isRoom) {
        self.tableBody.contentSize = CGSizeMake(JX_SCREEN_WIDTH *3, self.tableBody.frame.size.height);
    }else{
        self.tableBody.contentSize = CGSizeMake(JX_SCREEN_WIDTH *2, self.tableBody.frame.size.height);
    }
    
    self.tableBody.delegate = self;
    self.tableBody.pagingEnabled = YES;
    self.tableBody.showsHorizontalScrollIndicator = NO;
    self.tableBody.backgroundColor = THEMEBACKCOLOR;
    
    [self.view addSubview:self.topSiftView];
    
    if(_isRoom){
        [self.tableBody addSubview:self.luckyView];
        [_luckyView.sendButton addTarget:self action:@selector(sendRedPacket:) forControlEvents:UIControlEventTouchUpInside];
    }
    [self.tableBody addSubview:self.nomalView];
    [self.tableBody addSubview:self.orderView];
    
    [_nomalView.sendButton addTarget:self action:@selector(sendRedPacket:) forControlEvents:UIControlEventTouchUpInside];
    [_orderView.sendButton addTarget:self action:@selector(sendRedPacket:) forControlEvents:UIControlEventTouchUpInside];
}


-(JXRedInputView *)luckyView{
    if (!_luckyView) {
        _luckyView = [[JXRedInputView alloc] initWithFrame:CGRectMake(0, 0, JX_SCREEN_WIDTH, self.tableBody.contentSize.height) type:2 isRoom:_isRoom delegate:self];
    }
    return _luckyView;
}
-(JXRedInputView *)nomalView{
    if (!_nomalView) {
        _nomalView = [[JXRedInputView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_luckyView.frame), 0, JX_SCREEN_WIDTH, self.tableBody.contentSize.height) type:1 isRoom:_isRoom delegate:self];
    }
    return _nomalView;
}
-(JXRedInputView *)orderView{
    if (!_orderView) {
        _orderView = [[JXRedInputView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_nomalView.frame), 0, JX_SCREEN_WIDTH, self.tableBody.contentSize.height) type:3 isRoom:_isRoom delegate:self];
    }
    return _orderView;
}
-(JXTopSiftJobView *)topSiftView{
    if (!_topSiftView) {
        _topSiftView = [[JXTopSiftJobView alloc] initWithFrame:CGRectMake(0, JX_SCREEN_TOP, JX_SCREEN_WIDTH, 40)];
        _topSiftView.delegate = self;
        _topSiftView.isShowMoreParaBtn = NO;
        _topSiftView.preferred = 0;
        NSArray * itemsArray;
        if (_isRoom) {
            itemsArray = [[NSArray alloc] initWithObjects:Localized(@"JX_LuckGift"),Localized(@"JX_UsualGift"),Localized(@"JX_MesGift"), nil];
        }else{
            itemsArray = [[NSArray alloc] initWithObjects:Localized(@"JX_UsualGift"),Localized(@"JX_MesGift"), nil];
        }
        _topSiftView.dataArray = itemsArray;
    }
    return _topSiftView;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)topItemBtnClick:(UIButton *)btn{
    [self checkAfterScroll:(btn.tag-100)];
}

- (void)checkAfterScroll:(CGFloat)offsetX{
    [self.tableBody setContentOffset:CGPointMake(offsetX*JX_SCREEN_WIDTH, 0) animated:YES];
    [self endEdit:nil];
}

-(void)endEdit:(UIGestureRecognizer *)ges{
    [_luckyView stopEdit];
    [_nomalView stopEdit];
    [_orderView stopEdit];
}

#pragma mark -------------ScrollDelegate----------------

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self endEdit:nil];
    int page = (int)(scrollView.contentOffset.x/JX_SCREEN_WIDTH);
    switch (page) {
        case 0:
            [_topSiftView resetItemBtnWith:0];
            [_topSiftView moveBottomSlideLine:0];
            break;
        case 1:
            [_topSiftView resetItemBtnWith:JX_SCREEN_WIDTH];
            [_topSiftView moveBottomSlideLine:JX_SCREEN_WIDTH];
            break;
        case 2:
            [_topSiftView resetItemBtnWith:JX_SCREEN_WIDTH*2];
            [_topSiftView moveBottomSlideLine:JX_SCREEN_WIDTH*2];
            break;
            
        default:
            break;
    }
}

-(void)sendRedPacket:(UIButton *)button{
    //1是普通红包，2是手气红包，3是口令红包
    if (button.tag == 1) {
        _moneyText = _nomalView.moneyTextField.text;
        _countText = _nomalView.countTextField.text;
        _greetText = _nomalView.greetTextField.text;
    }else if(button.tag == 2){
        _moneyText = _luckyView.moneyTextField.text;
        _countText = _luckyView.countTextField.text;
        _greetText = _luckyView.greetTextField.text;
    }else if(button.tag == 3){
        _moneyText = _orderView.moneyTextField.text;
        _countText = _orderView.countTextField.text;
        _greetText = _orderView.greetTextField.text;//口令
    }
    if (_moneyText == nil || [_moneyText isEqualToString:@""]) {
        [g_App showAlert:Localized(@"JX_InputGiftCount")];
        return;
    }
    
    if (!_isRoom) {
        _countText = @"1";
    }
    
    if (_isRoom && (_countText == nil|| [_countText isEqualToString:@""] || [_countText intValue] <= 0)) {
        [g_App showAlert:Localized(@"JXGiftForRoomVC_InputGiftCount")];
        return;
    }
    
    if (([_moneyText doubleValue]/[_countText intValue]) < 0.01) {
        [g_App showAlert:Localized(@"JXRedPaket_001")];
        return;
    }
    if ([_moneyText doubleValue] > g_App.myMoney) {
        [g_App showAlert:Localized(@"JX_NotEnough") delegate:self tag:2000 onlyConfirm:NO];
        return;
    }
    if (500 >= [_moneyText floatValue]&&[_moneyText floatValue] > 0) {
        
        if (button.tag == 3 && [_greetText isEqualToString:@""]) {
            [g_App showAlert:Localized(@"JXGiftForRoomVC_InputGiftWord")];
            return;
        }
        //祝福语
        if ([_greetText isEqualToString:@""]) {
            _greetText = Localized(@"JX_GiftText");
        }
        self.indexInt = button.tag;
        if ([g_server.myself.isPayPassword boolValue]) {
            self.verVC = [JXVerifyPayVC alloc];
            self.verVC.type = JXVerifyTypeSendReadPacket;
            self.verVC.RMB = _moneyText;
            self.verVC.delegate = self;
            self.verVC.didDismissVC = @selector(dismissVerifyPayVC);
            self.verVC.didVerifyPay = @selector(didVerifyPay:);
            self.verVC = [self.verVC init];
            
            [self.view addSubview:self.verVC.view];
        } else {
            JXPayPasswordVC *payPswVC = [JXPayPasswordVC alloc];
            payPswVC.type = JXPayTypeSetupPassword;
            payPswVC.enterType = JXEnterTypeSendRedPacket;
            payPswVC = [payPswVC init];
            [g_navigation pushViewController:payPswVC animated:YES];
        }
    }else{
        [g_App showAlert:Localized(@"JX_InputMoneyCount")];
    }
    
}

- (void)didVerifyPay:(NSString *)sender {
    long time = (long)[[NSDate date] timeIntervalSince1970];
    NSString *secret = [self getSecretWithText:sender time:time];
    [g_server sendRedPacketV1:[_moneyText doubleValue] type:(int)self.indexInt count:[_countText intValue] greetings:_greetText roomJid:self.roomJid toUserId:self.toUserId time:time secret:secret toView:self];

}

- (void)dismissVerifyPayVC {
    [self.verVC.view removeFromSuperview];
}

//服务端返回数据
-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
    [_wait stop];
    if ([aDownload.action isEqualToString:act_getUserMoeny]) {
        g_App.myMoney = [dict[@"balance"] doubleValue];
        if (g_App.myMoney <= 0) {
            [g_App showAlert:Localized(@"JX_NotEnough") delegate:self tag:2000 onlyConfirm:NO];
        }
    }
    if ([aDownload.action isEqualToString:act_sendRedPacket] || [aDownload.action isEqualToString:act_sendRedPacketV1]) {
        NSMutableDictionary * muDict = [NSMutableDictionary dictionaryWithDictionary:dict];
        [muDict setObject:_greetText forKey:@"greet"];
        [self dismissVerifyPayVC];  // 销毁支付密码界面
        //成功创建红包，发送一条含红包Id的消息
        if (_delegate && [_delegate respondsToSelector:@selector(sendRedPacketDelegate:)]) {
            [_delegate performSelector:@selector(sendRedPacketDelegate:) withObject:muDict];
        }
        [self actionQuit];
    }
}
-(int) didServerResultFailed:(JXConnection*)aDownload dict:(NSDictionary*)dict{
    [_wait stop];
    if ([aDownload.action isEqualToString:act_sendRedPacket] || [aDownload.action isEqualToString:act_sendRedPacketV1]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.verVC clearUpPassword];
        });
    }
    return show_error;
}

-(int) didServerConnectError:(JXConnection*)aDownload error:(NSError *)error{//error为空时，代表超时
    [_wait stop];
    return show_error;
}
-(void) didServerConnectStart:(JXConnection*)aDownload{
    [_wait start];
}

#pragma mark - alertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (alertView.tag == 2000){
        if (buttonIndex == 1) {
            [self rechargeButtonAction];
        }
    }
}
-(void)rechargeButtonAction{
    JXRechargeViewController * rechargeVC = [[JXRechargeViewController alloc]init];
    rechargeVC.rechargeDelegate = self;
    rechargeVC.isQuitAfterSuccess = YES;
//    [g_window addSubview:rechargeVC.view];
    [g_navigation pushViewController:rechargeVC animated:YES];
}

#pragma mark - RechargeDelegate
-(void)rechargeSuccessed{
    
}


-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    JXRedInputView * inputView = (JXRedInputView *)textField.superview.superview;
    if (textField.returnKeyType == UIReturnKeyDone) {
        [inputView stopEdit];
    }
    return YES;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if ([string isEqualToString:@""]) {//删除
        return YES;
    }
    JXRedInputView * inputView = (JXRedInputView *)textField.superview.superview;
    if (textField == inputView.countTextField && [textField.text intValue] > 1000) {
        return NO;
    }
//    if (textField == inputView.moneyTextField) {
//        NSString * moneyStr = [textField.text stringByAppendingString:string];
//        if ([moneyStr floatValue] > 500.0f) {
//            return NO;
//        }
//    }
    if (textField == inputView.greetTextField && range.length > 0 && range.location + string.length > 15) {
        NSString *textStr = [textField.text substringToIndex:range.location];
        NSString *str = [textStr stringByAppendingString:string];
        textField.text = [str substringToIndex:15];
        
        return NO;
    }
    return YES;
}

- (NSString *)getSecretWithText:(NSString *)text time:(long)time {
    NSMutableString *str1 = [NSMutableString string];
    [str1 appendString:APIKEY];
    [str1 appendString:[NSString stringWithFormat:@"%ld",time]];
    [str1 appendString:[NSString stringWithFormat:@"%@",[NSNumber numberWithDouble:[_moneyText doubleValue]]]];
    str1 = [[g_server getMD5String:str1] mutableCopy];
    
    [str1 appendString:g_myself.userId];
    [str1 appendString:g_server.access_token];
    NSMutableString *str2 = [NSMutableString string];
    str2 = [[g_server getMD5String:text] mutableCopy];
    [str1 appendString:str2];
    str1 = [[g_server getMD5String:str1] mutableCopy];
    
    return [str1 copy];

}

@end
