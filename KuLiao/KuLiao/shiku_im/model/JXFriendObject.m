//
//  JXFriendObject.m
//
//  Created by Reese on 13-8-11.
//  Copyright (c) 2013年 Reese. All rights reserved.
//

#import "JXFriendObject.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "AppDelegate.h"
#import "SBJsonParser.h"

@implementation JXFriendObject

static JXFriendObject *sharedUser;

+(JXFriendObject*)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedUser=[[JXFriendObject alloc]init];
    });
    return sharedUser;
}

-(id)init{
    self = [super init];
    if(self){
        _tableName = @"newFriend";
    }
    return self;
}

-(void)dealloc{
    NSLog(@"JXFriendObject.dealloc");
//    [super dealloc];
}

-(BOOL)insert{
    self.roomFlag   = [NSNumber numberWithInt:0];
    self.companyId  = [NSNumber numberWithInt:0];
    self.offlineNoPushMsg = [NSNumber numberWithInt:0];
    self.talkTime = [NSNumber numberWithLong:0];
    return [super insert];
}

-(JXFriendObject*)userFromDictionary:(NSDictionary*)aDic
{
    JXFriendObject* user = [[JXFriendObject alloc]init];
    [super userFromDictionary:user dict:aDic];
    return user;
}

-(NSMutableArray*)fetchAllFriendsFromLocal
{
    NSString* sql = @"select a.*,b.status as trueStatus from newfriend as a LEFT JOIN friend as b on a.userId=b.userId order by a.timeCreate desc";
    return [self doFetch:sql];
}

-(NSMutableArray*)doFetch:(NSString*)sql
{
    NSMutableArray *resultArr=[[NSMutableArray alloc]init];
    
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [super checkTableCreatedInDb:db];
    
    FMResultSet *rs=[db executeQuery:sql];
    while ([rs next]) {
        JXFriendObject *user=[[JXFriendObject alloc] init];
        [super userFromDataset:user rs:rs];
        [resultArr addObject:user];
//        [user release];
    }
    [rs close];
    if([resultArr count]==0){
//        [resultArr release];
        resultArr = nil;
    }
    return resultArr;
}

-(void)notifyNewRequest{
    //发送全局通知
    [g_notify postNotificationName:kXMPPNewRequestNotifaction object:self userInfo:nil];
}

-(void)doSaveUser{
    [self update];
    
    JXUserObject* user = [[JXUserObject alloc]init];
    [user loadFromObject:self];
    user.status = self.status;
    user.msgsNew = [NSNumber numberWithInt:0];
    user.content = nil;//很重要，必须有
    if([user haveTheUser])
        [user update];
    else{
        [user insert];
        [user notifyNewFriend];
    }
//    [user release];
}

//- (void)doSaveAddressBook{
//    NSDictionary *dict = (NSDictionary *)self.content;
//    JXAddressBook *addressBook = [[JXAddressBook alloc] init];
//    addressBook.toUserId = [NSString stringWithFormat:@"%@",dict[@"toUserId"]];
//    addressBook.toUserName = dict[@"toUserName"];
//    addressBook.toTelephone = dict[@"toTelephone"];
//    addressBook.telephone = dict[@"telephone"];
//    addressBook.registerEd = dict[@"registerEd"];
//    addressBook.registerTime = [NSDate dateWithTimeIntervalSince1970:[dict[@"registerTime"] longLongValue]];
//    addressBook.isRead = [NSNumber numberWithBool:0];
//    [addressBook insert];
//}

-(void)doDelUser{
    self.status = [NSNumber numberWithInt:friend_status_none];
    [self update];

    [JXUserObject deleteUserAndMsg:self.userId];
}

-(NSString*)doMsgForNewUser{
    NSString* s;
    JXMessageObject* p = [[JXMessageObject alloc] init];
    if([self.isMySend boolValue]){
        p.fromUserId     = MY_USER_ID;
        p.toUserId   = self.userId;
        s = Localized(@"JXFriendObject_ChatNow");
        p.isMySend    = YES;
    }else{
        p.fromUserId   = self.userId;
        p.toUserId     = MY_USER_ID;
        s = Localized(@"JXFriendObject_StartChat");
        p.isMySend    = NO;
        
    }
    if ([self.type intValue] == XMPP_TYPE_FRIEND) {
        p.fromUserId   = self.userId;
        p.toUserId     = MY_USER_ID;
        if ([self.isMySend boolValue]) {
            p.fromUserId = MY_USER_ID;
            p.toUserId = self.userId;
        }
        s = Localized(@"JXFriendObject_AddedFriend");
    }
    p.content      = s;
    p.type         = [NSNumber numberWithInt:kWCMessageTypeText];
    p.isSend       = [NSNumber numberWithInt:transfer_status_yes];
    p.isRead       = [NSNumber numberWithInt:1];
    p.timeSend     = [NSDate date];
    [p insert:nil];
    [p notifyNewMsg];
    
    JXUserObject *user = [[JXUserObject alloc] init];
    user.userId = self.userId;
    user.userNickname = self.userNickname;
    user.content = p.content;
    [user insert];
    
    return s;
}

-(void)onSendRequest{
    if(![self.isMySend boolValue])
        return;
    NSNumber* tempStatus=nil;
    JXUserObject* user = [[JXUserObject sharedInstance] getUserById:self.userId];
    if(user)
        tempStatus = user.status;//先记住之前的关系
    switch ([self.type intValue]) {
        case XMPP_TYPE_SAYHELLO:
            if([tempStatus intValue]<=friend_status_none){
                self.status = [NSNumber numberWithInt:friend_status_see];
                [self doSaveUser];
            }
            break;
        case XMPP_TYPE_PASS:
        case XMPP_TYPE_CONTACTFRIEND:
            self.status = [NSNumber numberWithInt:friend_status_friend];
            [self doSaveUser];
            [g_notify postNotificationName:kFriendPassNotif object:self];
//            [self doMsgForNewUser];
            break;
        case XMPP_TYPE_FEEDBACK:
            break;
        case XMPP_TYPE_NEWSEE:
            if([tempStatus intValue]<=friend_status_none){//新关注他人时，除非关系小于0,否则都用原来的关系,有可能已为2
                self.status = [NSNumber numberWithInt:friend_status_see];
                [self doSaveUser];
            }
            break;
        case XMPP_TYPE_DELSEE://删除关注
            [self doDelUser];
            break;
        case XMPP_TYPE_SEVERDELFRIEND:
        case XMPP_TYPE_DELALL:
            [self doDelUser];
            break;
        case XMPP_TYPE_SEVERDEL:
            [self doDelUser];
            break;
        case XMPP_TYPE_SEVERBLACK:
        case XMPP_TYPE_BLACK:
            self.status = [NSNumber numberWithInt:friend_status_black];
            [self doSaveUser];//建立黑名单
            [self notifyDelFriend];
            break;
        case XMPP_TYPE_SEVERNOBLACK:
        case XMPP_TYPE_NOBLACK:
            self.status = [NSNumber numberWithInt:friend_status_friend];
            [self doSaveUser];//取消黑名单
            break;
        case XMPP_TYPE_FRIEND:
            self.status = [NSNumber numberWithInt:friend_status_friend];
            [self doSaveUser];
            [self doMsgForNewUser];
            [g_notify postNotificationName:kFriendPassNotif object:self];
            break;
        default:
            break;
    }
//    [user release];
}

-(void)onReceiveRequest{
    if([self.isMySend boolValue])
        return;
    NSNumber* tempStatus=nil;
    JXUserObject* user = [[JXUserObject sharedInstance] getUserById:self.userId];
    if(user)
        tempStatus = user.status;//先记住之前的关系

    if([tempStatus intValue]<friend_status_none){//来者是我的黑名单时，直接忽略
//        [user release];
        return;
    }
    
    switch ([self.type intValue]) {
        case XMPP_TYPE_SAYHELLO:
            break;
        case XMPP_TYPE_PASS:
        case XMPP_TYPE_CONTACTFRIEND:
            self.status = [NSNumber numberWithInt:friend_status_friend];
            [self doSaveUser];
            [self doMsgForNewUser];
            [g_notify postNotificationName:kFriendPassNotif object:self];
            break;
        case XMPP_TYPE_FEEDBACK:
            break;
        case XMPP_TYPE_NEWSEE:
            if([tempStatus intValue]==friend_status_see){//如果原来已关注，则升级为互粉
                self.status = [NSNumber numberWithInt:friend_status_friend];
                [self doSaveUser];
            }
            break;
        case XMPP_TYPE_DELSEE:
            if([tempStatus intValue]==friend_status_friend){//如果原来已关注，则降级为单方
                self.status = [NSNumber numberWithInt:friend_status_see];
                [self doSaveUser];
            }
            break;
            
        case XMPP_TYPE_SEVERDELFRIEND:
        case XMPP_TYPE_DELALL:
            [self doDelUser];
            break;
        case XMPP_TYPE_SEVERDEL:
            [self doDelUser];
            break;
        case XMPP_TYPE_SEVERBLACK:
        case XMPP_TYPE_BLACK:
            self.status = [NSNumber numberWithInt:friend_status_hisBlack];
            [self doSaveUser];//建立黑名单
            [self notifyDelFriend];
            break;
        case XMPP_TYPE_SEVERNOBLACK:
        case XMPP_TYPE_NOBLACK:
            self.status = [NSNumber numberWithInt:friend_status_friend];
            [self doSaveUser];
            break;
        case XMPP_TYPE_FRIEND:
            self.status = [NSNumber numberWithInt:friend_status_friend];
            [self doSaveUser];
            [self doMsgForNewUser];
            break;
            
//        case XMPP_TYPE_CONTACTREGISTER:
//            [self doSaveAddressBook];
//            [g_notify postNotificationName:kRefreshAddressBookNotif object:nil];
//            break;
        default:
            break;
    }
//    [user release];
}

-(void)loadFromMessageObj:(JXMessageObject*)msg{
    self.type = msg.type;
    self.content = msg.content;
    self.timeSend = msg.timeSend;
    self.isMySend = [NSNumber numberWithBool:msg.isMySend];
    if([self.isMySend boolValue]){
        self.userId = msg.toUserId;
        self.userNickname = msg.toUserName;
    }else{
        self.userId = msg.fromUserId;
        self.userNickname = msg.fromUserName;
    }
    
    if ([msg.type integerValue] == XMPP_TYPE_SEVERDEL) {
        self.userId = [NSString stringWithFormat:@"%@",msg.objectId];
        self.userNickname = [self getUserNameWithUserId:self.userId];
    }
    
    if ([msg.type integerValue] == XMPP_TYPE_SEVERBLACK || [msg.type integerValue] == XMPP_TYPE_SEVERNOBLACK || [msg.type integerValue] == XMPP_TYPE_SEVERDELFRIEND) {
        
        SBJsonParser * resultParser = [[SBJsonParser alloc] init] ;
        NSDictionary *resultObject = [resultParser objectWithString:msg.objectId];
        
        if ([resultObject[@"toUserId"] isEqualToString:MY_USER_ID]) {
            self.userId = resultObject[@"fromUserId"];
            self.userNickname = resultObject[@"fromUserName"];
            self.isMySend = [NSNumber numberWithBool:NO];
        }else {
            self.userNickname = resultObject[@"toUserName"];
            self.userId = resultObject[@"toUserId"];
            self.isMySend = [NSNumber numberWithBool:YES];
        }
    }
    
    JXFriendObject *user = [self selectUser:self.userId];
    self.status = user.status;
    self.msgsNew = user.msgsNew;
    if (user.userNickname.length > 0) {
        self.userNickname = user.userNickname;
    }
    [self insert];
}

-(void)doWriteDb{
    if([self.isMySend boolValue])
        [self onSendRequest];
    else
        [self onReceiveRequest];
}

-(NSString*)getLastContent{
    NSString* s = self.content;
    int n = [self.type intValue];
    if([self.isMySend boolValue]){
        switch (n) {
            case XMPP_TYPE_SAYHELLO:
                s= Localized(@"JXFriendObject_WaitPass");
                break;
            case XMPP_TYPE_PASS:
                s = Localized(@"JXFriendObject_Passed");
                break;
            case XMPP_TYPE_FEEDBACK:
                s = self.content;
                break;
            case XMPP_TYPE_NEWSEE:
                s = Localized(@"JXFriendObject_Followed");
                break;
            case XMPP_TYPE_DELSEE:
                s = Localized(@"JXFriendObject_CencalFollowed");
                break;
            case XMPP_TYPE_SEVERDELFRIEND:
            case XMPP_TYPE_DELALL:
                s = [NSString stringWithFormat:@"%@ %@",Localized(@"JXAlert_DeleteFirend"),self.userNickname];
                break;
            case XMPP_TYPE_SEVERDEL:
                s = self.content;
                break;
            case XMPP_TYPE_SEVERBLACK:
            case XMPP_TYPE_BLACK:
                s = [NSString stringWithFormat:@"%@ %@",Localized(@"JXFriendObject_AddedBlackList"),self.userNickname];
                break;
            case XMPP_TYPE_SEVERNOBLACK:
            case XMPP_TYPE_NOBLACK:
                s = [NSString stringWithFormat:@"%@ %@",MY_USER_NAME,Localized(@"JXFriendObject_NoBlack")];
                break;
            case XMPP_TYPE_FRIEND:
                s = Localized(@"JXFriendObject_AddedFriend");
                break;
            case XMPP_TYPE_CONTACTFRIEND:
                s = Localized(@"JX_FriendsViaMobileContacts");
                break;
            default:
                break;
        }
    }else{
        switch (n) {
            case XMPP_TYPE_SAYHELLO:
                s = self.content;
                break;
            case XMPP_TYPE_PASS:
                s = Localized(@"JXFriendObject_PassGo");
                break;
            case XMPP_TYPE_FEEDBACK:
                s = self.content;
                break;
            case XMPP_TYPE_NEWSEE:
                s = Localized(@"JXFriendObject_FollowYour");
                break;
            case XMPP_TYPE_DELSEE:
                s = Localized(@"JXFriendObject_CancelFollow");
                break;
            case XMPP_TYPE_SEVERDELFRIEND:
            case XMPP_TYPE_DELALL:
                s = [NSString stringWithFormat:@"%@ %@",self.userNickname,Localized(@"JXFriendObject_Deleted")];
                break;
            case XMPP_TYPE_SEVERDEL:
                s = self.content;
                break;
            case XMPP_TYPE_RECOMMEND:
                s = Localized(@"JXFriendObject_RecomYou");
                break;
            case XMPP_TYPE_SEVERBLACK:
            case XMPP_TYPE_BLACK:
                s = [NSString stringWithFormat:@"%@ %@",self.userNickname,Localized(@"JXFriendObject_PulledBlack")];
                break;
            case XMPP_TYPE_SEVERNOBLACK:
            case XMPP_TYPE_NOBLACK:
                s = [NSString stringWithFormat:@"%@ %@",self.userNickname,Localized(@"JXFriendObject_NoBlack")];
                break;
            case XMPP_TYPE_FRIEND:
                s = Localized(@"JXFriendObject_BeAddFriend");
                break;
            case XMPP_TYPE_CONTACTFRIEND:
                s = Localized(@"JX_FriendsViaMobileContacts");
                break;
            default:
                break;
        }
    }
    return s;
}

// 查找user
- (JXFriendObject *)selectUser:(NSString *)userId {
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkTableCreatedInDb:db];
    
    FMResultSet *rs=[db executeQuery:[NSString stringWithFormat:@"select * from %@ where userId=?",_tableName],userId];
    JXFriendObject *user=[[JXFriendObject alloc] init];
    while ([rs next]) {
        [super userFromDataset:user rs:rs];
        //        [user release];
    }
    [rs close];
    
    return user;
}

-(JXFriendObject*)getFriendById:(NSString*)userId {
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    
    FMResultSet *rs=[db executeQuery:[NSString stringWithFormat:@"select * from %@ where userId=?",_tableName],userId];
    if ([rs next]) {
        JXFriendObject *friend=[[JXFriendObject alloc]init];
        [super userFromDataset:friend rs:rs];
        [rs close];
        return friend;
    };
    return nil;
}

// 更新新消息
- (BOOL)updateNewMsgUserId:(NSString *)userId num:(int)num {
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:MY_USER_ID];
    [self checkTableCreatedInDb:db];
    NSString *sql = [NSString stringWithFormat:@"update %@ set newMsgs=? where userId=?",_tableName];
    BOOL worked=[db executeUpdate:sql,[NSNumber numberWithInt:num],userId];
    return worked;
}

-(NSString*)getUserNameWithUserId:(NSString*)userId{
    if(userId==nil)
        return nil;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:MY_USER_ID];
    //获取用户名
    NSString* sql= [NSString stringWithFormat:@"select userNickname from %@ where userId=%@",_tableName,userId];
    FMResultSet *rs=[db executeQuery:sql];
    if([rs next]) {
        NSString* s = [rs objectForColumnName:@"userNickname"];
        return s;
    }
    
    return nil;
}

@end
