//
//  JXGroupViewController.m
//  BaseProject
//
//  Created by Huan Cho on 13-8-3.
//  Copyright (c) 2013年 ch. All rights reserved.
//

#import "JXGroupViewController.h"
//#import "Statics.h"
//#import "KKMessageCell.h"
//#import "XMPPStream.h"
#import "JXMessageObject.h"
#import "JXXMPP.h"
#import "JXChatViewController.h"
#import "AppDelegate.h"
#import "JXLabel.h"
#import "JXImageView.h"
#import "JXCell.h"
#import "JXRoomPool.h"
#import "JXTableView.h"
#import "JXRoomMemberVC.h"
#import "JXRoomObject.h"
#import "JXSelFriendVC.h"
#import "JXNewRoomVC.h"
#import "menuImageView.h"
#import "JXUserInfoVC.h"
#import "JXRoomRemind.h"
#import "JXInputVC.h"
#import "JXCommonInputVC.h"
#import "JXSearchGroupVC.h"
//#import "JXTableViewController.h"


#define Scroll_Move 45

#define padding 20
@interface JXGroupViewController()<UITextFieldDelegate,JXCommonInputVCDelegate>{
    NSMutableArray * _myGroupArray;
    NSMutableArray * _allGroupArray;
}

@property (nonatomic, copy) NSString *roomJid;
@property (nonatomic, copy) NSString *roomUserId;
@property (nonatomic, copy) NSString *roomUserName;

@end
@implementation JXGroupViewController

#pragma mark - life circle

- (id)init
{
    self = [super init];
    if (self) {
//        self.title = @"";
        self.heightHeader = JX_SCREEN_TOP;
        self.heightFooter = 0;
        self.title = Localized(@"JX_ManyPerChat");
        //self.view.frame = CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT-JX_SCREEN_BOTTOM);
        self.isGotoBack = YES;
        [self createHeadAndFoot];
        
//        CGRect frame = self.tableView.frame;
//        frame.origin.y += 40;
//        frame.size.height -= 40;
//        self.tableView.frame = frame;

        [self customView];
        NSString *image = THESIMPLESTYLE ? @"im_003_more_button_black" : @"im_003_more_button_normal";
        UIButton* btn = [UIFactory createButtonWithImage:image
                                               highlight:nil
                                                  target:self
                                                selector:@selector(onNewRoom)];
        
        btn.frame = CGRectMake(JX_SCREEN_WIDTH - 40, JX_SCREEN_TOP - 34, 24, 24);
        [self.tableHeader addSubview:btn];
        
#pragma 隐藏群搜索功能
        if ([g_config.isOpenRoomSearch boolValue]) {
            NSString *img = THESIMPLESTYLE ? @"search_publicNumber_black" : @"search_publicNumber";
            btn = [UIFactory createButtonWithImage:img
                                         highlight:nil
                                            target:self
                                          selector:@selector(onSearchRoom)];
            btn.frame = CGRectMake(JX_SCREEN_WIDTH - 80, JX_SCREEN_TOP - 34, 24, 24);
            [self.tableHeader addSubview:btn];
        }
        
        _myGroupArray = [[NSMutableArray alloc] init];
        _allGroupArray = [[NSMutableArray alloc] init];
        _page=0;
        _isLoading=0;
        _selMenu = 0;
        [self getServerData];

        [g_notify addObserver:self selector:@selector(onReceiveRoomRemind:) name:kXMPPRoomNotifaction object:nil];
        [g_notify addObserver:self selector:@selector(onQuitRoom:) name:kQuitRoomNotifaction object:nil];
        [g_notify addObserver:self selector:@selector(doRefresh:) name:kUpdateUserNotifaction object:nil];
        [g_notify addObserver:self selector:@selector(headImageNotification:) name:kGroupHeadImageModifyNotifaction object:nil];
    }
    return self;
}

-(void)headImageNotification:(NSNotification *)notification{
    [_table reloadData];
}

//-(void)onClick:(UIButton*)sender{
//}
- (void)doRefresh:(NSNotification *)notif {
    [_myGroupArray removeAllObjects];
    [self getServerData];
}

- (void) customView {
    //顶部筛选控件
//    _topSiftView = [[JXTopSiftJobView alloc] initWithFrame:CGRectMake(0, JX_SCREEN_TOP, JX_SCREEN_WIDTH, 40)];
//    _topSiftView.delegate = self;
//    _topSiftView.isShowMoreParaBtn = NO;
//    _topSiftView.dataArray = [[NSArray alloc] initWithObjects:Localized(@"JXGroupVC_MyRoom"),Localized(@"JXGroupVC_AllRoom"), nil];
//    //    _topSiftView.searchForType = SearchForPos;
//    [self.view addSubview:_topSiftView];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)dealloc {
    [g_notify removeObserver:self];
    [g_notify  removeObserver:self name:kXMPPRoomNotifaction object:nil];
    [g_notify  removeObserver:self name:kQuitRoomNotifaction object:nil];
    [g_notify  removeObserver:self name:kUpdateUserNotifaction object:nil];
    [g_notify  removeObserver:self name:kGroupHeadImageModifyNotifaction object:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (_selMenu == 1) {
        [_scrollView setContentOffset:CGPointMake(JX_SCREEN_WIDTH/2+Scroll_Move*0.5, 0) animated:NO];
    }else{
        [_scrollView setContentOffset:CGPointMake(JX_SCREEN_WIDTH, 0) animated:NO];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

-(void)onNewRoom{
    if ([g_config.isCommonCreateGroup intValue] == 1) {
        [g_App showAlert:Localized(@"JX_NotCreateNewRoom")];
        return;
    }
    JXNewRoomVC* vc = [[JXNewRoomVC alloc]init];
    [g_navigation pushViewController:vc animated:YES];
}

- (void)onSearchRoom {
    
    JXCommonInputVC *vc = [[JXCommonInputVC alloc] init];
    vc.delegate = self;
    vc.titleStr = Localized(@"JX_CommonGroupSearch");
    vc.subTitle = Localized(@"JX_ManyPerChat");
    vc.tip = Localized(@"JX_InputRoomName");
    vc.btnTitle = Localized(@"JX_Seach");
    [g_navigation pushViewController:vc animated:YES];
    
}

- (void)commonInputVCBtnActionWithVC:(JXCommonInputVC *)commonInputVC {
    
    JXSearchGroupVC *vc = [[JXSearchGroupVC alloc] init];
    vc.searchName = commonInputVC.name.text;
    [g_navigation pushViewController:vc animated:YES];
}

#pragma mark   ---------tableView协议----------------
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_selMenu == 0) {
        return _myGroupArray.count;
    }else if (_selMenu == 1) {
        return _allGroupArray.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* cellName = [NSString stringWithFormat:@"groupJXCell"];
    JXCell * cell = [tableView dequeueReusableCellWithIdentifier:cellName];
    JXUserObject *user;
    if (_selMenu == 0) {
        user = _myGroupArray[indexPath.row];
    }else if (_selMenu == 1) {
        user = _allGroupArray[indexPath.row];
    }
    if(cell==nil){
        cell = [[JXCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellName];
        [_table addToPool:cell];
    }
    cell.delegate = self;
    cell.didTouch = @selector(onHeadImage:);
//    [cell groupCellDataSet:dict indexPath:indexPath];
    
//    NSTimeInterval t = [[dataDict objectForKey:@"createTime"] longLongValue];
//    NSDate* d = [NSDate dateWithTimeIntervalSince1970:t];
    
    cell.index = (int)indexPath.row;
//    if (_selMenu == 0) {
//        cell.title = dataDict[@"name"];
//    }else
        cell.title = [NSString stringWithFormat:@"%@",user.userNickname];
//    }
    cell.subtitle = user.userDescription;
    cell.bottomTitle = [TimeUtil formatDate:user.timeCreate format:@"MM-dd HH:mm"];
    cell.userId = user.createUserId;
    
    cell.headImageView.tag = (int)indexPath.row;
    cell.headImageView.delegate = self;
    cell.headImageView.didTouch = @selector(onHeadImage:);
    
    [cell.lbTitle setText:cell.title];
    cell.lbTitle.tag = cell.index;
    
    [cell.lbSubTitle setText:cell.subtitle];
    [cell.timeLabel setText:cell.bottomTitle];
    cell.bageNumber.delegate = self;
//    bageNumber.didDragout = self.didDragout;
    cell.bage = cell.bage;
    
    NSString * roomIdStr = user.roomId;
    cell.roomId = roomIdStr;
    [cell headImageViewImageWithUserId:user.userId roomId:roomIdStr];
    cell.isSmall = NO;
    
    [self doAutoScroll:indexPath];
    return cell;
}

-(void)onHeadImage:(JXImageView*)sender{
    JXUserObject *user;
    if (_selMenu == 0) {
        user = _myGroupArray[sender.tag];
    }else if (_selMenu == 1) {
        user = _allGroupArray[sender.tag];
    }
    
    JXRoomMemberVC* vc = [JXRoomMemberVC alloc];
    vc.roomId = user.roomId;
    vc = [vc init];
    [g_navigation pushViewController:vc animated:YES];
    
//    [g_server getRoom:dict[@"id"] toView:self];

//    [g_server getUser:[[dict objectForKey:@"userId"] stringValue] toView:self];
//    dict = nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    if(g_xmpp.isLogined != 1){
        // 掉线后点击title重连
        // 判断XMPP是否在线  不在线重连
        [g_xmpp showXmppOfflineAlert];
        return;
    }
    
    [_inputText resignFirstResponder];
    _sel = (int)indexPath.row;
    JXUserObject *dict;
    if (_selMenu == 0) {
        dict = _myGroupArray[_sel];
    }else if (_selMenu == 1) {
        dict = _allGroupArray[_sel];
    }

    JXUserObject *user = [[JXUserObject sharedInstance] getUserById:dict.userId];
    
    if(user && [user.groupStatus intValue] == 0){
        
        _chatRoom = [[JXXMPP sharedInstance].roomPool joinRoom:dict.userId title:dict.userNickname isNew:YES];
        //老房间:
        [self showChatView];
    }else{
        
        _chatRoom = [[JXXMPP sharedInstance].roomPool joinRoom:dict.userId title:dict.userNickname isNew:YES];
        BOOL isNeedVerify = [dict.isNeedVerify boolValue];
        long long userId = [dict.createUserId longLongValue];
        if (isNeedVerify && userId != [g_myself.userId longLongValue]) {

            self.roomJid = dict.userId;
            self.roomUserName = dict.userNickname;
            self.roomUserId = dict.createUserId;
            
            JXInputVC* vc = [JXInputVC alloc];
            vc.delegate = self;
            vc.didTouch = @selector(onInputHello:);
            vc.inputTitle = Localized(@"JX_GroupOwnersHaveEnabled");
            vc.titleColor = [UIColor lightGrayColor];
            vc.titleFont = [UIFont systemFontOfSize:13.0];
            vc.inputHint = Localized(@"JX_PleaseEnterTheReason");
            vc = [vc init];
            [g_window addSubview:vc.view];
        }else {
            
            [_wait start:Localized(@"JXAlert_AddRoomIng") delay:30];
            //新房间:
            _chatRoom.delegate = self;
            [_chatRoom joinRoom:YES];
        }
    }
    dict = nil;
    UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.selected = NO;
    
}


-(void)onInputHello:(JXInputVC*)sender{
    
    JXMessageObject *msg = [[JXMessageObject alloc] init];
    msg.fromUserId = MY_USER_ID;
    msg.toUserId = [NSString stringWithFormat:@"%@", self.roomUserId];
    msg.fromUserName = MY_USER_NAME;
    msg.toUserName = self.roomUserName;
    msg.timeSend = [NSDate date];
    msg.type = [NSNumber numberWithInt:kRoomRemind_NeedVerify];
    NSString *userIds = g_myself.userId;
    NSString *userNames = g_myself.userNickname;
    NSDictionary *dict = @{
                           @"userIds" : userIds,
                           @"userNames" : userNames,
                           @"roomJid" : self.roomJid,
                           @"reason" : sender.inputText,
                           @"isInvite" : [NSNumber numberWithBool:YES]
                           };
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    msg.objectId = jsonStr;
    [g_xmpp sendMessage:msg roomName:nil];
    
//    msg.fromUserId = self.roomJid;
//    msg.type = [NSNumber numberWithInt:kWCMessageTypeRemind];
//    msg.content = @"申请已发送给群主，请等待群主确认";
//    [msg insert:self.roomJid];
//    if ([self.delegate respondsToSelector:@selector(needVerify:)]) {
//        [self.delegate needVerify:msg];
//    }
}

-(void)xmppRoomDidJoin:(XMPPRoom *)sender{
    
    JXUserObject *user;
    if (_selMenu == 0) {
        user = _myGroupArray[_sel];
    }else if (_selMenu == 1) {
        user = _allGroupArray[_sel];
    }
//    JXUserObject* user = [[JXUserObject alloc]init];
//    user.userNickname = [dict objectForKey:@"name"];
//    user.userId = [dict objectForKey:@"jid"];
//    user.userDescription = [dict objectForKey:@"desc"];
//    user.roomId = [dict objectForKey:@"id"];
//    user.showRead = [dict objectForKey:@"showRead"];
//    user.showMember = [dict objectForKey:@"showMember"];
//    user.allowSendCard = [dict objectForKey:@"allowSendCard"];
//    user.chatRecordTimeOut = [dict objectForKey:@"chatRecordTimeOut"];
//    user.talkTime = [dict objectForKey:@"talkTime"];
//    user.allowInviteFriend = [dict objectForKey:@"allowInviteFriend"];
//    user.allowUploadFile = [dict objectForKey:@"allowUploadFile"];
//    user.allowConference = [dict objectForKey:@"allowConference"];
//    user.allowSpeakCourse = [dict objectForKey:@"allowSpeakCourse"];
//    user.isNeedVerify = [dict objectForKey:@"isNeedVerify"];
    if (![user haveTheUser])
        [user insertRoom];
//    else
//        [user update];
//    [user release];
    
    [g_server addRoomMember:user.roomId userId:g_myself.userId nickName:g_myself.userNickname toView:self];
    
//    dict = nil;
    _chatRoom.delegate = nil;
    
    [self showChatView];
}

-(void)startReconnect{
    NSArray * tempArray;
    if (_selMenu == 0) {
        tempArray = _myGroupArray;
    }else if (_selMenu == 1) {
        tempArray = _allGroupArray;
    }
    
    for (int i = 0; i < [tempArray count]; i++) {
        JXUserObject *user=tempArray[i];
        
//        JXUserObject* user = [[JXUserObject alloc]init];
//        user.userNickname = [dict objectForKey:@"name"];
//        user.userId = [dict objectForKey:@"jid"];
//        user.userDescription = [dict objectForKey:@"desc"];
//        user.roomId = [dict objectForKey:@"id"];
//        user.showRead = [dict objectForKey:@"showRead"];
//        user.showMember = [dict objectForKey:@"showMember"];
//        user.allowSendCard = [dict objectForKey:@"allowSendCard"];
//        user.chatRecordTimeOut = [dict objectForKey:@"chatRecordTimeOut"];
//        user.talkTime = [dict objectForKey:@"talkTime"];
//        user.allowInviteFriend = [dict objectForKey:@"allowInviteFriend"];
//        user.allowUploadFile = [dict objectForKey:@"allowUploadFile"];
//        user.allowConference = [dict objectForKey:@"allowConference"];
//        user.allowSpeakCourse = [dict objectForKey:@"allowSpeakCourse"];
//        user.isNeedVerify = [dict objectForKey:@"isNeedVerify"];
        if (![user haveTheUser])
            [user insertRoom];
        else
            [user update];
//        [user release];
        
        [g_server addRoomMember:user.roomId userId:g_myself.userId nickName:g_myself.userNickname toView:self];
        
//        dict = nil;
        _chatRoom.delegate = nil;
    }
}

-(void)showChatView{
    [_wait stop];
    JXUserObject *user;
    if (_selMenu == 0) {
        user = _myGroupArray[_sel];
    }else if (_selMenu == 1) {
        user = _allGroupArray[_sel];
    }
    
    roomData * roomdata = [[roomData alloc] init];
    [roomdata getDataFromDict:[user toDictionary]];
    
    JXChatViewController *sendView=[JXChatViewController alloc];
    sendView.title = user.userNickname;
    sendView.roomJid = user.userId;
    sendView.roomId = user.roomId;
    sendView.chatRoom = _chatRoom;
    sendView.room = roomdata;

//    JXUserObject * userObj = [[JXUserObject alloc]init];
//    userObj.userId = [dict objectForKey:@"jid"];
//    userObj.showRead = [dict objectForKey:@"showRead"];
//    userObj.showMember = [dict objectForKey:@"showMember"];
//    userObj.allowSendCard = [dict objectForKey:@"allowSendCard"];
//    userObj.userNickname = [dict objectForKey:@"name"];
//    userObj.chatRecordTimeOut = roomdata.chatRecordTimeOut;
//    userObj.talkTime = [dict objectForKey:@"talkTime"];
//    userObj.allowInviteFriend = [dict objectForKey:@"allowInviteFriend"];
//    userObj.allowUploadFile = [dict objectForKey:@"allowUploadFile"];
//    userObj.allowConference = [dict objectForKey:@"allowConference"];
//    userObj.allowSpeakCourse = [dict objectForKey:@"allowSpeakCourse"];
//    userObj.isNeedVerify= [dict objectForKey:@"isNeedVerify"];
    sendView.chatPerson = user;
    
    sendView = [sendView init];
//    [g_App.window addSubview:sendView.view];
    [g_navigation pushViewController:sendView animated:YES];
    
//    dict = nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64;
}

-(void)buildButtons{
    //int height=60;
    int height1=26;
//    int height=0;
    
    _inputText  = [[UITextField alloc]initWithFrame:CGRectMake(5, JX_SCREEN_TOP+2, 310, height1)];
    _inputText.textColor = [UIColor blackColor];
    _inputText.userInteractionEnabled = YES;
    _inputText.delegate = self;
    _inputText.placeholder = Localized(@"JXGroupVC_InputRoomName");
	_inputText.borderStyle = UITextBorderStyleRoundedRect;
    _inputText.font = g_factory.font15;
    _inputText.text = Localized(@"JXGroupVC_Sky");
	_inputText.autocorrectionType = UITextAutocorrectionTypeNo;
	_inputText.returnKeyType = UIReturnKeyDone;
	_inputText.clearButtonMode = UITextFieldViewModeWhileEditing;
    _table.tableHeaderView = _inputText;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}


-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
    [_wait hide];

    [self stopLoading];
    if([aDownload.action isEqualToString:act_roomList] || [aDownload.action isEqualToString:act_roomListHis] ){
        self.isShowFooterPull = [array1 count]>=jx_page_size;
        
        NSMutableArray * tempArray;
        if (_selMenu == 0) {
            tempArray = _myGroupArray;
        }else if (_selMenu == 1) {
            tempArray = _allGroupArray;
        }
        
        
        if (_page == 0) {
            
            [tempArray removeAllObjects];
        }
        
        for (int i = 0; i < [array1 count]; i++) {
            NSDictionary *dict=array1[i];
            
            JXUserObject* user = [[JXUserObject alloc]init];
            user.userNickname = [dict objectForKey:@"name"];
            user.userId = [dict objectForKey:@"jid"];
            user.userDescription = [dict objectForKey:@"desc"];
            user.roomId = [dict objectForKey:@"id"];
            user.showRead = [dict objectForKey:@"showRead"];
            user.showMember = [dict objectForKey:@"showMember"];
            user.allowSendCard = [dict objectForKey:@"allowSendCard"];
            user.chatRecordTimeOut = [NSString stringWithFormat:@"%@", [dict objectForKey:@"chatRecordTimeOut"]];
            user.offlineNoPushMsg = [[dict objectForKey:@"member"] objectForKey:@"offlineNoPushMsg"];
            user.talkTime = [dict objectForKey:@"talkTime"];
            user.allowInviteFriend = [dict objectForKey:@"allowInviteFriend"];
            user.allowUploadFile = [dict objectForKey:@"allowUploadFile"];
            user.allowConference = [dict objectForKey:@"allowConference"];
            user.allowSpeakCourse = [dict objectForKey:@"allowSpeakCourse"];
            user.category = [dict objectForKey:@"category"];
            user.createUserId = [dict objectForKey:@"userId"];
            user.timeCreate = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"createTime"] longLongValue]];
            user.isNeedVerify = [dict objectForKey:@"isNeedVerify"];
            
            if ([aDownload.action isEqualToString:act_roomListHis]) {
                
                if (![user haveTheUser]){
                    [user insertRoom];
                }else {
                    [user updateUserNickname];
                }
            }
            
            [tempArray addObject:user];
        }
        
        
        
//        if(_page == 0){
//            [tempArray removeAllObjects];
//            [tempArray addObjectsFromArray:array1];
//            //保存所有进入过的房间
//            if ([aDownload.action isEqualToString:act_roomListHis]) {
//                for (int i = 0; i < [tempArray count]; i++) {
//                    NSDictionary *dict=tempArray[i];
//
//                    JXUserObject* user = [[JXUserObject alloc]init];
//                    user.userNickname = [dict objectForKey:@"name"];
//                    user.userId = [dict objectForKey:@"jid"];
//                    user.userDescription = [dict objectForKey:@"desc"];
//                    user.roomId = [dict objectForKey:@"id"];
//                    user.showRead = [dict objectForKey:@"showRead"];
//                    user.showMember = [dict objectForKey:@"showMember"];
//                    user.allowSendCard = [dict objectForKey:@"allowSendCard"];
//                    user.chatRecordTimeOut = [NSString stringWithFormat:@"%@", [dict objectForKey:@"chatRecordTimeOut"]];
//                    user.offlineNoPushMsg = [[dict objectForKey:@"member"] objectForKey:@"offlineNoPushMsg"];
//                    user.talkTime = [dict objectForKey:@"talkTime"];
//                    user.allowInviteFriend = [dict objectForKey:@"allowInviteFriend"];
//                    user.allowUploadFile = [dict objectForKey:@"allowUploadFile"];
//                    user.allowConference = [dict objectForKey:@"allowConference"];
//                    user.allowSpeakCourse = [dict objectForKey:@"allowSpeakCourse"];
//                    user.category = [dict objectForKey:@"category"];
//                    user.createUserId = [dict objectForKey:@"userId"];
//
//                    if (![user haveTheUser]){
//                        [user insertRoom];
//                    }else {
//                        [user updateUserNickname];
//                    }
//
//                }
//            }
//
//        }else{
//            if([array1 count]>0)
//                [tempArray addObjectsFromArray:array1];
//        }

        _refreshCount++;
        [_table reloadData];
    }
    if( [aDownload.action isEqualToString:act_UserGet] ){
        JXUserObject* user = [[JXUserObject alloc]init];
        [user getDataFromDict:dict];
        
        JXUserInfoVC* vc = [JXUserInfoVC alloc];
        vc.user       = user;
        vc.fromAddType = 6;
        vc = [vc init];
//        [g_window addSubview:vc.view];
        [g_navigation pushViewController:vc animated:YES];
//        [user release];
    }
    
    if( [aDownload.action isEqualToString:act_roomGet] ){
        
        JXUserObject* user = [[JXUserObject alloc]init];
        [user getDataFromDict:dict];
        
        NSDictionary * groupDict = [user toDictionary];
        roomData * roomdata = [[roomData alloc] init];
        [roomdata getDataFromDict:groupDict];
        
        [roomdata getDataFromDict:dict];
        
        // 非本群成员，不能进入
        BOOL flag = NO;
        for (NSInteger i = 0; i < roomdata.members.count; i ++) {
            memberData *data = roomdata.members[i];
            if (data.userId == [g_myself.userId longLongValue]) {
                flag = YES;
                break;
            }
        }
        if (!flag) {
            [g_App showAlert:Localized(@"JX_NotEnterRoom")];
            return;
        }
        
        JXRoomMemberVC* vc = [JXRoomMemberVC alloc];
        vc.chatRoom   = [[JXXMPP sharedInstance].roomPool joinRoom:roomdata.roomJid title:roomdata.name isNew:NO];
        vc.room       = roomdata;
        vc = [vc init];
//        [g_window addSubview:vc.view];
        [g_navigation pushViewController:vc animated:YES];
    }
    if( [aDownload.action isEqualToString:act_roomMemberSet] ){
    }
}

-(int) didServerResultFailed:(JXConnection*)aDownload dict:(NSDictionary*)dict{
    
    
    
    [_wait hide];
    return show_error;
}

-(int) didServerConnectError:(JXConnection*)aDownload error:(NSError *)error{//error为空时，代表超时
    [_wait hide];
    return show_error;
}

-(void) didServerConnectStart:(JXConnection*)aDownload{
    [_wait start];
}

//筛选点击
- (void)topItemBtnClick:(UIButton *)btn{
    [self checkAfterScroll:(btn.tag-100)];
    [_topSiftView resetAllParaBtn];
}

- (void)checkAfterScroll:(CGFloat)offsetX{
    if (offsetX == 0) {
        _selMenu = 0;
        if (_myGroupArray.count <= 0) {
            [self scrollToPageUp];
        }else {
            [self.tableView reloadData];
        }
    }else {
        _selMenu = 1;
        if (_allGroupArray.count <= 0) {
            [self scrollToPageUp];
        }else {
            [self.tableView reloadData];
        }
    }
    
}
-(void)scrollToPageUp{
    if(_isLoading)
        return;
    _page = 0;
    [self performSelector:@selector(stopLoading) withObject:nil afterDelay:1.0];
    
    if(_selMenu==1){
        
        [g_server listRoom:_page roomName:nil toView:self];
    }
    else{
        [g_server listHisRoom:_page pageSize:1000 toView:self];
    }
    
}
-(void)getServerData{
    self.isShowFooterPull = _selMenu == 1;
    if(_selMenu==1){
        
        [g_server listRoom:_page roomName:nil toView:self];
        self.isShowFooterPull = YES;
    }
    else{
        self.isShowFooterPull = NO;

        _myGroupArray = [[JXUserObject sharedInstance] fetchAllRoomsFromLocal];
        if (_myGroupArray.count <= 0) {
            [self scrollToPageUp];
        }else {
            [self.tableView reloadData];
        }
    }
}

-(void)onReceiveRoomRemind:(NSNotification *)notifacation//更改名称
{
    NSMutableArray * tempArray;
    if (_selMenu == 0) {
        tempArray = _myGroupArray;
    }else if (_selMenu == 1) {
        tempArray = _allGroupArray;
    }
    JXRoomRemind* p     = (JXRoomRemind *)notifacation.object;
    if([p.type intValue] == kRoomRemind_RoomName){
        for(int i=0;i<[tempArray count];i++){
            JXUserObject *user=tempArray[i];
            if([p.objectId isEqualToString:user.userId]){
                user.userNickname = p.content;
//                [dict setValue:p.content forKey:@"name"];
                NSIndexPath* row = [NSIndexPath indexPathForRow:i inSection:0];

                JXCell* cell = (JXCell*)[_table cellForRowAtIndexPath:row];
                cell.title = user.userNickname;
                cell = nil;
                
                break;
            }
//            dict = nil;
        }
//        self.title = p.content;
    }
    

    if([p.type intValue] == kRoomRemind_DelMember || [p.type intValue] == kRoomRemind_DelRoom){
        for(int i=0;i<[tempArray count];i++){
            JXUserObject *user=tempArray[i];
            if([p.objectId isEqualToString:user.userId] && [p.toUserId isEqualToString:MY_USER_ID]){
                [tempArray removeObjectAtIndex:i];
                _refreshCount++;
                [_table reloadData];
                break;
            }
//            dict = nil;
        }
    }
}

-(void)onQuitRoom:(NSNotification *)notifacation//删除房间
{
    NSMutableArray * tempArray;
    if (_selMenu == 0) {
        tempArray = _myGroupArray;
    }else if (_selMenu == 1) {
        tempArray = _allGroupArray;
    }
    JXRoomObject* p     = (JXRoomObject *)notifacation.object;
    for(int i=0;i<[tempArray count];i++){
        JXUserObject *user=tempArray[i];
        if([p.roomJid isEqualToString:user.userId]){
            [tempArray removeObjectAtIndex:i];
            _refreshCount++;
            [_table reloadData];
            break;
        }
//        dict = nil;
    }
    p = nil;
}

@end
