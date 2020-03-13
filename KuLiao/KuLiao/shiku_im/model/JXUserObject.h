//
//  JXUserObject.h
//
//  Created by Reese on 13-8-11.
//  Copyright (c) 2013年 Reese. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JXUserBaseObj.h"

@class resumeBaseData;
@class memberData;

@interface JXUserObject : JXUserBaseObj{
}
@property (nonatomic,strong) NSString* telephone; // 加区号
@property (nonatomic,strong) NSString* phone; // 未加区号,暂未存数据库
@property (nonatomic,strong) NSString* password;
@property (nonatomic,strong) NSDate*   birthday;
@property (nonatomic,strong) NSString* companyName;
@property (nonatomic,strong) NSString* model;
@property (nonatomic,strong) NSString* osVersion;
@property (nonatomic,strong) NSString* serialNumber;
@property (nonatomic,strong) NSString* location;
@property (nonatomic,strong) NSNumber* sex;  //0 : 女   1 : 男
@property (nonatomic,strong) NSNumber* countryId;
@property (nonatomic,strong) NSNumber* provinceId;
@property (nonatomic,strong) NSNumber* cityId;
@property (nonatomic,strong) NSNumber* areaId;
@property (nonatomic,strong) NSNumber* latitude;
@property (nonatomic,strong) NSNumber* longitude;
@property (nonatomic,strong) NSNumber* level;
@property (nonatomic,strong) NSNumber* vip;
@property (nonatomic,strong) NSNumber* fansCount;
@property (nonatomic,strong) NSNumber* attCount;
@property (nonatomic,strong) NSString * friendCount;
@property (nonatomic,strong) NSString* areaCode;
@property (nonatomic,strong) NSNumber* isBeenBlack;//是否被拉黑
@property (nonatomic,strong) NSString* myInviteCode;  //多人邀请码
@property (nonatomic, copy) NSString *account;  // 即时通讯号
@property (nonatomic, copy) NSString *setAccountCount;  // 即时通讯号已修改次数
//@property (nonatomic, strong) NSNumber *isMultipleLogin;
@property (nonatomic, strong) NSNumber *showLastLoginTime; // 离线时间

// 隐私设置
@property (nonatomic,strong) NSString *chatSyncTimeLen; // 单聊聊天记录 同步时长
@property (nonatomic,strong) NSString *friendsVerify; // 好友验证
@property (nonatomic,strong) NSString *isEncrypt; // 消息加密传输
@property (nonatomic,strong) NSString *isTyping; // 正在输入
@property (nonatomic,strong) NSString *isVibration; // 震动
@property (nonatomic,strong) NSString *multipleDevices; // 多点登录
@property (nonatomic,strong) NSString *isUseGoogleMap; // 谷歌地图
@property (nonatomic,strong) NSString *payPassword; // 支付密码
@property (nonatomic,strong) NSString *oldPayPassword; // 旧支付密码
@property (nonatomic,strong) NSNumber *isPayPassword; // 是否存在支付密码
@property (nonatomic,strong) NSString *phoneSearch; // 允许通过手机号搜索我 1 允许 0 不允许
@property (nonatomic,strong) NSString *nameSearch; // 允许通过昵称搜索我  1 允许 0 不允许

@property (nonatomic, strong) NSString *msgBackGroundUrl;// 朋友圈顶部图片URL
@property (nonatomic, strong) NSArray *filterCircleUserIds;// 不看的生活圈 userid 列表

//短信验证码登录
@property (nonatomic, strong) NSString *verificationCode;// 短信验证码

// 我收藏的表情
@property (nonatomic, strong) NSMutableArray *favorites;

// 已拨打的电话号码
@property (nonatomic, strong) NSMutableDictionary *phoneDic;

+(JXUserObject*)sharedInstance;

-(NSMutableArray*)fetchAllFriendsFromLocal;
-(NSMutableArray*)fetchFriendsFromLocalWhereLike:(NSString *)searchStr;
-(NSMutableArray*)fetchAllRoomsFromLocal;
// 获取指定类型群组
-(NSMutableArray*)fetchRoomsFromLocalWithCategory:(NSNumber *)category;
-(NSMutableArray*)fetchAllCompanyFromLocal;
-(NSMutableArray*)fetchAllPayFromLocal;
-(NSMutableArray*)fetchAllUserFromLocal;
-(NSMutableArray*)fetchAllBlackFromLocal;
-(NSMutableArray*)fetchBlackFromLocalWhereLike:(NSString *)searchStr;
-(NSMutableArray*)fetchSystemUser;

-(BOOL)insertRoom;
-(void)createSystemFriend;
-(JXUserObject*)getUserById:(NSString*)aUserId;
-(void)getDataFromDict:(NSDictionary*)dict;
-(void)getDataFromDictSmall:(NSDictionary*)dict;
-(void)copyFromResume:(resumeBaseData*)resume;
-(void)copyFromRoomMember:(memberData*)p;
-(int)getNewTotal;

+(void)deleteUserAndMsg:(NSString*)userId;
+(BOOL)updateNewMsgsTo0;
+(NSString*)getUserNameWithUserId:(NSString*)userId;
- (void)insertFriend;
-(NSMutableArray*)fetchAllFriendsOrNotFromLocal;

// 更新最后输入
- (BOOL) updateLastInput;

// 更新消息界面显示的最后一条消息
- (BOOL) updateLastContent;

// 更新置顶时间
- (BOOL) updateTopTime;

// 更新群组有效性
- (BOOL) updateGroupInvalid;

// 更新用户昵称
- (BOOL) updateUserNickname;

// 更新用户备注
- (BOOL) updateRemarkName;

// 更新用户聊天记录过期时间
- (BOOL) updateUserChatRecordTimeOut;

// 更新列表最近一条消息记录
- (BOOL) updateUserLastChatList:(NSArray *)array;

// 更新是否开启阅后即焚标志
- (BOOL) updateIsOpenReadDel;

// 更新消息免打扰
- (BOOL) updateOfflineNoPushMsg;

// 更新@我
- (BOOL) updateIsAtMe;

// 更新群组全员禁言时间
- (BOOL) updateGroupTalkTime;

// 更新userType
- (BOOL) updateUserType;

// 更新创建者
- (BOOL)updateCreateUser;

// 更新群组设置
- (BOOL)updateGroupSetting;

// 更新好友关系
- (BOOL)updateStatus;

// 更新我的设备是否在线
- (BOOL)updateIsOnLine;

// 更新群组最后群成员加入时间
- (BOOL)updateJoinTime;

// 更新新消息数量
- (BOOL)updateNewMsgNum;


// 删除用户过期聊天记录
- (BOOL) deleteUserChatRecordTimeOutMsg;

- (BOOL) deleteAllUser;

// 获取已拨打号码
- (NSMutableDictionary *) getPhoneDic;
//插入已拨打的电话号码
- (BOOL) insertPhone:(NSString *)phone time:(NSDate *)time;
// 删除已拨打的电话号码
- (BOOL) deletePhone:(NSString *)phone;


@end
