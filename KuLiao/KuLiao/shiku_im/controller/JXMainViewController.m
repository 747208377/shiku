//
//  JXMainViewController.m
//
//  Created by flyeagleTang on 14-4-3.
//  Copyright (c) 2014年 Reese. All rights reserved.
//

#import "JXMainViewController.h"
#import "JXTabMenuView.h"
#import "JXMsgViewController.h"
#import "JXFriendViewController.h"
#import "AppDelegate.h"
#import "JXNewFriendViewController.h"
#import "JXFriendObject.h"
#import "PSMyViewController.h"
#ifdef Live_Version
#import "JXLiveViewController.h"
#endif

#import "WeiboViewControlle.h"
#import "JXSquareViewController.h"
#import "JXProgressVC.h"
#import "JXGroupViewController.h"
#import "OrganizTreeViewController.h"
#import "JXLabelObject.h"
#import "JXBlogRemind.h"

@implementation JXMainViewController
@synthesize tb=_tb;

@synthesize btn=_btn,mainView=_mainView;
@synthesize IS_HR_MODE;

@synthesize psMyviewVC=_psMyviewVC;



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
//        self.view.frame = CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT);
        self.view.backgroundColor = [UIColor clearColor];

//        g_navigation.lastVC = nil;
//        [g_navigation.subViews removeAllObjects];
//        [g_navigation pushViewController:self animated:YES];
//        
        _topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_TOP)];
        //        [self.view addSubview:_topView];
//        [_topView release];
        
        _mainView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT-JX_SCREEN_BOTTOM)];
        [self.view addSubview:_mainView];
//        [_mainView release];
        
        _bottomView = [[UIImageView alloc] initWithFrame:CGRectMake(0, JX_SCREEN_HEIGHT-JX_SCREEN_BOTTOM, JX_SCREEN_WIDTH, JX_SCREEN_BOTTOM)];
        _bottomView.userInteractionEnabled = YES;
        _bottomView.backgroundColor = THESIMPLESTYLE ? HEXCOLOR(0xF1F1F1) : [UIColor whiteColor];
        [self.view addSubview:_bottomView];
//        [_bottomView release];
        
        [self buildTop];
        
        [g_notify addObserver:self selector:@selector(onXmppLoginChanged:) name:kXmppLoginNotifaction object:nil];
        [g_notify addObserver:self selector:@selector(hasLoginOther:) name:kXMPPLoginOtherNotification object:nil];
        [g_notify addObserver:self selector:@selector(appEnterForegroundNotif:) name:kApplicationWillEnterForeground object:nil]; // 进入前台

#ifdef IS_SHOW_MENU
        _squareVC = [[JXSquareViewController alloc] init];
#else
        _weiboVC = [WeiboViewControlle alloc];
        _weiboVC.user = g_server.myself;
        _weiboVC = [_weiboVC init];
#endif
        if (g_server.isManualLogin) {
            
            _groupVC = [JXGroupViewController alloc];
            [_groupVC scrollToPageUp];
        }
        _msgVc = [[JXMsgViewController alloc] init];
        _friendVC = [[JXFriendViewController alloc] init];
        _psMyviewVC = [[PSMyViewController alloc] init];
//#ifdef Live_Version
//        _liveVC = [[JXLiveViewController alloc]init];
//#else
//        _organizVC = [[OrganizTreeViewController alloc] init];
//#endif
//
        
        [self doSelected:0];

        [g_notify addObserver:self selector:@selector(loginSynchronizeFriends:) name:kXmppClickLoginNotifaction object:nil];
        [g_notify addObserver:self selector:@selector(appDidEnterForeground) name:kApplicationWillEnterForeground object:nil];
        [g_notify addObserver:self selector:@selector(getUserInfo:) name:kXMPPMessageUpadteUserInfoNotification object:nil];
        [g_notify addObserver:self selector:@selector(getRoomSet:) name:kXMPPMessageUpadteGroupNotification object:nil];
    }
    return self;
}

- (void)appEnterForegroundNotif:(NSNotification *)noti {
    [g_server offlineOperation:(g_server.lastOfflineTime *1000 + g_server.timeDifference)/1000 toView:self];
}

- (void)getUserInfo:(NSNotification *)noti {
    JXMessageObject *msg = noti.object;
    [g_server getUser:msg.toUserId toView:self];
}

- (void)getRoomSet:(NSNotification *)noti {
    JXMessageObject *msg = noti.object;
    [g_server getRoom:msg.toUserId toView:self];
}

-(void)dealloc{
//    [_psMyviewVC.view release];
//    [_msgVc.view release];
    [g_notify removeObserver:self name:kXmppLoginNotifaction object:nil];
    [g_notify removeObserver:self name:kSystemLoginNotifaction object:nil];
    [g_notify removeObserver:self name:kXmppClickLoginNotifaction object:nil];
    [g_notify removeObserver:self name:kXMPPLoginOtherNotification object:nil];
    [g_notify removeObserver:self name:kApplicationWillEnterForeground object:nil];
    [g_notify removeObserver:self name:kXMPPMessageUpadteUserInfoNotification object:nil];
//    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self loginSynchronizeFriends:nil];
    
    if (g_server.isManualLogin) {
        
        NSArray *array = [[JXLabelObject sharedInstance] fetchAllLabelsFromLocal];
        if (array.count <= 0) {
            // 同步标签
            [g_server friendGroupListToView:self];
        }
    }
    
    // 获取服务器时间
    [g_server getCurrentTimeToView:self];
//    // 获取离线调用接口列表
//    [g_server offlineOperation:(g_server.lastOfflineTime *1000 + g_server.timeDifference)/1000 toView:self];
}


- (void)appDidEnterForeground {
    // 获取服务器时间
    [g_server getCurrentTimeToView:self];
}

- (void)loginSynchronizeFriends:(NSNotification*)notification{
    //判断服务器好友数量是否与本地一致
    _friendArray = [g_server.myself fetchAllFriendsOrNotFromLocal];
//    NSLog(@"%d -------%ld",[g_server.myself.friendCount intValue] , [_friendArray count]);
//    if ([g_server.myself.friendCount intValue] > [_friendArray count] && [g_server.myself.friendCount intValue] >0) {
//        [g_App showAlert:Localized(@"JXAlert_SynchFirendOK") delegate:self];
    if ([g_myself.isupdate intValue] == 1 || _friendArray.count <= 0) {
        [g_server listAttention:0 userId:MY_USER_ID toView:self];
    }else{
        
        [[JXXMPP sharedInstance] performSelector:@selector(login) withObject:nil afterDelay:2];//2秒后执行xmpp登录
    }
    
//    }
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag == 10002) {
        [g_server performSelector:@selector(showLogin) withObject:nil afterDelay:0.5];
        return;
    }else if (buttonIndex == 1) {
        [g_server listAttention:0 userId:MY_USER_ID toView:self];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

-(void)buildTop{
    _tb = [JXTabMenuView alloc];
//    NSString * thirdSrt;
//    NSString * thirdImgStr;
//    NSString * thiidSelectImgSrt;
//#ifdef Live_Version
//    thirdSrt = Localized(@"JXLiveVC_Live");
//    thirdImgStr = @"live_normal";
//    thiidSelectImgSrt = @"live_press";
//#else
//    thirdSrt = Localized(@"JX_Colleague");
//    thirdImgStr = @"my_organizBook";
//    thiidSelectImgSrt = @"my_organizBook_press";
//#endif
    
    _tb.items = [NSArray arrayWithObjects:Localized(@"JXMainViewController_Message"),Localized(@"JX_MailList"),Localized(@"JXMainViewController_Find"),Localized(@"JX_My"),nil];
    
    _tb.imagesNormal = [NSArray arrayWithObjects:@"news_normal",@"group_chat_normal",@"find_normal",@"me_normal",nil];
    _tb.imagesSelect = [NSArray arrayWithObjects:@"news_press_gray",@"group_chat_press_gray",@"find_press_gray",@"me_press_gray",nil];
    
    _tb.delegate  = self;
    _tb.onDragout = @selector(onDragout:);
    [_tb setBackgroundImageName:@"MessageListCellBkg"];
    _tb.onClick  = @selector(actionSegment:);
    _tb = [_tb initWithFrame:CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_BOTTOM)];
    [_bottomView addSubview:_tb];
    
    
    NSMutableArray *remindArray = [[JXBlogRemind sharedInstance] doFetchUnread];
    [_tb setBadge:2 title:[NSString stringWithFormat:@"%ld",remindArray.count]];
}


-(void)actionSegment:(UIButton*)sender{
    [self doSelected:(int)sender.tag];
}

-(void)doSelected:(int)n{
    [_selectVC.view removeFromSuperview];
    switch (n){
        case 0:
            _selectVC = _msgVc;
            break;
        case 1:
            _selectVC = _friendVC;
            break;
        case 2:
#ifdef IS_SHOW_MENU
            _selectVC = _squareVC;
#else
            _selectVC = _weiboVC;
#endif
            break;
        case 3:
            _selectVC = _psMyviewVC;
            break;
    }
    [_tb selectOne:n];
    [_mainView addSubview:_selectVC.view];
}

-(void)onXmppLoginChanged:(NSNumber*)isLogin{
    if([JXXMPP sharedInstance].isLogined == login_status_yes)
        [self onAfterLogin];
    switch (_tb.selected){
        case 0:
            _btn.hidden = [JXXMPP sharedInstance].isLogined;
            break;
        case 1:
            _btn.hidden = ![JXXMPP sharedInstance].isLogined;
            break;
        case 2:
            _btn.hidden = NO;
            break;
        case 3:
            _btn.hidden = ![JXXMPP sharedInstance].isLogined;
            break;
    }
}

-(void)onAfterLogin{
//    [_msgVc scrollToPageUp];
}

-(void)hasLoginOther:(NSNotification *)notifcation{
    [g_App showAlert:Localized(@"JXXMPP_Other") delegate:self tag:10002 onlyConfirm:YES];
}

-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
    //更新本地好友
    if ([aDownload.action isEqualToString:act_AttentionList]) {
        JXProgressVC * pv = [JXProgressVC alloc];
        pv.dbFriends = (long)[_friendArray count];
        pv.dataArray = array1;
        pv = [pv init];
        if (array1.count > 300) {
            [g_navigation pushViewController:pv animated:YES];
        }
//        [self.view addSubview:pv.view];
        
    }
    
    // 同步标签
    if ([aDownload.action isEqualToString:act_FriendGroupList]) {
        
        for (NSInteger i = 0; i < array1.count; i ++) {
            NSDictionary *dict = array1[i];
            JXLabelObject *labelObj = [[JXLabelObject alloc] init];
            labelObj.groupId = dict[@"groupId"];
            labelObj.groupName = dict[@"groupName"];
            labelObj.userId = dict[@"userId"];
            
            NSArray *userIdList = dict[@"userIdList"];
            NSString *userIdListStr = [userIdList componentsJoinedByString:@","];
            if (userIdListStr.length > 0) {
                labelObj.userIdList = [NSString stringWithFormat:@"%@", userIdListStr];
            }
            [labelObj insert];
        }
        
        // 删除服务器上已经删除的
        NSArray *arr = [[JXLabelObject sharedInstance] fetchAllLabelsFromLocal];
        for (NSInteger i = 0; i < arr.count; i ++) {
            JXLabelObject *locLabel = arr[i];
            BOOL flag = NO;
            for (NSInteger j = 0; j < array1.count; j ++) {
                NSDictionary * dict = array1[j];
               
                if ([locLabel.groupId isEqualToString:dict[@"groupId"]]) {
                    flag = YES;
                    break;
                }
            }
            
            if (!flag) {
                [locLabel delete];
            }
        }
    }
    if ([aDownload.action isEqualToString:act_offlineOperation]) {
        for (NSDictionary *dict in array1) {
            if ([[dict objectForKey:@"tag"] isEqualToString:@"label"]) {
                [g_notify postNotificationName:kOfflineOperationUpdateLabelList object:nil];
            }
            else if ([[dict objectForKey:@"tag"] isEqualToString:@"friend"]) {
                [g_server getUser:[dict objectForKey:@"friendId"] toView:self];
            }
            else if ([[dict objectForKey:@"tag"] isEqualToString:@"room"]) {
                [g_server getRoom:[dict objectForKey:@"friendId"] toView:self];
            }
        }
    }
    if ([aDownload.action isEqualToString:act_UserGet]) {
        JXUserObject *user = [[JXUserObject alloc] init];
        [user getDataFromDict:dict];
        JXUserObject *user1 = [[JXUserObject sharedInstance] getUserById:user.userId];
        user.content = user1.content;
        
        [user update];
        
        [g_notify postNotificationName:kOfflineOperationUpdateUserSet object:user];
    }
    if ([aDownload.action isEqualToString:act_roomGet]) {
        JXUserObject *user = [[JXUserObject alloc] init];
        [user getDataFromDict:dict];
        
        NSDictionary * groupDict = [user toDictionary];
        roomData * roomdata = [[roomData alloc] init];
        [roomdata getDataFromDict:groupDict];
        
        [roomdata getDataFromDict:dict];

        JXUserObject *user1 = [[JXUserObject sharedInstance] getUserById:roomdata.roomJid];
        user.content = user1.content;
        user.userId = roomdata.roomJid;
        user.status = user1.status;
        user.userNickname = roomdata.name;
        user.roomId = roomdata.roomId;
        
        [user update];
        
        [g_notify postNotificationName:kOfflineOperationUpdateUserSet object:user];
    }

}

-(int) didServerResultFailed:(JXConnection*)aDownload dict:(NSDictionary*)dict{
    
    return hide_error;
}

-(int) didServerConnectError:(JXConnection*)aDownload error:(NSError *)error{//error为空时，代表超时
    
    return hide_error;
}

@end
