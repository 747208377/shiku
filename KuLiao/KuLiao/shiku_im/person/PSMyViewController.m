//
//  myViewController.m
//  sjvodios
//
//  Created by  on 12-5-29.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PSMyViewController.h"
#import "JXImageView.h"
#import "JXLabel.h"
#import "AppDelegate.h"
#import "JXServer.h"
#import "JXConnection.h"
#import "UIFactory.h"
#import "JXTableView.h"
#import "JXFriendViewController.h"
#import "ImageResize.h"
#import "userWeiboVC.h"
#import "myMediaVC.h"
#import "webpageVC.h"
#import "loginVC.h"
#import "JXNewFriendViewController.h"
#import "PSRegisterBaseVC.h"
#import "photosViewController.h"
#import "JXSettingVC.h"
#import "PSUpdateUserVC.h"
#import "OrganizTreeViewController.h"
#import "JXCourseListVC.h"
#import "JXMyMoneyViewController.h"
#import "JXNearVC.h"
#import "JXSelFriendVC.h"
#import "JXSelectFriendsVC.h"
#ifdef Meeting_Version
#import "JXAVCallViewController.h"
#endif

#ifdef Live_Version
#import "JXLiveViewController.h"
#endif

#import "JXFriendViewController.h"
#import "JXGroupViewController.h"
#import "UIImage+Color.h"

#define HEIGHT 50
#define MY_INSET  0  // 每行左右间隙
#define TOP_ADD_HEIGHT  400  // 顶部添加的高度，防止下拉顶部空白

@implementation PSMyViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.isRefresh = NO;
        self.title = Localized(@"JX_My");
        self.heightHeader = 0;
        self.heightFooter = JX_SCREEN_BOTTOM;
        //self.view.frame = CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT-JX_SCREEN_BOTTOM);
        [self createHeadAndFoot];
        self.tableBody.backgroundColor = HEXCOLOR(0xf0eff4);


        int h=-20;
        int w=JX_SCREEN_WIDTH;
        
        float marginHei = 10;
        
        int H = 86;

        JXImageView* iv;
        iv = [self createHeadButtonclick:@selector(onResume)];
        _topImageVeiw = iv;
        CGFloat height = THE_DEVICE_HAVE_HEAD ? 55 : 75;
        if (THESIMPLESTYLE) {
            iv.frame = CGRectMake(0, h-TOP_ADD_HEIGHT, w, 266+TOP_ADD_HEIGHT-H+55);
            h+=iv.frame.size.height-TOP_ADD_HEIGHT;
        }else {
            iv.frame = CGRectMake(0, h-TOP_ADD_HEIGHT, w, 266+TOP_ADD_HEIGHT-H);
            h+=iv.frame.size.height-TOP_ADD_HEIGHT+ height;
        }
        
        
        // 好友
//        NSArray *friends = [[JXUserObject sharedInstance] fetchAllUserFromLocal];
//        UIButton *button;
//        button = [self createViewWithFrame:CGRectMake(0, h, JX_SCREEN_WIDTH/2, H) title:[NSString stringWithFormat:@"%ld",friends.count] icon:@"my_topFriends" index:0 showLine:YES];
//
//        // 群组
//        NSArray *groups = [[JXUserObject sharedInstance] fetchAllRoomsFromLocal];
//        button = [self createViewWithFrame:CGRectMake(CGRectGetMaxX(button.frame), h, JX_SCREEN_WIDTH/2, H) title:[NSString stringWithFormat:@"%ld",groups.count] icon:@"my_groups" index:1 showLine:NO];
//        h+=button.frame.size.height+marginHei;
        
        
//        iv = [self createButton:@"我的名片盒" drawTop:YES drawBottom:YES icon:@"set_card" click:@selector(onFriend)];
//        iv.frame = CGRectMake(0,h, w, HEIGHT);
//        h+=iv.frame.size.height;

//        NSArray * titleArray = [NSArray arrayWithObjects:@"我的资料",@"我的朋友",@"我的空间",@"搜索好友",@"我的附件",nil];
//        NSArray * iconArray = [NSArray arrayWithObjects:@"my_friend",@"my_space",@"search_friends",@"my_attachment",@"balance_recharge",@"set_up",nil];
        
//        iv = [self createButton:@"我的资料" drawTop:YES drawBottom:YES icon:@"资料" click:@selector(onResume)];
//        iv.frame = CGRectMake(0,h, w, HEIGHT);
//        h+=iv.frame.size.height+marginHei;
        

//        iv = [self createButton:Localized(@"PSMyViewController_MyFirend") drawTop:NO drawBottom:YES icon:@"my_friend" click:@selector(onFriend)];
//        iv.frame = CGRectMake(0,h, w, HEIGHT);
//        h+=iv.frame.size.height;

        
//        iv = [self createButton:@"搜索好友" drawTop:NO drawBottom:YES icon:@"search_friends" click:@selector(onSearch)];
//        iv.frame = CGRectMake(0,h, w, HEIGHT);
//        h+=iv.frame.size.height;
        if ([g_App.isShowRedPacket intValue] == 1) {
            iv = [self createButton:Localized(@"JX_MyBalance") drawTop:NO drawBottom:YES icon:THESIMPLESTYLE ? @"balance_recharge_simple" : @"balance_recharge" click:@selector(onRecharge)];
            iv.frame = CGRectMake(MY_INSET,h, w-MY_INSET*2, HEIGHT);
//            _moneyLabel = [[UILabel alloc]initWithFrame:CGRectMake(JX_SCREEN_WIDTH-135,11,100-MY_INSET,30)];
//            _moneyLabel.textAlignment = NSTextAlignmentRight;
//            _moneyLabel.userInteractionEnabled = NO;
//            _moneyLabel.font = g_factory.font15;
//            [iv addSubview:_moneyLabel];
            
            h+=iv.frame.size.height;
        }
        
        iv = [self createButton:Localized(@"JX_MyDynamics") drawTop:NO drawBottom:YES icon:THESIMPLESTYLE ? @"my_space_simple" : @"my_space" click:@selector(onMyBlog)];
        iv.frame = CGRectMake(MY_INSET,h, w-MY_INSET*2, HEIGHT);
        h+=iv.frame.size.height;
        
        iv = [self createButton:Localized(@"JX_MyCollection") drawTop:NO drawBottom:YES icon:THESIMPLESTYLE ? @"collection_me_simple" : @"collection_me" click:@selector(onMyFavorite)];
        iv.frame = CGRectMake(MY_INSET,h, w-MY_INSET*2, HEIGHT);
        h+=iv.frame.size.height;
        
//        iv = [self createButton:Localized(@"PSMyViewController_MyAtt") drawTop:NO drawBottom:YES icon:@"my_attachment" click:@selector(onVideo)];
//        iv.frame = CGRectMake(0,h, w, HEIGHT);
//        h+=iv.frame.size.height;
        
        iv = [self createButton:Localized(@"JX_MyLecture") drawTop:NO drawBottom:YES icon:THESIMPLESTYLE ? @"my_lecture_simple" : @"my_lecture" click:@selector(onCourse)];
        iv.frame = CGRectMake(MY_INSET,h, w-MY_INSET*2, HEIGHT);
        h+=iv.frame.size.height + marginHei;
        
//        iv = [self createButton:Localized(@"JXNearVC_NearHere") drawTop:NO drawBottom:YES icon:@"nearby_normal" click:@selector(onNear)];
//        iv.frame = CGRectMake(0,h, w, HEIGHT);
//        h+=iv.frame.size.height;

//#ifdef Live_Version
//        iv = [self createButton:Localized(@"OrganizVC_Organiz") drawTop:NO drawBottom:YES icon:@"my_organizBook" click:@selector(onOrganiz)];
//        iv.frame = CGRectMake(0,h, w, HEIGHT);
//        h+=iv.frame.size.height;
//#endif
        
        
//        iv = [self createButton:@"收藏职位" drawTop:NO drawBottom:YES icon:@"set_collect" click:@selector(onMoney)];
//        iv.frame = CGRectMake(0,h, w, HEIGHT);
//        h+=iv.frame.size.height;
        BOOL isShowLine = NO;
#ifdef IS_SHOW_MENU
#else
#ifdef Meeting_Version
        isShowLine = YES;
        iv = [self createButton:Localized(@"JXSettingVC_VideoMeeting") drawTop:isShowLine drawBottom:YES icon:THESIMPLESTYLE ? @"videomeeting_simple" : @"videomeeting" click:@selector(onMeeting)];
        iv.frame = CGRectMake(0,h, w, HEIGHT);
        h+=iv.frame.size.height;
        isShowLine = NO;
#else
        isShowLine = YES;
#endif
        
#ifdef Live_Version
        if ([g_App.isShowRedPacket intValue] == 1 ) {
            iv = [self createButton:Localized(@"JX_LiveDemonstration") drawTop:isShowLine drawBottom:YES icon:THESIMPLESTYLE ? @"videoshow_simple" : @"videoshow" click:@selector(onLive)];
            iv.frame = CGRectMake(0,h, w, HEIGHT);
            h+=iv.frame.size.height + marginHei;
        }
        isShowLine = YES;
#else
        isShowLine = NO;
#endif

#endif


        iv = [self createButton:Localized(@"JXSettingVC_Set") drawTop:isShowLine drawBottom:YES icon:THESIMPLESTYLE ? @"set_up_simple" : @"set_up" click:@selector(onSetting)];
        iv.frame = CGRectMake(MY_INSET,h, w-MY_INSET*2, HEIGHT);
//        h+=iv.frame.size.height;
        
        if ((h + HEIGHT + 20) > self.tableBody.frame.size.height) {
            self.tableBody.contentSize = CGSizeMake(self_width, h + HEIGHT + 20);
        }
        
        [g_notify addObserver:self selector:@selector(doRefresh:) name:kUpdateUserNotifaction object:nil];
        [g_notify addObserver:self selector:@selector(updateUserInfo:) name:kXMPPMessageUpadteUserInfoNotification object:nil];
        //获取用户余额
        [g_server getUserMoenyToView:self];
    }
    return self;
}

- (void)updateUserInfo:(NSNotification *)noti {
    self.isXmppUpdate = YES;
    [g_server getUser:g_server.myself.userId toView:self];
}

-(void)dealloc{
    NSLog(@"PSMyViewController.dealloc");
    [g_notify removeObserver:self name:kUpdateUserNotifaction object:nil];
    [g_notify removeObserver:self name:kXMPPMessageUpadteUserInfoNotification object:nil];
//    [_image release];
//    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

//设置状态栏颜色
- (void)setStatusBarBackgroundColor:(UIColor *)color {
    
    UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
    if ([statusBar respondsToSelector:@selector(setBackgroundColor:)]) {
        statusBar.backgroundColor = color;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSArray *friends = [[JXUserObject sharedInstance] fetchAllUserFromLocal];
    _friendLabel.text = [NSString stringWithFormat:@"%ld",friends.count];
    NSArray *groups = [[JXUserObject sharedInstance] fetchAllRoomsFromLocal];
    _groupLabel.text = [NSString stringWithFormat:@"%ld",groups.count];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.isRefresh) {
        self.isRefresh = NO;
    }else{
        [super viewDidAppear:animated];
        [self doRefresh:nil];
    }

}

-(void)doRefresh:(NSNotification *)notifacation{
    _head.image = nil;
    [g_server getHeadImageSmall:g_server.myself.userId userName:g_server.myself.userNickname imageView:_head];
    //获取用户余额
//    [g_server getUserMoenyToView:self];
    _userName.text = g_server.myself.userNickname;
    _userDesc.text = g_server.myself.telephone;
//    _moneyLabel.text = [NSString stringWithFormat:@"%.2f%@",g_App.myMoney,Localized(@"JX_ChinaMoney")];
}

//-(void)refreshUserDetail{
//    _moneyLabel.text = [NSString stringWithFormat:@"%.2f%@",g_App.myMoney,Localized(@"JX_ChinaMoney")];
//}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
//服务端返回数据
-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
        [_wait hide];
    
    if( [aDownload.action isEqualToString:act_resumeList] ){
    }
    if( [aDownload.action isEqualToString:act_UserGet] ){
        JXUserObject* user = [[JXUserObject alloc]init];
        [user getDataFromDict:dict];
        
        g_server.myself.userNickname = user.userNickname;
        NSRange range = [user.telephone rangeOfString:@"86"];
        if (range.location != NSNotFound) {
            g_server.myself.telephone = [user.telephone substringFromIndex:range.location + range.length];
        }
        
        if (self.isXmppUpdate) {
            self.isXmppUpdate = NO;
            _userName.text = user.userNickname;
            [g_server delHeadImage:g_server.myself.userId];
            [g_server getHeadImageSmall:g_server.myself.userId userName:g_server.myself.userNickname imageView:_head];
            return;
        }
        
        PSUpdateUserVC* vc = [PSUpdateUserVC alloc];
        vc.headImage = [_head.image copy];
        vc.user = user;
        
        //JTFX
//        [user release];
        
        vc = [vc init];
        
//        [g_notify postNotificationName:kUpdateUserNotifaction object:nil];
        
//        [g_window addSubview:vc.view];
        [g_navigation pushViewController:vc animated:YES];
    }
    if ([aDownload.action isEqualToString:act_getUserMoeny]) {
        g_App.myMoney = [dict[@"balance"] doubleValue];
        _moneyLabel.text = [NSString stringWithFormat:@"%.2f%@",g_App.myMoney,Localized(@"JX_ChinaMoney")];
    }
}

-(int) didServerResultFailed:(JXConnection*)aDownload dict:(NSDictionary*)dict{
    [_wait hide];
    return hide_error;
}

-(int) didServerConnectError:(JXConnection*)aDownload error:(NSError *)error{//error为空时，代表超时
    [_wait hide];
    return hide_error;
}

-(void) didServerConnectStart:(JXConnection*)aDownload{
//    [_wait start];
}

-(void)actionClear{
    [_wait start:Localized(@"PSMyViewController_Clearing") delay:100];
}

#ifdef Live_Version
// 直播
- (void)onLive {
    JXLiveViewController *vc = [[JXLiveViewController alloc] init];
    [g_navigation pushViewController:vc animated:YES];
}
#endif

#ifdef Meeting_Version
// 视频会议
- (void)onMeeting {
    if(g_xmpp.isLogined != 1){
        [g_xmpp showXmppOfflineAlert];
        return;
    }
    
    NSString *str1;
    NSString *str2;

    str1 = Localized(@"JXSettingVC_VideoMeeting");
    str2 = Localized(@"JX_Meeting");

    JXActionSheetVC *actionVC = [[JXActionSheetVC alloc] initWithImages:@[@"meeting_tel",@"meeting_video"] names:@[str2,str1]];
    actionVC.delegate = self;
    [self presentViewController:actionVC animated:NO completion:nil];
}

- (void)actionSheet:(JXActionSheetVC *)actionSheet didButtonWithIndex:(NSInteger)index {
    if (index == 0) {
        [self onGroupAudioMeeting:nil];
    }else if(index == 1){
        [self onGroupVideoMeeting:nil];
    }
}
-(void)onGroupAudioMeeting:(JXMessageObject*)msg{

    self.isAudioMeeting = YES;
    [self onInvite];
    //    [g_meeting startAudioMeeting:no roomJid:s];
}

-(void)onGroupVideoMeeting:(JXMessageObject*)msg{

    self.isAudioMeeting = NO;
    [self onInvite];
    //    [g_meeting startVideoMeeting:no roomJid:s];
}
-(void)onInvite{

    
    NSMutableSet* p = [[NSMutableSet alloc]init];
    
    JXSelectFriendsVC* vc = [JXSelectFriendsVC alloc];
    vc.isNewRoom = NO;
    vc.isShowMySelf = NO;
    vc.type = JXSelUserTypeSelFriends;
//    vc.room = _room;
    vc.existSet = p;
    vc.delegate = self;
    vc.didSelect = @selector(meetingAddMember:);
    vc = [vc init];
    //    [g_window addSubview:vc.view];
    [g_navigation pushViewController:vc animated:YES];
}
-(void)meetingAddMember:(JXSelectFriendsVC*)vc{
    int type;
    if (self.isAudioMeeting) {
        type = kWCMessageTypeAudioMeetingInvite;
    }else {
        type = kWCMessageTypeVideoMeetingInvite;
    }
    for(NSNumber* n in vc.set){
        JXUserObject *user;
        if (vc.seekTextField.text.length > 0) {
            user = vc.searchArray[[n intValue] % 1000];
        }else{
            user = [[vc.letterResultArr objectAtIndex:[n intValue] / 1000] objectAtIndex:[n intValue] % 1000];
        }
        NSString* s = [NSString stringWithFormat:@"%@",user.userId];
        [g_meeting sendMeetingInvite:s toUserName:user.userNickname roomJid:MY_USER_ID callId:nil type:type];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (g_meeting.isMeeting) {
            return;
        }
        JXAVCallViewController *avVC = [[JXAVCallViewController alloc] init];
        avVC.roomNum = MY_USER_ID;
        avVC.isAudio = self.isAudioMeeting;
        avVC.isGroup = YES;
        avVC.toUserName = MY_USER_NAME;
        avVC.view.frame = [UIScreen mainScreen].bounds;
        [g_window addSubview:avVC.view];
        
    });
    
}
#endif


-(void)onMyBlog{
    userWeiboVC* vc = [userWeiboVC alloc];
    vc.user = g_myself;
    vc.isGotoBack = YES;
    vc = [vc init];
//    [g_window addSubview:vc.view];
    [g_navigation pushViewController:vc animated:YES];

}
-(void)onNear{
    JXNearVC * nearVc = [[JXNearVC alloc] init];
//    [g_window addSubview:nearVc.view];
    [g_navigation pushViewController:nearVc animated:YES];
}
-(void)onFriend{
    JXFriendViewController* vc = [[JXFriendViewController alloc]init];
//    [g_window addSubview:vc.view];
    [g_navigation pushViewController:vc animated:YES];
}

-(void)onResume{
    [g_server getUser:MY_USER_ID toView:self];
}

-(void)onSpace{
//    mySpaceViewController* vc = [[mySpaceViewController alloc]init];
//    [g_window addSubview:vc.view];
}

-(void)onVideo{
    myMediaVC* vc = [[myMediaVC alloc] init];
//    [g_window addSubview:vc.view];
    [g_navigation pushViewController:vc animated:YES];
}
-(void)onMyFavorite{
    WeiboViewControlle * collection = [[WeiboViewControlle alloc] initCollection];
    
//    [g_window addSubview:collection.view];
    [g_navigation pushViewController:collection animated:YES];
}

- (void)onCourse {
    JXCourseListVC *vc = [[JXCourseListVC alloc] init];
//    [g_window addSubview:vc.view];
    [g_navigation pushViewController:vc animated:YES];
}

-(void)onRecharge{
    JXMyMoneyViewController * moneyVC = [[JXMyMoneyViewController alloc] init];
//    [g_window addSubview:moneyVC.view];
    [g_navigation pushViewController:moneyVC animated:YES];
    
}

-(void)onOrganiz{
    OrganizTreeViewController * organizVC = [[OrganizTreeViewController alloc] init];
//    [g_window addSubview:organizVC.view];
    [g_navigation pushViewController:organizVC animated:YES];
}
-(void)onMyLove{
    
}

-(void)onMoney{
}

-(void)onSetting{
    JXSettingVC* vc = [[JXSettingVC alloc]init];
//    [g_window addSubview:vc.view];
    [g_navigation pushViewController:vc animated:YES];
}

-(JXImageView*)createHeadButtonclick:(SEL)click{
    JXImageView* btn = [[JXImageView alloc] init];
    btn.backgroundColor = [UIColor whiteColor];
    btn.userInteractionEnabled = YES;
    btn.didTouch = click;
    btn.delegate = self;
    [self.tableBody addSubview:btn];
    UIColor *color;
    if (THESIMPLESTYLE) {
        color = [UIColor whiteColor];
    }else {
        color = THEMECOLOR;
    }
    [self setupView:btn colors:@[(__bridge id)color.CGColor,(__bridge id)[color colorWithAlphaComponent:0.5].CGColor]];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, THE_DEVICE_HAVE_HEAD ? 24+TOP_ADD_HEIGHT : 40+TOP_ADD_HEIGHT, JX_SCREEN_WIDTH, 20)];
    title.text = Localized(@"JX_PersonalCenter");
    title.font = SYSFONT(18);
    title.textColor = [UIColor whiteColor];
    title.textAlignment = NSTextAlignmentCenter;
    [btn addSubview:title];
    
    UIView *baseView = [[UIView alloc] initWithFrame:CGRectMake(6, CGRectGetMaxY(title.frame)+ (THE_DEVICE_HAVE_HEAD ? 16 : 20), JX_SCREEN_WIDTH-12, 160)];
    baseView.layer.masksToBounds = YES;
    baseView.layer.cornerRadius = 10.f;
    baseView.backgroundColor = [UIColor whiteColor];
    [btn addSubview:baseView];
    
    // 头像阴影
    JXImageView *shadow = [[JXImageView alloc]initWithFrame:CGRectMake(13, (baseView.frame.size.height-84)/2-5, 100, 100)];
    shadow.image = [UIImage imageNamed:@"my_icon_shadow"];
    shadow.didTouch = @selector(onResume);
    shadow.delegate = self;
    [baseView addSubview:shadow];

    //头像
    _head = [[JXImageView alloc]initWithFrame:CGRectMake(20, (baseView.frame.size.height-84)/2, 84, 84)];
    _head.layer.cornerRadius = _head.frame.size.width / 2;
    _head.layer.masksToBounds = YES;
    _head.didTouch = @selector(onResume);
    _head.delegate = self;
    [baseView addSubview:_head];
    

    //名字Label
    UILabel* p = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(_head.frame)+20, CGRectGetMinY(_head.frame)+18, 150, 20)];
    p.font = SYSFONT(16);
    p.text = MY_USER_NAME;
    p.textColor = HEXCOLOR(0x323232);
    p.backgroundColor = [UIColor clearColor];
    [baseView addSubview:p];
    _userName = p;
    
    //电话Label
    p = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMinX(p.frame), CGRectGetMaxY(p.frame)+10, 100, 16)];
    p.font = SYSFONT(13);
    p.text = g_server.myself.telephone;
    p.textColor = [UIColor grayColor];
    p.backgroundColor = [UIColor clearColor];
    [baseView addSubview:p];
    _userDesc = p;
    
    UIImageView* iv = [[UIImageView alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH-INSETS-40-MY_INSET, (baseView.frame.size.height-20)/2, 20, 20)];
    iv.image = [UIImage imageNamed:@"set_list_next"];
    [baseView addSubview:iv];
    
    UIImageView* qrImgV = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMinX(iv.frame)-38, (baseView.frame.size.height-23)/2, 23, 23)];
    qrImgV.image = [UIImage imageNamed:@"my_qrcode"];
    [baseView addSubview:qrImgV];

    return btn;
}

- (void)onColleagues:(UITapGestureRecognizer *)tap {
    // 防止好友、群组同时调用
    if (_isSelected)
        return;
    _isSelected = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _isSelected = NO;
    });
    switch (tap.view.tag) {
        case 0:{
            JXFriendViewController *friendVC = [JXFriendViewController alloc];
            friendVC.isMyGoIn = YES;
            friendVC = [friendVC  init];
            [g_navigation pushViewController:friendVC animated:YES];
        }
            break;
        case 1:{
            JXGroupViewController *groupVC = [[JXGroupViewController alloc] init];
            [g_navigation pushViewController:groupVC animated:YES];
        }
            break;
        default:
            break;
    }

}

- (UIButton *)createViewWithFrame:(CGRect)frame title:(NSString *)title icon:(NSString *)icon index:(CGFloat)index showLine:(BOOL)isShow{
    UIButton *view = [[UIButton alloc] init];
    [view setBackgroundImage:[UIImage createImageWithColor:[UIColor whiteColor]] forState:UIControlStateNormal];
    [view setBackgroundImage:[UIImage createImageWithColor:HEXCOLOR(0xF6F5FA)] forState:UIControlStateHighlighted];
    view.frame = frame;
    view.tag = index;
    [self.tableBody addSubview:view];

    int imgH = 40.5;
    UIImageView *imgV = [[UIImageView alloc] init];
    imgV.frame = CGRectMake((view.frame.size.width-imgH)/2, (view.frame.size.height-imgH-15-3)/2, imgH, imgH);
    imgV.image = [UIImage imageNamed:icon];
    [view addSubview:imgV];
    
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(0, CGRectGetMaxY(imgV.frame)+3, view.frame.size.width, 15);
    label.text = title;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = SYSFONT(15);
    label.textColor = HEXCOLOR(0x323232);
    [view addSubview:label];
    if (index == 0) {
        _friendLabel = label;
    }else {
        _groupLabel = label;
    }
    if (isShow) {
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(view.frame.size.width-.5, (view.frame.size.height-24)/2, .5, 24)];
        line.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1];
        [view addSubview:line];
    }
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onColleagues:)];
    [view addGestureRecognizer:tap];
    
    return view;
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
//    p.delegate = self;
//    p.didTouch = click;
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
    
    if(click){
        UIImageView* iv;
        iv = [[UIImageView alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH-INSETS-20-3-MY_INSET, 16, 20, 20)];
        iv.image = [UIImage imageNamed:@"set_list_next"];
        [btn addSubview:iv];
        
    }
    return btn;
}
//内存泄漏，为啥？
-(void)onHeadImage{
    [g_server delHeadImage:g_myself.userId];
    
    JXImageScrollVC * imageVC = [[JXImageScrollVC alloc]init];
    
    imageVC.imageSize = CGSizeMake(JX_SCREEN_WIDTH, JX_SCREEN_WIDTH);
    
    imageVC.iv = [[JXImageView alloc] initWithFrame:CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_WIDTH)];
    
    imageVC.iv.center = imageVC.view.center;
    
    [g_server getHeadImageLarge:g_myself.userId userName:g_myself.userNickname imageView:imageVC.iv];
    
    [self addTransition:imageVC];
    
    [self presentViewController:imageVC animated:YES completion:^{
        self.isRefresh = YES;
    
    }];
    
//    [imageVC release];
    
    

}

- (void)setupView:(UIView *)view colors:(NSArray *)colors {
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = CGRectMake(0, 0, JX_SCREEN_WIDTH, 266+TOP_ADD_HEIGHT-86);  // 设置显示的frame
    gradientLayer.colors = colors;  // 设置渐变颜色
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(1, 0);
    [view.layer addSublayer:gradientLayer];
}


//添加VC转场动画
- (void) addTransition:(JXImageScrollVC *) siv
{
    self.scaleTransition = [[DMScaleTransition alloc]init];
    [siv setTransitioningDelegate:self.scaleTransition];
    
}

//-(void)onSearch{
//    JXNearVC* vc = [[JXNearVC alloc] init];
//    [g_window addSubview:vc.view];
//    [vc onSearch];
//}


@end
