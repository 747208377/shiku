//
//  JXDidPushObj.m
//  shiku_im
//
//  Created by p on 2019/5/14.
//  Copyright © 2019年 Reese. All rights reserved.
//

#import "JXDidPushObj.h"
#import "WeiboViewControlle.h"
#import "JXNewFriendViewController.h"
#import "JXMsgViewController.h"
#import "JXTransferNoticeVC.h"
#import "JXChatViewController.h"
#import "JXRoomPool.h"
#import "JXFriendViewController.h"

@implementation JXDidPushObj

static JXDidPushObj *shared;

+(JXDidPushObj*)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared=[[JXDidPushObj alloc]init];
    });
    return shared;
}

- (instancetype)init {
    if ([super init]) {
        
        [g_notify addObserver:self selector:@selector(onLoginChanged:) name:kXmppLoginNotifaction object:nil];//登录状态变化了
    }
    return self;
}
-(void)onLoginChanged:(NSNotification *)notifacation{
    
    switch ([JXXMPP sharedInstance].isLogined){
        case login_status_ing:{

        }
            break;
        case login_status_no:{

        }
            break;
        case login_status_yes:{
            [self didReceiveRemoteNotif];
        }
            
            break;
    }
}

// 点击推送
- (void)didReceiveRemoteNotif {
    
    NSDictionary *dict = [g_default objectForKey:kDidReceiveRemoteDic];
    if (!dict) {
        return;
    }
    
    [g_default setObject:nil forKey:kDidReceiveRemoteDic];
    [g_default synchronize];
    
    
    NSString *url = [dict objectForKey:@"url"];
    if (url.length > 0) {
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];  
        
        return;
    }
    
    
    [g_navigation popToRootViewController];
    
    if ([[dict objectForKey:@"messageType"] intValue] == kWCMessageTypeWeiboPraise || [[dict objectForKey:@"messageType"] intValue] == kWCMessageTypeWeiboComment || [[dict objectForKey:@"messageType"] intValue] == kWCMessageTypeWeiboRemind) {
        
        [g_mainVC doSelected:2];
        
        WeiboViewControlle *weiboVC = [WeiboViewControlle alloc];
        weiboVC.user = g_server.myself;
        weiboVC = [weiboVC init];
        [g_navigation pushViewController:weiboVC animated:YES];
        
        return;
    }
    
    if ([[dict objectForKey:@"messageType"] intValue]/100==5) {
        
        [g_mainVC doSelected:1];
        // 清空角标
        JXMsgAndUserObject* newobj = [[JXMsgAndUserObject alloc]init];
        newobj.user = [[JXUserObject sharedInstance] getUserById:FRIEND_CENTER_USERID];
        newobj.message = [[JXMessageObject alloc] init];
        newobj.message.toUserId = FRIEND_CENTER_USERID;
        newobj.user.msgsNew = [NSNumber numberWithInt:0];
        [newobj.message updateNewMsgsTo0];
        
        NSArray *friends = [[JXFriendObject sharedInstance] fetchAllFriendsFromLocal];
        for (NSInteger i = 0; i < friends.count; i ++) {
            JXFriendObject *friend = friends[i];
            if ([friend.msgsNew integerValue] > 0) {
                [friend updateNewMsgUserId:friend.userId num:0];
            }
        }
        
        [g_mainVC.friendVC showNewMsgCount:0];
        
        JXNewFriendViewController* vc = [[JXNewFriendViewController alloc]init];
        [g_navigation pushViewController:vc animated:YES];
        
        return;
    }
    
    
    [g_mainVC doSelected:0];
    
    
    //    NSDictionary *dict = notif.object;
    
    NSString *userId = [dict objectForKey:@"from"];
    if ([dict objectForKey:@"roomJid"]) {
        userId = [dict objectForKey:@"roomJid"];
    }
    
    JXUserObject *user = [[JXUserObject sharedInstance] getUserById:userId];
    JXMessageObject *p=[[JXMessageObject alloc]init];
    //        [p fromRs:rs];
    p.content = user.content;
    p.type = user.type;
    p.timeSend = user.timeSend;
    p.fromUserId = user.userId;
    p.toUserId = MY_USER_ID;
    
    //    JXMsgAndUserObject *p=[array objectAtIndex:indexPath.row];
    if (![user.userId isEqualToString:FRIEND_CENTER_USERID]) {
        g_mainVC.msgVc.msgTotal -= [user.msgsNew intValue];
    }
    [UIApplication sharedApplication].applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber - [user.msgsNew intValue];
//    [g_server userChangeMsgNum:[UIApplication sharedApplication].applicationIconBadgeNumber toView:self];
    
    if([user.userId isEqualToString:FRIEND_CENTER_USERID]){
        JXNewFriendViewController* vc = [[JXNewFriendViewController alloc]init];
        //        [g_App.window addSubview:vc.view];
        [g_navigation pushViewController:vc animated:YES];
        return;
    }
    if ([user.userId intValue] == [SHIKU_TRANSFER intValue]) {
        JXTransferNoticeVC *noticeVC = [[JXTransferNoticeVC alloc] init];
        [g_navigation pushViewController:noticeVC animated:YES];
        user.msgsNew = [NSNumber numberWithInt:0];
        [p updateNewMsgsTo0];
        [g_mainVC.msgVc getTotalNewMsgCount];
        return;
    }
    
    JXChatViewController *sendView=[JXChatViewController alloc];
    
    //    sendView.scrollLine = lineNum;
    sendView.title = user.remarkName.length > 0 ? user.remarkName : user.userNickname;
    if([user.roomFlag intValue] > 0 || user.roomId.length > 0){
        //        if(g_xmpp.isLogined != 1){
        //            // 掉线后点击title重连
        //            [g_xmpp showXmppOfflineAlert];
        //            return;
        //        }
        
        sendView.roomJid = user.userId;
        sendView.roomId   = user.roomId;
        sendView.groupStatus = user.groupStatus;
        if ([user.groupStatus intValue] == 0) {
            
            sendView.chatRoom  = [[JXXMPP sharedInstance].roomPool joinRoom:user.userId title:user.userNickname isNew:NO];
        }
        
        if (user.roomFlag || user.roomId.length > 0) {
            NSDictionary * groupDict = [user toDictionary];
            roomData * roomdata = [[roomData alloc] init];
            [roomdata getDataFromDict:groupDict];
            sendView.room = roomdata;
            sendView.newMsgCount = [user.msgsNew intValue];
            
            
            user.isAtMe = [NSNumber numberWithInt:0];
            [user updateIsAtMe];
        }
        
    }
    //    sendView.rowIndex = indexPath.row;
    sendView.lastMsg = p;
    sendView.chatPerson = user;
    sendView = [sendView init];
    //    [g_App.window addSubview:sendView.view];
    [g_navigation pushViewController:sendView animated:YES];
    sendView.view.hidden = NO;
    
    user.msgsNew = [NSNumber numberWithInt:0];
    [p updateNewMsgsTo0];
    
    [g_mainVC.msgVc cancelBtnAction];
    
    [g_mainVC.msgVc getTotalNewMsgCount];
    
}

@end
