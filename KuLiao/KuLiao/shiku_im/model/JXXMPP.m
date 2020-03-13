//
//  JXXMPP.m
//  WeChat
//
//  Created by Reese on 13-8-10.
//  Copyright (c) 2013年 Reese. All rights reserved.
//
// Log levels: off, error, warn, info, verbose

#import "JXXMPP.h"
#import "GCDAsyncSocket.h"
#import "XMPP.h"
#import "XMPPReconnect.h"
#import "XMPPCapabilities.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "XMPPRoster.h"
#import "XMPPMessage.h"
#import "TURNSocket.h"
#import "SBJsonWriter.h"
#import "AppDelegate.h"
#import "FMDatabase.h"
#import "emojiViewController.h"
#import "JXRoomPool.h"
#import "XMPPMessage+XEP_0184.h"
#import "JXMainViewController.h"
#import "JXFriendObject.h"
#import "FileInfo.h"
#import "JXGroupViewController.h"
#import "JXRoomObject.h"
#import "JXRoomRemind.h"
#import "JXBlogRemind.h"
#import "JXFriendObject.h"
#import "AppleReachability.h"

#if DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelOff;
#else
static const DDLogLevel ddLogLevel = DDLogLevelOff;
#endif




#define DOCUMENT_PATH NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]
#define CACHES_PATH NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0]

@interface JXXMPP ()<XMPPReconnectDelegate,XMPPStreamManagementDelegate>

@property (nonatomic, strong) ATMHud *wait;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSTimer *IQTimer;
@property (nonatomic, assign) NSInteger IQNum;
@property (nonatomic, assign) NSInteger reconnectTimerCount;

@end

@implementation JXXMPP
@synthesize stream=xmppStream,isLogined,roomPool,poolSend=_poolSend,blackList;




static JXXMPP *sharedManager;

+(JXXMPP*)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager=[[JXXMPP alloc]init];
        //
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
        [sharedManager setupStream];
    });
    
    return sharedManager;
}

-(id)init{
    self = [super init];
    _poolSend = [[NSMutableDictionary alloc]init];
    _poolSendRead = [[NSMutableArray alloc]init];
    blackList = [[NSMutableSet alloc]init];
    _poolSendIQ = [[NSMutableArray alloc] init];
    isLogined = login_status_no;
    _chatingUserIds = [[NSMutableArray alloc]init];
//    _isEncryptAll = [[NSUserDefaults standardUserDefaults] boolForKey:kMESSAGE_isEncrypt];
    [g_notify addObserver:self selector:@selector(readDelete:) name:kCellReadDelNotification object:nil];
    self.newMsgAfterLogin = 0;
    self.reconnectTimerCount = 10;
    _IQNum = 0;
    _wait = [ATMHud sharedInstance];
    self.isReconnect = YES;
    
    return self;
}

- (void)dealloc
{
    [blackList removeAllObjects];
//    [blackList release];
//    [_db close];
//    [_db release];
	[self teardownStream];
//    [roomPool release];
    [_poolSend removeAllObjects];
    [_IQTimer invalidate];
    _IQTimer = nil;
//    [_poolSend release];
//    [password release];
//    [super dealloc];
    [g_notify removeObserver:self name:kCellReadDelNotification object:nil];
}

-(void)login{
    
    NSLog(@"XMPPLogin ---");
    AppleReachability *reach = [AppleReachability reachabilityWithHostName:@"www.apple.com"];
    NetworkStatus internetStatus = [reach currentReachabilityStatus];
    switch (internetStatus) {
        case NotReachable:{
            if (self.isLogined != login_status_no) {
                [self logout];
            }
        }
            break;
            
        default:{
            
            self.isReconnect = YES;
            pingTimeoutCount = 0;
            if(isLogined == login_status_yes)
                return;
            if (![self connect]) {
                //        [g_App showAlert:@"服务器连接失败,本demo服务器非24小时开启，若急需请QQ 287076078"];
            };
        }
            break;
    }
    
    
}

-(void)doLogin{
    NSLog(@"xmpp ---- doLogin");
    self.newMsgAfterLogin = 0; //重新登陆后，新消息要置0
    pingTimeoutCount = 0;
    self.isCloseStream = NO;
    [FileInfo createDir:myTempFilePath];
    [self goOnline];
    [xmppRoster fetchRoster];//获取花名册
    self.isLogined = login_status_yes;
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        [self.roomPool createAll];
//    });
    [self notify];
    [self enableIQ];
}
  
-(void)logout{
    if(!isLogined)
        return;
    
    NSLog(@"XMPPLogout ---");
    NSLog(@"isLogined = %d", self.isLogined);
    if (self.isLogined == login_status_yes) {
        g_server.lastOfflineTime = [[NSDate date] timeIntervalSince1970];
        [g_default setObject:[NSNumber numberWithLongLong:g_server.lastOfflineTime] forKey:kLastOfflineTime];
        [g_default synchronize];
    }
    
    self.isLogined = login_status_no;
    [self notify];
    self.newMsgAfterLogin = 0;
	isXmppConnected = NO;
    [self disconnect];
    [roomPool deleteAll];
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma  mark ------------发消息------------
- (void)sendMessage:(JXMessageObject*)msg roomName:(NSString*)roomName
{
    
    // 普通消息设置重发次数
    if (msg.isVisible && msg.sendCount <= 0) {
        msg.sendCount = 5;
    }
    //采用SBjson将params转化为json格式的字符串
    //    msg.roomJid = roomName;
    if([msg.messageId length]<=0)//必须有
        [msg setMsgId];
    if ([g_myself.isEncrypt intValue] == 1) {
        msg.isEncrypt = [NSNumber numberWithInt:YES];
    }else{
        msg.isEncrypt = [NSNumber numberWithInt:NO];
    }
    
    // 消息发送时间更新
    NSTimeInterval time = [msg.timeSend timeIntervalSince1970];
    msg.timeSend = [NSDate dateWithTimeIntervalSince1970:(time *1000 + g_server.timeDifference)/1000];
    
    // 直接发给此账号的其他端
    if ([msg.toUserId rangeOfString:MY_USER_ID].location != NSNotFound && msg.toUserId.length > [MY_USER_ID length]) {
        NSString *relayUserId = msg.toUserId;
        msg.toUserId = MY_USER_ID;
        [self relaySendMessage:msg relayUserId:relayUserId roomName:nil];
        
        return;
    }
    
    if (!roomName || roomName.length <= 0) {
        // 多点登录转发给其他端
        [g_multipleLogin relaySendMessage:nil msg:msg];
    }

    
	SBJsonWriter * OderJsonwriter = [SBJsonWriter new];
	NSString * jsonString = [OderJsonwriter stringWithObject:[msg toDictionary]];
    
    
    XMPPMessage *aMessage;
    NSString* from = [NSString stringWithFormat:@"%@@%@",msg.fromUserId,g_config.XMPPDomain];
    if(roomName == nil){
        NSString* to = [NSString stringWithFormat:@"%@@%@",msg.toUserId,g_config.XMPPDomain];
        aMessage=[XMPPMessage messageWithType:@"chat" to:[XMPPJID jidWithString:to]];
        to   = nil;
    }
    else{
        NSString* roomJid = [NSString stringWithFormat:@"%@@muc.%@",roomName,g_config.XMPPDomain];
        aMessage=[XMPPMessage messageWithType:@"groupchat" to:[XMPPJID jidWithString:roomJid]];
        roomJid = nil;
    }
    [aMessage addAttributeWithName:@"id" stringValue:msg.messageId];

    if ([g_config.isOpenReceipt boolValue] || [msg.type intValue] == kWCMessageTypeMultipleLogin) {
        
        NSXMLElement * request = [NSXMLElement elementWithName:@"request" xmlns:@"urn:xmpp:receipts"];
        [aMessage addChild:request];
        request = nil;
    }

    DDXMLNode* node = [DDXMLNode elementWithName:@"body" stringValue:jsonString];
    [aMessage addChild:node];
    node = nil;

    NSLog(@"sendMessage:%@,%@",msg.messageId,jsonString);
    [xmppStream sendElement:aMessage];
    
    
    //判断消息是否为已读类型
    if ([msg.type intValue] == kWCMessageTypeIsRead) {
        bool found = NO;
        //不重复添加
        for (JXMessageObject * msgObj in _poolSendRead){
            if ([msgObj.messageId isEqualToString: msg.messageId]){
                found = YES;
                break;
            }
        }
        if (!found) {
            [_poolSendRead addObject:msg];
        }
    }else{
        // 排除发送正在输入
        if ([msg.type intValue] != kWCMessageTypeRelay)
            [_poolSend setObject:msg forKey:msg.messageId];
    }
    AppleReachability *reach = [AppleReachability reachabilityWithHostName:@"www.apple.com"];
    NetworkStatus internetStatus = [reach currentReachabilityStatus];
    switch (internetStatus) {
        case NotReachable:{
            
            [msg updateIsSend:transfer_status_no];
            if (![msg.fromUserId isEqualToString:msg.toUserId]) {
                if ([msg.type intValue] != kWCMessageTypeAVPing) {
                    [msg notifyTimeout];//重发次数为0,才发超时通知
                }
            }
        }
            break;
            
        default:
            
            [self performSelector:@selector(onSendTimeout:) withObject:msg afterDelay:[msg getMaxWaitTime]];
            break;
    }
    
    from = nil;
}


#pragma  mark ------------多点登录转发发消息------------
- (void)relaySendMessage:(JXMessageObject*)msg relayUserId:(NSString *)relayUserId roomName:(NSString*)roomName
{
    // 普通消息设置重发次数
    if (msg.isVisible && msg.sendCount <= 0) {
        msg.sendCount = 5;
    }
    //采用SBjson将params转化为json格式的字符串
    //    msg.roomJid = roomName;
    if([msg.messageId length]<=0)//必须有
        [msg setMsgId];
    if ([g_myself.isEncrypt intValue] == 1) {
        msg.isEncrypt = [NSNumber numberWithInt:YES];
    }else{
        msg.isEncrypt = [NSNumber numberWithInt:NO];
    }
    
    SBJsonWriter * OderJsonwriter = [SBJsonWriter new];
    NSString * jsonString = [OderJsonwriter stringWithObject:[msg toDictionary]];
    
    NSRange range = [relayUserId rangeOfString:@"_"];
    NSString *relayType = [relayUserId substringFromIndex:range.location + 1];
    
    XMPPMessage *aMessage;
    NSString* from = [NSString stringWithFormat:@"%@@%@",msg.fromUserId,g_config.XMPPDomain];
    if(roomName == nil){
        NSString* to = [NSString stringWithFormat:@"%@@%@/%@",g_myself.userId,g_config.XMPPDomain,relayType];
        aMessage=[XMPPMessage messageWithType:@"chat" to:[XMPPJID jidWithString:to]];
        to   = nil;
    }
    else{
        NSString* roomJid = [NSString stringWithFormat:@"%@@muc.%@",roomName,g_config.XMPPDomain];
        aMessage=[XMPPMessage messageWithType:@"groupchat" to:[XMPPJID jidWithString:roomJid]];
        roomJid = nil;
    }
    [aMessage addAttributeWithName:@"id" stringValue:msg.messageId];
    
    if ([g_config.isOpenReceipt boolValue] || [msg.type intValue] == kWCMessageTypeMultipleLogin) {
        
        NSXMLElement * request = [NSXMLElement elementWithName:@"request" xmlns:@"urn:xmpp:receipts"];
        [aMessage addChild:request];
        request = nil;
    }
    
    DDXMLNode* node = [DDXMLNode elementWithName:@"body" stringValue:jsonString];
    [aMessage addChild:node];
    node = nil;
    
    NSLog(@"sendMessage:%@,%@",msg.messageId,jsonString);
    [xmppStream sendElement:aMessage];
    
    //判断消息是否为已读类型
    if ([msg.type intValue] == kWCMessageTypeIsRead) {
        bool found = NO;
        //不重复添加
        for (JXMessageObject * msgObj in _poolSendRead){
            if ([msgObj.messageId isEqualToString: msg.messageId]){
                found = YES;
                break;
            }
        }
        if (!found) {
            [_poolSendRead addObject:msg];
        }
    }else{
        // 排除发送正在输入
        if ([msg.type intValue] != kWCMessageTypeRelay){
            if ([msg.fromUserId isEqualToString:msg.toUserId]) {
                msg.toUserId = relayUserId;
            }
            [_poolSend setObject:msg forKey:msg.messageId];
        }
    }
    
    [self performSelector:@selector(onSendTimeout:) withObject:msg afterDelay:[msg getMaxWaitTime]];
    from = nil;
}

-(void)sendMessageInvite:(JXMessageObject *)msg{
    [_poolSend setObject:msg forKey:msg.messageId];
    [self performSelector:@selector(onSendTimeout:) withObject:msg afterDelay:[msg getMaxWaitTime]];
}

/*
-(void)sendMsgIsRead{
    if([g_xmpp.poolSendRead count] == 0|| g_xmpp.poolSendRead == nil)
        return;
    
    for (int i = 0; i < [g_xmpp.poolSendRead count]; i++) {
        JXMessageObject * msg = g_xmpp.poolSendRead[i];
        if (msg.sendCount>0){//一般只重发3次，在发之前赋值3
            msg.sendCount--;
            [g_xmpp sendMessage:msg roomName:nil];
        }
        else
            [g_xmpp.poolSendRead removeObject:msg];
    }
}
*/

-(void)onSendTimeout:(JXMessageObject *)p{//超时未收到回执
    if(p){
        if([p.isSend isEqualToNumber:[NSNumber numberWithInt:transfer_status_yes]])
            return;
        [p updateIsSend:transfer_status_ing];
        if(p.sendCount>0){//一般只重发3次，在发之前赋值3
            NSLog(@"autoSend:%d",p.sendCount);
            [self login];
            NSString* roomJid=nil;
            if(p.isGroup)
                roomJid = p.toUserId;
            [self sendMessage:p roomName:roomJid];
            p.sendCount--;//重发次数减1
        }else{
            
            [p updateIsSend:transfer_status_no];
            if (![p.fromUserId isEqualToString:p.toUserId]) {
                if ([p.type intValue] != kWCMessageTypeAVPing) {
                    [p notifyTimeout];//重发次数为0,才发超时通知
                }
            }
        }
    }
}

#pragma mark --------配置XML流---------
- (void)setupStream
{
	NSAssert(xmppStream == nil, @"Method setupStream invoked multiple times");
	
    
	xmppStream = [[XMPPStream alloc] init];
	
#if !TARGET_IPHONE_SIMULATOR
	{
        xmppStream.enableBackgroundingOnSocket = YES;
	}
#endif
    
    // 设置发送心跳包
    xmppAutoPing = [[XMPPAutoPing alloc] init];
    xmppAutoPing.pingInterval = g_config.XMPPPingTime;   // 心跳包发送时间间隔
    [xmppAutoPing activate:xmppStream];
    [xmppAutoPing addDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
	
    // 自动重连
    xmppReconnect = [[XMPPReconnect alloc] init];
    xmppReconnect.autoReconnect = YES;
    xmppReconnect.reconnectDelay = 0.f;
    xmppReconnect.reconnectTimerInterval = 3.0;
	
    xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
	
	xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
	
	xmppRoster.autoFetchRoster = YES;
	xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
    
    
    if (![g_config.isOpenReceipt boolValue]) {
        // 创建流状态缓存对象
        _streamStorage = [[XMPPStreamManagementPersistentStorage alloc] init];
        // 创建流管理对象
        _xmppStreamManagement = [[XMPPStreamManagement alloc] initWithStorage:_streamStorage];
        // 设置自动恢复
        [_xmppStreamManagement setAutoResume:YES];
        // 设置代理和返回队列
        [_xmppStreamManagement addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [_xmppStreamManagement requestAck];
        [_xmppStreamManagement automaticallyRequestAcksAfterStanzaCount:1 orTimeout:10];
        [_xmppStreamManagement automaticallySendAcksAfterStanzaCount:1 orTimeout:10];
        // 激活模块
        [_xmppStreamManagement activate:xmppStream];
    }
    
    [xmppReconnect         activate:xmppStream];
    [xmppRoster            activate:xmppStream];
    
	// Add ourself as a delegate to anything we may be interested in
    [xmppReconnect addDelegate:self delegateQueue:dispatch_get_main_queue()];
	[xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    xmppStream.hostName = g_config.XMPPHost;
    xmppStream.hostPort = 5222;
    
	// You may need to alter these settings depending on the server you're connecting to
	allowSelfSignedCertificates = NO;
	allowSSLHostNameMismatch = NO;
    
    self.roomPool = [[JXRoomPool alloc] init];
}

#pragma mark -- terminate
/**
 *  申请后台更多的时间来完成关闭流的任务
 */
-(void)applicationWillTerminate
{
    UIApplication *app=[UIApplication sharedApplication];
    UIBackgroundTaskIdentifier taskId;
    taskId=[app beginBackgroundTaskWithExpirationHandler:^(void){
        [app endBackgroundTask:taskId];
    }];

    [xmppStream disconnectAfterSending];
}

- (void)xmppStreamManagement:(XMPPStreamManagement *)sender wasEnabled:(NSXMLElement *)enabled {
    
}
- (void)xmppStreamManagement:(XMPPStreamManagement *)sender wasNotEnabled:(NSXMLElement *)failed {
    
}

#pragma mark - 消息回执
- (void)xmppStreamManagement:(XMPPStreamManagement *)sender didReceiveAckForStanzaIds:(NSArray<id> *)stanzaIds {
    NSLog(@"XMPPElement2 --- ");
    if ([g_config.isOpenReceipt boolValue]) {
        return;
    }
    for (NSInteger i = 0; i < stanzaIds.count; i ++) {
        NSString *msgId = stanzaIds[i];
        //正常消息回执
        JXMessageObject *msg   = (JXMessageObject*)[_poolSend objectForKey:msgId];
//        if ([msg.type intValue] == kWCMessageTypeMultipleLogin) {
//            [g_multipleLogin upDateOtherOnline:message isOnLine:[NSNumber numberWithInt:msg.content.intValue]];
//        }
//        NSLog(@"收到回执:%@,%@",messageId,[message receiptResponseID]);
        if([msg.isSend intValue] != transfer_status_yes &&msg.messageId != nil){
            [self doSendFriendRequest:msg];
            if ([msg.type intValue] == kWCMessageTypeWithdraw) {
                msg.content = Localized(@"JX_AlreadyWithdraw");
            }
            [msg updateLastSend:UpdateLastSendType_Add];
            [msg updateIsSend:transfer_status_yes];
            [msg notifyReceipt];
            [msg notifyMyLastSend];
            [_poolSend removeObjectForKey:msg.messageId];
        }
        
        //已读消息的回执
        if (msg == nil) {
            for (int i = 0; i < [_poolSendRead count]; i++) {
                JXMessageObject * p = _poolSendRead[i];
                if ([p.messageId isEqualToString:msgId]) {
                    //对方已收到已读消息的回执
                    [p updateIsReadWithContent];
                    [g_notify postNotificationName:kXMPPMessageReadTypeReceiptNotification object:p];//接收方收到已读消息的回执，改变标志避免重复发
                    [_poolSendRead removeObject:p];
                    p =nil;
                    break;
                }
            }
        }
        
        msg = nil;
        return;
    }
}

- (BOOL)xmppReconnect:(XMPPReconnect *)sender shouldAttemptAutoReconnect:(SCNetworkConnectionFlags)connectionFlags {
    
    return YES;
}


- (void)teardownStream
{
	[xmppStream removeDelegate:self];
	
	[xmppReconnect         deactivate];
	
	[xmppStream disconnect];
	
	xmppStream = nil;
	xmppReconnect = nil;
}

// 心跳包回调
#pragma mark - XMPPAutoPingDelegate
- (void)xmppAutoPingDidReceivePong:(XMPPAutoPing *)sender{
    // 如果至少有1次超时了，再收到pong包，则清除超时次数
    if (pingTimeoutCount > 0) {
        pingTimeoutCount = 0;
    }
}
- (void)xmppAutoPingDidTimeout:(XMPPAutoPing *)sender {
    // 收到两次超时，就disconnect
    pingTimeoutCount++;
    if (pingTimeoutCount >= 2) {
        NSLog(@"xmpp ---- PingDidTimeout");
        [self logout];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self login];
        });
    }
}

// It's easy to create XML elments to send and to read received XML elements.
// You have the entire NSXMLElement and NSXMLNode API's.
//
// In addition to this, the NSXMLElement+XMPP category provides some very handy methods for working with XMPP.
//
// On the iPhone, Apple chose not to include the full NSXML suite.
// No problem - we use the KissXML library as a drop in replacement.
//
// For more information on working with XML elements, see the Wiki article:
// http://code.google.com/p/xmppframework/wiki/WorkingWithElements

- (void)goOnline
{
	XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
	
	[xmppStream sendElement:presence];
}

- (void)goOffline
{
	XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
	
	[xmppStream sendElement:presence];
}

-(void)notify{
    [g_notify  postNotificationName:kXmppLoginNotifaction object:nil];
    if (self.isLogined == login_status_yes) {
        // 上线发送消息通知其他端
        [g_multipleLogin sendOnlineMessage];
    }else {
    }
    [self loginChanged];
    if (self.isLogined != login_status_ing) {
        [_wait stop];
    }
    [self.timer invalidate];
    self.timer = nil;
}

- (BOOL)connect
{
//    if (![xmppStream isDisconnected])
//        return YES;
    
	NSString *userID = [[NSUserDefaults standardUserDefaults] stringForKey:kMY_USER_ID];
	NSString *myPassword = [[NSUserDefaults standardUserDefaults] stringForKey:kMY_USER_PASSWORD];
//    BOOL isMultipleLogin = [[g_default objectForKey:kISMultipleLogin] boolValue];
    BOOL isMultipleLogin = [g_myself.multipleDevices intValue] > 0 ? YES : NO;
    NSString *sameResource = @"/youjob";
    if (isMultipleLogin) {
        sameResource = @"/ios";
    }
    xmppStream.hostName = g_config.XMPPHost;
    NSString *myJID = [NSString stringWithFormat:@"%@@%@%@",userID,g_config.XMPPDomain,sameResource];//拼接主机名&resource
    
	if (myJID == nil || myPassword == nil) {
		return NO;
	}
    self.isLogined = login_status_ing;
    [self notify];
    
    [xmppStream setMyJID:[XMPPJID jidWithString:myJID]];
//    password = [g_server getMD5String:myPassword];
    password = myPassword;
    
	NSError *error = nil;
    if (![xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error])
	{
        self.isLogined = login_status_no;
        [self notify];
		DDLogError(@"Error connecting: %@", error);
		return NO;
	}
	return YES;
}

- (void)disconnect
{
    // 离线前发送消息通知其他端
    [g_multipleLogin sendOfflineMessage];
    
    self.isReconnect = NO;
	[self goOffline];
    if (self.isCloseStream && ![g_config.isOpenReceipt boolValue]) {
        self.isCloseStream = NO;
        [self applicationWillTerminate];
    }else {
        [xmppStream disconnect];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UIApplicationDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
#if TARGET_IPHONE_SIMULATOR
	DDLogError(@"The iPhone simulator does not process background network traffic. "
			   @"Inbound traffic is queued until the keepAliveTimeout:handler: fires.");
#endif

	if ([application respondsToSelector:@selector(setKeepAliveTimeout:handler:)])
	{
		[application setKeepAliveTimeout:600 handler:^{
			
			DDLogVerbose(@"KeepAliveHandler");
			
			// Do other keep alive stuff here.
		}];
	}
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (NSManagedObjectContext *)managedObjectContext_roster
{
	return [xmppRosterStorage mainThreadManagedObjectContext];
}
// Returns the URL to the application's Documents directory.

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	if (allowSelfSignedCertificates)
	{
		[settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
	}
	
	if (allowSSLHostNameMismatch)
	{
		[settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
	}
	else
	{
		// Google does things incorrectly (does not conform to RFC).
		// Because so many people ask questions about this (assume xmpp framework is broken),
		// I've explicitly added code that shows how other xmpp clients "do the right thing"
		// when connecting to a google server (gmail, or google apps for domains).
		
		NSString *expectedCertName = nil;
		
		NSString *serverDomain = xmppStream.hostName;
		NSString *virtualDomain = [xmppStream.myJID domain];
		
		if ([serverDomain isEqualToString:@"talk.google.com"])
		{
			if ([virtualDomain isEqualToString:@"gmail.com"])
			{
				expectedCertName = virtualDomain;
			}
			else
			{
				expectedCertName = serverDomain;
			}
		}
		else if (serverDomain == nil)
		{
			expectedCertName = virtualDomain;
		}
		else
		{
			expectedCertName = serverDomain;
		}
		
		if (expectedCertName)
		{
			[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
		}
	}
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	isXmppConnected = YES;
	
	NSError *error = nil;
	
	if (![xmppStream authenticateWithPassword:password error:&error])
	{
        self.isLogined = login_status_no;
        [self notify];
		DDLogError(@"Error authenticating: %@", error);
	}
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    [self doLogin];
    if (![g_config.isOpenReceipt boolValue]) {
        [_xmppStreamManagement enableStreamManagementWithResumption:YES maxTimeout:60];
        //    [_xmppStreamManagement requestAck];
        [_xmppStreamManagement sendAck];
    }
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    if ([[error stringValue] isEqualToString:@"Password not verified"]) {
        self.isPasswordError = YES;
    }
    self.isLogined = login_status_no;
    self.isReconnect = NO;
    [self notify];
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
//	DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [iq elementID]);
	
    if ([[iq stringValue] rangeOfString:@"enable"].location != NSNotFound) {
        NSLog(@"收到iq:%@",iq);
        self.IQTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(sendIQ:) userInfo:nil repeats:YES];
    }
    
	return NO;
}

#pragma mark - －－－－－－－－－收到消息时调用
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    //    <message xmlns="jabber:client" id="JyebH-103" to="62275004d76f4e64affe38f48ebe30cb@www.talk.com/26a9fe46" type="groupchat" from="room2@conference.www.talk.com/tjx"><body>gg</body><x xmlns="jabber:x:event"><offline/><delivered/><displayed/><composing/></x></message>
    //    <message id="JyebH-110" to="luorc@www.talk.com" from="tjx@www.talk.com/Spark 2.6.3" type="chat"><body>dddd</body><thread>FtWwwk</thread><x xmlns="jabber:x:event"><offline/><composing/></x></message>

    
//	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    NSLog(@"message----: %@", message);
    
    
    pingTimeoutCount = 0;
    
    NSString* type = [[message attributeForName:@"type"] stringValue];
//    NSString* read = [[message attributeForName:@"read"] stringValue];
    NSString* messageId = [[message attributeForName:@"id"] stringValue];

    NSString *body = [[message elementForName:@"body"] stringValue];
    NSString *fromUserId=[self getUserId:[message fromStr]];
    NSString *toUserId=[self getUserId:[message toStr]];
    NSXMLElement *x = [message elementForName:@"x"];
    
//    NSLog(@"didReceiveMessage:%@,%@",messageId,body);
//    if(delay != nil && [type isEqualToString:@"groupchat"] && messageId == nil)//如果是群聊的历史消息，则忽略
//        return;
    if([message hasReceiptResponse]) {//如果是回执，则通知界面
        //正常消息回执
        JXMessageObject *msg   = (JXMessageObject*)[_poolSend objectForKey:[message receiptResponseID]];
        if ([msg.type intValue] == kWCMessageTypeMultipleLogin) {
            [g_multipleLogin upDateOtherOnline:message isOnLine:[NSNumber numberWithInt:msg.content.intValue]];
        }
        NSLog(@"收到回执:%@,%@",messageId,[message receiptResponseID]);
        if([msg.isSend intValue] != transfer_status_yes &&msg.messageId != nil){
            [self doSendFriendRequest:msg];
            [msg updateLastSend:UpdateLastSendType_Add];
            [msg updateIsSend:transfer_status_yes];
            [msg notifyReceipt];
            [msg notifyMyLastSend];
            [_poolSend removeObjectForKey:msg.messageId];
        }
        
        //已读消息的回执
        if (msg == nil) {
            for (int i = 0; i < [_poolSendRead count]; i++) {
                JXMessageObject * p = _poolSendRead[i];
                if ([p.messageId isEqualToString:[message receiptResponseID]]) {
                    //对方已收到已读消息的回执
                    [p updateIsReadWithContent];
                    [g_notify postNotificationName:kXMPPMessageReadTypeReceiptNotification object:p];//接收方收到已读消息的回执，改变标志避免重复发
                    [_poolSendRead removeObject:p];
                    p =nil;
                    break;
                }
            }
        }
        
        msg = nil;
        return;
    }
    
    if(![blackList containsObject:fromUserId]){ //排除黑名单，未对黑名单处理
        SBJsonParser * resultParser = [[SBJsonParser alloc] init];
        //将字符串转为字典
        NSDictionary* resultObject = [resultParser objectWithString:body];
//        [resultParser release];
        
        JXMessageObject *msg=[[JXMessageObject alloc] init];
        if([type isEqualToString:@"chat"] || [type isEqualToString:@"groupchat"]){
            //创建message对象
            msg.messageId    = [messageId copy];
            //            msg.timeSend     = [NSDate date];//接收消息一律以本机时间为准，才不会乱序
            
            [self sendXMPPIQ:(NSString *)msg.messageId];
            if(msg.messageId == nil)
                msg.messageId = [resultObject objectForKey:@"messageId"];

            [msg fromDictionary:resultObject];
            
            if ([fromUserId isEqualToString:MY_USER_ID]) {
                msg.isMultipleRelay = YES;
            }else {
                msg.isMultipleRelay = NO;
            }
            
            if ([msg.content isKindOfClass:[NSDictionary class]]) {
                
                SBJsonWriter *jsonWriter = [[SBJsonWriter alloc] init];
                msg.content = [jsonWriter stringWithObject:(NSDictionary *)msg.content];
            }
            
            
            // 已过期的消息不处理
            if (([msg.deleteTime timeIntervalSince1970] < [[NSDate date] timeIntervalSince1970]) && [msg.deleteTime timeIntervalSince1970] > 0) {
                return;
            }
            
            if ([type isEqualToString:@"chat"] && msg.fromUserId && msg.toUserId && [msg.fromUserId isEqualToString:msg.toUserId]) {
                NSString *from = [message fromStr];
                NSRange range = [from rangeOfString:@"/"];
                NSString *device = [from substringFromIndex:range.location + 1];
                if ([device isEqualToString:@"android"]) {
                    msg.fromUserId = ANDROID_USERID;
                    fromUserId  = ANDROID_USERID;
                }
                if ([device isEqualToString:@"pc"]) {
                    msg.fromUserId = PC_USERID;
                    fromUserId  = PC_USERID;
                }
                if ([device isEqualToString:@"mac"]) {
                    msg.fromUserId = MAC_USERID;
                    fromUserId  = MAC_USERID;
                }
                if ([device isEqualToString:@"web"]) {
                    msg.fromUserId = WEB_USERID;
                    fromUserId  = WEB_USERID;
                }
            }
            msg.fromId       = fromUserId;
            msg.toId         = toUserId;
            
            if([msg.toUserId intValue]<=0)
                msg.toUserId     = toUserId;
            if([msg.fromUserId intValue]<=0)//如果是群聊，则获取正确的fromUserId
                msg.fromUserId   = fromUserId;
            
            if ([msg.fromUserName isKindOfClass:[NSString class]]) {
                if([msg.fromUserName length]>0 && [type isEqualToString:@"chat"] && ![msg.fromUserId isEqualToString:MY_USER_ID]){//保存陌生人信息：
                    [self saveFromUser:msg];
                }
            }
            
            if ([msg.type intValue] == kWCMessageTypeMultipleLogin) {
                [self sendMsgReceipt:message];//收到200验证消息后，发回执
                [g_multipleLogin upDateOtherOnline:message isOnLine:[NSNumber numberWithInt:msg.content.intValue]];
            }else {
                if ([type isEqualToString:@"groupchat"]) {
                    msg.isGroup = YES;
//                    if (x) {
//                        msg.isDelay = YES;
//                    }
                    
                    msg.isDelay      = [[message elementForName:@"delay"] stringValue] != nil;
                }else {
                    msg.isGroup = NO;
                    msg.isDelay      = [[message elementForName:@"delay"] stringValue] != nil;
                }
                [g_multipleLogin relaySendMessage:message msg:msg];
            }
            
            //判断是否为已读类型
            if ([msg.type intValue] == kWCMessageTypeIsRead){
//                [self sendMsgReceipt:message];//收到已读消息后，发回执，确认收到
                BOOL isHave = [msg haveTheMessage];
                BOOL inserted = NO;
                if ([type isEqualToString:@"chat"]) {
                    inserted = [msg insert:nil];
                }else {
                    msg.isGroup  = YES;
                    msg.toUserId = fromUserId;
                    if ([msg.fromUserId isEqualToString:MY_USER_ID]) {
                        return;
                    }
                    inserted = [msg insert:fromUserId];
                }
                if (inserted) {
//                    if(![msg.fromUserId isEqualToString:MY_USER_ID]){//假如是我发送的，则以收到回执为准
                        if (isHave) {
                            return;
                        }
                        [msg updateIsReadWithContent];
                        [g_notify postNotificationName:kXMPPMessageReadTypeNotification object:msg];//发送方收到已读类型，改变消息图片为已读
//                        if (!msg.isGroup) {
                        
                        // 阅后即焚：对方查看了我发送的阅后即焚消息，收到已读回执后删除阅后即焚消息
                    NSString *fetchUserId;
                    if ([msg.fromUserId isEqualToString:MY_USER_ID]) {
                        fetchUserId = msg.toUserId;
                    }else {
                        fetchUserId = msg.fromUserId;
                    }
                            NSMutableArray *arr = [[JXMessageObject sharedInstance] fetchAllMessageListWithUser:fetchUserId];
                            for (NSInteger i = 0; i < arr.count; i ++) {
                                JXMessageObject * p = [arr objectAtIndex:i];
                                if ([p.messageId isEqualToString:msg.content]) {
                                    if ([p.isReadDel boolValue]) {
                                        if ([p.type intValue] == kWCMessageTypeImage || [p.type intValue] == kWCMessageTypeVoice || [p.type intValue] == kWCMessageTypeVideo || [p.type intValue] == kWCMessageTypeText) {
                                            
                                            if ([p.fromUserId isEqualToString:MY_USER_ID]) {
                                                JXMessageObject *newMsg = [[JXMessageObject alloc] init];
                                                newMsg.isShowTime = NO;
                                                newMsg.messageId = msg.content;
                                                if(![type isEqualToString:@"chat"]){
                                                    newMsg.isGroup = YES;
                                                    msg.toUserId = fromUserId;
                                                }else {
//                                                    [self sendMsgReceipt:message];
                                                }
                                                newMsg.type = [NSNumber numberWithInt:kWCMessageTypeRemind];
                                                newMsg.content = Localized(@"JX_OtherLookedYourReadingMsg");
                                                newMsg.fromUserId = msg.fromUserId;
                                                newMsg.toUserId = msg.toUserId;
                                                [newMsg update];
                                                [newMsg updateLastSend:UpdateLastSendType_None];
                                                msg = nil;
                                            }else {
                                                [p delete];
                                            }
                                            
                                        }
                                    }
                                }
//                            }
                            
                        }
                        
//                    }
                }
                return;
            }
            
            if(msg.type != nil ){
                // 判断是否是撤回消息
                if ([msg.type intValue] == kWCMessageTypeWithdraw) {
                    
                    JXMessageObject *newMsg = [[JXMessageObject alloc] init];
                    newMsg.isShowTime = NO;
                    newMsg.messageId = msg.content;
                    if(![type isEqualToString:@"chat"]){
                        newMsg.isGroup = YES;
                        msg.toUserId = fromUserId;
                    }else {
//                        [self sendMsgReceipt:message];
                    }
                    newMsg.type = [NSNumber numberWithInt:kWCMessageTypeRemind];
                    if ([msg.fromUserId isEqualToString:MY_USER_ID]) {
                        newMsg.content = Localized(@"JX_AlreadyWithdraw");
                    }else {
                        newMsg.content = [NSString stringWithFormat:@"%@%@",msg.fromUserName, Localized(@"JX_OtherWithdraw")];
                    }
                    newMsg.fromUserId = msg.fromUserId;
                    newMsg.toUserId = msg.toUserId;
                    newMsg.timeSend = msg.timeSend;
                    JXMessageObject *msg1 = [newMsg getMsgWithMsgId:msg.content];
                    if (msg1 && [msg1.type integerValue] != kWCMessageTypeRemind) {
                        [newMsg updateLastSend:UpdateLastSendType_None];
                        [g_notify postNotificationName:kXMPPMessageWithdrawNotification object:newMsg];
                    }
                    [newMsg update];
                    msg = nil;
                    return;
                }
                
                // 分享消息
                if ([msg.type intValue] == kWCMessageTypeShare) {
                    msg.content = [NSString stringWithFormat:@"[%@]",Localized(@"JXLink")];
                }
                // 转账已被领取消息
                if ([msg.type intValue] == kWCMessageTypeTransferReceive) {
                    [g_notify postNotificationName:kXMPPMessageTransferReceiveNotification object:msg];
                }
                // 转账已被退回消息
                if ([msg.type intValue] == kWCMessageTypeTransferBack) {
                    [g_notify postNotificationName:kXMPPMessageTransferBackNotification object:msg];
                }
                // 扫码支付款
                if ([msg.type intValue] == kWCMessageTypePaymentOut || [msg.type intValue] == kWCMessageTypeReceiptOut ||[msg.type intValue] == kWCMessageTypePaymentGet ||[msg.type intValue] == kWCMessageTypeReceiptGet) {
                    [g_notify postNotificationName:kXMPPMessageQrPaymentNotification object:msg];
                }
                // 修改密码/首次设置支付密码/隐私设置/标签的增删改查
                if ([msg.type intValue] == kWCMessageTypeUpadtePassword) {
                    if ([msg.objectId isEqualToString:SYNC_LOGIN_PASSWORD] && !msg.isDelay) {
                        [g_server otherUpdatePassword];
                    }
                    else if ([msg.objectId isEqualToString:SYNC_LOGIN_PASSWORD]) {
                        g_server.myself.isPayPassword = @1;
                    }
                    else{
                        [g_notify postNotificationName:kXMPPMessageUpadtePasswordNotification object:msg];
                    }
                }
                // 编辑自己的基本资料/用户
                if ([msg.type intValue] == kWCMessageTypeUpadteUserInfo) {
                    [g_notify postNotificationName:kXMPPMessageUpadteUserInfoNotification object:msg];
                }
                // 编辑群组资料
                if ([msg.type intValue] == kWCMessageTypeUpadteGroup) {
                    [g_notify postNotificationName:kXMPPMessageUpadteGroupNotification object:msg];
                }
                if([type isEqualToString:@"chat"]){
                    //单聊发送回执：
                    if (![fromUserId isEqualToString:MY_USER_ID]) {
//                        [self sendMsgReceipt:message];
                    }
                    // 判断是否是正在输入
                    if ([msg.type intValue] == kWCMessageTypeRelay) {
                        [g_notify postNotificationName:kXMPPMessageEnteringNotification object:msg];
                        msg = nil;
                        return;
                    }
                    // 点赞 & 评论
                    if ([msg.type intValue] == kWCMessageTypeWeiboPraise || [msg.type intValue] == kWCMessageTypeWeiboComment || [msg.type intValue] == kWCMessageTypeWeiboRemind) {
                        JXBlogRemind *br = [[JXBlogRemind alloc] init];
                        [br fromObject:msg];
                        [br insertObj];
                        [g_notify postNotificationName:kXMPPMessageWeiboRemind object:msg];
                        msg = nil;
                        return;
                    }
                    // 加好友消息
                    if([msg isAddFriendMsg]){
                        if ([msg.type intValue] == XMPP_TYPE_CONTACTREGISTER) {
                            [g_notify postNotificationName:kMsgComeContactRegister object:msg];
                        }else {
                            [self doReceiveFriendRequest:msg];
                        }
                        return;
                    }
                    
                    // 面对面建群通知
                    if ([msg.type integerValue] == kRoomRemind_FaceRoomSearch) {
                        [g_notify postNotificationName:kMsgRoomFaceNotif object:msg];
                        return;
                    }
                    
                    //群文件：
                    if([msg.type intValue] == kWCMessageTypeGroupFileUpload || [msg.type intValue] == kWCMessageTypeGroupFileDelete || [msg.type intValue] == kWCMessageTypeGroupFileDownload){
                        [msg doGroupFileMsg];
                        return;
                    }
                    //清空双方聊天记录
                    if ([msg.type intValue] == kWCMessageTypeDelMsgTwoSides) {
                        JXMessageObject *msg1 = [[JXMessageObject alloc] init];
                        msg1.toUserId = msg.fromUserId;
                        [msg1 deleteAll];
                        msg1.type = [NSNumber numberWithInt:1];
                        msg1.content = @" ";
                        [msg1 updateLastSend:UpdateLastSendType_None];
                        [msg1 notifyMyLastSend];
                        [g_server emptyMsgWithTouserId:msg1.fromUserId type:[NSNumber numberWithInt:0] toView:self];
                        [g_notify postNotificationName:kRefreshChatLogNotif object:nil];
                    }
                    
                    if (![msg haveTheMessage]) {
                        BOOL isRoomControlMsg = msg.isRoomControlMsg;
                        BOOL isInsert = [msg insert:nil];//在保存时检测MessageId是否已存在记录
                        if (isRoomControlMsg && !isInsert) {
                            return;
                        }

                        [msg updateLastSend:UpdateLastSendType_Add];
                        [msg notifyNewMsg];//在显示时检测MessageId是否已显示
                    }
                }else{
                    
                    //群文件：
                    if([msg.type intValue] == kWCMessageTypeGroupFileUpload || [msg.type intValue] == kWCMessageTypeGroupFileDelete || [msg.type intValue] == kWCMessageTypeGroupFileDownload){
                        [msg doGroupFileMsg];
                        return;
                    }
                    
//                    if ([msg.toUserId isEqualToString:MY_USER_ID] && [msg.type intValue] == kRoomRemind_DelMember) {
//                        //删除数据库里的本地房间
//                        [JXUserObject deleteUserAndMsg:msg.objectId];
//                    }
                    
                    msg.isGroup  = YES;
                    BOOL isRoomControlMsg = msg.isRoomControlMsg;
                    if(!isRoomControlMsg)
                        msg.toUserId = fromUserId;

//                    if(![msg.fromUserId isEqualToString:MY_USER_ID]){
                    
                    if(![msg insert:fromUserId]){ //在保存时检测MessageId是否已存在记录
                        if (isRoomControlMsg) {
                            return;
                        }
                        msg.isRepeat = YES;
                    }else {
                        [msg updateLastSend:UpdateLastSendType_Add];
                    }
                    [msg notifyNewMsg];
//                    }
                    
                }
            }
        }
        
        msg = nil;
    }
}


- (void)sendIQ:(NSTimer *)timer {
    _IQNum = _IQNum > 5 ? 0 : _IQNum +1;
    // 消息回执（发送给服务器）
    // 每秒执行一次，判断5秒没发回执就发一次，或者消息数量大于100也发一次
    if (_poolSendIQ.count >= 100 || (_IQNum >= 5 && _poolSendIQ.count > 0)) {
        XMPPIQ *xmppIQ = [XMPPIQ iqWithType:@"set" to:[XMPPJID jidWithString:g_config.XMPPDomain]];
        
        DDXMLNode* idN = [DDXMLNode elementWithName:@"id" stringValue:[xmppStream generateUUID]];
        [xmppIQ addChild:idN];
        
        NSXMLElement * xmlns = [NSXMLElement elementWithName:@"body" xmlns:@"xmpp:shiku:ack"];
        NSArray *arr = [[NSArray alloc] init];
        
        if (_poolSendIQ.count > 100) {
            arr = [_poolSendIQ subarrayWithRange:NSMakeRange(0, 100)];
        }else {
            arr = _poolSendIQ.copy;
        }

        xmlns.stringValue = [arr componentsJoinedByString:@","];

        [xmppIQ addChild:xmlns];
        
        [xmppStream sendElement:xmppIQ];
        
        // 消息发送后清空_poolSendIQ里面的messageId
        if (_poolSendIQ.count > 100) {
            [_poolSendIQ removeObjectsInRange:NSMakeRange(0, 100)];
        }else {
            [_poolSendIQ removeAllObjects];
        }
        
        NSLog(@"发送xmppIQ = %@",xmppIQ);
    }
    
}


- (void)sendXMPPIQ:(NSString *)messageId {
    //保存没条消息的messageId
    if (IsStringNull(messageId)) {
        return;
    }
    if (![_poolSendIQ containsObject:messageId]) {
        [_poolSendIQ addObject:messageId];
    }
}

- (void)enableIQ {
    // 向服务器发开启消息
    XMPPIQ *xmppIQ = [XMPPIQ iqWithType:@"set" to:[XMPPJID jidWithString:g_config.XMPPDomain] elementID:[xmppStream generateUUID]];
    
    NSXMLElement * xmlns = [NSXMLElement elementWithName:@"enable" xmlns:@"xmpp:shiku:ack"];
    xmlns.stringValue = @"enable";
    [xmppIQ addChild:xmlns];
    
    [xmppStream sendElement:xmppIQ];
    
    NSLog(@"xmppIQ = %@",xmppIQ);
}

- (void) sendMsgReceipt:(XMPPMessage *)message{//单聊发送消息回执
    // 客户端暂时不发送回执，由服务器代发（200 消息除外）
//    NSString *delay = [[message elementForName:@"delay"] stringValue];
//    if([message hasReceiptRequest] && delay == nil){//离线不发送回执
    if([message hasReceiptRequest]){//离线也发送回执，这样服务器可以确保消息送达
        XMPPMessage* reply = [message generateReceiptResponse];//发送回执
        [xmppStream sendElement:reply];
        NSLog(@"单聊发送消息回执");
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
	DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [presence fromStr]);
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(NSXMLElement*)element
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSString *elementName = [element name];
    
    if ([elementName isEqualToString:@"stream:error"]){
        DDXMLNode * errorNode = (DDXMLNode *)element;
        NSArray * errorNodeArray = [errorNode children];
        for (DDXMLNode * node in errorNodeArray) {
            if ([[node name] isEqualToString:@"conflict"]) {
                self.isReconnect = NO;
                [_reconnectTimer invalidate];
                _reconnectTimer = nil;
                NSLog(@"xmpp ---- error");
                [self logout];
                if (!self.isChatLogMove) {
                    [g_notify postNotificationName:kXMPPLoginOtherNotification object:nil];
                }
                return;
            }
        }
    }
    elementName = nil;
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSLog(@"XMPP ---- disconnect");
    NSLog(@"xmpp ---- error --- %@", error);
    if (error && self.isReconnect && self.reconnectTimerCount == 10) {
        self.reconnectTimerCount = 11;
        [roomPool deleteAll];
        self.isLogined = login_status_no;
        g_server.lastOfflineTime = [[NSDate date] timeIntervalSince1970];
        [self login];
    }
    
//    [self logout];
    
//    self.isReconnect = NO;
//    [self logout];
//    if (g_server.isLogin) {
//        [g_server userChangeMsgNum:[UIApplication sharedApplication].applicationIconBadgeNumber toView:self];
//    }
    
	if (isXmppConnected)
	{
		DDLogError(@"Unable to connect to server. Check xmppStream.hostName");
	}
}

- (NSString *)xmppStream:(XMPPStream *)sender alternativeResourceForConflictingResource:(NSString *)conflictingResource{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    return nil;
}




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRosterDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence
{
    
    XMPPJID *jid=[XMPPJID jidWithString:[presence stringValue]];
    [xmppRoster acceptPresenceSubscriptionRequestFrom:jid andAddToRoster:YES];
}

- (void)addSomeBody:(NSString *)userId
{
    [xmppRoster subscribePresenceToUser:[XMPPJID jidWithString:[NSString stringWithFormat:@"%@@%@",userId,g_config.XMPPDomain]]];
}

-(void)fetchUser:(NSString*)userId
{
    [g_server getUser:userId toView:self];
}

-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
    if ([aDownload.action isEqualToString:act_readDelMsg]) {
        NSLog(@"删除成功");
    }
    if([dict count]>0){
        JXUserObject* user = [[JXUserObject alloc]init];
        [user userFromDictionary:user dict:dict];
        [user insert];
//        [user release];
    }
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message{
//    NSString *body = [[message elementForName:@"body"] stringValue];
//	DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, body);
}

- (FMDatabase*)openUserDb:(NSString*)userId{
    userId = [userId uppercaseString];
    if([_userIdOld isEqualToString:userId]){
        if(_db && [_db goodConnection])
            return _db;
    }
//    [_userIdOld release];
//    _userIdOld = [userId retain];
    _userIdOld = userId;
    NSString* t =  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString* s = [NSString stringWithFormat:@"%@/%@.db",t,userId];
    
//    [_db close];
//    [_db release];
    _db = [[FMDatabase alloc] initWithPath:s];
    if (![_db open]) {
//        NSLog(@"数据库打开失败");
        return nil;
    };
    NSLog(@"dataPath:%@",_db.databasePath);
    
    if (userId.length > 0) {
        [self getBlackList];
    }
    return _db;
}

-(void)getBlackList{
    [blackList removeAllObjects];
    NSMutableArray* a = [[JXUserObject sharedInstance] fetchAllBlackFromLocal];
    for(int i=0;i<[a count];i++){
        JXUserObject* p = [a objectAtIndex:i];
        [blackList addObject:p.userId];
//        [p release];
    }
    a = nil;
}

-(NSString*)getUserId:(NSString*)s{
    NSRange range = [s rangeOfString:@"@"];
    if(range.location != NSNotFound)
        s = [s substringToIndex:range.location];
    return s;
}

-(void)saveToUser:(JXMessageObject*)msg{
    JXUserObject *user=[[JXUserObject alloc]init];
    user.userId = msg.toUserId;
    if (![user haveTheUser]) {
        user.userNickname = msg.toUserName;
        user.userDescription = msg.toUserName;
        [user insert];
    }
//    [user release];
}

-(void)saveFromUser:(JXMessageObject*)msg{
    JXUserObject *user=[[JXUserObject alloc]init];
    user.userId = msg.fromUserId;
    if (![user haveTheUser]) {
        user.userNickname = msg.fromUserName;
        user.userDescription = msg.fromUserName;
        [user insert];
    }
//    [user release];
}
#pragma mark-----阅后即焚删除本地数据
- (void)readDelete:(NSNotification *)notification{
    JXMessageObject *msg = notification.object;
    [msg delete];
//    if (!msg.isGroup || !msg.isMySend) {//群聊不删除服务器消息
//        [g_server readDeleteMsg:msg toView:self];
//    }
}

-(void)notifyNewMsg{
    NSLog(@"收到新消息：%f",g_xmpp.lastNewMsgTime);
    double n = [[NSDate date] timeIntervalSince1970]-g_xmpp.lastNewMsgTime;
    if(n>0.5){//假如0.5秒之内没有新消息到达，则认为收取完毕，一次性刷新
        NSLog(@"刷新聊天记录：%f",n);
//        self.newMsgAfterLogin = 1;
        [g_notify postNotificationName:kXMPPAllMsgNotifaction object:nil userInfo:nil];
    }
}

-(void)doReceiveFriendRequest:(JXMessageObject*)msg{
    if(![msg isAddFriendMsg])
        return;
    if([msg.type intValue] == XMPP_TYPE_SAYHELLO || [msg.type intValue] == XMPP_TYPE_FEEDBACK){
        int n = [msg.type intValue];
        msg.type = [NSNumber numberWithInt:kWCMessageTypeText];
        msg.isRead = [NSNumber numberWithInt:1];
        [msg insert:nil];
        msg.type = [NSNumber numberWithInt:n];
    }

    JXFriendObject* friend = [[JXFriendObject alloc]init];
    [friend loadFromMessageObj:msg];
    [friend doWriteDb];
    [friend notifyNewRequest];

    JXFriendObject *user = [[JXFriendObject sharedInstance] getFriendById:friend.userId];
    msg.content = [friend getLastContent];
    if ([user.msgsNew intValue] > 0) {
        [msg updateLastSend:UpdateLastSendType_None];
    }else {
        [user updateNewMsgUserId:user.userId num:1];
        [msg updateLastSend:UpdateLastSendType_Add];
    }
    [msg notifyNewMsg];
}

-(void)doSendFriendRequest:(JXMessageObject*)msg{
    if(![msg isAddFriendMsg])
        return;
    if(!msg.isMySend)
        return;
    if([msg.type intValue] == XMPP_TYPE_SAYHELLO || [msg.type intValue] == XMPP_TYPE_FEEDBACK){
        int n = [msg.type intValue];
        msg.timeReceive = [NSDate date];
        msg.type = [NSNumber numberWithInt:kWCMessageTypeText];
        msg.isSend = [NSNumber numberWithInt:transfer_status_yes];
        msg.isRead = [NSNumber numberWithInt:1];
        [msg insert:nil];
        msg.type = [NSNumber numberWithInt:n];
    }

    JXFriendObject* friend = [[JXFriendObject alloc]init];
    [friend loadFromMessageObj:msg];
    [friend doWriteDb];

    msg.content = [friend getLastContent];
    [msg updateLastSend:UpdateLastSendType_None];
    [msg notifyNewMsg];
}

-(void)inviteGroup{
    /*
     //被邀请进入房间
     NSXMLElement * x = [message elementForName:@"x" xmlns:XMPPMUCUserNamespace];
     NSXMLElement * invite  = [x elementForName:@"invite"];
     NSXMLElement * decline = [x elementForName:@"decline"];
     NSString * reason  = [[invite elementForName:@"reason"] stringValue];
     
     NSXMLElement * directInvite = [message elementForName:@"x" xmlns:@"jabber:x:conference"];
     
     if (invite || directInvite || decline)
     {
     
     SBJsonParser * resultParser = [[SBJsonParser alloc] init];
     //将字符串转为字典
     NSDictionary* resultObject = [resultParser objectWithString:reason];
     //          [resultParser release];
     
     roomData * room = [[roomData alloc]init];
     [room getDataFromDict:resultObject];
     JXUserObject* user = [[JXUserObject alloc]init];
     if (room != nil) {
     user.userNickname = room.name;
     user.userId = room.roomJid;
     user.userDescription = room.desc;
     user.roomId = room.roomId;
     }
     
     if (invite || directInvite) {
     [user insertRoom];
     JXRoomObject * chatRoom = [g_xmpp.roomPool joinRoom:room.roomJid title:room.name isNew:YES];
     [chatRoom reconnect];
     }else{
     //              [JXUserObject deleteUserAndMsg:room.roomJid];
     //              [g_server delRoomMember:room.roomId userId:[g_myself.userId intValue] toView:self];
     NSLog(@"删除成员回调");
     }
     
     
     
     return;
     }
     */
}

// xmpp掉线后提示
- (void) showXmppOfflineAlert {
    
    [g_App showAlert:Localized(@"JX_Reconnect") delegate:self];
}

- (void) timerAction:(NSTimer *)timer{
    [_wait stop];
    // 连接失败
    [JXMyTools showTipView:Localized(@"JX_ConnectFailed")];
    [timer invalidate];
    self.timer = nil;
}

#pragma mark UIAlertView delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        
        AppleReachability *reach = [AppleReachability reachabilityWithHostName:@"www.apple.com"];
        NetworkStatus internetStatus = [reach currentReachabilityStatus];
        switch (internetStatus) {
            case NotReachable:{
                if (self.isLogined != login_status_no) {
                    [self logout];
                }
                [g_App showAlert:Localized(@"JX_NetWorkError")];
            }
                break;
                
            default:{
                //        if (alertView.tag == 10000) { // XMPP掉线
                _isShowLoginChange = YES;
                //            [_wait start:Localized(@"JX_Connection")];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (self.isLogined != 1) {
                        self.timer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(timerAction:) userInfo:nil repeats:NO];
                        //                    self.loginStatus = YES;
                        NSLog(@"XMPP --- alert");
                        [self logout];
                        [_wait start:Localized(@"JX_Connection")];
                        [self login];
                    }
                });
                //        }
            }
                break;
        }
    }
}

-(BOOL)deleteMessageWithUserId:(NSString *)userId messageId:(NSString *)msgId{//删除一条聊天记录
    NSString* myUserId = MY_USER_ID;
    if([myUserId length]<=0)
        return NO;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    
    NSString *queryString=[NSString stringWithFormat:@"delete from msg_%@ where messageId=?",userId];
    
    BOOL worked=[db executeUpdate:queryString,msgId];
    return worked;
}

-(JXMessageObject*)findMessageWithUserId:(NSString *)userId messageId:(NSString *)msgId{//搜索一条记录
    NSString* myUserId = MY_USER_ID;
    if([myUserId length]<=0)
        return NO;
    FMDatabase* db = [[JXXMPP sharedInstance] openUserDb:myUserId];
    
    NSString *queryString=[NSString stringWithFormat:@"select * from msg_%@ where messageId=?",userId];
    
    FMResultSet *rs=[db executeQuery:queryString,msgId];
    JXMessageObject *p=nil;
    while ([rs next]) {
        p = [[JXMessageObject alloc]init];
        [p fromRs:rs];
        break;
    }
    return p;
}

- (void)loginChanged {
    // 弹登录提示
    if (_isShowLoginChange) {
        _isShowLoginChange = NO;
        switch (self.isLogined){
            case login_status_ing:
                // 连接失败
//                [JXMyTools showTipView:Localized(@"JX_ConnectFailed")];
                break;
            case login_status_no:
                
                g_server.lastOfflineTime = [[NSDate date] timeIntervalSince1970];
                // 连接失败
//                [JXMyTools showTipView:Localized(@"JX_ConnectFailed")];
                break;
            case login_status_yes:
                // 连接成功
                [JXMyTools showTipView:Localized(@"JX_ConnectSuccessfully")];
                break;
        }
    }
    
    // 定时检测XMPP登录状态，实现重连机制
    if (!self.isReconnect) {
        self.isReconnect = YES;
        return;
    }
    if(self.isLogined != login_status_yes) {
        [_reconnectTimer invalidate];
        _reconnectTimer = nil;
        if (self.reconnectTimerCount <= 30) {
            _reconnectTimer = [NSTimer scheduledTimerWithTimeInterval:self.reconnectTimerCount target:self selector:@selector(xmppTimerAction:) userInfo:nil repeats:NO];
            NSLog(@"login-开始登陆 - %d",self.isLogined);
        }
    }else {
        [_reconnectTimer invalidate];
        _reconnectTimer = nil;
    }
}

- (void)xmppTimerAction:(NSTimer *)timer {
    NSLog(@"login-timerAction - %d",self.isLogined);
    if (self.isLogined != login_status_yes){
        self.reconnectTimerCount ++;
        [self logout];
        [self login];
    }else {
        self.reconnectTimerCount = 10;
        [_reconnectTimer invalidate];
        _reconnectTimer = nil;
    }
}

@end
