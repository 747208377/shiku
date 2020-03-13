//
//  forgetPwdVC.m
//  shiku_im
//
//  Created by flyeagleTang on 14-6-7.
//  Copyright (c) 2014年 Reese. All rights reserved.
//

#import "forgetPwdVC.h"
#import "JXTelAreaListVC.h"
#import "JXUserObject.h"
#import "loginVC.h"

#define HEIGHT 44


@interface forgetPwdVC () <UITextFieldDelegate>
{
   UIButton *_areaCodeBtn;
   NSTimer* timer;
   JXUserObject *_user;
   UIImageView * _imgCodeImg;
   UITextField *_imgCode;   //图片验证码
   UIButton * _graphicButton;
}

@end

@implementation forgetPwdVC

- (id)init
{
   self = [super init];
   if (self) {
      
   }
   return self;
}

- (void)viewDidLoad
{
   [super viewDidLoad];
   if (self.isModify) {
      self.title = Localized(@"JX_UpdatePassWord");
   }else{
      self.title = Localized(@"JX_ForgetPassWord");
   }
   
   
   _user = [JXUserObject sharedInstance];
   _seconds = 0;
   self.isGotoBack   = YES;
   self.heightFooter = 0;
   self.heightHeader = JX_SCREEN_TOP;
   //self.view.frame = CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT);
   [self createHeadAndFoot];
   self.tableBody.backgroundColor = HEXCOLOR(0xf0eff4);
   int n = INSETS;
   
   /*
    JXLabel* lb;
    lb = [[JXLabel alloc]initWithFrame:CGRectMake(10, 50-n, 60, 30)];
    lb.textColor = [UIColor blackColor];
    lb.backgroundColor = [UIColor clearColor];
    lb.text = @"手机号";
    [self.tableBody addSubview:lb];
    [lb release];
    
    lb = [[JXLabel alloc]initWithFrame:CGRectMake(10, 100-n, 60, 30)];
    lb.textColor = [UIColor blackColor];
    lb.backgroundColor = [UIColor clearColor];
    lb.text = @"验证码";
    [self.tableBody addSubview:lb];
    [lb release];
    
    lb = [[JXLabel alloc]initWithFrame:CGRectMake(10, 150-n, 60, 30)];
    lb.textColor = [UIColor blackColor];
    lb.backgroundColor = [UIColor clearColor];
    lb.text = @"新密码";
    [self.tableBody addSubview:lb];
    [lb release];
    
    lb = [[JXLabel alloc]initWithFrame:CGRectMake(10, 200-n, 60, 30)];
    lb.textColor = [UIColor blackColor];
    lb.backgroundColor = [UIColor clearColor];
    lb.text = @"确认";
    [self.tableBody addSubview:lb];
    [lb release];*/
   
   //区号
   if (!_phone) {
      _phone = [UIFactory createTextFieldWith:CGRectMake(INSETS, n, self_width-INSETS-INSETS, HEIGHT) delegate:self returnKeyType:UIReturnKeyNext secureTextEntry:NO placeholder:Localized(@"JX_InputPhone") font:g_factory.font16];
      _phone.clearButtonMode = UITextFieldViewModeWhileEditing;
      
      [self.tableBody addSubview:_phone];
      _phone.layer.masksToBounds = YES;
      _phone.layer.cornerRadius = 4;
      UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 70, HEIGHT)];
      _phone.leftView = leftView;
      _phone.leftViewMode = UITextFieldViewModeAlways;
      NSString *areaStr;
      if (![g_default objectForKey:kMY_USER_AREACODE]) {
         areaStr = @"+86";
      } else {
         areaStr = [NSString stringWithFormat:@"+%@",[g_default objectForKey:kMY_USER_AREACODE]];
      }
      _areaCodeBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 65, HEIGHT)];
      [_areaCodeBtn setTitle:areaStr forState:UIControlStateNormal];
      _areaCodeBtn.titleLabel.font = SYSFONT(15);
      [_areaCodeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
      [_areaCodeBtn setImage:[UIImage imageNamed:@"down_arrow_black"] forState:UIControlStateNormal];
      _areaCodeBtn.custom_acceptEventInterval = 1.0f;
      [_areaCodeBtn addTarget:self action:@selector(areaCodeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
      [self resetBtnEdgeInsets:_areaCodeBtn];
      [leftView addSubview:_areaCodeBtn];
      UIView *verticalLine = [[UIView alloc] initWithFrame:CGRectMake(_areaCodeBtn.frame.size.width-0.5, 13, 0.5, 16)];
      verticalLine.backgroundColor = [UIColor lightGrayColor];
      [_areaCodeBtn addSubview:verticalLine];
      
   }
   n = n+HEIGHT+INSETS;
   
   //        _code = [[UITextField alloc] initWithFrame:CGRectMake(INSETS,n,188,HEIGHT)];
   //        _code.delegate = self;
   //        _code.autocorrectionType = UITextAutocorrectionTypeNo;
   //        _code.autocapitalizationType = UITextAutocapitalizationTypeNone;
   //        _code.enablesReturnKeyAutomatically = YES;
   //        _code.borderStyle = UITextBorderStyleRoundedRect;
   //        _code.returnKeyType = UIReturnKeyDone;
   //        _code.clearButtonMode = UITextFieldViewModeWhileEditing;
   //        _code.placeholder = Localized(@"JX_InputMessageCode");
   //        [self.tableBody addSubview:_code];
   ////        [_code release];
   //
   //        _send = [UIFactory createButtonWithTitle:Localized(@"JX_Send")
   //                                       titleFont:g_factory.font14
   //                                      titleColor:[UIColor whiteColor]
   //                                          normal:@"feaBtn_backImg_sel"
   //                                       highlight:@"feaBtn_backImg_sel" ];
   //        [_send addTarget:self action:@selector(onSend) forControlEvents:UIControlEventTouchUpInside];
   //        _send.frame = CGRectMake(JX_SCREEN_WIDTH-27-105+INSETS*2, n, 105, HEIGHT);
   //        [self.tableBody addSubview:_send];
   
   if (!self.isModify) {

      //图片验证码
      //        self.imgCodeView = [self customItemWith:Localized(@"JX_imageCode") currentY:currentY allLengthTop:YES bottomLine:YES labelWidth:_labelWidth];
      _imgCode = [UIFactory createTextFieldWith:CGRectMake(INSETS, n, self_width-INSETS-INSETS-70-INSETS-35-4, HEIGHT) delegate:self returnKeyType:UIReturnKeyNext secureTextEntry:NO placeholder:Localized(@"JX_inputImgCode") font:g_factory.font16];
      _imgCode.clearButtonMode = UITextFieldViewModeWhileEditing;
      [self.tableBody addSubview:_imgCode];
      _imgCode.layer.masksToBounds = YES;
      _imgCode.layer.cornerRadius = 4;
      //        _imgCode = [[UITextField alloc] initWithFrame:CGRectMake(_labelWidth+20+5, 15, self.tableBody.frame.size.width-_labelWidth-20-5, 20)];
      //        _imgCode.font = SYSFONT(15);
      //        _imgCode.placeholder = Localized(@"JX_inputImgCode");
      //        _imgCode.delegate = self;
      //        [self.imgCodeView addSubview:_imgCode];
      [self createLeftViewWithImage:[UIImage imageNamed:@"verify"] superView:_imgCode];

      _imgCodeImg = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_imgCode.frame)+INSETS, 0, 70, 35)];
      _imgCodeImg.center = CGPointMake(_imgCodeImg.center.x, _imgCode.center.y);
      _imgCodeImg.userInteractionEnabled = YES;
      [self.tableBody addSubview:_imgCodeImg];
      //   _imgCodeImg.image = [UIImage imageNamed:@"refreshImgCode"];
      //   UITapGestureRecognizer * tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(getImgCodeImgGes:)];
      //   [_imgCodeImg addGestureRecognizer:tapGes];
      
      _graphicButton = [UIButton buttonWithType:UIButtonTypeCustom];
      _graphicButton.frame = CGRectMake(CGRectGetMaxX(_imgCodeImg.frame)+4, 7, 35, 35);
      _graphicButton.center = CGPointMake(_graphicButton.center.x,_imgCode.center.y);
      [_graphicButton setBackgroundImage:[UIImage imageNamed:@"refreshGraphic"] forState:UIControlStateNormal];
      [_graphicButton setBackgroundImage:[UIImage imageNamed:@"refreshGraphic"] forState:UIControlStateHighlighted];
      [_graphicButton addTarget:self action:@selector(refreshGraphicAction:) forControlEvents:UIControlEventTouchUpInside];
      [self.tableBody addSubview:_graphicButton];
      
      n = n+HEIGHT+INSETS;
      
      
      _code = [[UITextField alloc] initWithFrame:CGRectMake(INSETS, n, JX_SCREEN_WIDTH-110-INSETS-INSETS, HEIGHT)];
      _code.delegate = self;
      _code.autocorrectionType = UITextAutocorrectionTypeNo;
      _code.autocapitalizationType = UITextAutocapitalizationTypeNone;
      _code.enablesReturnKeyAutomatically = YES;
      _code.font = g_factory.font16;
      _code.borderStyle = UITextBorderStyleRoundedRect;
      _code.returnKeyType = UIReturnKeyDone;
      _code.clearButtonMode = UITextFieldViewModeWhileEditing;
      _code.placeholder = Localized(@"JX_InputMessageCode");
      
      [self.tableBody addSubview:_code];
      [self createLeftViewWithImage:[UIImage imageNamed:@"code"] superView:_code];

      _send = [UIFactory createButtonWithTitle:Localized(@"JX_Send")
                                     titleFont:g_factory.font16
                                    titleColor:[UIColor whiteColor]
                                        normal:nil
                                     highlight:nil ];
      [_send addTarget:self action:@selector(sendSMS) forControlEvents:UIControlEventTouchUpInside];
      _send.backgroundColor = g_theme.themeColor;
      _send.frame = CGRectMake(JX_SCREEN_WIDTH-105-INSETS, n, 105, HEIGHT);
      [self.tableBody addSubview:_send];
      n = n+HEIGHT+INSETS;

   }

   
   if (self.isModify) {
      _oldPwd = [[UITextField alloc] initWithFrame:CGRectMake(INSETS,n,WIDTH,HEIGHT)];
      _oldPwd.delegate = self;
      _oldPwd.autocorrectionType = UITextAutocorrectionTypeNo;
      _oldPwd.autocapitalizationType = UITextAutocapitalizationTypeNone;
      _oldPwd.enablesReturnKeyAutomatically = YES;
      _oldPwd.borderStyle = UITextBorderStyleRoundedRect;
      _oldPwd.returnKeyType = UIReturnKeyDone;
      _oldPwd.clearButtonMode = UITextFieldViewModeWhileEditing;
      _oldPwd.placeholder = Localized(@"JX_InputOldPassWord");
      _oldPwd.secureTextEntry = YES;
      _oldPwd.font = g_factory.font16;
      [self.tableBody addSubview:_oldPwd];
      [self createLeftViewWithImage:[UIImage imageNamed:@"password"] superView:_oldPwd];
      n = n+HEIGHT+INSETS;
      
   }
   
   
   _pwd = [[UITextField alloc] initWithFrame:CGRectMake(INSETS,n,WIDTH,HEIGHT)];
   _pwd.delegate = self;
   _pwd.autocorrectionType = UITextAutocorrectionTypeNo;
   _pwd.autocapitalizationType = UITextAutocapitalizationTypeNone;
   _pwd.enablesReturnKeyAutomatically = YES;
   _pwd.borderStyle = UITextBorderStyleRoundedRect;
   _pwd.returnKeyType = UIReturnKeyDone;
   _pwd.clearButtonMode = UITextFieldViewModeWhileEditing;
   _pwd.placeholder = Localized(@"JX_InputNewPassWord");
   _pwd.secureTextEntry = YES;
   _pwd.font = g_factory.font16;
   [self.tableBody addSubview:_pwd];
   [self createLeftViewWithImage:[UIImage imageNamed:@"password"] superView:_pwd];
   n = n+HEIGHT+INSETS;
   
   _repeat = [[UITextField alloc] initWithFrame:CGRectMake(INSETS,n,WIDTH,HEIGHT)];
   _repeat.delegate = self;
   _repeat.autocorrectionType = UITextAutocorrectionTypeNo;
   _repeat.autocapitalizationType = UITextAutocapitalizationTypeNone;
   _repeat.enablesReturnKeyAutomatically = YES;
   _repeat.borderStyle = UITextBorderStyleRoundedRect;
   _repeat.returnKeyType = UIReturnKeyDone;
   _repeat.clearButtonMode = UITextFieldViewModeWhileEditing;
   _repeat.placeholder = Localized(@"JX_ConfirmNewPassWord");
   _repeat.secureTextEntry = YES;
   _repeat.font = g_factory.font16;
   [self createLeftViewWithImage:[UIImage imageNamed:@"password"] superView:_repeat];
   [self.tableBody addSubview:_repeat];
   n = n+HEIGHT+INSETS;
   
   UIButton* _btn = [UIFactory createCommonButton:Localized(@"JX_UpdatePassWord") target:self action:@selector(onClick:)];
   [_btn.titleLabel setFont:g_factory.font17];
   _btn.frame = CGRectMake(INSETS, n, WIDTH, HEIGHT);
   [self.tableBody addSubview:_btn];
   
   
   _phone.text = g_myself.telephone;
   if (self.isModify) {
      _phone.enabled = NO;

   }else{
      if (_phone.text.length > 0) {
         [self getImgCodeImg];
      }

   }
   
}

- (void)didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
   // Dispose of any resources that can be recreated.
}

-(void)refreshGraphicAction:(UIButton *)button{
   [self getImgCodeImg];
}

-(void)getImgCodeImg{
   if(_phone.text.length > 0){
      //    if ([self checkPhoneNum]) {
      //请求图片验证码
      NSString *areaCode = [_areaCodeBtn.titleLabel.text stringByReplacingOccurrencesOfString:@"+" withString:@""];
      NSString * codeUrl = [g_server getImgCode:_phone.text areaCode:areaCode];
      NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:codeUrl] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10.0];
      
      [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
         if (!connectionError) {
            UIImage * codeImage = [UIImage imageWithData:data];
            if (codeImage != nil) {
               _imgCodeImg.image = codeImage;
            }else{
               [g_App showAlert:Localized(@"JX_ImageCodeFailed")];
            }
            
         }else{
            NSLog(@"%@",connectionError);
            [g_App showAlert:connectionError.localizedDescription];
         }
      }];
//      [_imgCodeImg sd_setImageWithURL:[NSURL URLWithString:codeUrl] placeholderImage:[UIImage imageNamed:@"refreshImgCode"] options:SDWebImageRefreshCached completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
//         if (!error) {
//            _imgCodeImg.image = image;
//         }else{
//            NSLog(@"%@",error);
//         }
//      }];
   }else{
      
   }
   
}


#pragma mark------验证
-(void)onClick:(UIButton *)btn{
   btn.enabled = NO;
   dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      btn.enabled = YES;
   });
   if([_phone.text length]<= 0){
      [g_App showAlert:Localized(@"JX_InputPhone")];
      return;
   }

   if (!self.isModify) {

      if([_code.text length]<4){
         //_code.text = @"1315";
         [g_App showAlert:Localized(@"JX_InputMessageCode")];
         return;
      }

   }
   if (self.isModify && [_oldPwd.text length] <= 0){
      [g_App showAlert:Localized(@"JX_InputPassWord")];
      return;
   }
   
   if([_pwd.text length]<=0){
      [g_App showAlert:Localized(@"JX_InputPassWord")];
      return;
   }
   if([_repeat.text length]<=0){
      [g_App showAlert:Localized(@"JX_ConfirmPassWord")];
      return;
   }
   if(![_pwd.text isEqualToString:_repeat.text]){
      [g_App showAlert:Localized(@"JX_PasswordFiled")];
      return;
   }
   
   if ([_pwd.text isEqualToString:_oldPwd.text]) {
      [g_App showAlert:Localized(@"JX_PasswordOriginal")];
      return;
   }
   
   //   if([_smsCode length]<=0){
   //      //忽略短信验证
   //      //_smsCode = _code.text;
   //      [g_App showAlert:@"请输入验证码"];
   //      return;
   //   }
   [self.view endEditing:YES];
   NSString *areaCode = [_areaCodeBtn.titleLabel.text stringByReplacingOccurrencesOfString:@"+" withString:@""];
   if (self.isModify){
      [_wait start];
      [g_server updatePwd:_phone.text areaCode:areaCode oldPwd:_oldPwd.text newPwd:_pwd.text toView:self];
   }else{
      BOOL b = YES;

      b = [_code.text isEqualToString:_smsCode];

      if(b){
         [_wait start];
         [g_server resetPwd:_phone.text areaCode:areaCode randcode:_smsCode newPwd:_pwd.text toView:self];
         
      }
      else
         [g_App showAlert:Localized(@"inputPhoneVC_MsgCodeNotOK")];
       //        [g_App showAlert:@"短信验证码不对"];
   }
  
}
//验证手机号格式
- (void)sendSMS{
   [_phone resignFirstResponder];
   [_imgCode resignFirstResponder];
   [_code resignFirstResponder];
   
   _send.enabled = NO;
   if (_imgCode.text.length < 3) {
      [g_App showAlert:Localized(@"JX_inputImgCode")];
      _send.enabled = YES;
      return;
   }
   
   [self onSend];
   
//   if([self isMobileNumber:_phone.text]){
//      //验证手机号码是否已注册
//      //        [g_server verifyPhone:[NSString stringWithFormat:@"%@%@",[_areaCodeBtn.titleLabel.text stringByReplacingOccurrencesOfString:@"+" withString:@""],_phoneNumTextField.text] toView:self];
//
//      //请求验证码
//
//
//   }else {
//      _send.enabled = YES;
//   }
}
//验证手机号码格式
- (BOOL)isMobileNumber:(NSString *)number{
   if ([_phone.text length] == 0) {
      UIAlertView* alert = [[UIAlertView alloc] initWithTitle:Localized(@"JX_Tip") message:Localized(@"JX_InputPhone") delegate:nil cancelButtonTitle:Localized(@"JX_Confirm") otherButtonTitles:nil, nil];
      [alert show];
      //        [alert release];
      return NO;
   }
   
   if ([_areaCodeBtn.titleLabel.text isEqualToString:@"+86"]) {
      NSString *regex = @"^(0|86|17951)?(13[0-9]|15[012356789]|17[678]|18[0-9]|14[57])[0-9]{8}$";
      NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
      BOOL isMatch = [pred evaluateWithObject:number];
      
      if (!isMatch) {
         [g_App showAlert:Localized(@"inputPhoneVC_InputTurePhone")];
//         UIAlertView* alert = [[UIAlertView alloc] initWithTitle:Localized(@"JXVerifyAccountVC_Prompt") message:Localized(@"JXVerifyAccountVC_PhoneNumberError") delegate:nil cancelButtonTitle:Localized(@"JXVerifyAccountVC_OK") otherButtonTitles:nil, nil];
//         [alert show];
         //            [alert release];
         return NO;
      }
   }
   return YES;
}

-(void)onSend{
   
   if (!_send.selected) {
      [_wait start];
      NSString *areaCode = [_areaCodeBtn.titleLabel.text stringByReplacingOccurrencesOfString:@"+" withString:@""];
      //      _user = [JXUserObject sharedInstance];
      _user.areaCode = areaCode;
      [g_server sendSMS:[NSString stringWithFormat:@"%@",_phone.text] areaCode:areaCode isRegister:NO imgCode:_imgCode.text toView:self];
   }
   
}

-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
   [_wait stop];
   if([aDownload.action isEqualToString:act_SendSMS]){
      _send.enabled = YES;
      _send.selected = YES;
      _send.userInteractionEnabled = NO;
      _send.backgroundColor = [UIColor grayColor];
      _smsCode = [[dict objectForKey:@"code"] copy];
      [_send setTitle:@"60s" forState:UIControlStateSelected];
      _seconds = 60;
      timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(showTime:) userInfo:_send repeats:YES];
   }
   if([aDownload.action isEqualToString:act_PwdUpdate]){
      [g_App showAlert:Localized(@"JX_UpdatePassWordOK")];
      g_myself.password = [g_server getMD5String:_pwd.text];
      [g_default setObject:[g_server getMD5String:_pwd.text] forKey:kMY_USER_PASSWORD];
      [g_default synchronize];
      [self actionQuit];
      [self relogin];
   }
   if([aDownload.action isEqualToString:act_PwdReset]){
      [g_App showAlert:Localized(@"JX_UpdatePassWordOK")];
      g_myself.password = [g_server getMD5String:_pwd.text];
      [g_default setObject:[g_server getMD5String:_pwd.text] forKey:kMY_USER_PASSWORD];
      [g_default synchronize];
      [self actionQuit];
   }
}

-(int) didServerResultFailed:(JXConnection*)aDownload dict:(NSDictionary*)dict{
   if([aDownload.action isEqualToString:act_SendSMS]){
      [_send setTitle:Localized(@"JX_SendAngin") forState:UIControlStateNormal];
      _send.enabled = YES;
   }else if ([aDownload.action isEqualToString:act_PwdUpdate]) {
      NSString *error = [[dict objectForKey:@"data"] objectForKey:@"resultMsg"];
      
      [g_App showAlert:[NSString stringWithFormat:@"%@",error]];
      
      return hide_error;
   }
   
   [_wait stop];
   return show_error;
}

-(int) didServerConnectError:(JXConnection*)aDownload error:(NSError *)error{//error为空时，代表超时
   [_wait stop];
   _send.enabled = YES;
   return show_error;
}

-(void) didServerConnectStart:(JXConnection*)aDownload{
   [_wait stop];
}

-(void)showTime:(NSTimer*)sender{
   UIButton *but = (UIButton*)[timer userInfo];
   _seconds--;
   [but setTitle:[NSString stringWithFormat:@"%ds",_seconds] forState:UIControlStateSelected];
   if(_seconds<=0){
      but.selected = NO;
      but.userInteractionEnabled = YES;
      but.backgroundColor = g_theme.themeColor;
      [_send setTitle:Localized(@"JX_SendAngin") forState:UIControlStateNormal];
      if (timer) {
         timer = nil;
         [sender invalidate];
      }
      _seconds = 60;
      
   }
}

-(void)textFieldDidEndEditing:(UITextField *)textField{

   if (textField == _phone) {
      [self getImgCodeImg];
   }


}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
   [self.view endEditing:YES];
   return YES;
}
- (void)areaCodeBtnClick:(UIButton *)but{
   [self.view endEditing:YES];
   JXTelAreaListVC *telAreaListVC = [[JXTelAreaListVC alloc] init];
   telAreaListVC.telAreaDelegate = self;
   telAreaListVC.didSelect = @selector(didSelectTelArea:);
//   [g_window addSubview:telAreaListVC.view];
   [g_navigation pushViewController:telAreaListVC animated:YES];
}

- (void)didSelectTelArea:(NSString *)areaCode{
   [_areaCodeBtn setTitle:[NSString stringWithFormat:@"+%@",areaCode] forState:UIControlStateNormal];
   [self resetBtnEdgeInsets:_areaCodeBtn];
}
- (void)resetBtnEdgeInsets:(UIButton *)btn{
   [btn setTitleEdgeInsets:UIEdgeInsetsMake(0, -btn.imageView.frame.size.width-2, 0, btn.imageView.frame.size.width+2)];
   [btn setImageEdgeInsets:UIEdgeInsetsMake(0, btn.titleLabel.frame.size.width+2, 0, -btn.titleLabel.frame.size.width-2)];
}


-(void)relogin{
   [g_default removeObjectForKey:kMY_USER_PASSWORD];
   [g_default removeObjectForKey:kMY_USER_TOKEN];
   [share_defaults removeObjectForKey:kMY_ShareExtensionToken];
   //    [g_default setObject:nil forKey:kMY_USER_TOKEN];
   g_server.access_token = nil;
   
   [g_notify postNotificationName:kSystemLogoutNotifaction object:nil];
   [[JXXMPP sharedInstance] logout];
   NSLog(@"XMPP ---- forgetPwdVC relogin");
   
   loginVC* vc = [loginVC alloc];
   vc.isAutoLogin = NO;
   vc.isSwitchUser= NO;
   vc = [vc init];
   [g_mainVC.view removeFromSuperview];
   g_mainVC = nil;
   [self.view removeFromSuperview];
   self.view = nil;
   
   g_navigation.rootViewController = vc;
   //    g_navigation.lastVC = nil;
   //    [g_navigation.subViews removeAllObjects];
   //    [g_navigation pushViewController:vc];
   //    g_App.window.rootViewController = vc;
   //    [g_App.window makeKeyAndVisible];
   
   //    loginVC* vc = [loginVC alloc];
   //    vc.isAutoLogin = NO;
   //    vc.isSwitchUser= NO;
   //    vc = [vc init];
   //    [g_window addSubview:vc.view];
   //    [self actionQuit];
   //    [_wait performSelector:@selector(stop) withObject:nil afterDelay:1];
   [_wait stop];
#if TAR_IM
#ifdef Meeting_Version
   [g_meeting stopMeeting];
#endif
#endif
}


- (void)createLeftViewWithImage:(UIImage *)image superView:(UITextField *)textField {
   UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 36, HEIGHT)];
   textField.leftView = leftView;
   textField.leftViewMode = UITextFieldViewModeAlways;
   UIImageView *leIgView = [[UIImageView alloc] initWithFrame:CGRectMake(11, 11, 22, 22)];
   leIgView.image = image;
   leIgView.contentMode = UIViewContentModeScaleAspectFit;
   [leftView addSubview:leIgView];
}


@end
