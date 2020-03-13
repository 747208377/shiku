//
//  JXUserObject.m
//
//  Created by Reese on 13-8-11.
//  Copyright (c) 2013年 Reese. All rights reserved.
//

#import "JXUserObject.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "AppDelegate.h"
#import "JXFriendObject.h"
#import "JXMessageObject.h"
#import "roomData.h"
#import "resumeData.h"
#import "DESUtil.h"
#import "JXRoomRemind.h"

@implementation JXUserObject

@synthesize
telephone,
password,
birthday,
companyName,
model,
osVersion,
serialNumber,
location,
//description,
sex,
countryId,
provinceId,
cityId,
areaId,
latitude,
longitude,
level,
vip,
fansCount,
attCount;


static JXUserObject *sharedUser;

+(JXUserObject*)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedUser=[[JXUserObject alloc]init];
    });
    return sharedUser;
}

-(id)init{
    self = [super init];
    if(self){
        _tableName = @"friend";
        
        _favorites = [NSMutableArray array];
        _phoneDic = [NSMutableDictionary dictionary];
        _msgBackGroundUrl = [NSString string];
    }
    return self;
}

-(void)dealloc{
    self.telephone = nil;
    self.password = nil;
    self.userType = nil;
    self.birthday = nil;
    self.companyName = nil;
    self.model = nil;
    self.osVersion = nil;
    self.serialNumber = nil;
    self.location = nil;
    self.sex = nil;
    self.role = nil;
    self.countryId = nil;
    self.provinceId = nil;
    self.cityId = nil;
    self.areaId = nil;
    self.latitude = nil;
    self.longitude = nil;
    self.level = nil;
    self.vip = nil;
    self.fansCount = nil;
    self.attCount = nil;
    self.myInviteCode = nil;
//    NSLog(@"JXUserObject.dealloc");
//    [super dealloc];
}

-(BOOL)insert{
    self.roomFlag   = [NSNumber numberWithInt:0];
    self.companyId  = [NSNumber numberWithInt:0];
    self.offlineNoPushMsg = [NSNumber numberWithInt:0];
    self.isAtMe = [NSNumber numberWithInt:0];
    self.talkTime = [NSNumber numberWithLong:0];
    return [super insert];
}

-(BOOL)insertRoom
{
    self.roomFlag= [NSNumber numberWithInt:1];
    self.companyId= [NSNumber numberWithInt:0];
    self.status= [NSNumber numberWithInt:2];
    self.offlineNoPushMsg = [NSNumber numberWithInt:0];
    self.isAtMe = [NSNumber numberWithInt:0];
    return [super insert];
}

-(JXUserObject*)userFromDictionary:(NSDictionary*)aDic
{
    JXUserObject* user = [[JXUserObject alloc]init];
    [super userFromDictionary:user dict:aDic];
    return user;
}
//好友关系
-(NSMutableArray*)fetchAllFriendsFromLocal
{
    NSString* sql = @"select * from friend where (status=2 or status=10) and companyId=0 and roomFlag=0 and isDevice=0 and userType <> 2 order by status desc, timeCreate desc";
    return [self doFetch:sql];
}

// 获取系统公众号
-(NSMutableArray*)fetchSystemUser {
    NSString* sql = @"select * from friend where (userType=2 and (status=8 or status=2) and companyId=0 and roomFlag=0 and isDevice=0) or userId=1100 order by timeCreate asc";
    return [self doFetch:sql];
}

//搜索好友
-(NSMutableArray*)fetchFriendsFromLocalWhereLike:(NSString *)searchStr
{
    NSString* sql = [NSString stringWithFormat:@"select * from friend where (status=8 or status=2) and companyId=0 and roomFlag=0  and userNickname like '%%%@%%' order by status desc, timeCreate desc",searchStr];
    return [self doFetch:sql];
}

//所有联系人,0没任何关系，－1黑名单，2好友关系，8系统账号，1单向关注
-(NSMutableArray*)fetchAllFriendsOrNotFromLocal
{
    NSString* sql = @"select * from friend where (status=-1 or status=1 or status=2) and companyId=0 and roomFlag=0 order by status desc, timeCreate desc";
    return [self doFetch:sql];
}

-(NSMutableArray*)fetchAllRoomsFromLocal
{
    NSString* sql = @"select * from friend where roomFlag=1 and companyId =0 order by status desc, timeCreate desc";
    return [self doFetch:sql];
}

// 获取指定类型群组
-(NSMutableArray*)fetchRoomsFromLocalWithCategory:(NSNumber *)category
{
    NSString* sql = [NSString stringWithFormat:@"select * from friend where roomFlag=1 and category=%@ and companyId =0 order by status desc, timeCreate desc",category];
    ;
    return [self doFetch:sql];
}

-(NSMutableArray*)fetchAllCompanyFromLocal
{
    NSString* sql = [NSString stringWithFormat:@"select * from friend where companyId>0 and roomFlag=0 and userId!='%@' order by status desc, timeCreate desc",MY_USER_ID];
    return [self doFetch:sql];
}
//主动打招呼后status＝1
-(NSMutableArray*)fetchAllPayFromLocal
{
    NSString* sql = [NSString stringWithFormat:@"select * from friend where status=1 and companyId=0 and roomFlag=0 and userId!='%@' order by status desc, timeCreate desc",MY_USER_ID];
    return [self doFetch:sql];
}

-(NSMutableArray*)fetchAllUserFromLocal
{
    NSString* sql = [NSString stringWithFormat:@"select * from friend where status=2 and companyId=0 and roomFlag=0 and userId!='%@' order by status desc, timeCreate desc",MY_USER_ID];
    return [self doFetch:sql];
}

-(NSMutableArray*)fetchAllBlackFromLocal
{
    NSString* sql = @"select * from friend where status=-1 order by status desc, timeCreate desc";
    return [self doFetch:sql];
}

-(NSMutableArray*)fetchBlackFromLocalWhereLike:(NSString *)searchStr
{
    NSString* sql = [NSString stringWithFormat:@"select * from friend where status<0 and userNickname like '%%%@%%' order by status desc, timeCreate desc",searchStr];
    return [self doFetch:sql];
}

//插入本地不存在的好友
- (void)insertFriend{
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:g_server.myself.userId];
    FMResultSet * rs =  [db executeQuery:[NSString stringWithFormat:@"select * from friend where userId=?"],self.userId];
    if (![rs next]) {
        
        NSString *insertStr=[NSString stringWithFormat:@"INSERT INTO friend ('userId','userNickname','remarkName','role','createUserId','userDescription','userHead','roomFlag','category','timeCreate','newMsgs','status','userType','companyId','type','content','isMySend','roomId','timeSend','downloadTime','lastInput','showRead','showMember','allowSendCard','allowInviteFriend','allowUploadFile','allowConference','allowSpeakCourse','isNeedVerify','topTime','groupStatus','isOnLine','isOpenReadDel','isSendRecipt','isDevice','chatRecordTimeOut','offlineNoPushMsg','isAtMe','talkTime') VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"];
        BOOL worked = [db executeUpdate:insertStr,self.userId,self.userNickname,self.remarkName,self.role,self.createUserId,self.userDescription,nil,self.roomFlag,self.category,self.timeCreate,self.msgsNew,self.status,self.userType,self.companyId,self.type,self.content,self.isMySend,self.roomId,self.timeSend,self.downloadTime,self.lastInput,self.showRead,self.showMember,self.allowSendCard,self.allowInviteFriend,self.allowUploadFile,self.allowConference,self.allowSpeakCourse,self.isNeedVerify,self.topTime,self.groupStatus,self.isOnLine,self.isOpenReadDel, self.isSendRecipt,self.isDevice,self.chatRecordTimeOut,self.offlineNoPushMsg,self.isAtMe,self.talkTime];
        NSLog(@"%d",worked);
    }else{
        //因为以前的漏洞，取消黑名单后status出现与服务端不一致
//        NSString * status=[rs objectForColumnName:kUSER_STATUS];
//        if ([status intValue] != [self.status intValue]) {
            NSString *insertStr=[NSString stringWithFormat:@"update friend set userNickname =?,status=?,userType=? where userId=?"];
            BOOL worked = [db executeUpdate:insertStr,self.userNickname,self.status,self.userType,self.userId];
            NSLog(@"%d",worked);
//        }
    }
    [g_App copyDbWithUserId:MY_USER_ID];
}

-(void)createSystemFriend{
    JXUserObject* user = [[JXUserObject alloc] init];
    user.userId = CALL_CENTER_USERID;
    user.userNickname = Localized(@"JXUserObject_SysMessage");
    user.status = [NSNumber numberWithInt:8];
    user.userType = [NSNumber numberWithInt:2];
    user.roomFlag = [NSNumber numberWithInt:0];
//    user.role = [NSNumber numberWithInt:2];
    user.content = Localized(@"JXUserObject_Wealcome");
    user.timeSend = [NSDate date];
    user.chatRecordTimeOut = g_myself.chatRecordTimeOut;
    if(!user.haveTheUser)
        [user insert];
    else {
        [user updateUserNickname];
    }
    
    user.userId = FRIEND_CENTER_USERID;
    user.userNickname = Localized(@"JXNewFriendVC_NewFirend");
    user.status = [NSNumber numberWithInt:8];
    user.userType = [NSNumber numberWithInt:0];
    user.roomFlag = [NSNumber numberWithInt:0];
//    user.content = Localized(@"JXUserObject_Friend");
    user.content = nil;
    user.timeSend = [NSDate date];
    user.chatRecordTimeOut = g_myself.chatRecordTimeOut;
    if(!user.haveTheUser)
        [user insert];
    else {
        [user updateUserNickname];
    }
    
    user.userId = BLOG_CENTER_USERID;
    user.userNickname = Localized(@"JXUserObject_BusinessMessage");
    user.status = [NSNumber numberWithInt:9];
    user.userType = [NSNumber numberWithInt:0];
    user.roomFlag = [NSNumber numberWithInt:0];
    user.content = nil;
    user.timeSend = [NSDate date];
    user.chatRecordTimeOut = g_myself.chatRecordTimeOut;
    if(!user.haveTheUser)
        [user insert];
    else {
        [user update];
    }
    
    // 我的其他端设备
    NSArray *names = @[Localized(@"JX_MyAndroid"), Localized(@"JX_MyWindowsComputer"), Localized(@"JX_MyMacComputer"), Localized(@"JX_MyWebPage")];
    NSArray *userIds = @[ANDROID_USERID, PC_USERID, MAC_USERID, WEB_USERID];
    
    for (NSInteger i = 0; i < names.count; i ++) {
//        BOOL isMultipleLogin = [[g_default objectForKey:kISMultipleLogin] boolValue];
        BOOL isMultipleLogin = [g_myself.multipleDevices intValue] > 0 ? YES : NO;
        user.userId = userIds[i];
        user.userNickname = names[i];
        user.status = [NSNumber numberWithInt:10];
        user.userType = [NSNumber numberWithInt:0];
        user.roomFlag = [NSNumber numberWithInt:0];
        user.isDevice = [NSNumber numberWithInt:1];
        user.isOnLine = [NSNumber numberWithInt:0];
        user.content = nil;
        user.timeSend = [NSDate date];
        user.chatRecordTimeOut = g_myself.chatRecordTimeOut;
        if (isMultipleLogin) {
            if (![user haveTheUser]) {
                [user insert];
            }else {
                [user updateIsOnLine];
                [g_notify postNotificationName:kUpdateIsOnLineMultipointLogin object:nil];
            }
        }else {
            [user delete];
        }
    }
    
}

-(NSMutableArray*)doFetch:(NSString*)sql
{
    NSMutableArray *resultArr=[[NSMutableArray alloc]init];
    
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [super checkTableCreatedInDb:db];
    
    FMResultSet *rs=[db executeQuery:sql];
    while ([rs next]) {
        JXUserObject *user=[[JXUserObject alloc] init];
        [super userFromDataset:user rs:rs];
//        [self userFromDataset:rs];
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

-(JXUserObject*)getUserById:(NSString*)aUserId
{
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    
    FMResultSet *rs=[db executeQuery:[NSString stringWithFormat:@"select * from %@ where userId=?",_tableName],aUserId];
    if ([rs next]) {
        JXUserObject *user=[[JXUserObject alloc]init];
        [super userFromDataset:user rs:rs];
        [rs close];
        return user;
    };
    return nil;
}

-(int)getNewTotal
{
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
     
    int n = 0;
    FMResultSet *rs=[db executeQuery:[NSString stringWithFormat:@"select sum(newMsgs) from %@ where newMsgs>0",_tableName]];
    if ([rs next]) {
        n = [[rs objectForColumnIndex:0] intValue];
        [rs close];
    };
    return n;
}

-(void)getDataFromDict:(NSDictionary*)dict{
    self.type = nil;
    self.content = nil;
    self.timeSend = nil;
    self.msgsNew = nil;
    self.timeCreate = [NSDate date];
    self.roomFlag = [NSNumber numberWithInt:0];

    /*
    我是A,调user/get?userId=B
    friends->isBeenBlack，A是不是被B拉黑
    friends->Blacklist，A是不是拉黑B
    */
    
    self.status = [[dict objectForKey:@"friends"] objectForKey:@"status"];
    self.userType = [dict objectForKey:@"userType"];
    self.isBeenBlack = [[dict objectForKey:@"friends"] objectForKey:@"isBeenBlack"];
    if ([self.isBeenBlack intValue] == 1) {
        self.status = [NSNumber numberWithInt:friend_status_hisBlack];
    }
    if([[[dict objectForKey:@"friends"] objectForKey:@"blacklist"] boolValue])
        self.status = [NSNumber numberWithInt:friend_status_black];
//    if([[[dict objectForKey:@"friends"] objectForKey:@"isBeenBlack"] boolValue])
//        self.status = [NSNumber numberWithInt:friend_status_hisBlack];
    self.userId = [[dict objectForKey:@"userId"] stringValue];
    NSString *remarkName = [[dict objectForKey:@"friends"] objectForKey:@"remarkName"];
    if (remarkName.length > 0) {
        self.remarkName = remarkName;
    }
    NSString *describe = [[dict objectForKey:@"friends"] objectForKey:@"describe"];
    if (describe.length > 0) {
        self.describe = describe;
    }
//    if ([dict objectForKey:@"toFriendsRole"]) {
//        NSArray *roleDict = [dict objectForKey:@"toFriendsRole"];
//        self.role = @([[[roleDict firstObject] objectForKey:@"role"] intValue]);
//    }
    self.userNickname = [dict objectForKey:@"nickname"];
    self.userDescription = [dict objectForKey:@"description"];
    self.companyId = [dict objectForKey:@"companyId"];
    self.companyName = [[dict objectForKey:@"company"] objectForKey:@"name"];
    self.msgBackGroundUrl = [dict objectForKey:@"msgBackGroundUrl"];
    self.showLastLoginTime = [dict objectForKey:@"showLastLoginTime"];
    
    self.telephone = [dict objectForKey:@"telephone"];
    self.phone = [dict objectForKey:@"phone"];
    self.password = [dict objectForKey:@"password"];
    self.userType = [dict objectForKey:@"userType"];
    self.birthday = [NSDate dateWithTimeIntervalSince1970:[[dict objectForKey:@"birthday"] longLongValue]];
    self.sex  = [dict objectForKey:@"sex"];
    self.countryId = [dict objectForKey:@"countryId"];
    self.provinceId = [dict objectForKey:@"provinceId"];
    self.cityId = [dict objectForKey:@"cityId"];
    self.areaId = [dict objectForKey:@"areaId"];
    self.fansCount = [dict objectForKey:@"fansCount"];
    self.attCount = [dict objectForKey:@"attCount"];
    self.level = [dict objectForKey:@"level"];
    self.vip = [dict objectForKey:@"vip"];

    self.model = [dict objectForKey:@"model"];
    self.osVersion = [dict objectForKey:@"osVersion"];
    self.serialNumber = [dict objectForKey:@"serialNumber"];
    self.location = [dict objectForKey:@"location"];
//    self.latitude = [dict objectForKey:@"latitude"];
//    self.longitude = [dict objectForKey:@"longitude"];
    self.latitude  = [[dict objectForKey:@"loc"] objectForKey:@"lat"];
    self.longitude = [[dict objectForKey:@"loc"] objectForKey:@"lng"];
    
    if ([dict objectForKey:@"friends"]) {
        self.offlineNoPushMsg = [[dict objectForKey:@"friends"] objectForKey:@"offlineNoPushMsg"];
        self.isOpenReadDel = [[dict objectForKey:@"friends"] objectForKey:@"isOpenSnapchat"];
        long time = [[[dict objectForKey:@"friends"] objectForKey:@"openTopChatTime"] longLongValue];
        self.topTime = [NSDate dateWithTimeIntervalSince1970:time];
    }
    if ([dict objectForKey:@"member"]) {
        long time = [[[dict objectForKey:@"member"] objectForKey:@"openTopChatTime"] longLongValue];
        self.topTime = [NSDate dateWithTimeIntervalSince1970:time];
        self.offlineNoPushMsg = [[dict objectForKey:@"member"] objectForKey:@"offlineNoPushMsg"];
    }
    
    self.chatRecordTimeOut = [NSString stringWithFormat:@"%@", [dict objectForKey:@"chatRecordTimeOut"]];
    self.talkTime = [dict objectForKey:@"talkTime"];
    self.myInviteCode = [dict objectForKey:@"myInviteCode"];
    self.setAccountCount = [dict objectForKey:@"setAccountCount"];
    self.account = [dict objectForKey:@"account"];
}

-(void)getDataFromDictSmall:(NSDictionary*)dict{
    self.type = nil;
    self.content = nil;
    self.timeSend = nil;
    self.msgsNew = nil;
    self.roomFlag = [NSNumber numberWithInt:0];
    
    self.timeCreate = [dict objectForKey:@"createTime"];
    self.status = [dict objectForKey:@"status"];
    if ([[dict objectForKey:@"isBeenBlack"] intValue] == 1) {
        self.status = [NSNumber numberWithInt:friend_status_hisBlack];
    }
    self.userType = [dict objectForKey:@"toUserType"];
    if ([[dict objectForKey:@"blacklist"] integerValue] == 1) {
        self.status = [NSNumber numberWithInt:-1];
    }
//    if ([dict objectForKey:@"toFriendsRole"]) {
//        NSArray *roleDict = [dict objectForKey:@"toFriendsRole"];
//        self.role = @([[[roleDict firstObject] objectForKey:@"role"] intValue]);
//    }
    self.userId = [[dict objectForKey:@"toUserId"] stringValue];
    self.remarkName = [dict objectForKey:@"remarkName"];
    if ([[dict objectForKey:@"remarkName"] length] > 0) {
        self.userNickname = [dict objectForKey:@"remarkName"];
    }else {
        self.userNickname = [dict objectForKey:@"toNickname"];
    }
    self.describe = [dict objectForKey:@"describe"];
    if ([dict objectForKey:@"companyId"]) {
        self.companyId = [dict objectForKey:@"companyId"];
    }else {
        self.companyId = [NSNumber numberWithInt:0];
    }
    if ([dict objectForKey:@"chatRecordTimeOut"]) {
        self.chatRecordTimeOut = [NSString stringWithFormat:@"%@",[dict objectForKey:@"chatRecordTimeOut"]];
    }
    if ([dict objectForKey:@"talkTime"]) {
        self.talkTime = [dict objectForKey:@"talkTime"];
    }
    if ([dict objectForKey:@"offlineNoPushMsg"]) {
        self.offlineNoPushMsg = [dict objectForKey:@"offlineNoPushMsg"];
    }
    
}

-(void)copyFromResume:(resumeBaseData*)resume{
    self.telephone   = resume.telephone;
    self.userNickname= resume.name;
    self.birthday    = [NSDate dateWithTimeIntervalSince1970:resume.birthday];
    self.sex         = [NSNumber numberWithBool:resume.sex];
    self.countryId   = [NSNumber numberWithInt:resume.countryId];
    self.provinceId  = [NSNumber numberWithInt:resume.provinceId];
    self.cityId      = [NSNumber numberWithInt:resume.cityId];
    self.areaId      = [NSNumber numberWithInt:resume.areaId];
    self.latitude    = [NSNumber numberWithDouble:g_server.latitude];
    self.longitude   = [NSNumber numberWithDouble:g_server.longitude];
}

+(void)deleteUserAndMsg:(NSString*)s{
    JXUserObject* p = [[JXUserObject alloc]init];
    p.userId = s;

    [p notifyDelFriend];
    [p delete];
//    [p release];
    
    JXMessageObject* m = [[JXMessageObject alloc]init];
    m.fromUserId = MY_USER_ID;
    m.toUserId = s;
    [m deleteAll];
//    [m release];
}

+(BOOL)updateNewMsgsTo0{
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:MY_USER_ID];
    BOOL worked=[db executeUpdate:[NSString stringWithFormat:@"update friend set newMsgs=0"]];
    return worked;
}

-(void)copyFromRoomMember:(memberData*)p{
    self.userId = [NSString stringWithFormat:@"%ld",p.userId];
    self.userNickname = p.userNickName;
}

// 更新最后输入
- (BOOL) updateLastInput {
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkTableCreatedInDb:db];
    
    NSString* sql = [NSString stringWithFormat:@"update %@ set lastInput=? where userId=?",_tableName];
    BOOL worked = [db executeUpdate:sql,self.lastInput,self.userId];
    return worked;
}

// 更新消息界面显示的最后一条消息
- (BOOL) updateLastContent {
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkTableCreatedInDb:db];
    
    NSString* sql = [NSString stringWithFormat:@"update %@ set content=? where userId=?",_tableName];
    BOOL worked = [db executeUpdate:sql,self.content,self.userId];
    return worked;
}


+(NSString*)getUserNameWithUserId:(NSString*)userId{
    if(userId==nil)
        return nil;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:MY_USER_ID];
    //获取用户名
    NSString* sql= [NSString stringWithFormat:@"select userNickname from friend where userId=%@",userId];
    FMResultSet *rs=[db executeQuery:sql];
    if([rs next]) {
        NSString* s = [rs objectForColumnName:@"userNickname"];
        return s;
    }
    
    return nil;
}

// 更新置顶时间
- (BOOL) updateTopTime {
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkTableCreatedInDb:db];
    
    NSString* sql = [NSString stringWithFormat:@"update %@ set topTime=? where userId=?",_tableName];
    BOOL worked = [db executeUpdate:sql,self.topTime,self.userId];
    return worked;
}

// 更新群组有效性
- (BOOL) updateGroupInvalid {
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkTableCreatedInDb:db];
    
    NSString* sql = [NSString stringWithFormat:@"update %@ set groupStatus=? where userId=?",_tableName];
    BOOL worked = [db executeUpdate:sql,self.groupStatus,self.userId];
    return worked;
}

// 更新用户昵称
- (BOOL) updateUserNickname {
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkTableCreatedInDb:db];
    
    NSString *nickName;
    if (self.remarkName.length > 0) {
        nickName = self.remarkName;
    }else {
        nickName = self.userNickname;
    }
    
    NSString* sql = [NSString stringWithFormat:@"update %@ set userNickname=? where userId=?",_tableName];
    BOOL worked = [db executeUpdate:sql,nickName,self.userId];
    return worked;
}

// 更新用户备注
- (BOOL) updateRemarkName {
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkTableCreatedInDb:db];
    
    NSString* sql = [NSString stringWithFormat:@"update %@ set remarkName=? where userId=?",_tableName];
    BOOL worked = [db executeUpdate:sql,self.remarkName,self.userId];
    return worked;
}

// 更新用户聊天记录过期时间
- (BOOL) updateUserChatRecordTimeOut {
    
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkTableCreatedInDb:db];
    
    NSString* sql = [NSString stringWithFormat:@"update %@ set chatRecordTimeOut=? where userId=?",_tableName];
    BOOL worked = [db executeUpdate:sql,self.chatRecordTimeOut,self.userId];
    return worked;
}

// 更新列表最近一条消息记录
- (BOOL) updateUserLastChatList:(NSArray *)array {
    for (NSInteger i = 0; i < array.count; i ++) {
        NSDictionary *dict = array[i];
        if ([g_xmpp.blackList containsObject:dict[@"jid"]]) {
            continue;
        }
        JXUserObject *user = [[JXUserObject sharedInstance] getUserById:dict[@"jid"]];
        
        
        NSNumber *isEncrypt = dict[@"isEncrypt"];
        NSString *messageId = dict[@"messageId"];
        long timeSend = [dict[@"timeSend"] longLongValue];
        NSString *content = dict[@"content"];
        
        content = [self getLastListContent:dict];
        
        
        if ([isEncrypt boolValue]) {
            NSMutableString *str = [NSMutableString string];
            [str appendString:APIKEY];
            [str appendString:[NSString stringWithFormat:@"%ld",timeSend]];
            [str appendString:messageId];
            NSString *keyStr = [g_server getMD5String:str];
            content = [DESUtil decryptDESStr:content key:keyStr];
            
        }else{
            content = content;
        }
        
        user.content = content;
        user.type = dict[@"type"];
        user.timeSend = [NSDate dateWithTimeIntervalSince1970:timeSend];
        
        if (user) {
            if (user.content.length > 0) {
                [user update];
            }
        }else {
//            user = [[JXUserObject alloc] init];
//            
//            user.content = content;
//            user.type = dict[@"type"];
//            if ([dict[@"isRoom"] boolValue]) {
//                user.roomFlag= [NSNumber numberWithInt:1];
//                user.companyId= [NSNumber numberWithInt:0];
//                user.status= [NSNumber numberWithInt:2];
//                user.offlineNoPushMsg = [NSNumber numberWithInt:0];
//                user.isAtMe = [NSNumber numberWithInt:0];
//            }
//            user.timeSend = [NSDate dateWithTimeIntervalSince1970:timeSend];
//            user.userId = dict[@"jid"];
//            user.userNickname = dict[@"toUserName"];
//            [user insert];
        }
    }
    return YES;
}

- (NSString *)getLastListContent:(NSDictionary *)dict {
    int type = [dict[@"type"] intValue];
    NSString *content = dict[@"content"];
    NSString *fromUserId = dict[@"from"];
    NSString *fromUserName = dict[@"fromUserName"];
    if (!fromUserName) {
        fromUserName = @"";
    }
    NSString *toUserId = dict[@"to"];
    NSString *toUserName = dict[@"toUserName"];
    if (!toUserName) {
        toUserName = @"";
    }
    switch (type) {
        case kWCMessageTypeWithdraw:{
            if ([dict[@"isRoom"] boolValue]) {
                
                if ([fromUserId isEqualToString:MY_USER_ID]) {
                    content = Localized(@"JX_AlreadyWithdraw");
                }else {
                    content = [NSString stringWithFormat:@"%@ %@",fromUserName, Localized(@"JX_OtherWithdraw")];

                }
            }else {
                if ([fromUserId isEqualToString:MY_USER_ID]) {
                    
                    content = Localized(@"JX_AlreadyWithdraw");
                }else {
                    content = [NSString stringWithFormat:@"%@ %@",fromUserName, Localized(@"JX_OtherWithdraw")];
                }
            }
        }
            break;
            
        case kWCMessageTypeShare:
            content = [NSString stringWithFormat:@"[%@]",Localized(@"JXLink")];
            break;
        case kWCMessageTypeRedPacketReceive:
            content = [NSString stringWithFormat:@"%@%@",fromUserName,Localized(@"JXRed_whoGet")];
            break;
        case kWCMessageTypeRedPacketReturn:
            content = [NSString stringWithFormat:@"%@",Localized(@"JX_ RedEnvelopeExpired")];
            break;
        case kWCMessageTypeGroupFileUpload:
            content = [NSString stringWithFormat:@"%@%@",fromUserName,Localized(@"JXMessage_fileUpload")];
            break;
        case kWCMessageTypeGroupFileDelete:
            content = [NSString stringWithFormat:@"%@%@",fromUserName,Localized(@"JXMessage_fileDelete")];
            break;
        case kWCMessageTypeGroupFileDownload:
            content = [NSString stringWithFormat:@"%@%@",fromUserName,Localized(@"JXMessage_fileDownload")];
            break;
        case kRoomRemind_RoomName:
            content = [NSString stringWithFormat:@"%@%@%@",fromUserName,Localized(@"JXMessageObject_UpdateRoomName"),content];
            break;
        case kRoomRemind_NickName:{
            content = [NSString stringWithFormat:@"%@%@%@",fromUserName,Localized(@"JXMessageObject_UpdateNickName"),content];
        }
            break;
        case kRoomRemind_DelRoom:
            if ([toUserId isEqualToString:MY_USER_ID]) {
                content = [NSString stringWithFormat:Localized(@"JX_DissolutionGroup"),fromUserName];
            }else {
                content = [NSString stringWithFormat:@"%@%@:%@",fromUserName,Localized(@"JXMessage_delRoom"),content];
            }
            
            break;
        case kRoomRemind_AddMember:
            if([toUserId isEqualToString:fromUserId])
                content = [NSString stringWithFormat:@"%@%@",fromUserName,Localized(@"JXMessageObject_GroupChat")];
            else
                content = [NSString stringWithFormat:@"%@%@%@",fromUserName,Localized(@"JXMessageObject_InterFriend"),toUserName];
            break;
        case kLiveRemind_ExitRoom:
            if([toUserId isEqualToString:fromUserId]){
                content = [NSString stringWithFormat:@"%@%@",fromUserName,Localized(@"EXITED_LIVE_ROOM")];//退出
                
            }else{
                content = [NSString stringWithFormat:@"%@%@",toUserName,Localized(@"JX_LiveVC_kickLive")];//被踢出
            }
            break;
        case kRoomRemind_DelMember:
            if([toUserId isEqualToString:fromUserId]){
                    content = [NSString stringWithFormat:@"%@%@",fromUserName,Localized(@"JXMessageObject_OutGroupChat")];
            }else{
                if ([toUserId isEqualToString:MY_USER_ID]) {
                    content = [NSString stringWithFormat:Localized(@"JX_OutOfTheGroup"),fromUserName];
                }else {
                    if ([fromUserName isEqualToString:toUserName]) {
                        content = [NSString stringWithFormat:@"%@%@",fromUserName,Localized(@"JXRoomMemberVC_OutPutRoom")];
                    }else {
                        content = [NSString stringWithFormat:@"%@%@%@",fromUserName,Localized(@"JXMessageObject_KickOut"),toUserName];
                    }
                }
            }
                
            break;
        case kRoomRemind_NewNotice:
            content = [NSString stringWithFormat:@"%@%@%@",fromUserName,Localized(@"JXMessageObject_AddNewAdv"),content];
            break;
        case kLiveRemind_ShatUp:
        case kRoomRemind_DisableSay:{
            if([content longLongValue]==0){
                content = [NSString stringWithFormat:@"%@%@%@%@",fromUserName,Localized(@"JXMessageObject_Yes"),toUserName,Localized(@"JXMessageObject_CancelGag")];
            }else{
                NSDate* d = [NSDate dateWithTimeIntervalSince1970:[content longLongValue]];
                NSString* t = [TimeUtil formatDate:d format:@"MM-dd HH:mm"];
                content = [NSString stringWithFormat:@"%@%@%@%@%@",fromUserName,Localized(@"JXMessageObject_Yes"),toUserName,Localized(@"JXMessageObject_SetGagWithTime"),t];
                d = nil;
            }
            break;
        }
        case kLiveRemind_SetManager:
        case kRoomRemind_SetManage:{
            if ([content integerValue] == 1) {
                content = [NSString stringWithFormat:@"%@%@%@%@",Localized(@"JXGroup_Owner"),Localized(@"JXSettingVC_Set"),toUserName,Localized(@"JXMessage_admin")];
            }else {
                content = [NSString stringWithFormat:@"%@%@%@",Localized(@"JXGroup_Owner"),Localized(@"CANCEL_ADMINISTRATOR"),toUserName];
            }
            break;
        }
        case kRoomRemind_EnterLiveRoom:{
            content = [NSString stringWithFormat:@"%@%@",toUserName,Localized(@"Enter_LiveRoom")];//加入房间消息
            break;
        }
        case kRoomRemind_ShowRead:{
            if ([content integerValue] == 1)
                content = [NSString stringWithFormat:@"%@%@%@",Localized(@"JXGroup_Owner"),Localized(@"JX_Enable"),Localized(@"JX_RoomReadMode")];
            else
                content = [NSString stringWithFormat:@"%@%@%@",Localized(@"JXGroup_Owner"),Localized(@"JX_Disable"),Localized(@"JX_RoomReadMode")];
            break;
        }
        case kRoomRemind_NeedVerify:{
            
            if (!content || content.length <= 0) {
                content = Localized(@"JX_GroupInvitationConfirmation");
            }else {
                if ([content integerValue] == 1)
                    content = Localized(@"JX_GroupOwnersOpenValidation");
                else
                    content = Localized(@"JX_GroupOwnersCloseValidation");
            }
            
            break;
        }
        case kRoomRemind_IsLook:{
            if ([content integerValue] == 0)
                content = Localized(@"JX_GroupOwnersPublicGroup");
            else
                content = Localized(@"JX_GroupOwnersPrivateGroup");
            break;
        }
            
        case kRoomRemind_ShowMember:{
            if ([content integerValue] == 1)
                content = Localized(@"JX_GroupOwnersShowMembers");
            else
                content = Localized(@"JX_GroupOwnersNotShowMembers");
            break;
        }
            
        case kRoomRemind_allowSendCard:{
            if ([content integerValue] == 1)
                content = Localized(@"JX_ManagerOpenChat");
            else
                content = Localized(@"JX_ManagerOffChat");
            break;
        }
            
        case kRoomRemind_RoomAllBanned:{
            if ([content integerValue] > 0)
                content = Localized(@"JX_ManagerOpenSilence");
            else
                content = Localized(@"JX_ManagerOffSilence");
            break;
        }
            
        case kRoomRemind_RoomAllowInviteFriend:{
            if ([content integerValue] > 0)
                content = Localized(@"JX_ManagerOpenInviteFriends");
            else
                content = Localized(@"JX_ManagerOffInviteFriends");
            break;
        }
            
        case kRoomRemind_RoomAllowUploadFile:{
            if ([content integerValue] > 0)
                content = Localized(@"JX_ManagerOpenSharedFiles");
            else
                content = Localized(@"JX_ManagerOffSharedFiles");
            break;
        }
            
        case kRoomRemind_RoomAllowConference:{
            if ([content integerValue] > 0)
                content = Localized(@"JX_ManagerOpenMeetings");
            else
                content = Localized(@"JX_ManagerOffMeetings");
            break;
        }
            
        case kRoomRemind_RoomAllowSpeakCourse:{
            if ([content integerValue] > 0)
                content = Localized(@"JX_ManagerOpenLectures");
            else
                content = Localized(@"JX_ManagerOffLectures");
            break;
        }
            
        case kRoomRemind_RoomTransfer:{
            content = [NSString stringWithFormat:@"\"%@\"%@", toUserName,Localized(@"JX_NewGroupManager")];
            break;
        }
        case kRoomRemind_SetInvisible:{
            if ([content integerValue] == 1) {
                content = [NSString stringWithFormat:@"%@%@%@%@",fromUserName,Localized(@"JXSettingVC_Set"),toUserName,Localized(@"JX_ForTheInvisibleMan")];
            }else if ([content integerValue] == -1){
                content = [NSString stringWithFormat:@"%@%@%@",fromUserName,Localized(@"JX_EliminateTheInvisible"),toUserName];
            }else if ([content integerValue] == 2){
                content = [NSString stringWithFormat:@"%@%@%@%@",fromUserName,Localized(@"JXSettingVC_Set"),toUserName,@"为监控人"];
            }else if ([content integerValue] == 0){
                content = [NSString stringWithFormat:@"%@%@%@",fromUserName,@"取消监控人",toUserName];
            }
            break;
        }
            
        case kRoomRemind_RoomDisable:{
            if ([content integerValue] == 1) {
                content = [NSString stringWithFormat:@"%@",Localized(@"JX_ThisGroupHasBeenDisabled")];
            }else {
                content = [NSString stringWithFormat:@"%@",Localized(@"JX_GroupNotUse")];
            }
            break;
        }
            
        case kRoomRemind_SetRecordTimeOut:{
            NSArray *pickerArr = @[Localized(@"JX_Forever"), Localized(@"JX_OneHour"), Localized(@"JX_OneDay"), Localized(@"JX_OneWeeks"), Localized(@"JX_OneMonth"), Localized(@"JX_OneQuarter"), Localized(@"JX_OneYear")];
            double outTime = [content doubleValue];
            NSString *str;
            if (outTime <= 0) {
                str = pickerArr[0];
            }else if (outTime == 0.04) {
                str = pickerArr[1];
            }else if (outTime == 1) {
                str = pickerArr[2];
            }else if (outTime == 7) {
                str = pickerArr[3];
            }else if (outTime == 30) {
                str = pickerArr[4];
            }else if (outTime == 90) {
                str = pickerArr[5];
            }else{
                str = pickerArr[6];
            }
            content = [NSString stringWithFormat:@"%@%@",Localized(@"JX_GroupManagerSetMsgDelTime"),str];
        }
        default:
            break;
    }
    
    return content;
}

// 更新群组全员禁言时间
- (BOOL) updateGroupTalkTime {
    
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkTableCreatedInDb:db];
    
    NSString* sql = [NSString stringWithFormat:@"update %@ set talkTime=? where userId=?",_tableName];
    BOOL worked = [db executeUpdate:sql,self.talkTime,self.userId];
    return worked;
}

// 更新是否开启阅后即焚标志
- (BOOL) updateIsOpenReadDel {
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkTableCreatedInDb:db];
    
    NSString* sql = [NSString stringWithFormat:@"update %@ set isOpenReadDel=? where userId=?",_tableName];
    BOOL worked = [db executeUpdate:sql,self.isOpenReadDel,self.userId];
    return worked;
}

// 更新消息免打扰
- (BOOL) updateOfflineNoPushMsg {
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkTableCreatedInDb:db];
    
    NSString* sql = [NSString stringWithFormat:@"update %@ set offlineNoPushMsg=? where userId=?",_tableName];
    BOOL worked = [db executeUpdate:sql,self.offlineNoPushMsg,self.userId];
    return worked;
}

// 更新@我
- (BOOL) updateIsAtMe{
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkTableCreatedInDb:db];
    
    NSString* sql = [NSString stringWithFormat:@"update %@ set isAtMe=? where userId=?",_tableName];
    BOOL worked = [db executeUpdate:sql,self.isAtMe,self.userId];
    return worked;
}

// 更新userType
- (BOOL) updateUserType {
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkTableCreatedInDb:db];
    
    NSString* sql = [NSString stringWithFormat:@"update %@ set userType=? where userId=?",_tableName];
    BOOL worked = [db executeUpdate:sql,self.userType,self.userId];
    return worked;
}

// 更新创建者
- (BOOL)updateCreateUser {
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkTableCreatedInDb:db];
    
    NSString* sql = [NSString stringWithFormat:@"update %@ set createUserId=? where userId=?",_tableName];
    BOOL worked = [db executeUpdate:sql,self.createUserId,self.userId];
    return worked;
}

// 更新群组设置
- (BOOL)updateGroupSetting {
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkTableCreatedInDb:db];
    
    NSString* sql = [NSString stringWithFormat:@"update %@ set showRead=?,allowSendCard=?,allowConference=?,allowSpeakCourse=?,isNeedVerify=?,talkTime=? where userId=?",_tableName];
    BOOL worked = [db executeUpdate:sql,self.showRead,self.allowSendCard,self.allowConference,self.allowSpeakCourse,self.isNeedVerify,self.talkTime,self.userId];
    return worked;
}

// 更新好友关系
- (BOOL)updateStatus {
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkTableCreatedInDb:db];
    
    NSString* sql = [NSString stringWithFormat:@"update %@ set status=? where userId=?",_tableName];
    BOOL worked = [db executeUpdate:sql,self.status,self.userId];
    return worked;
}

// 更新新消息数量
- (BOOL)updateNewMsgNum {
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkTableCreatedInDb:db];
    
    NSString* sql = [NSString stringWithFormat:@"update %@ set newMsgs=? where userId=?",_tableName];
    BOOL worked = [db executeUpdate:sql,self.msgsNew,self.userId];
    return worked;
}

// 更新我的设备是否在线
- (BOOL)updateIsOnLine {
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkTableCreatedInDb:db];
    
    NSString* sql = [NSString stringWithFormat:@"update %@ set isOnLine=? where userId=?",_tableName];
    BOOL worked = [db executeUpdate:sql,self.isOnLine,self.userId];
    return worked;
}

// 更新群组最后群成员加入时间
- (BOOL)updateJoinTime {
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkTableCreatedInDb:db];
    
    NSString* sql = [NSString stringWithFormat:@"update %@ set joinTime=? where userId=?",_tableName];
    BOOL worked = [db executeUpdate:sql,self.joinTime,self.userId];
    return worked;
}

// 删除用户过期聊天记录
- (BOOL) deleteUserChatRecordTimeOutMsg {
    NSMutableArray *array = [[JXMessageObject sharedInstance] fetchRecentChat];
    for (NSInteger i = 0; i < array.count; i ++) {
        JXMsgAndUserObject *userObj = array[i];
        [[JXMessageObject sharedInstance] deleteTimeOutMsg:userObj.user.userId chatRecordTimeOut:userObj.user.chatRecordTimeOut];
    }
    return YES;
}

- (BOOL) deleteAllUser {
    
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkTableCreatedInDb:db];
    NSString *sql = [NSString stringWithFormat:@"delete from %@ where length(userId) > 5 and length(userId) < 10",_tableName];
    BOOL worked=[db executeUpdate:sql,self.userId];
    return worked;
}

//插入已拨打的电话号码
- (BOOL) insertPhone:(NSString *)phone time:(NSDate *)time {
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkPhoneTableCreatedInDb:db];
    FMResultSet * rs =  [db executeQuery:[NSString stringWithFormat:@"select * from telePhone where phone=?"],phone];
    BOOL flag = NO;
    if([rs next]) {
        flag = YES;
    }
    
    //    FMDBQuickCheck(worked);
    if (!flag) {
        NSString *insertStr=[NSString stringWithFormat:@"INSERT INTO '%@' ('phone','time') VALUES (?,?)",@"telePhone"];
        BOOL worked = [db executeUpdate:insertStr,phone, time];
        return worked;
    }
    return YES;
}

// 删除已拨打的电话号码
- (BOOL) deletePhone:(NSString *)phone {
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkPhoneTableCreatedInDb:db];
    BOOL worked = [db executeUpdate:[NSString stringWithFormat:@"delete from telePhone where phone=?"],phone];
    return worked;
}

- (NSMutableDictionary *) getPhoneDic {
    NSString* myUserId = MY_USER_ID;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    [self checkPhoneTableCreatedInDb:db];
     NSString* sql = [NSString stringWithFormat:@"select * from telePhone"];
    FMResultSet *rs = [db executeQuery:sql];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    while ([rs next]) {
        
        [dict setObject:[rs dateForColumn:@"time"] forKey:[rs stringForColumn:@"phone"]];
    }
    
    return dict;
}

-(BOOL)checkPhoneTableCreatedInDb:(FMDatabase *)db
{
    NSString *createStr=[NSString stringWithFormat:@"CREATE  TABLE IF NOT EXISTS '%@' ('phone' VARCHAR, 'time' DATETIME)",@"telePhone"];
    
    BOOL worked = [db executeUpdate:createStr];
    //    FMDBQuickCheck(worked);
    return worked;
}



@end
