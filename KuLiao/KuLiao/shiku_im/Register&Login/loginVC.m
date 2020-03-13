//
//  loginVC.m
//  shiku_im
//
//  Created by flyeagleTang on 14-6-7.
//  Copyright (c) 2014年 Reese. All rights reserved.
//

#import "loginVC.h"
#import "forgetPwdVC.h"
#import "inputPhoneVC.h"
#import "JXMainViewController.h"
#import "JXTelAreaListVC.h"
#import "QCheckBox.h"
#import "webpageVC.h"
#import "JXServerListVC.h"
#import "JXLocation.h"
#import "WXApi.h"

#define HEIGHT 44
#define tyCurrentWindow [[UIApplication sharedApplication].windows firstObject]

@interface loginVC ()<UITextFieldDelegate,QCheckBoxDelegate,JXLocationDelegate,JXLocationDelegate,WXApiDelegate,WXApiManagerDelegate>
{
    UIButton *_areaCodeBtn;
    QCheckBox * _checkProtocolBtn;
    UIButton *_forgetBtn;
    BOOL _isFirstLocation;
    NSString *_myToken;
    
    //短信验证码登录
    UIButton *_switchLogin; //切换登录方式
    UIImageView * _imgCodeImg;
    UITextField *_imgCode;   //图片验证码
    UIButton *_send;   //发送短信
    UIButton * _graphicButton;
    NSString* _smsCode;
    int _seconds;
    NSTimer *_timer;
}

@end

@implementation loginVC

- (id)init
{
    self = [super init];
    if (self) {
//        _pSelf = self;
        _user = [[JXUserObject alloc] init];
        //        self.isGotoBack   = self.isSwitchUser;
        self.title = Localized(@"JX_Login");
        self.heightFooter = 0;
        self.heightHeader = JX_SCREEN_TOP;
        //self.view.frame = CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT);
        if (_isThirdLogin) {
//            self.isGotoBack = YES;
            self.title = Localized(@"JX_BindNo.");
        }
        if (self.isSMSLogin) {
            self.title = Localized(@"JX_SMSLogin");
            self.isGotoBack = YES;
        }
        
        g_server.isManualLogin = NO;

        [self createHeadAndFoot];
        self.tableBody.backgroundColor = [UIColor whiteColor];
        _myToken = [g_default objectForKey:kMY_USER_TOKEN];

        int n = INSETS;
        g_server.isLogin = NO;
        g_navigation.lastVC = nil;
        
        UIButton* btn = [UIFactory createButtonWithTitle:Localized(@"JX_SetupServer") titleFont:[UIFont systemFontOfSize:15] titleColor:[UIColor whiteColor] normal:nil highlight:nil];
        [btn setTitleColor:THESIMPLESTYLE ? [UIColor blackColor] : [UIColor whiteColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(onSetting) forControlEvents:UIControlEventTouchUpInside];
        btn.frame = CGRectMake(JX_SCREEN_WIDTH-88, JX_SCREEN_TOP - 38, 83, 30);
        btn.hidden = _isThirdLogin || self.isSMSLogin;
        [self.tableHeader addSubview:btn];
        
        n += 40;
        //酷聊icon
        UIImageView * kuliaoIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"酷聊120"]];
        kuliaoIconView.frame = CGRectMake((JX_SCREEN_WIDTH-95)/2, n, 95, 95);
        [self.tableBody addSubview:kuliaoIconView];
        
        
        //酷聊title
        NSString * titleStr;
#if TAR_IM
        titleStr = APP_NAME;
//#elif TAR_LIVE
//        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
//        // app名称
//        titleStr = [infoDictionary objectForKey:@"CFBundleDisplayName"];
#endif
//        UILabel * kuliaoTitleLabel = [UIFactory createLabelWith:CGRectMake(0, CGRectGetMaxY(kuliaoIconView.frame), 100, 35) text:titleStr font:g_factory.font20 textColor:[UIColor blackColor] backgroundColor:[UIColor clearColor]];
//        kuliaoTitleLabel.center = CGPointMake(kuliaoIconView.center.x, kuliaoTitleLabel.center.y);
//        kuliaoTitleLabel.textAlignment = NSTextAlignmentCenter;
//        [self.tableBody addSubview:kuliaoTitleLabel];
        
//        UIButton* lb;
        /*
         lb = [[JXLabel alloc]initWithFrame:CGRectMake(10, 100, 60, 30)];
         lb.textColor = [UIColor blackColor];
         lb.backgroundColor = [UIColor clearColor];
         lb.text = @"手机：";
         [self.tableBody addSubview:lb];
         [lb release];
         
         lb = [[JXLabel alloc]initWithFrame:CGRectMake(10, 150, 60, 30)];
         lb.textColor = [UIColor blackColor];
         lb.backgroundColor = [UIColor clearColor];
         lb.text = @"密码：";
         [self.tableBody addSubview:lb];
         [lb release];*/
        //(INSETS, n, self_width-INSETS-INSETS, HEIGHT)
        
        n += 135;
        //区号
        if (!_phone) {
            _phone = [UIFactory createTextFieldWith:CGRectMake(50, n, JX_SCREEN_WIDTH-50*2, HEIGHT) delegate:self returnKeyType:UIReturnKeyNext secureTextEntry:NO placeholder:Localized(@"JX_InputPhone") font:g_factory.font16];
            _phone.attributedPlaceholder = [[NSAttributedString alloc] initWithString:Localized(@"JX_InputPhone") attributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]}];
            _phone.clearButtonMode = UITextFieldViewModeWhileEditing;
            _phone.keyboardType = UIKeyboardTypeNumberPad;
            _phone.borderStyle = UITextBorderStyleNone;
            [self.tableBody addSubview:_phone];
            [_phone addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            
            UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, HEIGHT, HEIGHT)];
            _phone.leftView = leftView;
            _phone.leftViewMode = UITextFieldViewModeAlways;
            UIImageView *phIgView = [[UIImageView alloc] initWithFrame:CGRectMake(2, 11, 22, 22)];
            phIgView.image = [UIImage imageNamed:@"account"];
            phIgView.contentMode = UIViewContentModeScaleAspectFit;
            [leftView addSubview:phIgView];
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(leftView.frame)-4, _phone.frame.size.width, 0.5)];
            line.backgroundColor = HEXCOLOR(0xD6D6D6);
            [leftView addSubview:line];
            
            UIView *riPhView = [[UIView alloc] initWithFrame:CGRectMake(_phone.frame.size.width-44, 0, HEIGHT+10, HEIGHT)];
            _phone.rightView = riPhView;
            _phone.rightViewMode = UITextFieldViewModeAlways;
            [_phone addTarget:self action:@selector(longLimit:) forControlEvents:UIControlEventEditingChanged];
            NSString *areaStr;
            if (![g_default objectForKey:kMY_USER_AREACODE]) {
                areaStr = @"+86";
            } else {
                areaStr = [NSString stringWithFormat:@"+%@",[g_default objectForKey:kMY_USER_AREACODE]];
            }
            _areaCodeBtn = [[UIButton alloc] initWithFrame:CGRectMake(2, 11, 60, 22)];
            [_areaCodeBtn setTitle:areaStr forState:UIControlStateNormal];
            _areaCodeBtn.titleLabel.font = SYSFONT(16);
            [_areaCodeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//            [_areaCodeBtn setImage:[UIImage imageNamed:@"account"] forState:UIControlStateNormal];
            _areaCodeBtn.custom_acceptEventInterval = 1.0f;
            [_areaCodeBtn addTarget:self action:@selector(areaCodeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
            [self resetBtnEdgeInsets:_areaCodeBtn];
            [riPhView addSubview:_areaCodeBtn];
         }
        
        //账号
        //        _phone = [[UITextField alloc] initWithFrame:CGRectMake(50, n+170, JX_SCREEN_WIDTH-50*2, HEIGHT)];
        //        _phone.delegate = self;
        //        _phone.autocorrectionType = UITextAutocorrectionTypeNo;
        //        _phone.autocapitalizationType = UITextAutocapitalizationTypeNone;
        //        _phone.enablesReturnKeyAutomatically = YES;
        //        _phone.borderStyle = UITextBorderStyleRoundedRect;
        //        _phone.returnKeyType = UIReturnKeyDone;
        //        _phone.clearButtonMode = UITextFieldViewModeWhileEditing;
        //        _phone.placeholder = Localized(@"JX_InputPhone");
        //        _phone.userInteractionEnabled = YES;
        //        [_phone addTarget:self action:@selector(longLimit:) forControlEvents:UIControlEventEditingChanged];
        //        [self.tableBody addSubview:_phone];
        //        [_phone release];
        n = n+HEIGHT+INSETS+5;
        //监听账号是否被删除
        //
        //        UIImageView *leftView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 34, 30)];
        //        leftView.image = [UIImage imageNamed:@"userhead"];
        //        leftView.contentMode = UIViewContentModeScaleAspectFit;
        //        _phone.leftView = leftView;
        //        _phone.leftViewMode = UITextFieldViewModeAlways;
        
        if (self.isSMSLogin) {
            //图片验证码
            _imgCode = [UIFactory createTextFieldWith:CGRectMake(50, n, JX_SCREEN_WIDTH-50*2-70-INSETS-35-4, HEIGHT) delegate:self returnKeyType:UIReturnKeyNext secureTextEntry:NO placeholder:Localized(@"JX_inputImgCode") font:g_factory.font16];
            _imgCode.attributedPlaceholder = [[NSAttributedString alloc] initWithString:Localized(@"JX_inputImgCode") attributes:@{NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
            _imgCode.borderStyle = UITextBorderStyleNone;
            _imgCode.clearButtonMode = UITextFieldViewModeWhileEditing;
            [self.tableBody addSubview:_imgCode];
            
            UIView *imCView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, HEIGHT, HEIGHT)];
            _imgCode.leftView = imCView;
            _imgCode.leftViewMode = UITextFieldViewModeAlways;
            UIImageView *imCIView = [[UIImageView alloc] initWithFrame:CGRectMake(2, 11, 22, 22)];
            imCIView.image = [UIImage imageNamed:@"verify"];
            imCIView.contentMode = UIViewContentModeScaleAspectFit;
            [imCView addSubview:imCIView];
            
            UIView *imCLine = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(imCView.frame)-4, _phone.frame.size.width, 0.5)];
            imCLine.backgroundColor = HEXCOLOR(0xD6D6D6);
            [imCView addSubview:imCLine];
            
            _imgCodeImg = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_imgCode.frame)+INSETS, 0, 70, 35)];
            _imgCodeImg.center = CGPointMake(_imgCodeImg.center.x, _imgCode.center.y);
            _imgCodeImg.userInteractionEnabled = YES;
            [self.tableBody addSubview:_imgCodeImg];
            
            UIView *imgCodeLine = [[UIView alloc] initWithFrame:CGRectMake(_imgCodeImg.frame.size.width, 3, 0.5, _imgCodeImg.frame.size.height-6)];
            imgCodeLine.backgroundColor = HEXCOLOR(0xD6D6D6);
            [_imgCodeImg addSubview:imgCodeLine];
            
            _graphicButton = [UIButton buttonWithType:UIButtonTypeCustom];
            _graphicButton.frame = CGRectMake(CGRectGetMaxX(_imgCodeImg.frame)+6, 7, 26, 26);
            _graphicButton.center = CGPointMake(_graphicButton.center.x,_imgCode.center.y);
            [_graphicButton setBackgroundImage:[UIImage imageNamed:@"refreshGraphic"] forState:UIControlStateNormal];
            [_graphicButton setBackgroundImage:[UIImage imageNamed:@"refreshGraphic"] forState:UIControlStateHighlighted];
            [_graphicButton addTarget:self action:@selector(refreshGraphicAction:) forControlEvents:UIControlEventTouchUpInside];
            [self.tableBody addSubview:_graphicButton];
            n = n+HEIGHT+INSETS+5;
        }
        
        //密码
        _pwd = [[UITextField alloc] initWithFrame:CGRectMake(50, n, JX_SCREEN_WIDTH-50*2, HEIGHT)];
        _pwd.delegate = self;
        _pwd.font = g_factory.font16;
        _pwd.autocorrectionType = UITextAutocorrectionTypeNo;
        _pwd.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _pwd.enablesReturnKeyAutomatically = YES;
//        _pwd.borderStyle = UITextBorderStyleRoundedRect;
        _pwd.returnKeyType = UIReturnKeyDone;
        _pwd.clearButtonMode = UITextFieldViewModeWhileEditing;
        _pwd.attributedPlaceholder = [[NSAttributedString alloc] initWithString:Localized(@"JX_InputPassWord") attributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]}];
        _pwd.secureTextEntry = !self.isSMSLogin;
        _pwd.userInteractionEnabled = YES;
        
        [self.tableBody addSubview:_pwd];
        
//        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(_pwd.frame.size.width-.5, 8, .5, (HEIGHT-8)/2)];
//        line.backgroundColor = HEXCOLOR(0xD6D6D6);
//        [_pwd addSubview:line];
        
//        //忘记密码
//        UIButton *lbUser = [[UIButton alloc]initWithFrame:CGRectMake(JX_SCREEN_WIDTH-60-50, n+10, 70, 20)];
//        [lbUser setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//        [lbUser setTitle:Localized(@"JX_ForgetPassWord") forState:UIControlStateNormal];
//        lbUser.titleLabel.font = g_factory.font16;
//        lbUser.custom_acceptEventInterval = 1.0f;
//        [lbUser addTarget:self action:@selector(onForget) forControlEvents:UIControlEventTouchUpInside];
//        lbUser.titleEdgeInsets = UIEdgeInsetsMake(0, -27, 0, 0);
//        [self.tableBody addSubview:lbUser];
//        _forgetBtn = lbUser;

        
        if (self.isSMSLogin) {
            _pwd.attributedPlaceholder = [[NSAttributedString alloc] initWithString:Localized(@"JX_InputMessageCode") attributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]}];
            
            _send = [UIFactory createButtonWithTitle:Localized(@"JX_Send")
                                           titleFont:g_factory.font16
                                          titleColor:[UIColor whiteColor]
                                              normal:nil
                                           highlight:nil ];
            _send.frame = CGRectMake(JX_SCREEN_WIDTH-75-55, n+INSETS-6, 75, 32);
            [_send addTarget:self action:@selector(sendSMS) forControlEvents:UIControlEventTouchUpInside];
            _send.backgroundColor = g_theme.themeColor;
            _send.layer.masksToBounds = YES;
            _send.layer.cornerRadius = _send.frame.size.height/2;
            [self.tableBody addSubview:_send];
            
        }else {
            UIView *eyeView = [[UIView alloc]initWithFrame:CGRectMake(_pwd.frame.size.width-40, 0, 40, 40)];
            _pwd.rightView = eyeView;
            _pwd.rightViewMode = UITextFieldViewModeAlways;
            UIButton *rightBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, 12, 20, 16)];
            [rightBtn setBackgroundImage:[UIImage imageNamed:@"ic_password_hide"] forState:UIControlStateNormal];
            [rightBtn setBackgroundImage:[UIImage imageNamed:@"ic_password_display"] forState:UIControlStateSelected];
            [rightBtn addTarget:self action:@selector(passWordRightViewClicked:) forControlEvents:UIControlEventTouchUpInside];
            [eyeView addSubview:rightBtn];
        }

        
        n = n+HEIGHT+INSETS;
        
        UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, HEIGHT, HEIGHT)];
        _pwd.leftView = rightView;
        _pwd.leftViewMode = UITextFieldViewModeAlways;
        UIImageView *riIgView = [[UIImageView alloc] initWithFrame:CGRectMake(2, 11, 22, 22)];
        riIgView.image = [UIImage imageNamed:@"password"];
        riIgView.contentMode = UIViewContentModeScaleAspectFit;
        [rightView addSubview:riIgView];
        
        UIView *verticalLine = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(rightView.frame)-4, _pwd.frame.size.width, 0.5)];
        verticalLine.backgroundColor = HEXCOLOR(0xD6D6D6);
        [rightView addSubview:verticalLine];
        
        n += 6;
        //忘记密码
        UIButton *lbUser = [[UIButton alloc]initWithFrame:CGRectMake(50, n, 100, 20)];
        [lbUser setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [lbUser setTitle:Localized(@"JX_ForgetPassWord") forState:UIControlStateNormal];
        lbUser.titleLabel.font = g_factory.font16;
        lbUser.custom_acceptEventInterval = 1.0f;
        [lbUser addTarget:self action:@selector(onForget) forControlEvents:UIControlEventTouchUpInside];
        lbUser.titleEdgeInsets = UIEdgeInsetsMake(0, -27, 0, 0);
        [self.tableBody addSubview:lbUser];
        _forgetBtn = lbUser;
        
        //注册用户
        CGSize size =[Localized(@"JX_Register") boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:g_factory.font16} context:nil].size;
        UIButton *lb = [[UIButton alloc]initWithFrame:CGRectMake(JX_SCREEN_WIDTH-50-(140 - (140 - size.width) / 2), n, 140, 20)];
        lb.titleLabel.font = g_factory.font16;
        [lb setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [lb setTitle:Localized(@"JX_Register") forState:UIControlStateNormal];
        lb.custom_acceptEventInterval = 1.0f;
        [lb addTarget:self action:@selector(onRegister) forControlEvents:UIControlEventTouchUpInside];
        lb.hidden = self.isSMSLogin;
        
        [self.tableBody addSubview:lb];
        
        if (!self.isSMSLogin) {
            n = n+36;
        }
        
//        if (![[g_default objectForKey:@"agreement"] boolValue]) {            //用户协议
//            UIView * protocolView = [[UIView alloc] init];
//            [self.tableBody addSubview:protocolView];
////
////            UIButton * catProtocolbtn = [UIButton buttonWithType:UIButtonTypeSystem];
////            catProtocolbtn.frame = CGRectMake(0, 0, protocolView.frame.size.width, 25);
//            NSString * agreeStr = Localized(@"JX_IAgree");
//            NSString * protocolStr = Localized(@"JX_ShikuProtocolTitle");
//
////            NSString * agreeProtocolStr = [NSString stringWithFormat:@"%@%@",agreeStr,protocolStr];
////            NSMutableAttributedString* tncString = [[NSMutableAttributedString alloc] initWithString:agreeProtocolStr];
////
////            [tncString addAttribute:NSUnderlineStyleAttributeName
////                              value:@(NSUnderlineStyleSingle)
////                              range:(NSRange){agreeStr.length,[protocolStr length]}];
////            [tncString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor]  range:NSMakeRange(agreeStr.length,[protocolStr length])];
////            [tncString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor]  range:NSMakeRange(0,agreeStr.length)];
////            [tncString addAttribute:NSUnderlineColorAttributeName value:[UIColor blueColor] range:(NSRange){agreeStr.length,[protocolStr length]}];
////            [catProtocolbtn setAttributedTitle:tncString forState:UIControlStateNormal];
////            [catProtocolbtn addTarget:self action:@selector(catUserProtocol) forControlEvents:UIControlEventTouchUpInside];
////            [protocolView addSubview:catProtocolbtn];
//
//            UIButton *agrBtn = [[UIButton alloc] init];
//            CGSize agreSize = [agreeStr boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:agrBtn.titleLabel.font} context:nil].size;
//            agrBtn.frame = CGRectMake(0, 0, agreSize.width, agreSize.height);
//            [agrBtn setTitle:agreeStr forState:UIControlStateNormal];
//            [agrBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
//            agrBtn.titleLabel.font = SYSFONT(15);
//            [agrBtn addTarget:self
//                       action:@selector(agrBtnAction:)
//             forControlEvents:UIControlEventTouchUpInside];
//            [protocolView addSubview:agrBtn];
//
//            UILabel *protocolLab = [[UILabel alloc] init];
//            CGSize proSize = [protocolStr boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:protocolLab.font} context:nil].size;
//            protocolLab.frame = CGRectMake(CGRectGetMaxX(agrBtn.frame), 0, proSize.width, proSize.height);
//            protocolLab.textColor = [UIColor blueColor];
//            protocolLab.font = SYSFONT(16);
//            NSDictionary *attribtDic = @{NSUnderlineStyleAttributeName: [NSNumber numberWithInteger:NSUnderlineStyleSingle]};
//            NSMutableAttributedString *attribtStr = [[NSMutableAttributedString alloc]initWithString:protocolStr attributes:attribtDic];
//            protocolLab.attributedText = attribtStr;
//            [protocolView addSubview:protocolLab];
//            protocolLab.userInteractionEnabled = YES;
//            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(catUserProtocol)];
//            [protocolLab addGestureRecognizer:tap];
//
//            CGFloat w = agreSize.width+proSize.width;
//            protocolView.frame = CGRectMake((JX_SCREEN_WIDTH -w)/2, n, w, 25);
//            _checkProtocolBtn = [[QCheckBox alloc] initWithDelegate:self];
//            [self.tableBody addSubview:_checkProtocolBtn];
//            _checkProtocolBtn.frame = CGRectMake((JX_SCREEN_WIDTH -w)/2-20, n, 20, 20);
//
////            CGSize size = [agreeProtocolStr boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:catProtocolbtn.titleLabel.font} context:nil].size;
////            _checkProtocolBtn.frame = CGRectMake((catProtocolbtn.frame.size.width - size.width) / 2 - 28, 3, 20, 20);
//
//
//            n+=25;
//        }
        
        n+=20;
        
        //登陆按钮
        _btn = [UIFactory createCommonButton:Localized(@"JX_LoginNow") target:self action:@selector(onClick)];
        _btn.custom_acceptEventInterval = 1.0f;
        [_btn.titleLabel setFont:g_factory.font17];
        _btn.layer.cornerRadius = 20;
        _btn.clipsToBounds = YES;
        _btn.frame = CGRectMake(100, n, JX_SCREEN_WIDTH-100*2, 40);
        
        _btn.userInteractionEnabled = NO;
        [self.tableBody addSubview:_btn];
        n = n+HEIGHT+INSETS;
        
        // 屏幕太小，第三方登录超过登录界面，就另外计算y
        CGFloat wxWidth = 48;
        BOOL isSmall = JX_SCREEN_HEIGHT-JX_SCREEN_TOP - wxWidth - 30 <= CGRectGetMaxY(_btn.frame)+30;
        CGFloat loginY = isSmall ? CGRectGetMaxY(_btn.frame)+30 : JX_SCREEN_HEIGHT-JX_SCREEN_TOP - wxWidth - 41;
        UIImageView *wxLogin = [[UIImageView alloc] initWithFrame:CGRectMake((JX_SCREEN_WIDTH-wxWidth-wxWidth-5)/3, loginY, wxWidth, wxWidth)];
        wxLogin.image = [UIImage imageNamed:@"wechat_icon"];
        wxLogin.userInteractionEnabled = YES;
        [self.tableBody addSubview:wxLogin];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didWechatToLogin:)];
        [wxLogin addGestureRecognizer:tap];
        wxLogin.hidden = (_isThirdLogin || self.isSMSLogin);
        if (isSmall) {
            self.tableBody.contentSize = CGSizeMake(0, CGRectGetMaxY(wxLogin.frame)+20);
        }
        
        //短信登录
        UIImageView *smsLogin = [[UIImageView alloc] initWithFrame:CGRectMake((JX_SCREEN_WIDTH-wxWidth-wxWidth)/3*2+wxWidth, loginY, wxWidth, wxWidth)];
        smsLogin.image = [UIImage imageNamed:@"sms_login"];
        smsLogin.userInteractionEnabled = YES;
        [self.tableBody addSubview:smsLogin];
        smsLogin.hidden = (_isThirdLogin || self.isSMSLogin);
        
        UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchLoginWay)];
        [smsLogin addGestureRecognizer:tap1];

        
        // 微信登录回调
        [WXApiManager sharedManager].delegate = self;

        if ([g_default objectForKey:kMY_USER_NICKNAME])
            _user.userNickname = MY_USER_NAME;
        
        if ([g_default objectForKey:kMY_USER_ID])
            _user.userId = [g_default objectForKey:kMY_USER_ID];
        
        if ([g_default objectForKey:kMY_USER_COMPANY_ID])
            _user.companyId = [g_default objectForKey:kMY_USER_COMPANY_ID];
        
        if ([g_default objectForKey:kMY_USER_LoginName]) {
            [_phone setText:[g_default objectForKey:kMY_USER_LoginName]];
            
            _user.telephone = _phone.text;
        }
        if ([g_default objectForKey:kMY_USER_PASSWORD]) {
//            [_pwd setText:[g_default objectForKey:kMY_USER_PASSWORD]];
            
            _user.password = _pwd.text;
            
        }
        if ([g_default objectForKey:kLocationLogin]) {
            NSDictionary *dict = [g_default objectForKey:kLocationLogin];
            g_server.longitude = [[dict objectForKey:@"longitude"] doubleValue];
            g_server.latitude = [[dict objectForKey:@"latitude"] doubleValue];
        }
        

        
        [g_notify addObserver:self selector:@selector(onRegistered:) name:kRegisterNotifaction object:nil];
        [g_notify addObserver:self selector:@selector(authRespNotification:) name:kWxSendAuthRespNotification object:nil];

        if(!self.isAutoLogin || IsStringNull(_myToken)) {
            _btn.userInteractionEnabled = YES;
        }else {
            _launchImageView = [[UIImageView alloc] init];
            _launchImageView.frame = self.view.bounds;
            _launchImageView.image = [UIImage imageNamed:[self getLaunchImageName]];
            [self.view addSubview:_launchImageView];
        }
//        NSString *area = [g_default objectForKey:kLocationArea];
//        if (area.length > 0) {
        
        if(self.isAutoLogin && !IsStringNull(_myToken))
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [_wait start:Localized(@"JX_Logining")];
                [_wait startWithClearColor];
            });
        if (!_isThirdLogin) {
            [g_server getSetting:self];
        }
        
//        }else {
//            _isFirstLocation = NO;
//            JXLocation *location = [[JXLocation alloc] init];
//            location.delegate = self;
//            [location getLocationWithIp];
//        }
    }
    return self;
}

//验证手机号格式
- (void)sendSMS{
    if (!_send.selected) {
        NSString *areaCode = [_areaCodeBtn.titleLabel.text stringByReplacingOccurrencesOfString:@"+" withString:@""];
        _user = [JXUserObject sharedInstance];
        _user.areaCode = areaCode;
        
        [g_server sendSMS:[NSString stringWithFormat:@"%@",_phone.text] areaCode:areaCode isRegister:NO imgCode:_imgCode.text toView:self];
        [_send setTitle:Localized(@"JX_Sending") forState:UIControlStateNormal];
    }
}


-(void)textFieldDidBeginEditing:(UITextField *)textField{
    if (textField == _imgCode) {
    }
}


- (void)switchLoginWay {
    if (self.isSMSLogin) {
        [self actionQuit];
    }else {
        loginVC *vc = [loginVC alloc];
        vc.isSMSLogin = YES;
        vc = [vc init];
        [g_navigation pushViewController:vc animated:YES];
    }
}


-(void)refreshGraphicAction:(UIButton *)button{
    NSString *areaCode = [_areaCodeBtn.titleLabel.text stringByReplacingOccurrencesOfString:@"+" withString:@""];
    [g_server checkPhone:_phone.text areaCode:areaCode verifyType:1 toView:self];
}

-(void)getImgCodeImg{
    if([self isMobileNumber:_phone.text]){
        //    if ([self checkPhoneNum]) {
        //请求图片验证码
        NSString *areaCode = [_areaCodeBtn.titleLabel.text stringByReplacingOccurrencesOfString:@"+" withString:@""];
        NSString * codeUrl = [g_server getImgCode:_phone.text areaCode:areaCode];
        
        NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:codeUrl] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10.0];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
            if (!connectionError) {
                UIImage * codeImage = [UIImage imageWithData:data];
                _imgCodeImg.image = codeImage;
            }else{
                NSLog(@"%@",connectionError);
                [g_App showAlert:connectionError.localizedDescription];
            }
        }];
    }
    
}

//验证手机号码格式
- (BOOL)isMobileNumber:(NSString *)number{
    if ([g_config.isOpenSMSCode boolValue] && [g_config.regeditPhoneOrName intValue] != 1) {
        if ([_phone.text length] == 0) {
            [g_App showAlert:Localized(@"JX_InputPhone")];
            return NO;
        }
    }
    return YES;
}



#pragma mark - 微信登录
- (void)didWechatToLogin:(UITapGestureRecognizer *)tap {
//    if (![[g_default objectForKey:@"agreement"] boolValue]) {
//        [g_App showAlert:Localized(@"JX_NotAgreeProtocol")];
//        return;
//    }
    SendAuthReq* req = [[SendAuthReq alloc] init];
    req.scope = @"snsapi_userinfo"; // @"post_timeline,sns"
    req.state = @"login";
    req.openID = @"";
    
    [WXApi sendAuthReq:req
        viewController:self
              delegate:[WXApiManager sharedManager]];
}
- (void)authRespNotification:(NSNotification *)notif {
    SendAuthResp *response = notif.object;
    NSString *strMsg = [NSString stringWithFormat:@"Auth结果 code:%@,state:%@,errcode:%d", response.code, response.state, response.errCode];
    NSLog(@"-------%@",strMsg);
    [g_server getWxOpenId:response.code toView:self];

}

- (void)agrBtnAction:(UIButton *)btn {
    
    _checkProtocolBtn.selected = !_checkProtocolBtn.selected;
    [self didSelectedCheckBox:_checkProtocolBtn checked:_checkProtocolBtn.selected];
}

//设置文本框只能输入数字
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (_phone == textField) {
        return [self validateNumber:string];
    }
    return YES;
    
}
- (BOOL)validateNumber:(NSString*)number {
    if ([g_config.regeditPhoneOrName intValue] == 1) {
        // 如果用户名注册选项开启， 则不筛选
        NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"] invertedSet];
        NSString *filtered = [[number componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
        return [number isEqualToString:filtered];
    }
    BOOL res = YES;
    NSCharacterSet *tmpSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    int i = 0;
    while (i < number.length) {
        NSString *string = [number substringWithRange:NSMakeRange(i, 1)];
        NSRange range = [string rangeOfCharacterFromSet:tmpSet];
        if (range.length == 0) {
            res = NO;
            break;
        }
        i ++;
    }
    return res;
    
}

- (void)onSetting {
    
    JXServerListVC *vc = [[JXServerListVC alloc] init];
//    [g_window addSubview:vc.view];
    [g_navigation pushViewController:vc animated:YES];
}

-(void)location:(JXLocation *)location getLocationWithIp:(NSDictionary *)dict {
    if (_isFirstLocation) {
        return;
    }
    NSString *area = [NSString stringWithFormat:@"%@,%@,%@",dict[@"country"],dict[@"region"],dict[@"city"]];
    [g_default setObject:area forKey:kLocationArea];
    [g_default synchronize];
    
    if(self.isAutoLogin && !IsStringNull(_myToken))
        [_wait start:Localized(@"JX_Logining")];
    if (!_isThirdLogin) {
        [g_server getSetting:self];
    }
}

- (void)location:(JXLocation *)location getLocationError:(NSError *)error {
    if (_isFirstLocation) {
        return;
    }
    [g_default setObject:nil forKey:kLocationArea];
    [g_default synchronize];
    
    if(self.isAutoLogin && !IsStringNull(_myToken))
        [_wait start:Localized(@"JX_Logining")];
    if (!_isThirdLogin) {
        [g_server getSetting:self];
    }
}

-(void)longLimit:(UITextField *)textField
{
//    if (textField.text.length > 11) { 
//        textField.text = [textField.text substringToIndex:11];
//    }
}

-(void)dealloc{
//    _pSelf = nil;
    //    NSLog(@"loginVC.dealloc");
    [g_notify  removeObserver:self name:kRegisterNotifaction object:nil];
    //    [_user release];
    //    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self.view addGestureRecognizer:tap];
}

- (void)tapAction:(UITapGestureRecognizer *)tap {
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) textFieldDidChange:(UITextField *) TextField{
    if ([TextField.text isEqualToString:@""]) {
        _pwd.text = @"";
    }
//    if (TextField == _phone) { // 限制手机号最多只能输入11位,为了适配外国电话，将不能显示手机号位数
//        if ([g_config.regeditPhoneOrName intValue] == 1) {
//            if (_phone.text.length > 10) {
//                _phone.text = [_phone.text substringToIndex:10];
//            }
//        }else {
//            if (_phone.text.length > 11) {
//                _phone.text = [_phone.text substringToIndex:11];
//            }
//        }
//    }
}

-(void)onClick{
    
    //    self.isSwitchUser = NO;
    
    if([_phone.text length]<=0){
        if ([g_config.regeditPhoneOrName intValue] == 1) {
            [g_App showAlert:Localized(@"JX_InputUserAccount")];
        }else {
            [g_App showAlert:Localized(@"JX_InputPhone")];
        }
        return;
    }
    if([_pwd.text length]<=0){
        [g_App showAlert:self.isSMSLogin ? Localized(@"JX_InputMessageCode") : Localized(@"JX_InputPassWord")];
        return;
    }
//    if (![[g_default objectForKey:@"agreement"] boolValue]) {
//        [g_App showAlert:Localized(@"JX_NotAgreeProtocol")];
//        return;
//    }
    [self.view endEditing:YES];
    if (self.isSMSLogin) {
        _user.verificationCode = _pwd.text;
    }else {
        _user.password  = [g_server getMD5String:_pwd.text];
    }
    _user.telephone = _phone.text;
    _user.areaCode = [_areaCodeBtn.titleLabel.text stringByReplacingOccurrencesOfString:@"+" withString:@""];
    self.isAutoLogin = NO;
    [_wait start:Localized(@"JX_Logining")];
    [g_server getSetting:self];
//    [g_App.jxServer login:_user toView:self];
}

- (void)actionConfig {
    // 自动登录失败，清除token后，重新赋值一次
    _myToken = [g_default objectForKey:kMY_USER_TOKEN];

    if ([g_config.regeditPhoneOrName intValue] == 1) {
        _areaCodeBtn.hidden = YES;
        _forgetBtn.hidden = YES;
        _phone.keyboardType = UIKeyboardTypeDefault;  // 仅支持大小写字母数字
        _phone.placeholder = Localized(@"JX_InputUserAccount");
    }else {
        _areaCodeBtn.hidden = NO;
//        _forgetBtn.hidden = NO;
        _phone.keyboardType = UIKeyboardTypeNumberPad;  // 限制只能数字输入，使用数字键盘
        _phone.placeholder = Localized(@"JX_InputPhone");
        // 短信登录界面不显示忘记密码
        _forgetBtn.hidden = self.isSMSLogin;
    }

    if ([g_config.isOpenPositionService intValue] == 0) {
        _isFirstLocation = YES;
        _location = [[JXLocation alloc] init];
        _location.delegate = self;
        g_server.location = _location;
        [g_server locate];
    }
    if((self.isAutoLogin && !IsStringNull(_myToken)) || _isThirdLogin)
        if (_isThirdLogin) {
            [g_server thirdLogin:_user type:2 openId:g_server.openId isLogin:NO toView:self];
        }else {
            [self performSelector:@selector(autoLogin) withObject:nil afterDelay:.5];
        }
    else if (IsStringNull(_myToken) && !IsStringNull(_phone.text) && !IsStringNull(_pwd.text)) {
        g_server.isManualLogin = YES;
        [g_App.jxServer login:_user toView:self];
    }
    else
        [_wait stop];
}

-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
    if( [aDownload.action isEqualToString:act_Config]){
        
        [g_config didReceive:dict];
        [self actionConfig];
    }
    if([aDownload.action isEqualToString:act_CheckPhone]){
        [self getImgCodeImg];
    }
    if([aDownload.action isEqualToString:act_SendSMS]){
        [JXMyTools showTipView:Localized(@"JXAlert_SendOK")];
        _send.selected = YES;
        _send.userInteractionEnabled = NO;
        _send.backgroundColor = [UIColor grayColor];
        _smsCode = [[dict objectForKey:@"code"] copy];
        
        [_send setTitle:@"60s" forState:UIControlStateSelected];
        _seconds = 60;
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(showTime:) userInfo:_send repeats:YES];
    }

    if( [aDownload.action isEqualToString:act_UserLogin] || [aDownload.action isEqualToString:act_thirdLogin] || [aDownload.action isEqualToString:act_sdkLogin]){
        if ([aDownload.action isEqualToString:act_thirdLogin] || [aDownload.action isEqualToString:act_sdkLogin]) {
            g_server.openId = nil;
            [g_default setBool:YES forKey:kTHIRD_LOGIN_AUTO];
        }else {
            [g_default setBool:NO forKey:kTHIRD_LOGIN_AUTO];
        }
//        if (!IsStringNull(_pwd.text)) {
//            _user.password = [g_server getMD5String:_pwd.text];
//        }
//        [g_default setBool:[[dict objectForKey:@"multipleDevices"] boolValue] forKey:kISMultipleLogin];
//        [g_default synchronize];
        
        [g_server doLoginOK:dict user:_user];
        
        if(self.isSwitchUser){
            //切换登录，同步好友
            [g_notify postNotificationName:kXmppClickLoginNotifaction object:nil];
            
            // 更新“我”页面
            [g_notify postNotificationName:kUpdateUserNotifaction object:nil];
        }
        else
            [g_App showMainUI];
        [self actionQuit];
        
        [_wait stop];
    }
    if([aDownload.action isEqualToString:act_userLoginAuto]){
//        int status = [[dict objectForKey:@"serialStatus"] intValue];
//        int token  = [[dict objectForKey:@"tokenExists"] intValue];
//        if(status == 2){//序列号一致
//            if(token==1){//Token也存在，说明不用登录了
        
//        [g_default setBool:[[dict objectForKey:@"multipleDevices"] boolValue] forKey:kISMultipleLogin];
//        [g_default synchronize];
        
                [g_server doLoginOK:dict user:_user];
                [g_App showMainUI];
                [self actionQuit];
//            }else{
//                //Token不存在
//                [g_App showAlert:Localized(@"JX_LoginAgain")];
//                _launchImageView.hidden = YES;
//            }
//        }else{
//            //设备号已换
//            [g_App showAlert:Localized(@"JX_LoginAgainNow")];
//            _launchImageView.hidden = YES;
//        }
        
        [_wait stop];
    }
    if ([aDownload.action isEqualToString:act_GetWxOpenId]) {
        _launchImageView.hidden = NO;
        g_server.openId = [dict objectForKey:@"openid"];
        [g_server wxSdkLogin:_user type:2 openId:g_server.openId toView:self];
    }
    
    _btn.userInteractionEnabled = YES;
}

-(int) didServerResultFailed:(JXConnection*)aDownload dict:(NSDictionary*)dict{
    _btn.userInteractionEnabled = YES;
    _launchImageView.hidden = YES;
    
    if ([aDownload.action isEqualToString:act_Config]) {
        
        NSString *url = [g_default stringForKey:kLastApiUrl];
        g_config.apiUrl = url;
        
        [self actionConfig];
        return hide_error;
    }
    [_wait stop];
    if ([aDownload.action isEqualToString:act_sdkLogin] && [[dict objectForKey:@"resultCode"] intValue] == 1040305) {
        loginVC *login = [loginVC alloc];
        login.isThirdLogin = YES;
        login.isAutoLogin = NO;
        login.isSwitchUser= NO;
        login = [login init];
        [g_navigation pushViewController:login animated:YES];
        return hide_error;
    }
    if ([aDownload.action isEqualToString:act_thirdLogin] && [[dict objectForKey:@"resultCode"] intValue] == 1040306) {
        [self onRegister];
        return hide_error;
    }
    if([aDownload.action isEqualToString:act_userLoginAuto]){
        [g_default removeObjectForKey:kMY_USER_TOKEN];
        [share_defaults removeObjectForKey:kMY_ShareExtensionToken];
    }
    if ([aDownload.action isEqualToString:act_thirdLogin]) {
        g_server.openId = nil;
    }
    
    return show_error;
}

-(int) didServerConnectError:(JXConnection*)aDownload error:(NSError *)error{//error为空时，代表超时
    _btn.userInteractionEnabled = YES;
    _launchImageView.hidden = YES;

    if ([aDownload.action isEqualToString:act_Config]) {
        
        NSString *url = [g_default stringForKey:kLastApiUrl];
        g_config.apiUrl = url;
        
        [self actionConfig];
        return hide_error;
    }
    if([aDownload.action isEqualToString:act_userLoginAuto]){
        [g_default removeObjectForKey:kMY_USER_TOKEN];
        [share_defaults removeObjectForKey:kMY_ShareExtensionToken];
    }
    if ([aDownload.action isEqualToString:act_thirdLogin]) {
        g_server.openId = nil;
    }

    [_wait stop];
    return show_error;
}

-(void) didServerConnectStart:(JXConnection*)aDownload{
//    _btn.userInteractionEnabled = NO;
    if([aDownload.action isEqualToString:act_thirdLogin] || [aDownload.action isEqualToString:act_sdkLogin]){
        [_wait start];
    }
}

-(void)onRegister{
    inputPhoneVC* vc = [[inputPhoneVC alloc]init];
//    [g_window addSubview:vc.view];
    [g_navigation pushViewController:vc animated:YES];
}

-(void)onForget{
    forgetPwdVC* vc = [[forgetPwdVC alloc] init];
    vc.isModify = NO;
//    [g_window addSubview:vc.view];
    [g_navigation pushViewController:vc animated:YES];
}

-(void)autoLogin{
    
    _btn.userInteractionEnabled = ![g_server autoLogin:self];
    if (_btn.userInteractionEnabled) {
        _launchImageView.hidden = YES;
    }
}

-(void)onRegistered:(NSNotification *)notifacation{
    [self actionQuit];
    if(!self.isSwitchUser)
        [g_App showMainUI];
}

-(void)actionQuit{
    [super actionQuit];
//    _pSelf = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _phone) {
        [_pwd becomeFirstResponder];
    }else{
        [self.view endEditing:YES];
    }
    return YES;
}

- (void)areaCodeBtnClick:(UIButton *)but{
    [self.view endEditing:YES];
    JXTelAreaListVC *telAreaListVC = [[JXTelAreaListVC alloc] init];
    telAreaListVC.telAreaDelegate = self;
    telAreaListVC.didSelect = @selector(didSelectTelArea:);
//    [g_window addSubview:telAreaListVC.view];
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
- (void)passWordRightViewClicked:(UIButton *)but{
    [_pwd resignFirstResponder];
    but.selected = !but.selected;
    _pwd.secureTextEntry = !but.selected;
    
}

- (void)didSelectedCheckBox:(QCheckBox *)checkbox checked:(BOOL)checked{
    [g_default setObject:[NSNumber numberWithBool:checked] forKey:@"agreement"];
    [g_default synchronize];
}

-(void)catUserProtocol{
    webpageVC * webVC = [webpageVC alloc];
    webVC.url = [self protocolUrl];
    webVC.isSend = NO;
//    [[NSBundle mainBundle] pathForResource:@"用户协议" ofType:@"html"];
    webVC = [webVC init];
    [g_navigation.navigationView addSubview:webVC.view];
//    [g_navigation pushViewController:webVC animated:YES];
}

-(NSString *)protocolUrl{
    NSString * protocolStr = g_config.privacyPolicyPrefix;
    NSString * lange = g_constant.sysLanguage;
    if (![lange isEqualToString:ZHHANTNAME] && ![lange isEqualToString:NAME]) {
        lange = ENNAME;
    }
    return [NSString stringWithFormat:@"%@%@.html",protocolStr,lange];
}

// 获取启动图
- (NSString *)getLaunchImageName
{
    NSString *viewOrientation = @"Portrait";
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        viewOrientation = @"Landscape";
    }
    NSString *launchImageName = nil;
    NSArray* imagesDict = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"UILaunchImages"];
    CGSize viewSize = tyCurrentWindow.bounds.size;
    for (NSDictionary* dict in imagesDict)
    {
        CGSize imageSize = CGSizeFromString(dict[@"UILaunchImageSize"]);
        
        if (CGSizeEqualToSize(imageSize, viewSize) && [viewOrientation isEqualToString:dict[@"UILaunchImageOrientation"]])
        {
            launchImageName = dict[@"UILaunchImageName"];
        }
    }
    return launchImageName;
}

#pragma mark JXLocationDelegate
- (void)location:(JXLocation *)location CountryCode:(NSString *)countryCode CityName:(NSString *)cityName CityId:(NSString *)cityId Address:(NSString *)address Latitude:(double)lat Longitude:(double)lon{
    g_server.countryCode = countryCode;
    g_server.cityName = cityName;
    g_server.cityId = [cityId intValue];
    g_server.address = address;
    g_server.latitude = lat;
    g_server.longitude = lon;
    
    NSDictionary *dict = @{@"latitude":@(lat),@"longitude":@(lon)};
    
    [g_default setObject:dict forKey:kLocationLogin];
}

-(void)showTime:(NSTimer*)sender{
    UIButton *but = (UIButton*)[_timer userInfo];
    _seconds--;
    [but setTitle:[NSString stringWithFormat:@"%ds",_seconds] forState:UIControlStateSelected];
    
    if(_seconds<=0){
        but.selected = NO;
        but.userInteractionEnabled = YES;
        but.backgroundColor = g_theme.themeColor;
        [_send setTitle:Localized(@"JX_SendAngin") forState:UIControlStateNormal];
        if (_timer) {
            _timer = nil;
            [sender invalidate];
        }
        _seconds = 60;
        
    }
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end
