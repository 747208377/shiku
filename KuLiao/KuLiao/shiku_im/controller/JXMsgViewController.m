//  JXMsgViewController.m
//
//  Created by flyeagleTang on 14-4-3.
//  Copyright (c) 2014年 Reese. All rights reserved.
//

#import "JXMsgViewController.h"
#import "JXChatViewController.h"
#import "AppDelegate.h"
#import "JXLabel.h"
#import "JXImageView.h"
#import "JXCell.h"
#import "JXRoomPool.h"
#import "JXRoomObject.h"
#import "JXTableView.h"
#import "JXFriendObject.h"
#import "inputPhoneVC.h"
#import "inputPwdVC.h"
#import "loginVC.h"
#import "WeiboViewControlle.h"
#import "addMsgVC.h"
#import "JXNewFriendViewController.h"
#import "JXUserInfoVC.h"
#import "JXRoomObject.h"
#import "JXRoomRemind.h"
#import "FMDatabase.h"
#import "JXGroupViewController.h"
#import "JXSearchUserVC.h"
#import "JXNearVC.h"
#import "JXRoomMemberVC.h"
#import "JXMainViewController.h"
#import "JXTabMenuView.h"
#import "JXScanQRViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "JX_DownListView.h"
#import "JXNewRoomVC.h"
#import "JXSynTask.h"
#ifdef Live_Version
#import "JXLiveJidManager.h"
#endif
#import "JXPayViewController.h"
#import "JXTransferNoticeVC.h"
#import "JXFaceCreateRoomVC.h"

@interface JXMsgViewController ()<UIAlertViewDelegate, UITextFieldDelegate,JXSelectMenuViewDelegate,UITextViewDelegate>

@property (nonatomic, strong) UITextField *seekTextField;
@property (nonatomic, strong) NSMutableArray *searchArray;
@property (nonatomic, assign) BOOL dalayAction;
@property (nonatomic, assign) int topNum;
@property (nonatomic, strong) UIButton *moreBtn;
@property (nonatomic, strong) UIButton *editBtn;
@property (nonatomic, strong) UIButton *doneBtn;
@property (nonatomic, strong) JXRoomRemind *roomRemind;

@property (nonatomic, strong) UIActivityIndicatorView *activity;

@property (nonatomic, strong) NSMutableArray *taskArray;

@property (nonatomic, strong) UIView *bigView;
@property (nonatomic, strong) UIView *baseView;
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UILabel *replayTitle;
@property (nonatomic, strong) UITextView *replayTextView;
@property (nonatomic, assign) int replayNum;
@property (nonatomic, strong) JXMessageObject *repalyMsg;
@property (nonatomic, strong) NSString *lastMsgInput;
@property (nonatomic, strong) NSString *replayRoomId;

@property (nonatomic, assign) BOOL isEdit;

@end

@implementation JXMsgViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.heightHeader = JX_SCREEN_TOP;
        self.heightFooter = JX_SCREEN_BOTTOM;
        //self.view.frame = CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT-JX_SCREEN_BOTTOM);
        [self createHeadAndFoot];
        [self onLoginChanged:nil];

        _searchArray = [NSMutableArray array];
        _taskArray = [NSMutableArray array];
        
        [self customView];
        [self setupReplayView];
        [g_notify  addObserver:self selector:@selector(allMsgCome) name:kXMPPAllMsgNotifaction object:nil];//收到了所有消息,一次性刷新
        [g_notify  addObserver:self selector:@selector(newMsgCome:) name:kXMPPNewMsgNotifaction object:nil];//收到了一条新消息
        [g_notify  addObserver:self selector:@selector(newMsgSend:) name:kXMPPMyLastSendNotifaction object:nil];//发送了一条消息
        [g_notify addObserver:self selector:@selector(newRequest:) name:kXMPPNewRequestNotifaction object:nil];//收到了一个好友验证类消息
        [g_notify addObserver:self selector:@selector(onLoginChanged:) name:kXmppLoginNotifaction object:nil];//登录状态变化了
        [g_notify addObserver:self selector:@selector(delFriend:) name:kDeleteUserNotifaction object:nil];//删除了一个好友
        [g_notify addObserver:self selector:@selector(onReceiveRoomRemind:) name:kXMPPRoomNotifaction object:nil];//收到了群控制消息
        [g_notify addObserver:self selector:@selector(onQuitRoom:) name:kQuitRoomNotifaction object:nil];//退出了房间
        // 清除全部聊天记录
        [g_notify addObserver:self selector:@selector(delAllChatLogNotifi:) name:kDeleteAllChatLog object:nil];
        [g_notify addObserver:self selector:@selector(chatViewDisappear:) name:kChatViewDisappear object:nil];
        [g_notify addObserver:self selector:@selector(logoutNotifi:) name:kSystemLogoutNotifaction object:nil];
        // 撤回消息
        [g_notify addObserver:self selector:@selector(withdrawNotifi:) name:kXMPPMessageWithdrawNotification object:nil];
        // 更改备注名
        [g_notify addObserver:self selector:@selector(friendRemarkNotif:) name:kFriendRemark object:nil];
        // 进入前台
        [g_notify addObserver:self selector:@selector(appEnterForegroundNotif:) name:kApplicationWillEnterForeground object:nil];
        [g_notify addObserver:self selector:@selector(friendPassNotif:) name:kFriendPassNotif object:nil];
        
        [g_notify addObserver:self selector:@selector(updateRoomHead:) name:@"updateRoomHead" object:nil];

        upOrDown = 0;
    }
    return self;
}


- (void)updateRoomHead:(NSNotification *)notification {
//    NSDictionary *groupDict = notification.object;
//    
//    NSMutableArray *array;
//    if (_seekTextField.text.length > 0) {
//        array = _searchArray;
//    }else {
//        array = _array;
//    }
//    NSString *roomjid = [NSString stringWithFormat:@"%@",[groupDict objectForKey:@"roomJid"]];
//    NSInteger index = 0;
//    for (JXMsgAndUserObject * dict in array) {
//        if ([dict.user.userId intValue] == [roomjid intValue]) {
//            index = [array indexOfObject:dict];
//        }
//    }
//    JXCell *cell = [_table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
//    cell.headImageView.image = [UIImage imageNamed:@"shiku_transfer"];
//
//    [self.tableView reloadData];
}


-(void)dealloc{
    [g_notify removeObserver:self];
    [_array removeAllObjects];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self getServerData];
    
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self getTotalNewMsgCount];
//    [UIView animateWithDuration:0.4 animations:^{
//        self.view.frame = CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT);
//    }];
}

- (void)setupReplayView {
    int height = 44;
    self.bigView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.bigView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    self.bigView.hidden = YES;
    [g_App.window addSubview:self.bigView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyBoard)];
    [self.bigView addGestureRecognizer:tap];
    
    self.baseView = [[UIView alloc] initWithFrame:CGRectMake(40, JX_SCREEN_HEIGHT/4-.5, JX_SCREEN_WIDTH-80, 162.5)];
    self.baseView.backgroundColor = [UIColor whiteColor];
    self.baseView.layer.masksToBounds = YES;
    self. baseView.layer.cornerRadius = 4.0f;
    [self.bigView addSubview:self.baseView];
    int n = 20;
    _replayTitle = [[UILabel alloc] initWithFrame:CGRectMake(INSETS, n, self.baseView.frame.size.width - INSETS*2, 20)];
    _replayTitle.lineBreakMode = NSLineBreakByTruncatingTail;
    _replayTitle.textColor = HEXCOLOR(0x595959);
    _replayTitle.font = SYSFONT(16);
    [self.baseView addSubview:_replayTitle];
    
    n = n + height;
    self.replayTextView = [self createTextField:self.baseView default:nil hint:nil];
    self.replayTextView.backgroundColor = [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1];
    self.replayTextView.frame = CGRectMake(10, n, self.baseView.frame.size.width - INSETS*2, 35.5);
    self.replayTextView.delegate = self;
    self.replayTextView.textColor = HEXCOLOR(0x595959);
    n = n + INSETS + height;
    self.topView = [[UIView alloc] initWithFrame:CGRectMake(0, n, self.baseView.frame.size.width, 44)];
    [self.baseView addSubview:self.topView];
    
    // 两条线
    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.baseView.frame.size.width, 0.5)];
    topLine.backgroundColor = HEXCOLOR(0xD6D6D6);
    [self.topView addSubview:topLine];
    UIView *botLine = [[UIView alloc] initWithFrame:CGRectMake(self.baseView.frame.size.width/2, 0, 0.5, self.topView.frame.size.height)];
    botLine.backgroundColor = HEXCOLOR(0xD6D6D6);
    [self.topView addSubview:botLine];
    
    // 取消
    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(topLine.frame), self.baseView.frame.size.width/2, botLine.frame.size.height)];
    [cancelBtn setTitle:Localized(@"JX_Cencal") forState:UIControlStateNormal];
    [cancelBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [cancelBtn.titleLabel setFont:SYSFONT(15)];
    [cancelBtn addTarget:self action:@selector(hideBigView) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:cancelBtn];
    // 发送
    UIButton *sureBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.baseView.frame.size.width/2, CGRectGetMaxY(topLine.frame), self.baseView.frame.size.width/2, botLine.frame.size.height)];
    [sureBtn setTitle:Localized(@"JX_Send") forState:UIControlStateNormal];
    [sureBtn setTitleColor:HEXCOLOR(0x383893) forState:UIControlStateNormal];
    [sureBtn.titleLabel setFont:SYSFONT(15)];
    [sureBtn addTarget:self action:@selector(onRelease) forControlEvents:UIControlEventTouchUpInside];
    [self.topView addSubview:sureBtn];

}

- (void)hideBigView {
    [self resignKeyBoard];
}

- (void)onRelease {
    [self sendIt];
}

- (void)appEnterForegroundNotif:(NSNotification *)notif {
    
}

- (void)friendPassNotif:(NSNotification *)notif {
    JXFriendObject *user = notif.object;
    [g_server getUser:user.userId toView:self];
}

- (void) customView {
    
//    UIButton * scanButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    scanButton.frame = CGRectMake(8, JX_SCREEN_TOP - 38, 34, 34);
//    [scanButton setImage:[UIImage imageNamed:@"scanicon"] forState:UIControlStateNormal];
//    [scanButton setImage:[UIImage imageNamed:@"scanicon"] forState:UIControlStateHighlighted];
//    [scanButton setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
//    scanButton.custom_acceptEventInterval = 1.0f;
//    [scanButton addTarget:self action:@selector(showScanViewController:) forControlEvents:UIControlEventTouchUpInside];
//    [self.tableHeader addSubview:scanButton];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH - 40-BTN_RANG_UP, JX_SCREEN_TOP - 34-BTN_RANG_UP, 24+BTN_RANG_UP*2, 24+BTN_RANG_UP*2)];
    [btn addTarget:self action:@selector(onMore:) forControlEvents:UIControlEventTouchUpInside];
    [self.tableHeader addSubview:btn];
    
    NSString *image = THESIMPLESTYLE ? @"im_003_more_button_black" : @"im_003_more_button_normal";
    self.moreBtn = [UIFactory createButtonWithImage:image
                                           highlight:nil
                                              target:self
                                            selector:@selector(onMore:)];
    self.moreBtn.custom_acceptEventInterval = 1.0f;
    self.moreBtn.frame = CGRectMake(BTN_RANG_UP, BTN_RANG_UP, 24, 24);
    [btn addSubview:self.moreBtn];
    
    UIColor *curClor = THESIMPLESTYLE ? [UIColor blackColor] : [UIColor whiteColor];
    self.editBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, JX_SCREEN_TOP - 34, 60, 24)];
    [self.editBtn setTitle:@"编辑" forState:UIControlStateNormal];
    [self.editBtn setTitleColor:curClor forState:UIControlStateNormal];
    self.editBtn.titleLabel.font = [UIFont systemFontOfSize:16.0];
    [self.editBtn addTarget:self action:@selector(editBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.tableHeader addSubview:self.editBtn];
    
    self.doneBtn = [[UIButton alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH - 60, JX_SCREEN_TOP - 34, 60, 24)];
    [self.doneBtn setTitle:@"完成" forState:UIControlStateNormal];
    [self.doneBtn setTitleColor:curClor forState:UIControlStateNormal];
    self.doneBtn.titleLabel.font = [UIFont systemFontOfSize:16.0];
    [self.doneBtn addTarget:self action:@selector(doneBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    self.doneBtn.hidden = YES;
    [self.tableHeader addSubview:self.doneBtn];
    
    //搜索输入框
    
    UIView *backView = [[UIView alloc] initWithFrame:CGRectMake(0, JX_SCREEN_TOP, JX_SCREEN_WIDTH, 50)];
//    backView.backgroundColor = HEXCOLOR(0xf0f0f0);
    [self.view addSubview:backView];

    //    [seekImgView release];
    
//    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(backView.frame.size.width-5-45, 5, 45, 30)];
//    [cancelBtn setTitle:Localized(@"JX_Cencal") forState:UIControlStateNormal];
//    [cancelBtn setTitleColor:THEMECOLOR forState:UIControlStateNormal];
//    cancelBtn.custom_acceptEventInterval = .25f;
//    [cancelBtn addTarget:self action:@selector(cancelBtnAction) forControlEvents:UIControlEventTouchUpInside];
//    cancelBtn.titleLabel.font = SYSFONT(14);
//    [backView addSubview:cancelBtn];
    
    
    _seekTextField = [[UITextField alloc] initWithFrame:CGRectMake(15, 10, backView.frame.size.width - 30, 30)];
    _seekTextField.placeholder = [NSString stringWithFormat:@"%@", Localized(@"JX_SearchChatLog")];
    _seekTextField.backgroundColor = HEXCOLOR(0xf0f0f0);
    _seekTextField.textColor = [UIColor blackColor];
    [_seekTextField setFont:SYSFONT(14)];
//    _seekTextField.backgroundColor = [UIColor whiteColor];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_search"]];
    UIView *leftView = [[UIView alloc ]initWithFrame:CGRectMake(0, 0, 30, 30)];
//    imageView.center = CGPointMake(leftView.frame.size.width/2, leftView.frame.size.height/2);
    imageView.center = leftView.center;
    [leftView addSubview:imageView];
    _seekTextField.leftView = leftView;
    _seekTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _seekTextField.leftViewMode = UITextFieldViewModeAlways;
    _seekTextField.borderStyle = UITextBorderStyleNone;
    _seekTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _seekTextField.delegate = self;
    _seekTextField.returnKeyType = UIReturnKeyGoogle;
    [backView addSubview:_seekTextField];
    [_seekTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 49.5, JX_SCREEN_WIDTH, .5)];
    lineView.backgroundColor = HEXCOLOR(0xdcdcdc);
    [backView addSubview:lineView];
    
    self.tableView.tableHeaderView = backView;
    
}

- (void)editBtnAction:(UIButton *)btn {
    
    
    if (_seekTextField.text.length > 0) {
        return;
    }
    
    if (!self.isEdit) {
        self.isEdit = YES;
        self.moreBtn.hidden = YES;
        UIButton *button = (UIButton *)self.moreBtn.superview;
        button.hidden = YES;
        self.doneBtn.hidden = NO;
        [self.editBtn setTitle:@"清空" forState:UIControlStateNormal];
        [self.tableView reloadData];
        
    }else {
        
        [g_App showAlert:@"是否清空列表所有数据？" delegate:self tag:2457 onlyConfirm:NO];
        
    }
    
}

- (void)doneBtnAction:(UIButton *)btn {
    self.isEdit = NO;
    self.moreBtn.hidden = NO;
    UIButton *button = (UIButton *)self.moreBtn.superview;
    button.hidden = NO;
    self.doneBtn.hidden = YES;
    [self.editBtn setTitle:@"编辑" forState:UIControlStateNormal];
    [self.tableView reloadData];
}

- (void)actionTitle:(JXLabel *)sender {
    // 掉线后点击title重连
    if([JXXMPP sharedInstance].isLogined != login_status_yes){
        
        [g_xmpp showXmppOfflineAlert];
        
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:Localized(@"JX_Reconnect") message:nil delegate:self cancelButtonTitle:Localized(@"JX_Cencal") otherButtonTitles:Localized(@"JX_Confirm"), nil];
//        [alert show];
    }
}

// 更改备注名
- (void)friendRemarkNotif:(NSNotification *)notif {
    
    JXUserObject *user = notif.object;
    
    for (int i = 0; i < _array.count; i ++) {
        JXMsgAndUserObject *obj = _array[i];
        if ([obj.user.userId isEqualToString:user.userId]) {
            obj.user.remarkName = user.remarkName;
            [_table reloadRow:i section:0];
            break;
        }
    }
}

// 消息撤回
- (void)withdrawNotifi:(NSNotification *) notif {
    JXMessageObject *msg = notif.object;
    
    for(NSInteger i=[_array count]-1;i>=0;i--){
        JXMsgAndUserObject *p=[_array objectAtIndex:i];
        if([p.user.userId isEqualToString:msg.fromUserId] && [p.message.messageId isEqualToString:msg.content]){//如果找到被撤回的那条消息
            int n = [p.user.msgsNew intValue];
            n--;
            if(n<0)
                n = 0;
            if(! [p.message queryIsRead] ){//如果未读
                p.user.msgsNew = [NSNumber numberWithInt:n];//未读数量减1
                [msg updateLastSend:UpdateLastSendType_Dec];
            }
            break;
        }
        p =nil;
    }
    [self doRefresh:msg showNumber:YES];
}

- (void) textFieldDidChange:(UITextField *)textField {
    
    [self doneBtnAction:self.doneBtn];
    
    if (textField.text.length <= 0) {
        [self getServerData];
        return;
    }
    
    [_searchArray removeAllObjects];
    for (NSInteger i = 0; i < _array.count; i ++) {
        
        NSMutableArray *arr = [_array mutableCopy];
        JXMsgAndUserObject *obj = arr[i];
        
        NSArray * resultArray = [obj.message fetchSearchMessageWithUserId:obj.user.userId String:textField.text];
        
        for (JXMessageObject *msg in resultArray) {
            if(msg.content.length > 0) {
                JXMsgAndUserObject *searchObj = [[JXMsgAndUserObject alloc] init];
                searchObj.user = obj.user;
                searchObj.message = msg;
                [_searchArray addObject:searchObj];
            }
        }
    }
    [self.tableView reloadData];
    [self getTotalNewMsgCount];
}

#pragma mark 右上角更多
-(void)onMore:(UIButton *)sender{
    //    _control.hidden = YES;
//    UIWindow *window = [[UIApplication sharedApplication].delegate window];
//    CGRect moreFrame = [self.tableHeader convertRect:self.moreBtn.frame toView:window];

    NSMutableArray *titles = [NSMutableArray arrayWithArray:@[Localized(@"JX_LaunchGroupChat"),Localized(@"JX_FaceToFaceGroup"), Localized(@"JX_AddFriends"), Localized(@"JX_Scan"), Localized(@"JXNearVC_NearPer"),Localized(@"JX_Receiving"),Localized(@"JX_SearchPublicNumber")]];
    NSMutableArray *images = [NSMutableArray arrayWithArray:@[@"message_creat_group_black", @"message_face_group", @"message_add_friend_black", @"messaeg_scnning_black", @"message_near_person_black",@"message_near_receiving",@"message_search_publicNumber"]];
    NSMutableArray *sels = [NSMutableArray arrayWithArray:@[@"onNewRoom", @"onFaceCreateRoom", @"onSearch", @"showScanViewController", @"onNear",@"onReceiving",@"searchPublicNumber"]];
    NSArray *role = MY_USER_ROLE;
    if ([g_App.config.hideSearchByFriends intValue] == 1 && ([g_App.config.isCommonFindFriends intValue] == 0 || role.count > 0)) {
    }else {
        [titles removeObject:Localized(@"JX_AddFriends")];
        [images removeObject:@"message_add_friend_black"];
        [sels removeObject:@"onSearch"];
    }
    if ([g_App.config.isCommonCreateGroup intValue] == 1 && role.count <= 0) {
        [titles removeObject:Localized(@"JX_LaunchGroupChat")];
        [images removeObject:@"message_creat_group_black"];
        [sels removeObject:@"onNewRoom"];
    }
    if ([g_App.config.isOpenPositionService intValue] == 1) {
        [titles removeObject:Localized(@"JXNearVC_NearPer")];
        [images removeObject:@"message_near_person_black"];
        [sels removeObject:@"onNear"];
    }
    if ([g_App.isShowRedPacket intValue] == 0) {
        [titles removeObject:Localized(@"JX_Receiving")];
        [images removeObject:@"message_near_receiving"];
        [sels removeObject:@"onReceiving"];
    }

    JX_SelectMenuView *menuView = [[JX_SelectMenuView alloc] initWithTitle:titles image:images cellHeight:45];
    menuView.sels = sels;
    menuView.delegate = self;
    [g_App.window addSubview:menuView];
//    JX_DownListView * downListView = [[JX_DownListView alloc] initWithFrame:self.view.bounds];
//    downListView.listContents = @[Localized(@"JX_LaunchGroupChat"), Localized(@"JX_AddFriends"), Localized(@"JX_Scan"), Localized(@"JXNearVC_NearPer")];
//    downListView.listImages = @[@"message_creat_group_black", @"message_add_friend_black", @"messaeg_scnning_black", @"message_near_person_black"];
//
//    __weak typeof(self) weakSelf = self;
//    [downListView downlistPopOption:^(NSInteger index, NSString *content) {
//
//        [weakSelf moreListActionWithIndex:index];
//
//    } whichFrame:moreFrame animate:YES];
//    [downListView show];
    
    //    self.treeView.editing = !self.treeView.editing;
}

- (void)didMenuView:(JX_SelectMenuView *)MenuView WithIndex:(NSInteger)index {
    
    NSString *method = MenuView.sels[index];
    SEL _selector = NSSelectorFromString(method);
    [self performSelectorOnMainThread:_selector withObject:nil waitUntilDone:YES];
//    return;
//
//    NSArray *role = MY_USER_ROLE;
//    // 显示搜索好友
//    BOOL isShowSearch = [g_App.config.hideSearchByFriends boolValue] && (![g_App.config.isCommonFindFriends boolValue] || role.count > 0);
//    //显示创建房间
//    BOOL isShowRoom = [g_App.config.isCommonCreateGroup intValue] == 0 || role.count > 0;
//    //显示附近的人
//    BOOL isShowPosition = [g_App.config.isOpenPositionService intValue] == 0;
//    switch (index) {
//        case 0:
//            if (isShowRoom) {
//                [self onNewRoom];
//            }else {
//                if (isShowSearch) {
//                    [self onSearch];
//                }else {
//                    [self showScanViewController];
//                }
//            }
//            break;
//        case 1:
//            if (isShowRoom && isShowSearch) {
//                [self onSearch];
//            }else {
//                if ((isShowRoom && !isShowSearch) || (!isShowRoom && isShowSearch)) {
//                    [self showScanViewController];
//                }else if (!isShowRoom && !isShowSearch) {
//                    if (isShowPosition) {
//                        [self onNear];
//                    }else {
//                        [self searchPublicNumber];
//                    }
//                }
//            }
//            break;
//        case 2:
//            if (isShowSearch && isShowRoom) {
//                [self showScanViewController];
//            }else {
//                if ((isShowRoom && !isShowSearch) || (!isShowRoom && isShowSearch)) {
//                    if (isShowPosition) {
//                        [self onNear];
//                    }else {
//                        [self searchPublicNumber];
//                    }
//                }
//            }
//            break;
//        case 3:
//            if (isShowPosition) {
//                [self onNear];
//            }else {
//                [self searchPublicNumber];
//            }
//            break;
//        case 4:
//            [self searchPublicNumber];
//            break;
//        default:
//            break;
//    }
}



- (void) moreListActionWithIndex:(NSInteger)index {
    
    switch (index) {
        case 0:
            [self onNewRoom];
            break;
        case 1:
            [self onSearch];
            break;
        case 2:
            [self showScanViewController];
            break;
        case 3:
            [self onNear];
            break;
        default:
            break;
    }
}

// 搜索公众号
- (void)searchPublicNumber {
    JXSearchUserVC *searchUserVC = [JXSearchUserVC alloc];
    searchUserVC.type = JXSearchTypePublicNumber;
    searchUserVC = [searchUserVC init];
    [g_navigation pushViewController:searchUserVC animated:YES];
}

// 创建群组
-(void)onNewRoom{
    JXNewRoomVC* vc = [[JXNewRoomVC alloc]init];
    [g_navigation pushViewController:vc animated:YES];
}

// 面对面建群
- (void)onFaceCreateRoom {
    
    JXFaceCreateRoomVC *vc = [[JXFaceCreateRoomVC alloc] init];
    [g_navigation pushViewController:vc animated:YES];
}

// 附近的人
-(void)onNear{
    JXNearVC * nearVc = [[JXNearVC alloc] init];
    [g_navigation pushViewController:nearVc animated:YES];
}
// 收付款
- (void)onReceiving {
    JXPayViewController *payVC = [[JXPayViewController alloc] init];
    [g_navigation pushViewController:payVC animated:YES];
}

- (void) cancelBtnAction {
    if (_seekTextField.text.length > 0) {
        _seekTextField.text = nil;
        [self getServerData];
    }
    [_seekTextField resignFirstResponder];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        
        if (alertView.tag == 2457) {
            for (NSInteger i = 0; i < _array.count; i ++) {
                JXMsgAndUserObject *p=[_array objectAtIndex:i];
                if (![p.user.userId isEqualToString:FRIEND_CENTER_USERID]) {
                    self.msgTotal -= [p.user.msgsNew intValue];
                }
                
                p.user.topTime = nil;
                if (_topNum > 0)
                    _topNum --;
                
                [p.user updateTopTime];
                
                [p.user reset];
                [p.message deleteAll];
                p =nil;
                
                _refreshCount++;
            }
            
            [_array removeAllObjects];
            
            [g_notify postNotificationName:kFriendListRefresh object:nil];
            [self getTotalNewMsgCount];
            
            [self getServerData];
            
        }else {
            [[JXXMPP sharedInstance] login];
        }
        
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) delAllChatLogNotifi:(NSNotification *)notif {
    [self getServerData];
    self.msgTotal = 0;
}


#pragma mark   ---------tableView协议----------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* cellName = [NSString stringWithFormat:@"msg"];
    
    JXCell *cell = [tableView dequeueReusableCellWithIdentifier:cellName];
    NSMutableArray *array;
    if (_seekTextField.text.length > 0) {
        array = _searchArray;
    }else {
        array = _array;
    }
    JXMsgAndUserObject * dict = (JXMsgAndUserObject*) [array objectAtIndex:indexPath.row];
    
    if(cell==nil){
        cell = [[JXCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellName];;
        [_table addToPool:cell];
    }
    cell.delegate = self;
    cell.didTouch = @selector(onHeadImage:);
    cell.didDragout=@selector(onDrag:);
    cell.didReplay = @selector(onReplay:);
    cell.didDelMsg = @selector(onDelMsg:);
    //    [cell msgCellDataSet:dict indexPath:indexPath];
    cell.title = dict.user.remarkName.length > 0 ? dict.user.remarkName : dict.user.userNickname;
    
    cell.user = dict.user;
    cell.userId = dict.user.userId;
    cell.bage = [NSString stringWithFormat:@"%d",[dict.user.msgsNew intValue]];
    cell.isMsgVCCome = YES;
    cell.index = (int)indexPath.row;
    cell.bottomTitle  = [TimeUtil getTimeStrStyle1:[dict.message.timeSend timeIntervalSince1970]];
    
    cell.headImageView.tag = (int)indexPath.row;
    cell.headImageView.delegate = cell.delegate;
    cell.headImageView.didTouch = cell.didTouch;
    
    [cell.lbTitle setText:cell.title];
    cell.lbTitle.tag = cell.index;
    cell.isNotPush = [dict.user.offlineNoPushMsg boolValue];
    NSString *lastContet = [dict.message getLastContent];
    BOOL flag = NO;
    if ([dict.user.isAtMe intValue] == 1 && _seekTextField.text.length <= 0 && (dict.user.roomFlag || dict.user.roomId.length > 0)) {
        lastContet = [NSString stringWithFormat:@"%@%@",Localized(@"JX_Someone@Me"),[dict.message getLastContent]];
        flag = YES;
    }
    
    if(dict.user.lastInput.length > 0 && _seekTextField.text.length <= 0) {
        lastContet = [NSString stringWithFormat:@"%@%@",Localized(@"JX_Draft"),dict.user.lastInput];
        flag = YES;
//        NSString *str = Localized(@"JX_Draft");
//        NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@",str, dict.user.lastInput]];
//        NSRange range = [[NSString stringWithFormat:@"%@%@",str, dict.user.lastInput] rangeOfString:str];
//        [attr addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:range];
//        cell.lbSubTitle.attributedText = attr;
        
    }
    
    if ([dict.message.type intValue] == kWCMessageTypeText || flag) {

        [cell setSubtitle:lastContet];
    }else {
        cell.lbSubTitle.text = lastContet;
    }
    
    [cell.timeLabel setText:cell.bottomTitle];
    cell.bageNumber.delegate = cell.delegate;
    cell.bageNumber.didDragout = cell.didDragout;
    cell.bage = cell.bage;
    if ([dict.user.userId isEqualToString:FRIEND_CENTER_USERID]) {
        cell.bageNumber.lb.hidden = YES;
        CGRect frame = cell.bageNumber.frame;
        frame.size = CGSizeMake(10, 10);
        cell.bageNumber.frame = frame;
    }else {
        cell.bageNumber.lb.hidden = NO;
        CGRect frame = cell.bageNumber.frame;
        frame.size = CGSizeMake(20, 20);
        cell.bageNumber.frame = frame;
    }
    NSString * roomIdStr = dict.user.roomId;
    cell.roomId = roomIdStr;
    [cell headImageViewImageWithUserId:dict.user.userId roomId:roomIdStr];
    cell.isEdit = self.isEdit;
    cell.isSmall = NO;
    [self doAutoScroll:indexPath];
    //    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (dict.user.topTime) {
        cell.contentView.backgroundColor = HEXCOLOR(0xF0F1F2);
    }else {
        cell.contentView.backgroundColor = [UIColor whiteColor];
    }
    
    return cell;
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_seekTextField.text.length > 0) {
        return _searchArray.count;
    }
    return _array.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

#pragma mark  接受新消息广播
-(void)newMsgCome:(NSNotification *)notifacation
{
    JXMessageObject *msg = notifacation.object;
    if(msg==nil)
        return;
    BOOL showNumber=YES;

#ifdef Live_Version
    if([[JXLiveJidManager shareArray] contains:msg.toUserId] || [[JXLiveJidManager shareArray] contains:msg.fromUserId])
        return;
#endif
    
    if([msg.toUserId isEqualToString:MY_USER_ID]){
        if([msg.type intValue] == kWCMessageTypeAudioMeetingInvite || [msg.type intValue] == kWCMessageTypeVideoMeetingInvite)
            showNumber = NO;//一律不提醒
    }
    if(!msg.isVisible && ![msg isAddFriendMsg])
        return;
    if (!_audioPlayer) {
        _audioPlayer = [[JXAudioPlayer alloc]init];
    }
    
    _audioPlayer.isOpenProximityMonitoring = NO;
    NSString *userId = nil;
    if (msg.isGroup) {
        userId = msg.toUserId;
    }else {
        userId = msg.fromUserId;
    }
    
    JXUserObject *user = [[JXUserObject sharedInstance] getUserById:userId];
    
    
    if (msg.isGroup && msg.isDelay) {
        
        NSLog(@"msg --- %@",msg.content);
        // 更新任务endTime
        for (NSInteger i = 0; i < _taskArray.count; i ++) {
            NSDictionary *taskDic = _taskArray[i];
            if ([user.userId isEqualToString:taskDic[@"userId"]]) {
                NSDate *startTime = taskDic[@"startTime"];
                if ([msg.timeSend timeIntervalSince1970] <= [startTime timeIntervalSince1970]) {
                    [_taskArray removeObjectAtIndex:i];
                    break;
                }
                if (![taskDic objectForKey:@"endTime"]) {
                    [taskDic setValue:msg.timeSend forKey:@"endTime"];
                    [taskDic setValue:msg.messageId forKey:@"endMsgId"];
                    
                    [self createSynTask:taskDic];
                    
                    [g_notify postNotificationName:kUpdateMsgSynTask object:user.userId];
                }
                break;
            }
        }
        
    }
    
    if(msg.isRepeat){
        return;
    }
    
    if(![msg.fromUserId isEqualToString:MY_USER_ID] && !_audioPlayer.isPlaying && ![userId isEqualToString:current_chat_userId] && [user.offlineNoPushMsg intValue] != 1){
        _audioPlayer.audioFile = [imageFilePath stringByAppendingPathComponent:@"newmsg.mp3"];
        _audioPlayer.isNotStopLast = YES;
        [_audioPlayer open];
        [_audioPlayer play];
        if ([g_myself.isVibration intValue] > 0) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        }
    }
    if (![msg.fromUserId isEqualToString:MY_USER_ID] && ![userId isEqualToString:current_chat_userId]) {
        
        if (msg.isGroup && msg.isAtMe) {
            JXUserObject *user = [[JXUserObject alloc] init];
            user.userId = [msg getTableName];
            user.isAtMe = [NSNumber numberWithInt:1];
            [user updateIsAtMe];
        }
        
    }

    //[self doRefresh:msg showNumber:showNumber];
    msg = nil;
}

- (void)createSynTask:(NSDictionary *)dict{
    JXSynTask *task = [[JXSynTask alloc] init];
    task.userId = dict[@"userId"];
    task.roomId = dict[@"roomId"];
    task.startTime = dict[@"startTime"];
    task.endTime = dict[@"endTime"];
    task.lastTime = dict[@"lastTime"];
    task.startMsgId = dict[@"startMsgId"];
    task.endMsgId = dict[@"endMsgId"];
    [task insert];
}

-(void)newMsgSend:(NSNotification *)notifacation
{
    JXMessageObject *msg = notifacation.object;
    if(!msg.isVisible && ![msg isAddFriendMsg])
        return;
    if ([msg.type intValue] == kWCMessageTypeWithdraw) {
        msg.content = Localized(@"JX_AlreadyWithdraw");
    }
    [self doRefresh:msg showNumber:NO];
    msg = nil;
}

-(void)newRequest:(NSNotification *)notifacation
{
    JXFriendObject * friend = (JXFriendObject*) notifacation.object;
    friend = nil;
}

#pragma --------------------新来的消息Badge计算---------------
-(void)doRefresh:(JXMessageObject*)msg showNumber:(BOOL)showNumber{
    NSString* s;
    s = [msg getTableName];
    
    if([s isEqualToString:FRIEND_CENTER_USERID])//假如是朋友验证消息，过滤
        return;
    
    JXMsgAndUserObject *oldobj=nil;
    for(int i=0;i<[_array count];i++){
        oldobj=[_array objectAtIndex:i];
        if([oldobj.user.userId isEqualToString:s]){
            oldobj.message.content = [msg getLastContent];
            oldobj.message.type = msg.type;
            oldobj.message.timeSend = msg.timeSend;
            if([current_chat_userId isEqualToString:s] || msg.isMySend || !showNumber){//假如是我发送的，或正在这个界面，或不显示数量时
                if([current_chat_userId isEqualToString:s])//正在聊天时，置0;是我发送的消息时，不变化数量
                    oldobj.user.msgsNew = [NSNumber numberWithInt:0];
            }
            else{
                if ([msg.content rangeOfString:Localized(@"JX_OtherWithdraw")].location == NSNotFound) {
                    oldobj.user.msgsNew = [NSNumber numberWithInt:[oldobj.user.msgsNew intValue]+1];
                }
                
            }
            [_array removeObjectAtIndex:i];
            break;
        }
        oldobj = nil;
    }
    NSString *userId = nil;
    if (msg.isGroup) {
        userId = msg.toUserId;
    }else {
        userId = msg.fromUserId;
    }
    
    if(oldobj){//列表中有此用户：
        
        if (![msg.fromUserId isEqualToString:MY_USER_ID] && ![userId isEqualToString:current_chat_userId]) {
            
            if (msg.isGroup && msg.isAtMe) {
                oldobj.user.isAtMe = [NSNumber numberWithInt:1];
                [oldobj.user updateIsAtMe];
            }
            
        }
        
        if (oldobj.user.topTime) {
            oldobj.user.topTime = [NSDate date];
            [oldobj.user updateTopTime];
            [_array insertObject:oldobj atIndex:0];
        }else if(oldobj.user){
            
            [_array insertObject:oldobj atIndex:_topNum];
        }
        
        _refreshCount++;
        [_table reloadData];
    }else{
        //列表中没有此用户：
        JXMsgAndUserObject* newobj = [[JXMsgAndUserObject alloc]init];
        newobj.user = [[JXUserObject sharedInstance] getUserById:s];
        newobj.message = [msg copy];
        if([current_chat_userId isEqualToString:s] || msg.isMySend || !showNumber){//假如是我发送的，或正在这个界面，或不显示数量时
            if([current_chat_userId isEqualToString:s])//正在聊天时，置0;是我发送的消息时，不变化数量
                newobj.user.msgsNew = [NSNumber numberWithInt:0];
        }
        else
            if([s isEqualToString:FRIEND_CENTER_USERID])//假如是朋友验证消息，总为1
                return;
//                newobj.user.msgsNew = [NSNumber numberWithInt:1];
            else{
                newobj.user.msgsNew = [NSNumber numberWithInt:[newobj.user.msgsNew intValue]];
                if (msg.isGroup && msg.isAtMe) {
                    newobj.user.isAtMe = [NSNumber numberWithInt:1];
                    [newobj.user updateIsAtMe];
                }
            }
        
        if (newobj.user) {
            [_array insertObject:newobj atIndex:_topNum];
            
            NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_topNum inSection:0];
            [indexPaths addObject:indexPath];
            
            [_table beginUpdates];
            [_table insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
            [_table endUpdates];
            [_table gotoFirstRow:YES];
        }
        
        newobj = nil;
    }
    if(msg.isMySend || !showNumber)
        return;
    else
        [self getTotalNewMsgCount];
}

-(void)getServerData
{
    [self stopLoading];
    
    if(_array==nil || _page == 0){
//        NSLog(@"%d",[[_array objectAtIndex:0] retainCount]);
        [_array removeAllObjects];
//        [_array release];
        _array = [[NSMutableArray alloc]init];
        _refreshCount++;
    }
    //访问DB获取好友消息列表
    NSMutableArray* p = [[JXMessageObject sharedInstance] fetchRecentChat];
    
//    // 查出置顶个数
//    for (NSInteger i = 0; i < p.count; i ++) {
//        JXMsgAndUserObject * obj = (JXMsgAndUserObject*) [p objectAtIndex:i];
//
//        if (obj.user.topTime) {
//            _topNum ++;
//        }
//    }
    
    //    if (p.count>0 || _page == 0) {
    if (p.count>0) {
        [_array addObjectsFromArray:p];
        //让数组按时间排序
//        [self sortArrayWithTime];
        [_table hideEmptyImage];
        [_table reloadData];
        self.isShowFooterPull = NO;
    }
    
    if (_array.count <=0) {
        [_table showEmptyImage:EmptyTypeNoData];
        [_table reloadData];
    }
    
    [self getTotalNewMsgCount];
    
    [p removeAllObjects];
}



//数据（CELL）按时间顺序重新排列
- (void)sortArrayWithTime{

    for (int i = 0; i<[_array count]; i++)
    {
        
        for (int j=i+1; j<[_array count]; j++)
        {
            JXMsgAndUserObject * dicta = (JXMsgAndUserObject*) [_array objectAtIndex:i];
            NSDate * a = dicta.message.timeSend ;
//            NSLog(@"a = %d",[dicta.user.msgsNew intValue]);
            JXMsgAndUserObject * dictb = (JXMsgAndUserObject*) [_array objectAtIndex:j];
            NSDate * b = dictb.message.timeSend ;
            //                NSLog(@"b = %d",b);
            
            if ([[a laterDate:b] isEqualToDate:b])
            {
//                - (NSDate *)earlierDate:(NSDate *)anotherDate;
//                与anotherDate比较，返回较早的那个日期
//
//                - (NSDate *)laterDate:(NSDate *)anotherDate;
//                与anotherDate比较，返回较晚的那个日期
//                JXMsgAndUserObject * dictc = dicta;
                
                [_array replaceObjectAtIndex:i withObject:dictb];
                [_array replaceObjectAtIndex:j withObject:dicta];
            }
            
        }
        
    }
    
}


//-(void)afterDalay{
//    _dalayAction = NO;
//}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{   [super tableView:tableView didSelectRowAtIndexPath:indexPath];
//    NSLog(@"didSelectRowAtIndexPath.begin");
//    if (_dalayAction) {
//        return;
//    }else{
//        _dalayAction = YES;
//        [self performSelector:@selector(afterDalay) withObject:nil afterDelay:0.5];
//    }

    [self doneBtnAction:self.doneBtn];
    
    JXCell* cell = (JXCell*)[tableView cellForRowAtIndexPath:indexPath];
    
    cell.selected = NO;
    
    //清除badge
    cell.bage = @"0";
    NSMutableArray *array;
    if (_seekTextField.text.length > 0) {
        array = _searchArray;
    }else {
        array = _array;
    }
    JXMsgAndUserObject *p=[array objectAtIndex:indexPath.row];
    if (![p.user.userId isEqualToString:FRIEND_CENTER_USERID]) {
        self.msgTotal -= [cell.bage intValue];
    }
    [UIApplication sharedApplication].applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber - [p.user.msgsNew intValue];
//    [g_server userChangeMsgNum:[UIApplication sharedApplication].applicationIconBadgeNumber toView:self];
    
    int lineNum = 0;
    if (_seekTextField.text.length > 0) {
        lineNum = [p.message getLineNumWithUserId:p.user.userId];
    }
    
    if([p.user.userId isEqualToString:FRIEND_CENTER_USERID]){
        JXNewFriendViewController* vc = [[JXNewFriendViewController alloc]init];
//        [g_App.window addSubview:vc.view];
        [g_navigation pushViewController:vc animated:YES];
        return;
    }
    if ([p.user.userId intValue] == [SHIKU_TRANSFER intValue]) {
        JXTransferNoticeVC *noticeVC = [[JXTransferNoticeVC alloc] init];
        [g_navigation pushViewController:noticeVC animated:YES];
        p.user.msgsNew = [NSNumber numberWithInt:0];
        [p.message updateNewMsgsTo0];
        [self getTotalNewMsgCount];
        return;
    }
    
    JXChatViewController *sendView=[JXChatViewController alloc];
    
    sendView.scrollLine = lineNum;
    sendView.title = p.user.remarkName.length > 0 ? p.user.remarkName : p.user.userNickname;
    if([p.user.roomFlag intValue] > 0 || p.user.roomId.length > 0){
//        if(g_xmpp.isLogined != 1){
//            // 掉线后点击title重连
//            [g_xmpp showXmppOfflineAlert];
//            return;
//        }
        
        sendView.roomJid = p.user.userId;
        sendView.roomId   = p.user.roomId;
        sendView.groupStatus = p.user.groupStatus;
        if ([p.user.groupStatus intValue] == 0) {
            
            sendView.chatRoom  = [[JXXMPP sharedInstance].roomPool joinRoom:p.user.userId title:p.user.userNickname isNew:NO];
        }
        
        if (p.user.roomFlag || p.user.roomId.length > 0) {
            NSDictionary * groupDict = [p.user toDictionary];
            roomData * roomdata = [[roomData alloc] init];
            [roomdata getDataFromDict:groupDict];
            sendView.room = roomdata;
            sendView.newMsgCount = [p.user.msgsNew intValue];
            
            
            p.user.isAtMe = [NSNumber numberWithInt:0];
            [p.user updateIsAtMe];
        }
        
    }
    sendView.rowIndex = indexPath.row;
    sendView.lastMsg = p.message;
    sendView.chatPerson = p.user;
    sendView = [sendView init];
//    [g_App.window addSubview:sendView.view];
    [g_navigation pushViewController:sendView animated:YES];
    sendView.view.hidden = NO;
    
    p.user.msgsNew = [NSNumber numberWithInt:0];
    [p.message updateNewMsgsTo0];
    
    [self cancelBtnAction];
    
    [self getTotalNewMsgCount];
}

-(void)onLoginChanged:(NSNotification *)notifacation{
    
    if (!_activity) {
        _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self.tableHeader addSubview:_activity];
    }
    
    switch ([JXXMPP sharedInstance].isLogined){
        case login_status_ing:{
            self.title = Localized(@"JXMsgViewController_GoingOff");
            CGSize size = [self.title boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:18.0]} context:nil].size;
            _activity.frame = CGRectMake(JX_SCREEN_WIDTH / 2 + size.width / 2 + 10, JX_SCREEN_TOP - 32, 20, 20);
            
            [_activity startAnimating];
        }
            break;
        case login_status_no:{
            self.title = Localized(@"JXMsgViewController_OffLine");
            if (g_xmpp.isPasswordError) {
                self.title = [NSString stringWithFormat:@"%@(%@)",Localized(@"JXMainViewController_Message"),Localized(@"JX_PasswordError")];
            }
            [_activity stopAnimating];
        }
            break;
        case login_status_yes:{
            self.title = Localized(@"JXMsgViewController_OnLine");
            // 同步最近一条聊天记录
            [self getLastChatList];
            [_activity stopAnimating];
        }

            break;
    }
}

- (void)getLastChatList {
    
    BOOL isFirstSync = [g_default boolForKey:kISFirstGetLastChatList];
    
    long long syncTimeLen;
    
    
    if (!isFirstSync) {
//        if ([g_myself.chatSyncTimeLen longLongValue] > [g_myself.groupChatSyncTimeLen longLongValue]) {
            syncTimeLen = [g_myself.chatSyncTimeLen longLongValue];
//        }else {
//            syncTimeLen = [g_myself.groupChatSyncTimeLen longLongValue];
//        }
        
        double m = syncTimeLen * 24 * 3600;
        syncTimeLen = [[NSDate date] timeIntervalSince1970] - m;
        
        if ([g_myself.chatSyncTimeLen longLongValue] == 0 || [g_myself.chatSyncTimeLen longLongValue] == -1) {
            syncTimeLen = 0;
        }
        
        [g_default setBool:YES forKey:kISFirstGetLastChatList];
        
    }else {
        syncTimeLen = g_server.lastOfflineTime;
    }
    
    if ([g_myself.chatSyncTimeLen longLongValue] == -2) {
        
        [g_xmpp.roomPool createAll];
        
    }else {
        [g_server getLastChatListStartTime:[NSNumber numberWithLong:syncTimeLen - 30] toView:self];
    }
    
}

//对选中的Cell根据editingStyle进行操作
- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_seekTextField.text.length > 0) {
        return;
    }
    
    JXMsgAndUserObject *p=[_array objectAtIndex:indexPath.row];
    if (![p.user.userId isEqualToString:FRIEND_CENTER_USERID]) {
        self.msgTotal -= [p.user.msgsNew intValue];
    }

    [p.user reset];
    [p.message deleteAll];
    p =nil;
    
    [_array removeObjectAtIndex:indexPath.row];
    _refreshCount++;
    [_table reloadData];
    [self getTotalNewMsgCount];
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    JXMsgAndUserObject *p=[_array objectAtIndex:indexPath.row];
    UITableViewRowAction *readBtn = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:[p.user.msgsNew intValue] > 0 ? Localized(@"JX_MsgMarkedRead") : Localized(@"JX_MsgMarkedUnread") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        JXCell* cell = (JXCell*)[tableView cellForRowAtIndexPath:indexPath];
        
        if ([p.user.msgsNew intValue] > 0) {
            //清除badge
            cell.bage = @"0";
            p.user.msgsNew = @0;
            if (![p.user.userId isEqualToString:FRIEND_CENTER_USERID]) {
                self.msgTotal -= [cell.bage intValue];
            }
            p.user.msgsNew = [NSNumber numberWithInt:0];
            [p.message updateNewMsgsTo0];
        }else {
            cell.bage = @"1";
            p.user.msgsNew = @1;
            [p.user updateNewMsgNum];
        }
        [UIApplication sharedApplication].applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber - [p.user.msgsNew intValue];
//        [g_server userChangeMsgNum:[UIApplication sharedApplication].applicationIconBadgeNumber toView:self];

        [self getTotalNewMsgCount];
    }];
    
    readBtn.backgroundColor = [UIColor orangeColor];

    UITableViewRowAction *delBtn = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:Localized(@"JX_Delete") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        if (_seekTextField.text.length > 0) {
            return;
        }
        
        JXMsgAndUserObject *p=[_array objectAtIndex:indexPath.row];
        if (![p.user.userId isEqualToString:FRIEND_CENTER_USERID]) {
            self.msgTotal -= [p.user.msgsNew intValue];
        }
        
        p.user.topTime = nil;
        if (_topNum > 0)
            _topNum --;
        
        [p.user updateTopTime];
        
        [p.user reset];
        [g_notify postNotificationName:kFriendListRefresh object:nil];
        [p.message deleteAll];
        p =nil;
        
        [_array removeObjectAtIndex:indexPath.row];
        _refreshCount++;
        [_table reloadData];
        [self getTotalNewMsgCount];
        
    }];
    
    NSString *str;
    if (p.user.topTime) {
        str = Localized(@"JX_CancelTop");
    }else {
        str = Localized(@"JX_Top");
    }
    
    UITableViewRowAction *topBtn = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:str handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        [_array removeObject:p];
        if (p.user.topTime) {
            p.user.topTime = nil;
            if (_topNum > 0)
                _topNum --;
            
            [_array insertObject:p atIndex:_topNum];
        }else {
            p.user.topTime = [NSDate date];
            _topNum ++;
            [_array insertObject:p atIndex:0];
        }
        
        [p.user updateTopTime];
        
        [_table reloadData];
    }];
    
    return @[delBtn, readBtn, topBtn];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (_seekTextField.text.length > 0) {
        return NO;
    }
    
    //将“新的消息”及“系统消息”设为不可编辑
    JXMsgAndUserObject *p=[_array objectAtIndex:indexPath.row];
    long n = [p.user.userId intValue];

    if(n == [FRIEND_CENTER_USERID intValue])
        return NO;
    if(n == BLOG_CENTER_INT)
        return NO;
//    if(n == CALL_CENTER_INT)
//        return NO;

    return YES;
}

-(void)delFriend:(NSNotification *)notifacation
{
//    NSLog(@"delFriend.notify");
    JXUserObject* user = (JXUserObject *)notifacation.object;
    NSString* userId = user.userId;
    if(userId==nil)
        return;

    for(NSInteger i=[_array count]-1;i>=0;i--){
        JXMsgAndUserObject *p=[_array objectAtIndex:i];
        if([p.user.userId isEqualToString:userId]){
            [_array removeObjectAtIndex:i];
            break;
        }
        p =nil;
    }
    
    _refreshCount++;
    [_table reloadData];
    [self getTotalNewMsgCount];
}

- (void)onDelMsg:(JXCell *)cell {
    if (_seekTextField.text.length > 0) {
        return;
    }
    
    JXMsgAndUserObject *p=[_array objectAtIndex:cell.index];
    if (![p.user.userId isEqualToString:FRIEND_CENTER_USERID]) {
        self.msgTotal -= [p.user.msgsNew intValue];
    }
    
    p.user.topTime = nil;
    if (_topNum > 0)
        _topNum --;
    
    [p.user updateTopTime];
    
    [p.user reset];
    [g_notify postNotificationName:kFriendListRefresh object:nil];
    [p.message deleteAll];
    p =nil;
    
    [_array removeObjectAtIndex:cell.index];
    _refreshCount++;
    [self getTotalNewMsgCount];
    
    [self getServerData];
}

- (void)onReplay:(JXCell *)cell {
    
    self.replayNum = cell.index;
    
    NSMutableArray *array;
    if (_seekTextField.text.length > 0) {
        array = _searchArray;
    }else {
        array = _array;
    }
    JXMsgAndUserObject * dict = (JXMsgAndUserObject*) [array objectAtIndex:self.replayNum];
    
    if ([dict.user.userId isEqualToString:SHIKU_TRANSFER]) {
        return;
    }
    
    if (dict.user.roomId.length > 0) {
        self.replayRoomId = dict.user.roomId;
        [g_server roomGetRoom:self.replayRoomId toView:self];
    }else {
        [self showReplayView];
    }
}

- (void)showReplayView {
    NSMutableArray *array;
    if (_seekTextField.text.length > 0) {
        array = _searchArray;
    }else {
        array = _array;
    }
    JXMsgAndUserObject * dict = (JXMsgAndUserObject*) [array objectAtIndex:self.replayNum];
    JXUserObject *user = [[JXUserObject alloc] init];
    user = dict.user;
    if ([user.groupStatus intValue] == 1) {
        [g_App showAlert:Localized(@"JX_OutOfTheGroup1")];
        return;
    }
    if (self.replayTextView.text.length > 0) {
        self.replayTextView.text = nil;
    }
    self.bigView.hidden = NO;
    [self.replayTextView becomeFirstResponder];
    
    self.replayTitle.text = [NSString stringWithFormat:@"%@ : %@",Localized(@"JX_MsgTheQuickReply"),user.userNickname];
    self.lastMsgInput = [dict.message getLastContent]; // 记录最后一条消息
    
    self.replayTextView.textColor = [UIColor lightGrayColor];
    self.replayTextView.text = self.lastMsgInput;
    self.replayTextView.selectedRange = NSMakeRange(0, 0);
    // 加载水印时调用textViewDidChange 高度自适应
    [self textViewDidChange:self.replayTextView];
    // 防止出现特殊符号自动换行问题
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
    NSDictionary *attributes = @{NSFontAttributeName:SYSFONT(16),
                                 NSParagraphStyleAttributeName:paragraphStyle,
                                 NSForegroundColorAttributeName:[UIColor lightGrayColor]
                                 };
    self.replayTextView.attributedText = [[NSAttributedString alloc] initWithString:self.lastMsgInput attributes:attributes];
    
    JXUserObject *user1 = [[JXUserObject sharedInstance] getUserById:dict.user.userId];
    
    // 提前拿到数据防止cell.indexPath.row改变后导致发送消息错误
    self.repalyMsg = [[JXMessageObject alloc] init];
    self.repalyMsg.fromUserId = MY_USER_ID;
    self.repalyMsg.fromUserName = MY_USER_NAME;
    self.repalyMsg.toUserId = dict.user.userId;
    self.repalyMsg.isGroup = dict.user.roomId.length > 0 ? YES : NO;
    self.repalyMsg.type = [NSNumber numberWithInt:kWCMessageTypeText];
    self.repalyMsg.timeSend = [NSDate date];
    self.repalyMsg.isSend       = [NSNumber numberWithInt:transfer_status_ing];
    self.repalyMsg.isRead       = [NSNumber numberWithBool:NO];
    self.repalyMsg.isReadDel    = user1.isOpenReadDel;
    self.repalyMsg.sendCount    = 3;
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    //如果是提示内容，光标放置开始位置
    if (textView.textColor==[UIColor lightGrayColor]) {
        NSRange range;
        range.location = 0;
        range.length = 0;
        textView.selectedRange = range;
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    //如果不是delete响应,当前是提示信息，修改其属性
    if (![text isEqualToString:@""] && textView.textColor == [UIColor lightGrayColor]) {
        textView.text = @"";//置空
        textView.textColor = HEXCOLOR(0x595959);
    }
//    if ([text isEqualToString:@"\n"]) {  //回车事件
//        if ([textView.text isEqualToString:@""])//如果直接回车，显示提示内容
//        {
//            textView.textColor = [UIColor lightGrayColor];
//            textView.text = self.lastMsgInput;
//        }
//        return NO;
//    }
//    int maxHeight = 70;
//    CGRect frame = textView.frame;
//    if (frame.size.height > maxHeight) {
//        frame.size.height = maxHeight;
//        textView.scrollEnabled = YES;
//    }else {
//        textView.scrollEnabled = NO;
//    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    
    static CGFloat maxHeight =66.0f;

    
    //防止输入时在中文后输入英文过长直接中文和英文换行
    if ([textView.text isEqualToString:@""]) {
        textView.textColor = [UIColor lightGrayColor];
        textView.text = self.lastMsgInput;
    }
    
    CGRect frame = textView.frame;
    CGSize constraintSize = CGSizeMake(JX_SCREEN_WIDTH-80-INSETS*2, MAXFLOAT);
    CGSize size = [textView sizeThatFits:constraintSize];
    
    if (size.height >= maxHeight)
    {
        size.height = maxHeight;
        textView.scrollEnabled = YES;   // 允许滚动
    }
    else
    {
        textView.scrollEnabled = NO;    // 不允许滚动
    }

    textView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, size.height);
    NSLog(@"--------%@",NSStringFromCGRect(self.baseView.frame));

    self.baseView.frame = CGRectMake(40, JX_SCREEN_HEIGHT/4+35-size.height, JX_SCREEN_WIDTH-80, 162-35+size.height);
    self.topView.frame = CGRectMake(0, 118-35+size.height, self.baseView.frame.size.width, 40);
}

- (void)sendIt {
    [self resignKeyBoard];
    NSString *roomName = self.repalyMsg.isGroup ? self.repalyMsg.toUserId : nil;
    self.repalyMsg.content = self.replayTextView.text;
    [self.repalyMsg insert:self.repalyMsg.toUserId];
    self.repalyMsg.updateLastContent = YES;
    [self.repalyMsg updateLastSend:UpdateLastSendType_None];
    JXCell* cell = [_table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.replayNum inSection:0]];
    //清除badge
    cell.bage = @"0";
    
    NSMutableArray *array;
    if (_seekTextField.text.length > 0) {
        array = _searchArray;
    }else {
        array = _array;
    }
    JXMsgAndUserObject *p=[array objectAtIndex:self.replayNum];
    if (![p.user.userId isEqualToString:FRIEND_CENTER_USERID]) {
        self.msgTotal -= [cell.bage intValue];
    }
    [UIApplication sharedApplication].applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber - [p.user.msgsNew intValue];
//    [g_server userChangeMsgNum:[UIApplication sharedApplication].applicationIconBadgeNumber toView:self];
    
    [p.message updateNewMsgsTo0];
    [_table reloadRow:self.replayNum section:0];
    [g_xmpp sendMessage:self.repalyMsg roomName:roomName];
    [self doRefresh:self.repalyMsg showNumber:NO];
}

-(void)onHeadImage:(UIView*)sender{
    
    [self doneBtnAction:self.doneBtn];
    
    NSMutableArray *array;
    if (_seekTextField.text.length > 0) {
        array = _searchArray;
    }else {
        array = _array;
    }
    JXMsgAndUserObject *p=[array objectAtIndex:sender.tag];
    if([p.user.userId isEqualToString:FRIEND_CENTER_USERID] || [p.user.userId isEqualToString:CALL_CENTER_USERID] || [p.user.userId isEqualToString:SHIKU_TRANSFER])
        return;
    if([p.user.roomFlag boolValue] || p.user.roomId.length > 0) {
        NSString *s;
        switch ([p.user.groupStatus intValue]) {
            case 0:
                s = nil;
                break;
            case 1:
                s = Localized(@"JX_OutOfTheGroup1");
                break;
            case 2:
                s = Localized(@"JX_DissolutionGroup1");
                break;
                
            default:
                break;
        }
        
        if (s.length > 0) {
            [g_server showMsg:s];
        }else {
            
            JXRoomMemberVC* vc = [JXRoomMemberVC alloc];
//            vc.chatRoom   = [[JXXMPP sharedInstance].roomPool joinRoom:roomdata.roomJid title:roomdata.name isNew:NO];
//            vc.room       = roomdata;
            vc.roomId = p.user.roomId;
            vc.rowIndex = (int)sender.tag;
            vc = [vc init];
            //        [g_window addSubview:vc.view];
            [g_navigation pushViewController:vc animated:YES];
//            [g_server getRoom:p.user.roomId toView:self];
        }
    }else {
        JXUserInfoVC* vc = [JXUserInfoVC alloc];
        vc.userId       = p.user.userId;
        vc.fromAddType = 6;
        vc = [vc init];
        [g_navigation pushViewController:vc animated:YES];
        [self cancelBtnAction];
//        [g_server getUser:p.user.userId toView:self];
    }
    p = nil;
}

-(void)getTotalNewMsgCount{
    int n = 0;
    _topNum = 0;
    for (JXMsgAndUserObject * dict in _array) {
        if (![dict.user.userId isEqualToString:FRIEND_CENTER_USERID]) {
            n += [dict.user.msgsNew intValue];
            NSLog(@"新消息=%d",[dict.user.msgsNew intValue]);
        }
        
        if (dict.user.topTime) {
            _topNum ++;
        }
    }
    self.msgTotal =  n;
    [UIApplication sharedApplication].applicationIconBadgeNumber = n;
//    if (g_xmpp.isLogined) {
//        [g_server userChangeMsgNum:[UIApplication sharedApplication].applicationIconBadgeNumber toView:self];
//    }
}

- (void)chatViewDisappear:(NSNotification *)notif{
//    [_table reloadData];
//    [self getTotalNewMsgCount];
    [self getServerData];
}

-(void)logoutNotifi:(NSNotification *)notif{
    [_array removeAllObjects];
    [_table reloadData];
}
    
-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
    [_wait hide];
    //点击好友头像响应
    if( [aDownload.action isEqualToString:act_UserGet] ){
        JXUserObject* user = [[JXUserObject alloc]init];
        [user getDataFromDict:dict];
        [user updateUserType];
        [g_notify postNotificationName:kFriendListRefresh object:nil];
        
//        JXUserInfoVC* vc = [JXUserInfoVC alloc];
//        vc.user       = user;
//        vc = [vc init];
////        [g_window addSubview:vc.view];
//        [g_navigation pushViewController:vc animated:YES];
//        [self cancelBtnAction];
    }
    
    if( [aDownload.action isEqualToString:act_roomGet] ){
        
        JXUserObject* user = [[JXUserObject alloc]init];
        [user getDataFromDict:dict];
        
        NSDictionary * groupDict = [user toDictionary];
        roomData * roomdata = [[roomData alloc] init];
        [roomdata getDataFromDict:groupDict];
        
        [roomdata getDataFromDict:dict];
        
        JXRoomMemberVC* vc = [JXRoomMemberVC alloc];
        vc.chatRoom   = [[JXXMPP sharedInstance].roomPool joinRoom:roomdata.roomJid title:roomdata.name isNew:NO];
        vc.room       = roomdata;
        vc = [vc init];
//        [g_window addSubview:vc.view];
        [g_navigation pushViewController:vc animated:YES];
    }
    if ([aDownload.action isEqualToString:act_roomGetRoom]) {
        
        if ([dict objectForKey:@"jid"]) {
            
            if (![dict objectForKey:@"member"]) {
                [g_server showMsg:Localized(@"JX_YouOutOfGroup")];
            }else {
                int talkTime = [[dict objectForKey:@"talkTime"] intValue];
                if (talkTime > 0) {
                    int role = [[[dict objectForKey:@"member"] objectForKey:@"role"] intValue];
                    if (role == 1 || role == 2) {
                        [self showReplayView];
                    }else {
                        [g_App showAlert:Localized(@"JX_TotalSilence")];
                    }
                }else {
                    [g_server getRoomMember:self.replayRoomId userId:[g_myself.userId intValue] toView:self];
                }
            }
        }else {
            [g_server showMsg:Localized(@"JX_DissolutionGroup1")];
        }
        
    }
    if( [aDownload.action isEqualToString:act_roomMemberGet] ){
        long long disableSay = [[dict objectForKey:@"talkTime"] longLongValue];
        if ([[NSDate date] timeIntervalSince1970] < disableSay) {
            [g_App showAlert:Localized(@"HAS_BEEN_BANNED")];
        }else {
            [self showReplayView];
        }
    }

    if ([aDownload.action isEqualToString:act_tigaseGetLastChatList]) {
        
        [[JXUserObject sharedInstance] updateUserLastChatList:array1];
        if (array1.count > 0) {
            [self getServerData];
        }
        
        [_taskArray removeAllObjects];
        // 获取到群组本地最后一条消息
        for (NSInteger i = 0; i < array1.count; i ++) {
            NSDictionary *dict = array1[i];
            if ([[dict objectForKey:@"isRoom"] intValue] == 1) {
                // 获取最近一条记录
                NSArray *arr = [[JXMessageObject sharedInstance] fetchMessageListWithUser:[dict objectForKey:@"jid"] byAllNum:0 pageCount:20 startTime:[NSDate dateWithTimeIntervalSince1970:0]];
                JXMessageObject *lastMsg = nil;
                for (NSInteger i = 0; i < arr.count; i ++) {
                    JXMessageObject *firstMsg = arr[i];
                    if ([firstMsg.type integerValue] != kWCMessageTypeRemind) {
                        lastMsg = firstMsg;
                        break;
                    }
                }
                if (!lastMsg) {
//                    continue;
                    lastMsg = arr.firstObject;
                }
                JXUserObject *user = [[JXUserObject sharedInstance] getUserById:dict[@"jid"]];
                NSMutableDictionary *taskDic = [NSMutableDictionary dictionary];
                [taskDic setObject:[dict objectForKey:@"jid"] forKey:@"userId"];
                [taskDic setObject:[NSDate dateWithTimeIntervalSince1970:[dict[@"timeSend"] longLongValue]] forKey:@"lastTime"];
                if (lastMsg) {
                    [taskDic setObject:lastMsg.timeSend forKey:@"startTime"];
                    if (lastMsg.messageId) {
                        [taskDic setObject:lastMsg.messageId forKey:@"startMsgId"];
                    }
                }
                if (user.roomId) {
                    [taskDic setObject:user.roomId forKey:@"roomId"];
                }
                
                [_taskArray addObject:taskDic];
            }
        }
        
        [g_xmpp.roomPool createAll];
    }
}



-(int) didServerResultFailed:(JXConnection*)aDownload dict:(NSDictionary*)dict{
    [_wait hide];
    
    if ([aDownload.action isEqualToString:act_tigaseGetLastChatList]) {
        
        [g_xmpp.roomPool createAll];
    }

    if (![aDownload.action isEqualToString:act_userChangeMsgNum] && ![aDownload.action isEqualToString:act_tigaseGetLastChatList]) {
        return show_error;
    }
    return hide_error;
}

-(int) didServerConnectError:(JXConnection*)aDownload error:(NSError *)error{//error为空时，代表超时
    [_wait hide];

    if (![aDownload.action isEqualToString:act_userChangeMsgNum] && ![aDownload.action isEqualToString:act_tigaseGetLastChatList]) {
        return show_error;
    }
    return hide_error;
}

-(void) didServerConnectStart:(JXConnection*)aDownload{
    if (![aDownload.action isEqualToString:act_userChangeMsgNum] && ![aDownload.action isEqualToString:act_roomMemberGet] && ![aDownload.action isEqualToString:act_roomGetRoom]) {
        [_wait start];
    }
}

-(void)onDrag:(UIView*)sender{
    
    sender.hidden = YES;
}

-(void)onReceiveRoomRemind:(NSNotification *)notifacation//
{
    JXRoomRemind* p     = (JXRoomRemind *)notifacation.object;
    JXUserObject* user = [[JXUserObject sharedInstance] getUserById:p.objectId];//如果能查到，说明是群组，否则是直播间
    
    BOOL bRefresh=NO;
    if([p.type intValue] == kRoomRemind_RoomName){
        if(!user)
            return;
        user.userNickname  = p.content;
        [user update];
        
        for(int i=0;i<[_array count];i++){
            JXMsgAndUserObject* room=[_array objectAtIndex:i];
            if([room.user.userId isEqualToString:p.objectId]){
                room.user.userNickname = p.content;
                bRefresh = YES;
                break;
            }
            room = nil;
        }
    }
    if([p.type intValue] == kRoomRemind_NickName){
        memberData *data = [[memberData alloc] init];
        data.roomId = user.roomId;
        data.userNickName = p.content;
        data.userId = [p.toUserId longLongValue];
        [data updateUserNickName];
    }
    
    if([p.type intValue] == kRoomRemind_DelMember){
        if(!user)
            return;
        if([p.toUserId rangeOfString:MY_USER_ID].location != NSNotFound){
            if ([p.fromUserId isEqualToString:MY_USER_ID]) {
                [JXUserObject deleteUserAndMsg:user.userId];
            }
            user.groupStatus = [NSNumber numberWithInt:1];
            [user updateGroupInvalid];
            for (JXMsgAndUserObject *obj in _array) {
                if ([obj.user.userId isEqualToString:user.userId]) {
                    obj.user.groupStatus = [NSNumber numberWithInt:1];
                    break;
                }
            }
            [g_xmpp.roomPool delRoom:user.userId];
        }else{
//            [[JXMessageObject sharedInstance] deleteWithFromUser:p.toUserId roomId:user.userId];
            
            JXMsgAndUserObject *userObj = nil;
            for (JXMsgAndUserObject *obj in _array) {
                if ([obj.user.userId isEqualToString:user.userId]) {
                    userObj = obj;
                    memberData* member = [[memberData alloc] init];
                    member.userId = [p.toUserId intValue];
                    member.userNickName = p.toUserName;
                    member.roomId = user.roomId;
                    [member remove];
                    
                    NSDictionary * groupDict = [user toDictionary];
                    roomData * roomdata = [[roomData alloc] init];
                    [roomdata getDataFromDict:groupDict];
                    roomdata.roomId = user.roomId;
                    roomdata.members = roomdata.members;
                    break;
                }
            }
//            if ([p.fromUserId isEqualToString:MY_USER_ID]) {
//                [userObj.user delete];
//                [_array removeObject:userObj];
//                [_table reloadData];
//            }
            
        }
    }

    if([p.type intValue] == kRoomRemind_AddMember){
        if([p.toUserId isEqualToString:MY_USER_ID]){
            if(![g_xmpp.roomPool getRoom:p.objectId]){
                JXUserObject* user = [[JXUserObject alloc]init];
                user.userNickname = p.content;
                user.userId = p.objectId;
                user.userDescription = p.content;
                user.roomId = p.roomId;
//                user.showRead = p.fileSize;
                SBJsonParser * resultParser = [[SBJsonParser alloc] init] ;
                NSDictionary *resultObject = [resultParser objectWithString:p.other];
                user.showMember = resultObject[@"showMember"];
                user.allowSendCard = resultObject[@"allowSendCard"];
                user.showRead = resultObject[@"showRead"];
                user.talkTime = resultObject[@"talkTime"];
                user.allowInviteFriend = resultObject[@"allowInviteFriend"];
                user.allowUploadFile = resultObject[@"allowUploadFile"];
                user.allowConference = resultObject[@"allowConference"];
                user.allowSpeakCourse = resultObject[@"allowSpeakCourse"];
                user.chatRecordTimeOut = resultObject[@"chatRecordTimeOut"];
                user.isNeedVerify = resultObject[@"isNeedVerify"];
                
                [user insertRoom];
                [g_xmpp.roomPool joinRoom:user.userId title:user.userNickname isNew:NO];
                bRefresh = YES;
                
            }
        }
        
        JXUserObject* user = [[JXUserObject alloc]init];
        user.userId = p.objectId;
        user.groupStatus = [NSNumber numberWithInt:0];
        [user updateGroupInvalid];
        for (JXMsgAndUserObject *obj in _array) {
            if ([obj.user.userId isEqualToString:user.userId]) {
                obj.user.groupStatus = [NSNumber numberWithInt:0];
                break;
            }
        }
        
        for (JXMsgAndUserObject *obj in _array) {
            if ([obj.user.userId isEqualToString:user.userId]) {
                
                memberData* member = [[memberData alloc] init];
                member.userId = [p.toUserId intValue];
                member.userNickName = p.toUserName;
                member.roomId = p.roomId;
                [member insert];
                
                NSDictionary * groupDict = [obj.user toDictionary];
                roomData * roomdata = [[roomData alloc] init];
                [roomdata getDataFromDict:groupDict];
                roomdata.roomId = obj.user.roomId;
                roomdata.members = roomdata.members;
                break;
            }
        }
        
        if ([p.fromUserId isEqualToString:MY_USER_ID]) {
            self.roomRemind = p;
            JXRoomObject *chatRoom = [g_xmpp.roomPool joinRoom:p.objectId title:p.content isNew:YES];
            chatRoom.delegate = self;
            [chatRoom joinRoom:YES];
        }
        
        [self getServerData];
    }
 
    if([p.type intValue] == kRoomRemind_DelRoom){
        if(!user)
            return;
        //        [JXUserObject deleteUserAndMsg:user.userId];
        user.groupStatus = [NSNumber numberWithInt:2];
        [user updateGroupInvalid];
        
        JXMsgAndUserObject *userObj = nil;
        for (JXMsgAndUserObject *obj in _array) {
            if ([obj.user.userId isEqualToString:user.userId]) {
                userObj = obj;
                obj.user.groupStatus = [NSNumber numberWithInt:2];
                break;
            }
        }
        if ([p.fromUserId isEqualToString:MY_USER_ID]) {
            [userObj.user delete];
            [_array removeObject:userObj];
            [_table reloadData];
        }
        [g_xmpp.roomPool delRoom:user.userId];
    }

    if([p.type intValue] == kRoomRemind_ShowRead){
        BOOL bFound=NO;
        JXMsgAndUserObject *obj=nil;
        for(int i=0;i<[_array count];i++){
            obj=[_array objectAtIndex:i];
            if([obj.user.userId isEqualToString:p.objectId]){
                obj.user.showRead = [NSNumber numberWithInt:[p.content intValue]];
                [obj.user update];
                bFound = YES;
                break;
            }
        }
        if(!bFound){
            JXUserObject* user = [[JXUserObject sharedInstance] getUserById:p.objectId];
            user.showRead = [NSNumber numberWithInt:[p.content intValue]];
            [user update];
        }
    }
    
    if([p.type intValue] == kRoomRemind_ShowMember){
        BOOL bFound=NO;
        JXMsgAndUserObject *obj=nil;
        for(int i=0;i<[_array count];i++){
            obj=[_array objectAtIndex:i];
            if([obj.user.userId isEqualToString:p.objectId]){
                obj.user.showMember = [NSNumber numberWithInt:[p.content intValue]];
                [obj.user update];
                bFound = YES;
                break;
            }
        }
        if(!bFound){
            JXUserObject* user = [[JXUserObject sharedInstance] getUserById:p.objectId];
            user.showMember = [NSNumber numberWithInt:[p.content intValue]];
            [user update];
        }
    }
    
    if([p.type intValue] == kRoomRemind_allowSendCard){
        BOOL bFound=NO;
        JXMsgAndUserObject *obj=nil;
        for(int i=0;i<[_array count];i++){
            obj=[_array objectAtIndex:i];
            if([obj.user.userId isEqualToString:p.objectId]){
                obj.user.allowSendCard = [NSNumber numberWithInt:[p.content intValue]];
                [obj.user update];
                bFound = YES;
                break;
            }
        }
        if(!bFound){
            JXUserObject* user = [[JXUserObject sharedInstance] getUserById:p.objectId];
            user.allowSendCard = [NSNumber numberWithInt:[p.content intValue]];
            [user update];
        }
    }
    
    if ([p.type intValue] == kRoomRemind_SetManage) {
        //设置群组管理员
        
        JXUserObject *user = [[JXUserObject sharedInstance] getUserById:p.objectId];
        
        NSDictionary * groupDict = [user toDictionary];
        roomData * roomdata = [[roomData alloc] init];
        [roomdata getDataFromDict:groupDict];
        NSArray * allMem = [memberData fetchAllMembers:user.roomId];
        roomdata.members = [allMem mutableCopy];
        
        memberData *member = [roomdata getMember:p.toUserId];
        if ([member.role intValue] == 2) {
            member.role = [NSNumber numberWithInt:3];
        }else {
            member.role = [NSNumber numberWithInt:2];
        }
        [member update];
    }
    
    if([p.type intValue] == kRoomRemind_RoomAllBanned){
        BOOL bFound=NO;
        JXMsgAndUserObject *obj=nil;
        for(int i=0;i<[_array count];i++){
            obj=[_array objectAtIndex:i];
            if([obj.user.userId isEqualToString:p.objectId]){
                obj.user.talkTime = [NSNumber numberWithLong:[p.content longLongValue]];
                [obj.user updateGroupTalkTime];
                bFound = YES;
                break;
            }
        }
        if(!bFound){
            JXUserObject* user = [[JXUserObject sharedInstance] getUserById:p.objectId];
            user.talkTime = [NSNumber numberWithLong:[p.content longLongValue]];
            [user updateGroupTalkTime];
        }
    }
    if([p.type intValue] == kRoomRemind_RoomAllowInviteFriend){
        BOOL bFound=NO;
        JXMsgAndUserObject *obj=nil;
        for(int i=0;i<[_array count];i++){
            obj=[_array objectAtIndex:i];
            if([obj.user.userId isEqualToString:p.objectId]){
                obj.user.allowInviteFriend = [NSNumber numberWithInt:[p.content intValue]];
                [obj.user update];
                bFound = YES;
                break;
            }
        }
        if(!bFound){
            JXUserObject* user = [[JXUserObject sharedInstance] getUserById:p.objectId];
            user.allowSendCard = [NSNumber numberWithInt:[p.content intValue]];
            [user update];
        }
    }
    if([p.type intValue] == kRoomRemind_RoomAllowUploadFile){
        BOOL bFound=NO;
        JXMsgAndUserObject *obj=nil;
        for(int i=0;i<[_array count];i++){
            obj=[_array objectAtIndex:i];
            if([obj.user.userId isEqualToString:p.objectId]){
                obj.user.allowUploadFile = [NSNumber numberWithInt:[p.content intValue]];
                [obj.user update];
                bFound = YES;
                break;
            }
        }
        if(!bFound){
            JXUserObject* user = [[JXUserObject sharedInstance] getUserById:p.objectId];
            user.allowUploadFile = [NSNumber numberWithInt:[p.content intValue]];
            [user update];
        }
    }
    if([p.type intValue] == kRoomRemind_RoomAllowConference){
        BOOL bFound=NO;
        JXMsgAndUserObject *obj=nil;
        for(int i=0;i<[_array count];i++){
            obj=[_array objectAtIndex:i];
            if([obj.user.userId isEqualToString:p.objectId]){
                obj.user.allowConference = [NSNumber numberWithInt:[p.content intValue]];
                [obj.user update];
                bFound = YES;
                break;
            }
        }
        if(!bFound){
            JXUserObject* user = [[JXUserObject sharedInstance] getUserById:p.objectId];
            user.allowConference = [NSNumber numberWithInt:[p.content intValue]];
            [user update];
        }
    }
    if([p.type intValue] == kRoomRemind_RoomAllowSpeakCourse){
        BOOL bFound=NO;
        JXMsgAndUserObject *obj=nil;
        for(int i=0;i<[_array count];i++){
            obj=[_array objectAtIndex:i];
            if([obj.user.userId isEqualToString:p.objectId]){
                obj.user.allowSpeakCourse = [NSNumber numberWithInt:[p.content intValue]];
                [obj.user update];
                bFound = YES;
                break;
            }
        }
        if(!bFound){
            JXUserObject* user = [[JXUserObject sharedInstance] getUserById:p.objectId];
            user.allowSpeakCourse = [NSNumber numberWithInt:[p.content intValue]];
            [user update];
        }
    }
    
    if ([p.type intValue] == kRoomRemind_RoomTransfer) {
        JXUserObject *user = [[JXUserObject sharedInstance] getUserById:p.objectId];
        memberData *data = [[memberData alloc] init];
        data.userId = [p.fromUserId longLongValue];
        data.roomId = user.roomId;
        data.role = [NSNumber numberWithInt:3];
        [data updateRole];
        
        data = [[memberData alloc] init];
        data.userId = [p.toUserId longLongValue];
        data.roomId = user.roomId;
        data.role = [NSNumber numberWithInt:1];
        [data updateRole];
    }
    
    if ([p.type intValue] == kRoomRemind_SetRecordTimeOut) {
        
        JXUserObject *user = [[JXUserObject sharedInstance] getUserById:p.objectId];
        user.chatRecordTimeOut = p.content;
        [user updateUserChatRecordTimeOut];
    }
    
    if(bRefresh){
        _refreshCount++;
        [_table reloadData];
        [self getTotalNewMsgCount];
    }
    p = nil;
}

-(void)xmppRoomDidJoin:(XMPPRoom *)sender{

    JXUserObject* user = [[JXUserObject alloc]init];
    user.userNickname = self.roomRemind.content;
    user.userId = self.roomRemind.objectId;
    user.userDescription = nil;
    user.roomId = self.roomRemind.roomId;
    SBJsonParser * resultParser = [[SBJsonParser alloc] init] ;
    NSDictionary *resultObject = [resultParser objectWithString:self.roomRemind.other];
    user.showRead = [resultObject objectForKey:@"showRead"];
    user.showMember = [resultObject objectForKey:@"showMember"];
    user.allowSendCard = [resultObject objectForKey:@"allowSendCard"];
    user.talkTime = [resultObject objectForKey:@"talkTime"];
    user.allowInviteFriend = [resultObject objectForKey:@"allowInviteFriend"];
    user.allowUploadFile = [resultObject objectForKey:@"allowUploadFile"];
    user.allowConference = [resultObject objectForKey:@"allowConference"];
    user.allowSpeakCourse = [resultObject objectForKey:@"allowSpeakCourse"];
    user.chatRecordTimeOut = [resultObject objectForKey:@"chatRecordTimeOut"];
    user.isNeedVerify = [resultObject objectForKey:@"isNeedVerify"];
    
    if (![user haveTheUser])
        [user insertRoom];
//    else
//        [user update];
}

-(void)onQuitRoom:(NSNotification *)notifacation//超时未收到回执
{
    JXRoomObject* p     = (JXRoomObject *)notifacation.object;
    for(int i=0;i<[_array count];i++){
        JXMsgAndUserObject* room=[_array objectAtIndex:i];
        if([room.user.userId isEqualToString:p.roomJid]){
            [_array removeObjectAtIndex:i];
            _refreshCount++;
            [_table reloadData];
            [self getTotalNewMsgCount];
            break;
        }
        room = nil;
    }
    p = nil;
}
-(void)onSearch{
    JXSearchUserVC* vc = [JXSearchUserVC alloc];
    vc.delegate  = self;
    vc.didSelect = @selector(doSearch:);
    vc.type = JXSearchTypeUser;
//    [g_window addSubview:vc.view];
    vc = [vc init];
    [g_navigation pushViewController:vc animated:YES];
    
    [self cancelBtnAction];
}
-(void)doSearch:(searchData*)p{

    JXNearVC *nearVC = [[JXNearVC alloc]init];
    nearVC.isSearch = YES;
//    [g_window addSubview:nearVC.view];
    [g_navigation pushViewController:nearVC animated:YES];
//    nearVC.search = p;
//    nearVC.bNearOnly = NO;
//    nearVC.page = 0;;
//    nearVC.selMenu = 0;
//    [nearVC getServerData];
    [nearVC doSearch:p];
}

-(void)allMsgCome{
    [self getServerData];
}

-(void)showNewCount{//显示IM数量
    [g_mainVC.tb setBadge:0 title:[NSString stringWithFormat:@"%d",self.msgTotal]];
}

-(void)setMsgTotal:(int)n{
    if(n<0)
        n = 0;
    _msgTotal = n;
    [self showNewCount];
}

-(void)showScanViewController{
//    button.enabled = NO;
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        button.enabled = YES;
//    });
    
    AVAuthorizationStatus authStatus =  [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)
    {
        [g_server showMsg:Localized(@"JX_CanNotopenCenmar")];
        return;
    }
    
    JXScanQRViewController * scanVC = [[JXScanQRViewController alloc] init];
    
//    [g_window addSubview:scanVC.view];
    [g_navigation pushViewController:scanVC animated:YES];
}


- (void)resignKeyBoard {
    self.bigView.hidden = YES;
    [self hideKeyBoard];
    [self resetBigView];
}

- (void)resetBigView {
    self.replayTextView.frame = CGRectMake(10, 64, self.baseView.frame.size.width - INSETS*2, 35.5);
    self.baseView.frame = CGRectMake(40, JX_SCREEN_HEIGHT/4-.5, JX_SCREEN_WIDTH-80, 162.5);
    self.topView.frame = CGRectMake(0, 118, self.baseView.frame.size.width, 40);
}

- (void)hideKeyBoard {
    if (self.replayTextView.isFirstResponder) {
        [self.replayTextView resignFirstResponder];
    }
}

-(UITextView*)createTextField:(UIView*)parent default:(NSString*)s hint:(NSString*)hint{
    UITextView* p = [[UITextView alloc] initWithFrame:CGRectMake(0,INSETS,JX_SCREEN_WIDTH,54)];
    p.delegate = self;
    p.autocorrectionType = UITextAutocorrectionTypeNo;
    p.autocapitalizationType = UITextAutocapitalizationTypeNone;
    p.enablesReturnKeyAutomatically = YES;
    p.scrollEnabled = NO;
    p.showsVerticalScrollIndicator = NO;
    p.showsHorizontalScrollIndicator = NO;
    p.textAlignment = NSTextAlignmentLeft;
    p.userInteractionEnabled = YES;
    p.backgroundColor = [UIColor whiteColor];
    p.text = s;
    p.font = g_factory.font16;
    [parent addSubview:p];
    return p;
}



@end
