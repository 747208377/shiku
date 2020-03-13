//
//  JXCopyRoomVC.m
//  shiku_im
//
//  Created by 1 on 2019/6/5.
//  Copyright © 2019年 Reese. All rights reserved.
//

#import "JXCopyRoomVC.h"
#import "JXChatViewController.h"
#import "JXRoomPool.h"

@interface JXCopyRoomVC ()
@property (nonatomic, strong) UIImageView *iconV;

@end

@implementation JXCopyRoomVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isGotoBack = YES;
    self.heightFooter = 0;
    self.heightHeader = JX_SCREEN_TOP;
    [self createHeadAndFoot];
    
    self.title = @"一键复制新群";
    
    [self setupViews];
    [g_notify addObserver:self selector:@selector(headImageNotification:) name:kGroupHeadImageModifyNotifaction object:nil];
}

-(void)dealloc {
    [g_notify removeObserver:self];
}

-(void)headImageNotification:(NSNotification *)notification{
    NSDictionary * groupDict = notification.object;
    UIImage * hImage = groupDict[@"groupHeadImage"];
    _iconV.image = hImage;
}

- (void)setupViews {
    
    self.tableBody.backgroundColor = HEXCOLOR(0xECEBF1);
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 20, JX_SCREEN_WIDTH, 160)];
    view.backgroundColor = [UIColor whiteColor];
    [self.tableBody addSubview:view];
    
    _iconV = [[UIImageView alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH/2-30, 20, 60, 60)];
    _iconV.layer.masksToBounds = YES;
    _iconV.layer.cornerRadius = 30.f;
    [view addSubview:_iconV];
    [g_server getRoomHeadImageSmall:self.room.roomJid roomId:self.room.roomId imageView:_iconV];
    
    UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_iconV.frame)+10, JX_SCREEN_WIDTH, 20)];
    name.font = SYSFONT(15);
    name.text = self.room.name;
    name.textAlignment = NSTextAlignmentCenter;
    [view addSubview:name];
    
    UILabel *numLab = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(name.frame)+10, JX_SCREEN_WIDTH, 20)];
    numLab.font = SYSFONT(15);
    numLab.text = [NSString stringWithFormat:@"%ld人",self.room.members.count];
    numLab.textAlignment = NSTextAlignmentCenter;
    numLab.textColor = [UIColor grayColor];
    [view addSubview:numLab];
    
    
    
    UILabel *tint = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(view.frame)+10, 100, 20)];
    tint.font = SYSFONT(15);
    tint.textColor = [UIColor grayColor];
    tint.text = @"温馨提示";
    [self.tableBody addSubview:tint];
    
    tint = [[UILabel alloc] initWithFrame:CGRectMake(15, CGRectGetMaxY(tint.frame)+5, JX_SCREEN_WIDTH-30, 40)];
    tint.font = SYSFONT(15);
    tint.textColor = [UIColor grayColor];
    tint.numberOfLines = 0;
    tint.text = @"1、一键复制新群后，将生成一个群成员相同的新群\n2、生成的新群，群成员在老群中的设置无法复制";
    [self.tableBody addSubview:tint];
    
    
    UIButton *sureBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    sureBtn.frame = CGRectMake(10, CGRectGetMaxY(tint.frame)+10, JX_SCREEN_WIDTH-20, 44);
    sureBtn.backgroundColor = THEMECOLOR;
    [sureBtn setTitle:@"确认复制" forState:UIControlStateNormal];
    [sureBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [sureBtn addTarget:self action:@selector(onCopyRoom) forControlEvents:UIControlEventTouchUpInside];
    [self.tableBody addSubview:sureBtn];
}

- (void)onCopyRoom {
    [g_server copyRoom:self.room.roomId toView:self];

}

-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
    [_wait stop];
    if ([aDownload.action isEqualToString:act_copyRoom]) {
        [g_navigation popToRootViewController];
        roomData * roomdata = [[roomData alloc] init];
        [roomdata getDataFromDict:dict];
        
        JXChatViewController *sendView=[JXChatViewController alloc];
        sendView.title = self.room.name;
        
        sendView.roomJid = roomdata.roomJid;
        sendView.roomId   = roomdata.roomId;
        sendView.chatRoom  = [[JXXMPP sharedInstance].roomPool joinRoom:roomdata.roomJid title:self.room.name isNew:NO];
        sendView.room = roomdata;   
        
        JXUserObject *user = [[JXUserObject alloc] init];
        [user getDataFromDict:dict];


        sendView.chatPerson = user;
        sendView.chatPerson.userId = roomdata.roomJid;
        sendView.chatPerson.userNickname = self.room.name;
        
        user.userNickname = _room.name;
        user.userId = roomdata.roomJid;
        user.userDescription = roomdata.desc;
        user.roomId = roomdata.roomId;
        user.content = Localized(@"JX_WelcomeGroupChat");
        user.showRead =  [NSNumber numberWithBool:roomdata.showRead];
        user.showMember = [NSNumber numberWithBool:roomdata.showMember];
        user.allowSendCard = [NSNumber numberWithBool:roomdata.allowSendCard];
        user.allowInviteFriend = [NSNumber numberWithBool:roomdata.allowInviteFriend];
        user.allowUploadFile = [NSNumber numberWithBool:roomdata.allowUploadFile];
        user.allowSpeakCourse = [NSNumber numberWithBool:roomdata.allowSpeakCourse];
        user.isNeedVerify = [NSNumber numberWithBool:roomdata.isNeedVerify];
        user.createUserId = [NSString stringWithFormat:@"%ld",roomdata.userId];
        [user insertRoom];

        sendView = [sendView init];

        [g_navigation pushViewController:sendView animated:YES];
    }
}

-(int) didServerResultFailed:(JXConnection*)aDownload dict:(NSDictionary*)dict{
    [_wait stop];
    return show_error;
}

-(int) didServerConnectError:(JXConnection*)aDownload error:(NSError *)error{//error为空时，代表超时
    [_wait stop];
    return show_error;
}

-(void) didServerConnectStart:(JXConnection*)aDownload{
    [_wait start];
}

@end
