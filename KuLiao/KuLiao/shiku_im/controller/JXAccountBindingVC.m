//
//  JXAccountBindingVC.m
//  shiku_im
//
//  Created by 1 on 2019/3/14.
//  Copyright © 2019年 Reese. All rights reserved.
//

#import "JXAccountBindingVC.h"
#import "WXApi.h"

#define HEIGHT 50
#define MY_INSET  0  // 每行左右间隙
#define TOP_ADD_HEIGHT  400  // 顶部添加的高度，防止下拉顶部空白

@interface JXAccountBindingVC () <UIAlertViewDelegate,WXApiDelegate,WXApiManagerDelegate>
@property (nonatomic, strong) UIButton *wxBindStatus;

@end

@implementation JXAccountBindingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = Localized(@"JX_AccountAndBindSettings");
    self.isGotoBack = YES;
    self.heightHeader = JX_SCREEN_TOP;
    self.heightFooter = 0;
    [self createHeadAndFoot];
    [self getServerData];
    
    [self setupViews];
    // 微信登录回调
    [WXApiManager sharedManager].delegate = self;
    [g_notify addObserver:self selector:@selector(authRespNotification:) name:kWxSendAuthRespNotification object:nil];
}


- (void)getServerData {
    [g_server getBindInfo:self];
}

- (void)setupViews {
    self.tableBody.backgroundColor = HEXCOLOR(0xf0eff4);
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 120, 18)];
    title.text = Localized(@"JX_OtherLogin");
    title.font = SYSFONT(16);
    [self.tableBody addSubview:title];
    
    JXImageView* iv;
    
    iv = [self createButton:Localized(@"JX_WeChat") drawTop:YES drawBottom:YES icon:@"wechat_icon" click:@selector(bindAcount)];
    iv.frame = CGRectMake(MY_INSET,CGRectGetMaxY(title.frame)+20, JX_SCREEN_WIDTH, HEIGHT);
    
    self.wxBindStatus = [[UIButton alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH-20-60, 16, 60, 20)];
    [self.wxBindStatus setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [self.wxBindStatus.titleLabel setFont:SYSFONT(15)];
    [self.wxBindStatus.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self.wxBindStatus setTitle:Localized(@"JX_Unbounded") forState:UIControlStateNormal];
    [self.wxBindStatus setTitle:Localized(@"JX_Binding") forState:UIControlStateSelected];
    [iv addSubview:self.wxBindStatus];
    
}

- (void)bindAcount {
    if (self.wxBindStatus.selected) {
        [g_App showAlert:Localized(@"JX_UnbindWeChat?") delegate:self tag:1001 onlyConfirm:NO];
    }else {
        [g_App showAlert:Localized(@"JX_BindWeChat?") delegate:self tag:1002 onlyConfirm:NO];
    }
    
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        if (alertView.tag == 1001) {
            [g_server setAccountUnbind:2 toView:self];
        }
        if (alertView.tag == 1002) {
            SendAuthReq* req = [[SendAuthReq alloc] init];
            req.scope = @"snsapi_userinfo"; // @"post_timeline,sns"
            req.state = @"login";
            req.openID = @"";
            
            [WXApi sendAuthReq:req
                viewController:self
                      delegate:[WXApiManager sharedManager]];
        }
    }
}

- (void)authRespNotification:(NSNotification *)notif {
    SendAuthResp *response = notif.object;
    NSString *strMsg = [NSString stringWithFormat:@"Auth结果 code:%@,state:%@,errcode:%d", response.code, response.state, response.errCode];
    NSLog(@"-------%@",strMsg);
    
    [g_server getWxOpenId:response.code toView:self];
}


-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
    [_wait stop];
    if([aDownload.action isEqualToString:act_unbind]){
        self.wxBindStatus.selected = NO;
        [g_server showMsg:Localized(@"JX_UnboundSuccessfully")];
    }
    if ([aDownload.action isEqualToString:act_thirdLogin]) {
        g_server.openId = nil;
        self.wxBindStatus.selected = YES;
        [g_server showMsg:Localized(@"JX_BindingSuccessfully")];
    }
    if ([aDownload.action isEqualToString:act_GetWxOpenId]) {
        JXUserObject *user = [[JXUserObject alloc] init];
        if ([g_default objectForKey:kMY_USER_PASSWORD]) {
            user.password = [g_default objectForKey:kMY_USER_PASSWORD];
        }
        NSString *areaCode = [g_default objectForKey:kMY_USER_AREACODE];
        user.areaCode = areaCode.length > 0 ? areaCode : @"86";
        if ([g_default objectForKey:kMY_USER_LoginName]) {
            user.telephone = [g_default objectForKey:kMY_USER_LoginName];
        }
        
        g_server.openId = [dict objectForKey:@"openid"];
        
        [g_server thirdLogin:user type:2 openId:g_server.openId isLogin:YES toView:self];
    }
    if( [aDownload.action isEqualToString:act_getBindInfo] ){
        if (array1.count > 0) {
            for (NSDictionary *dict in array1) {
                if ([[dict objectForKey:@"type"] intValue] == 2) {
                    //微信绑定
                    self.wxBindStatus.selected = YES;
                }
                if ([[dict objectForKey:@"type"] intValue] == 1) {
                    //QQ绑定
                }
            }
        }
    }
}

-(int) didServerResultFailed:(JXConnection*)aDownload dict:(NSDictionary*)dict{
    [_wait stop];
    if ([aDownload.action isEqualToString:act_thirdLogin]) {
        g_server.openId = nil;
    }
    return show_error;
}

-(int) didServerConnectError:(JXConnection*)aDownload error:(NSError *)error{//error为空时，代表超时
    [_wait stop];
    if ([aDownload.action isEqualToString:act_thirdLogin]) {
        g_server.openId = nil;
    }
    return show_error;
}

-(void) didServerConnectStart:(JXConnection*)aDownload{
    [_wait start];
}


-(JXImageView*)createButton:(NSString*)title drawTop:(BOOL)drawTop drawBottom:(BOOL)drawBottom icon:(NSString*)icon click:(SEL)click{
    JXImageView* btn = [[JXImageView alloc] init];
    btn.backgroundColor = [UIColor whiteColor];
    btn.userInteractionEnabled = YES;
    btn.didTouch = click;
    btn.delegate = self;
    [self.tableBody addSubview:btn];
    
    JXLabel* p = [[JXLabel alloc] initWithFrame:CGRectMake(20*2+20, 0, self_width-35-20-5, HEIGHT)];
    p.text = title;
    p.font = g_factory.font16;
    p.backgroundColor = [UIColor clearColor];
    p.textColor = HEXCOLOR(0x323232);
    [btn addSubview:p];
    
    if(icon){
        UIImageView* iv = [[UIImageView alloc] initWithFrame:CGRectMake(20, (HEIGHT-20)/2, 21, 21)];
        iv.image = [UIImage imageNamed:icon];
        [btn addSubview:iv];
    }
    
    if(drawTop){
        UIView* line = [[UIView alloc] initWithFrame:CGRectMake(0,0,JX_SCREEN_WIDTH,0.3)];
        line.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1];
        [btn addSubview:line];
    }
    
    if(drawBottom){
        UIView* line = [[UIView alloc] initWithFrame:CGRectMake(0,HEIGHT-0.3,JX_SCREEN_WIDTH,0.3)];
        line.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1];
        [btn addSubview:line];
    }
    
//    if(click){
//        UIImageView* iv;
//        iv = [[UIImageView alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH-INSETS-20-3-MY_INSET, 16, 20, 20)];
//        iv.image = [UIImage imageNamed:@"set_list_next"];
//        [btn addSubview:iv];
//
//    }
    return btn;
}


@end
