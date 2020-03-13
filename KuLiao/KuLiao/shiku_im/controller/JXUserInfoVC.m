//
//  JXUserInfoVC.m
//  shiku_im
//
//  Created by flyeagleTang on 14-6-10.
//  Copyright (c) 2014年 Reese. All rights reserved.
//

#import "JXUserInfoVC.h"
//#import "selectTreeVC.h"
#import "selectValueVC.h"
#import "selectProvinceVC.h"
#import "ImageResize.h"
#import "JXChatViewController.h"
#import "JXLocationVC.h"
#import "JXMapData.h"
#import "JXInputValueVC.h"
#import "FMDatabase.h"
#import "userWeiboVC.h"
#import "JXReportUserVC.h"
#import "JXQRCodeViewController.h"
#import "JXImageScrollVC.h"
#import "DMScaleTransition.h"
#import "JXSetLabelVC.h"
#import "JXLabelObject.h"
#import "JXSetNoteAndLabelVC.h"

#define HEIGHT 50
//#define IMGSIZE 150

#define TopHeight 7
#define CellHeight 45

@interface JXUserInfoVC ()<JXReportUserDelegate,UITextFieldDelegate,JXSelectMenuViewDelegate>

@end

@implementation JXUserInfoVC
@synthesize user;

- (id)init
{
    self = [super init];
    if (self) {
        _titleArr = [[NSMutableArray alloc]init];
        _friendStatus = [user.status intValue];
        _latitude  = [user.latitude doubleValue];
        _longitude = [user.longitude doubleValue];
        
        self.isGotoBack   = YES;
        self.title = Localized(@"JX_BaseInfo");
        self.heightFooter = 0;
        self.heightHeader = JX_SCREEN_TOP;
        //self.view.frame = CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT);
        [self createHeadAndFoot];
        self.tableBody.backgroundColor = HEXCOLOR(0xf0eff4);
        self.tableBody.scrollEnabled = YES;
        
        if([self.userId isKindOfClass:[NSNumber class]])
            self.userId = [(NSNumber*)self.userId stringValue];
        
        [g_server getUser:self.userId toView:self];

        [g_notify addObserver:self selector:@selector(newReceipt:) name:kXMPPReceiptNotifaction object:nil];
        [g_notify addObserver:self selector:@selector(onSendTimeout:) name:kXMPPSendTimeOutNotifaction object:nil];
        [g_notify addObserver:self selector:@selector(friendPassNotif:) name:kFriendPassNotif object:nil];
        [g_notify addObserver:self selector:@selector(newRequest:) name:kXMPPNewRequestNotifaction object:nil];
        
        [self createViews];
        
        if (self.chatVC) {
            [self.chatVC.tableView reloadData];
        }
    }
    return self;
}

- (void)createViews {
    int h = 0;
    NSString* s;
    
    JXImageView* iv;
    
    // 更新头像缓存
    [g_server delHeadImage:self.userId];
    
    int Head_height = 123;
    UIView *headView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, JX_SCREEN_WIDTH, Head_height)];
    headView.backgroundColor = [UIColor whiteColor];
    [self.tableBody addSubview:headView];
    
    _head = [[JXImageView alloc]initWithFrame:CGRectMake(INSETS*2, INSETS*2, Head_height-INSETS*4, Head_height-INSETS*4)];
    _head.layer.cornerRadius = _head.frame.size.width/2;
    _head.layer.masksToBounds = YES;
    _head.didTouch = @selector(onHeadImage);
    _head.delegate = self;
    _head.image = [UIImage imageNamed:@"avatar_normal"];
    [headView addSubview:_head];
    [g_server getHeadImageLarge:self.userId userName:self.user.userNickname imageView:_head];

    // 名字
    _remarkName = [[UILabel alloc] init];
    _remarkName.font = [UIFont boldSystemFontOfSize:16];
    _remarkName.textColor = [UIColor blackColor];
    _remarkName.frame = CGRectMake(CGRectGetMaxX(_head.frame)+INSETS*2, INSETS*2, 70, 20);
    _remarkName.text = @"哈哈哈哈";
    [headView addSubview:_remarkName];
    
    _sex = [[UIImageView alloc] init];
    _sex.frame = CGRectMake(CGRectGetMaxX(_remarkName.frame)+3, INSETS*2+3, 14, 14);
    _sex.image = [UIImage imageNamed:@"basic_famale"];
    [headView addSubview:_sex];

    // 昵称
    _name = [[UILabel alloc] init];
    _name.font = SYSFONT(15);
    _name.textColor = [UIColor grayColor];
    _name.text = [NSString stringWithFormat:@"%@ : %@",Localized(@"JX_NickName"),@"--"];
    [headView addSubview:_name];
    
    //通讯号
    _account = [[UILabel alloc] init];
    _account.font = SYSFONT(15);
    _account.textColor = [UIColor grayColor];
    _account.text = [NSString stringWithFormat:@"%@ : %@",Localized(@"JX_Communication"),@"--"];
    [headView addSubview:_account];
    
    // 地区
    _city = [[UILabel alloc] init];
    _city.font = SYSFONT(15);
    _city.textColor = [UIColor grayColor];
    _city.text = [NSString stringWithFormat:@"%@ : %@",@"地区",@"--"];
    [headView addSubview:_city];

    
    h = Head_height;
    if ([self.userId intValue] != [MY_USER_ID intValue]) {
        //标签
        iv = [self createButton:Localized(@"JX_SetNotesAndLabels") drawTop:YES drawBottom:YES must:NO click:@selector(onRemark) superView:self.tableBody];
        iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
        _label = [self createLabel:iv default:user.userNickname];
        h+=iv.frame.size.height;
        
        // 描述
        iv = [self createButton:Localized(@"JX_UserInfoDescribe") drawTop:NO drawBottom:YES must:NO click:nil superView:self.tableBody];
        iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
        //如果是朋友且设置备注，这修改为备注，暂时不知道有没有此接口
        _describe = [self createLabel:iv default:user.describe];
        h+=iv.frame.size.height;
        _describeImgV = iv;
    }

    
//    if ([self.userId intValue]>10100 || [self.userId intValue]<10000) {
//        iv = [self createButton:Localized(@"JX_MemoName") drawTop:NO drawBottom:YES must:NO click:nil superView:self.tableBody];
//        iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
//        //如果是朋友且设置备注，这修改为备注，暂时不知道有没有此接口
//        _remarkName = [self createLabel:iv default:user.remarkName];
//        h+=iv.frame.size.height;
//
//        iv = [self createButton:Localized(@"JX_UserInfoDescribe") drawTop:NO drawBottom:YES must:NO click:nil superView:self.tableBody];
//        iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
//        //如果是朋友且设置备注，这修改为备注，暂时不知道有没有此接口
//        _describe = [self createLabel:iv default:user.describe];
//        h+=iv.frame.size.height;
//
//    }
    h+=INSETS;

    // 生活圈
    iv = [self createButton:Localized(@"JX_LifeCircle") drawTop:YES drawBottom:YES must:NO click:@selector(onMyBlog) superView:self.tableBody];
    iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
    h+=iv.frame.size.height;
    _lifeImgV = iv;
    
//    iv = [self createButton:Localized(@"JX_Sex") drawTop:NO drawBottom:YES must:NO click:nil superView:self.tableBody];
//    iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
//    NSArray* a = [NSArray arrayWithObjects:Localized(@"JX_Wuman"),Localized(@"JX_Man"),nil];
    
//    NSString * sexStr;
//    if ([user.sex intValue] == 0 || [user.sex intValue] == 1) {
//        sexStr = [a objectAtIndex:[user.sex intValue]];
//    }else if ([user.sex intValue] >= 10000) {
//        sexStr = @"--";
//    }else {
//        sexStr = @"";
//    }
//    _sex = [self createLabel:iv default:sexStr];
//
//    a = nil;
//    h+=iv.frame.size.height;
    // 生日
    iv = [self createButton:Localized(@"JX_BirthDay") drawTop:NO drawBottom:YES must:NO click:nil superView:self.tableBody];
    iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
    _date = [self createLabel:iv default:[TimeUtil formatDate:user.birthday format:@"yyyy-MM-dd"]];
    h+=iv.frame.size.height;
    _birthdayImgV = iv;
    
//    if ([g_config.isOpenPositionService intValue] == 0) {
//        iv = [self createButton:Localized(@"JX_Address") drawTop:NO drawBottom:YES must:NO click:nil superView:self.tableBody];
//        iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
//        _city = [self createLabel:iv default:city];
//        h+=iv.frame.size.height;
//    }
    
    // 在线时间
    iv = [self createButton:Localized(@"JX_LastOnlineTime") drawTop:NO drawBottom:YES must:NO click:nil superView:self.tableBody];
    iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
    _lastTImgV = iv;
    _lastTime = [self createLabel:iv default:[self dateTimeDifferenceWithStartTime:self.user.showLastLoginTime]];
    h+=iv.frame.size.height;
    
    // 显示手机号
    iv = [self createButton:Localized(@"JX_MobilePhoneNo.") drawTop:NO drawBottom:YES must:NO click:nil superView:self.tableBody];
    iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
    _showNImgV = iv;
    _showNum = [self createLabel:iv default:self.user.telephone];
    h+=iv.frame.size.height;

    h+=INSETS;
    
    _baseView = [[UIView alloc] initWithFrame:CGRectMake(0, h, JX_SCREEN_WIDTH, 0)];
    [self.tableBody addSubview:_baseView];
    h = 0;

    if ([g_config.isOpenPositionService intValue] == 0) {
        if (!self.isJustShow) {
            iv = [self createButton:Localized(@"JXUserInfoVC_Loation") drawTop:YES drawBottom:YES must:NO click:@selector(actionMap) superView:_baseView];
            iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
            h+=iv.frame.size.height;
        }
    }
    
    iv = [self createButton:Localized(@"JXQR_QRImage") drawTop:NO drawBottom:YES must:NO click:@selector(showUserQRCode) superView:_baseView];
    iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
    UIImageView * qrView = [[UIImageView alloc] init];
    qrView.frame = CGRectMake(JX_SCREEN_WIDTH-INSETS-20-3-30, 10, 30, 30);
    qrView.image = [UIImage imageNamed:@"qrcodeImage"];
    [iv addSubview:qrView];
    h+=iv.frame.size.height;
    
    if ([self.userId intValue] != [MY_USER_ID intValue]) {
//        iv = [self createButton:Localized(@"JX_Don'tLookCircleVideo") drawTop:NO drawBottom:YES must:NO click:nil superView:_baseView];
//        iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
//        h+=iv.frame.size.height;
//        
//        
//        UISwitch *see = [[UISwitch alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH -70, 10, 0, 0)];
//        [see addTarget:self action:@selector(notLookHisCircleAndVideo:) forControlEvents:UIControlEventValueChanged];
//        see.on = [g_server.myself.filterCircleUserIds containsObject:[NSNumber numberWithInt:[self.userId intValue]]];
//        [iv addSubview:see];
    }

#pragma mark 消息免打扰
    //        if (_friendStatus == friend_status_friend && ![user.isBeenBlack boolValue]) {
    
    //            iv = [self createButton:Localized(@"JX_MessageFree") drawTop:NO drawBottom:YES must:NO click:@selector(switchAction:)];
    //            iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
    //            h+=iv.frame.size.height;
    //        }
    //@"18938880001"
    if ([g_myself.telephone isEqualToString:@"18938880001"]) {
        
        iv = [self createButton:Localized(@"JX_MobilePhoneNo.") drawTop:NO drawBottom:YES must:NO click:@selector(callNumber) superView:_baseView];
        iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
        
        UILongPressGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longTapAction:)];
        [iv addGestureRecognizer:longTap];
        
        _tel = [[UILabel alloc] initWithFrame:CGRectMake(0,INSETS,JX_SCREEN_WIDTH - INSETS - 20 - 5,HEIGHT-INSETS*2)];
        _tel.userInteractionEnabled = NO;
        _tel.text = s;
        _tel.font = g_factory.font16;
        _tel.textAlignment = NSTextAlignmentRight;
        [iv addSubview:_tel];
        
        NSString *subString = [user.telephone substringToIndex:2];
        if ([subString isEqualToString:@"86"]) {
            NSDate *date = [g_myself.phoneDic objectForKey:[user.telephone substringFromIndex:2]];
            if (date) {
                long long n = (long long)[date timeIntervalSince1970];
                NSString *time = [TimeUtil getTimeStrStyle1:n];
                NSString *str = [NSString stringWithFormat:@"%@,%@:%@",[user.telephone substringFromIndex:2],Localized(@"JX_HaveToDial"),time];
                _tel.text = str;
            }else {
                _tel.text = [user.telephone substringFromIndex:2];
            }
            
        }else {
            _tel.text = user.telephone;
        }
        h+=iv.frame.size.height;
    }
    
    h+=INSETS;
    
    if (!self.isJustShow) {
        
        if([self.userId intValue] != [MY_USER_ID intValue]){
            _btn = [UIFactory createCommonButton:Localized(@"JX_AddFriend") target:self action:@selector(actionAddFriend:)];
            _btn.frame = CGRectMake(INSETS, h, WIDTH, HEIGHT);
            [_baseView addSubview:_btn];
            [self showAddFriend];
            h+=_btn.frame.size.height;
            h+=INSETS;
        }
        
        //如果是自己，则不现实按钮
        // 自己/公众号/厂家不删除
        if (![self.userId isEqualToString:MY_USER_ID] && ![self.userId isEqualToString:CALL_CENTER_USERID] && ![self.userId isEqualToString:@"10004476"]) {
            UIButton *btn = [UIFactory createButtonWithImage:THESIMPLESTYLE ? @"title_more_black" : @"title_more" highlight:nil target:self selector:@selector(onMore)];
            btn.frame = CGRectMake(JX_SCREEN_WIDTH-24-8, JX_SCREEN_TOP - 34, 24, 24);
            [self.tableHeader addSubview:btn];
        }
        
    }
    CGRect frame = _baseView.frame;
    frame.size.height = h;
    _baseView.frame = frame;
    
    if (self.tableBody.frame.size.height < CGRectGetMaxY(_baseView.frame)+30) {
        self.tableBody.contentSize = CGSizeMake(JX_SCREEN_WIDTH, CGRectGetMaxY(_baseView.frame)+30);
    }
    
//    JXUserObject *user = [[JXUserObject sharedInstance] getUserById:_userId];
//    [self setUserInfo:user];
}

- (void)notLookHisCircleAndVideo:(UISwitch *)switchButton {
    NSMutableArray *mutArr = g_server.myself.filterCircleUserIds.mutableCopy;
    BOOL haveTheUserId = [g_server.myself.filterCircleUserIds containsObject:[NSNumber numberWithInt:[self.userId intValue]]];
    if (haveTheUserId && !switchButton.isOn) {
        [mutArr removeObject:[NSNumber numberWithInt:[self.userId intValue]]];
    }else if (!haveTheUserId && switchButton.isOn){
        [mutArr addObject:[NSNumber numberWithInt:[self.userId intValue]]];
    }
    g_server.myself.filterCircleUserIds = mutArr;
    // 不看他(她)生活圈和视频
    [g_server filterUserCircle:self.user.userId type:switchButton.isOn ? @1 : @-1 toView:self];
}

- (void)newRequest:(NSNotification *)notif {
    [g_server getUser:self.userId toView:self];
}

- (void) setUserInfo:(JXUserObject *)user {
    if (self.user.content) {
        user.content = self.user.content;
    }
    self.user = user;
    
    // 更新用户信息
    [user updateUserNickname];
    
    _friendStatus = [user.status intValue];
    _latitude  = [user.latitude doubleValue];
    _longitude = [user.longitude doubleValue];
    
    // 设置用户名字、备注、通讯号、地区等...
    [self setLabelAndDescribe];
    
    if ([user.showLastLoginTime intValue] > 0 && [user.userType intValue] != 2) {
        _lastTime.text = [self dateTimeDifferenceWithStartTime:user.showLastLoginTime];
        _lastTImgV.hidden = NO;
    }else {
        _lastTImgV.hidden = YES;
        
    }
    if (user.telephone.length > 0 && [user.userType intValue] != 2) {
        _showNum.text = user.phone;
        _showNImgV.hidden = NO;
    }else {
        _showNImgV.hidden = YES;
    }

    if (self.tableBody.frame.size.height < CGRectGetMaxY(_baseView.frame)+30) {
        self.tableBody.contentSize = CGSizeMake(JX_SCREEN_WIDTH, CGRectGetMaxY(_baseView.frame)+30);
    }

    _date.text = [TimeUtil formatDate:user.birthday format:@"yyyy-MM-dd"];
    
    
    if ([user.offlineNoPushMsg intValue] == 1) {
        [_messageFreeSwitch setOn:YES];
    }else {
        [_messageFreeSwitch setOn:NO];
    }
    
    if (_tel) {
        NSString *subString = [user.telephone substringToIndex:2];
        if ([subString isEqualToString:@"86"]) {
            NSDate *date = [g_myself.phoneDic objectForKey:[user.telephone substringFromIndex:2]];
            if (date) {
                long long n = (long long)[date timeIntervalSince1970];
                NSString *time = [TimeUtil getTimeStrStyle1:n];
                NSString *str = [NSString stringWithFormat:@"%@,%@:%@",[user.telephone substringFromIndex:2],Localized(@"JX_HaveToDial"),time];
                _tel.text = str;
            }else {
                _tel.text = [user.telephone substringFromIndex:2];
            }
            
        }else {
            _tel.text = user.telephone;
        }
    }
    
    [self showAddFriend];
}

- (void)setLabelAndDescribe {
    NSString* city = [g_constant getAddressForNumber:user.provinceId cityId:user.cityId areaId:user.areaId];

    _remarkName.text = user.remarkName.length > 0 ? user.remarkName : user.userNickname;
    CGSize sizeN = [_remarkName.text sizeWithAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:16]}];
    _remarkName.frame = CGRectMake(CGRectGetMaxX(_head.frame)+INSETS*2, INSETS*2, sizeN.width, 20);
    
    _sex.frame = CGRectMake(CGRectGetMaxX(_remarkName.frame)+3, INSETS*2+3, 14, 14);
    if ([user.sex intValue] == 0) {// 女
        _sex.image = [UIImage imageNamed:@"basic_famale"];
    }else {// 男
        _sex.image = [UIImage imageNamed:@"basic_male"];
    }
    
    if (user.remarkName.length > 0) {
        _name.hidden = NO;
        _name.frame = CGRectMake(CGRectGetMinX(_remarkName.frame), CGRectGetMaxY(_remarkName.frame)+3, 200, 20);
        _account.frame = CGRectMake(CGRectGetMinX(_remarkName.frame), CGRectGetMaxY(_name.frame)+3, 200, 20);
        
        _name.text = [NSString stringWithFormat:@"%@ : %@",Localized(@"JX_NickName"),user.userNickname];
    }else {
        _name.hidden = YES;
        _account.frame = CGRectMake(CGRectGetMinX(_remarkName.frame), CGRectGetMaxY(_remarkName.frame)+3, 200, 20);
    }
    if (user.account.length > 0) {
        _account.hidden = NO;
        _city.frame = CGRectMake(CGRectGetMinX(_remarkName.frame), CGRectGetMaxY(_account.frame)+3, 200, 20);
        _account.text = [NSString stringWithFormat:@"%@ : %@",Localized(@"JX_Communication"),user.account.length > 0 ? user.account : @"--"];
    }else {
        _account.hidden = YES;
        _city.frame = CGRectMake(CGRectGetMinX(_remarkName.frame), user.remarkName.length > 0 ? CGRectGetMaxY(_name.frame)+3 :CGRectGetMaxY(_remarkName.frame)+3, 200, 20);
    }
    
    _city.text = [NSString stringWithFormat:@"%@ : %@",@"地区",city.length > 0 ? city : @"--"];

    
    _describe.text = self.user.describe;
    
    // 标签
    NSMutableArray *array = [[JXLabelObject sharedInstance] fetchLabelsWithUserId:self.user.userId];
    NSMutableString *labelsName = [NSMutableString string];
    for (NSInteger i = 0; i < array.count; i ++) {
        JXLabelObject *labelObj = array[i];
        if (i == 0) {
            [labelsName appendString:labelObj.groupName];
        }else {
            [labelsName appendFormat:@",%@",labelObj.groupName];
        }
    }
    if (labelsName.length > 0 && self.user.describe.length <= 0) {
        _labelLab.text = Localized(@"JX_Label");
        _label.text = labelsName;
        [self updateSubviewFrameIsHide:YES];
        _describeImgV.hidden = YES;
    }
    else if (labelsName.length > 0 && self.user.describe.length > 0) {
        _labelLab.text = Localized(@"JX_Label");
        _label.text = labelsName;
        [self updateSubviewFrameIsHide:NO];
        _describeImgV.hidden = NO;
    }
    else if (self.user.describe.length > 0 && labelsName.length <= 0) {
        _labelLab.text = Localized(@"JX_UserInfoDescribe");
        _label.text = self.user.describe;
        [self updateSubviewFrameIsHide:YES];
        _describeImgV.hidden = YES;
    }
    else {
        _labelLab.text = Localized(@"JX_SetNotesAndLabels");
        _label.text = @"";
        [self updateSubviewFrameIsHide:YES];
        _describeImgV.hidden = YES;
    }

}


- (void)updateSubviewFrameIsHide:(BOOL)isHide {
    
    int y = 0;
    if ([self.userId intValue] == [MY_USER_ID intValue]) {
        y = 233 - 100- INSETS;
    }else {
        if(isHide) {
            y = 233-50;
        }else {
            y = 233;
        }

    }
    _lifeImgV.frame = CGRectMake(0, y, JX_SCREEN_WIDTH, 50);
    
    y += 50;
    _birthdayImgV.frame = CGRectMake(0, y, JX_SCREEN_WIDTH, 50);
    if ([user.showLastLoginTime intValue] > 0 && [user.userType intValue] != 2){
        y += 50;
        _lastTImgV.frame = CGRectMake(0, y, JX_SCREEN_WIDTH, 50);
    }
    if (user.telephone.length > 0 && [user.userType intValue] != 2 && [g_config.regeditPhoneOrName intValue] == 0) {
        y += 50;
        _showNImgV.frame = CGRectMake(0, y, JX_SCREEN_WIDTH, 50);
    }
    y += 50;
    _baseView.frame = CGRectMake(0, y+INSETS, JX_SCREEN_WIDTH, _baseView.frame.size.height);

}


- (void)friendPassNotif:(NSNotification *)notif {
    JXFriendObject *user = notif.object;
    if ([user.userId isEqualToString:self.userId]) {
        _friendStatus = friend_status_friend;
        [self showAddFriend];
    }
}

- (void)callNumber {
    NSMutableString* str;
    NSString *subString = [user.telephone substringToIndex:2];
    if ([subString isEqualToString:@"86"]) {
        str = [[NSMutableString alloc]initWithFormat:@"telprompt://%@",[user.telephone substringFromIndex:2]];
        [g_myself insertPhone:[user.telephone substringFromIndex:2] time:[NSDate date]];
        [g_myself.phoneDic setObject:[NSDate date] forKey:[user.telephone substringFromIndex:2]];
        
        NSDate *date = [g_myself.phoneDic objectForKey:[user.telephone substringFromIndex:2]];
        if (date) {
            long long n = (long long)[date timeIntervalSince1970];
            NSString *time = [TimeUtil getTimeStrStyle1:n];
            NSString *str = [NSString stringWithFormat:@"%@,%@:%@",[user.telephone substringFromIndex:2],Localized(@"JX_HaveToDial"),time];
            _tel.text = str;
        }else {
            _tel.text = [user.telephone substringFromIndex:2];
        }
        
    }else {
        str = [[NSMutableString alloc]initWithFormat:@"telprompt://%@",user.telephone];
        [g_myself insertPhone:user.telephone time:[NSDate date]];
        [g_myself.phoneDic setObject:[NSDate date] forKey:user.telephone];
        
        _tel.text = user.telephone;
    }
    
    [g_notify postNotificationName:kNearRefreshCallPhone object:nil];
    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:str]];
}

- (void) longTapAction:(UILongPressGestureRecognizer *)longTap {
    if(longTap.state == UIGestureRecognizerStateBegan)
    {
        NSString *subString = [user.telephone substringToIndex:2];
        if ([subString isEqualToString:@"86"]) {
            [g_myself deletePhone:[user.telephone substringFromIndex:2]];
            [g_myself.phoneDic removeObjectForKey:[user.telephone substringFromIndex:2]];

            _tel.text = [user.telephone substringFromIndex:2];
            
        }else {
            [g_myself deletePhone:user.telephone];
            [g_myself.phoneDic removeObjectForKey:user.telephone];
            
            _tel.text = user.telephone;
        }
        
        [g_notify postNotificationName:kNearRefreshCallPhone object:nil];
    }
}

-(void)switchAction:(UISwitch *) sender{

    if (_friendStatus == friend_status_friend && ![user.isBeenBlack boolValue]) {
        
        int offlineNoPushMsg = sender.isOn;
        [g_server friendsUpdateOfflineNoPushMsgUserId:g_myself.userId toUserId:user.userId offlineNoPushMsg:offlineNoPushMsg type:0 toView:self];
    }else {
        [sender setOn:!sender.isOn];
        [g_App showAlert:Localized(@"JX_PleaseAddAsFriendFirst")];
    }
    
}

-(void)onHeadImage{
    [g_server delHeadImage:self.user.userId];
    
    JXImageScrollVC * imageVC = [[JXImageScrollVC alloc]init];
    
    imageVC.imageSize = CGSizeMake(JX_SCREEN_WIDTH, JX_SCREEN_WIDTH);
    
    imageVC.iv = [[JXImageView alloc] initWithFrame:CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_WIDTH)];
    
    imageVC.iv.center = imageVC.view.center;
    
    [g_server getHeadImageLarge:self.user.userId userName:self.user.userNickname imageView:imageVC.iv];
    
    [self addTransition:imageVC];

    [self presentViewController:imageVC animated:YES completion:^{
        
    }];
    
}

//添加VC转场动画
- (void) addTransition:(JXImageScrollVC *) siv
{
    _scaleTransition = [[DMScaleTransition alloc]init];
    [siv setTransitioningDelegate:_scaleTransition];
    
}

-(void)dealloc{
    NSLog(@"JXUserInfoVC.dealloc");
    [g_notify  removeObserver:self name:kXMPPSendTimeOutNotifaction object:nil];
    [g_notify  removeObserver:self name:kXMPPReceiptNotifaction object:nil];
    [g_notify removeObserver:self];
    self.user = nil;
//    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
    if([aDownload.action isEqualToString:act_AttentionAdd]){//加好友
        int n = [[dict objectForKey:@"type"] intValue];
        if( n==2 || n==4)
            _friendStatus = friend_status_friend;//成为好友，一般是无需验证
//        else
//            _friendStatus = friend_status_see;//单向关注

        if(_friendStatus == friend_status_friend){
            [_wait stop];
            [self doMakeFriend];
        }
        else
            [self doSayHello];
    }
    if ([aDownload.action isEqualToString:act_FriendDel]) {//删除好友
        [self.user doSendMsg:XMPP_TYPE_DELALL content:nil];
    }
    if([aDownload.action isEqualToString:act_BlacklistAdd]){//拉黑
        [self.user doSendMsg:XMPP_TYPE_BLACK content:nil];
    }

    if([aDownload.action isEqualToString:act_FriendRemark]){
        [_wait stop];
        JXUserObject* user1 = [[JXUserObject sharedInstance] getUserById:user.userId];
        user1.userNickname = user.remarkName;
        user1.remarkName = user.remarkName;
        user1.describe = user.describe;
        // 修改备注后实时刷新
        [user update];
        [g_notify postNotificationName:kFriendRemark object:user1];
        [g_App showAlert:Localized(@"JXAlert_SetOK")];
    }
    
    if([aDownload.action isEqualToString:act_BlacklistDel]){
        [self.user doSendMsg:XMPP_TYPE_NOBLACK content:nil];
    }
    
    if([aDownload.action isEqualToString:act_AttentionDel]){
        [user doSendMsg:XMPP_TYPE_DELSEE content:nil];
    }
    
    if([aDownload.action isEqualToString:act_Report]){
        [_wait stop];
        [g_App showAlert:Localized(@"JXUserInfoVC_ReportSuccess")];
    }
    
    if([aDownload.action isEqualToString:act_friendsUpdateOfflineNoPushMsg]){
        [_wait stop];
        [g_App showAlert:Localized(@"JXAlert_SetOK")];
    }
    if([aDownload.action isEqualToString:act_filterUserCircle]){
        [_wait stop];
    }
    if( [aDownload.action isEqualToString:act_UserGet] ){
        JXUserObject* user = [[JXUserObject alloc]init];
        [user getDataFromDict:dict];
        [user insertFriend];
        [self setUserInfo:user];
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
    if( [aDownload.action isEqualToString:act_UserGet] ){
        [_wait stop];
        return;
    }
    [_wait start];
}

-(JXImageView*)createButton:(NSString*)title drawTop:(BOOL)drawTop drawBottom:(BOOL)drawBottom must:(BOOL)must click:(SEL)click superView:(UIView *)superView{
    JXImageView* btn = [[JXImageView alloc] init];
    btn.backgroundColor = [UIColor whiteColor];
    btn.userInteractionEnabled = YES;
    btn.didTouch = click;
    btn.delegate = self;
    [superView addSubview:btn];
//    [btn release];
    
    if(must){
        UILabel* p = [[UILabel alloc] initWithFrame:CGRectMake(INSETS, 5, 20, HEIGHT-5)];
        p.text = @"*";
        p.font = g_factory.font18;
        p.backgroundColor = [UIColor clearColor];
        p.textColor = [UIColor redColor];
        p.textAlignment = NSTextAlignmentCenter;
        [btn addSubview:p];
//        [p release];
    }
    
    JXLabel* p = [[JXLabel alloc] initWithFrame:CGRectMake(20, 0, 200, HEIGHT)];
    p.text = title;
    p.font = g_factory.font15;
    p.backgroundColor = [UIColor clearColor];
    p.textColor = [UIColor blackColor];
    [btn addSubview:p];
    if (@selector(onRemark) == click) {
        _labelLab = p;
    }
    if(drawTop){
        UIView* line = [[UIView alloc] initWithFrame:CGRectMake(0,0,JX_SCREEN_WIDTH,0.3)];
        line.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1];
        [btn addSubview:line];
    }
    
    if(drawBottom){
        UIView* line = [[UIView alloc]initWithFrame:CGRectMake(0,HEIGHT-0.5,JX_SCREEN_WIDTH,0.3)];
        line.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1];
        [btn addSubview:line];
    }
    
    //这个选择器仅用于判断，之后会修改为不可点击
    SEL check = @selector(switchAction:);
    //创建switch
    if(click == check){
        UISwitch * switchView = [[UISwitch alloc]initWithFrame:CGRectMake(JX_SCREEN_WIDTH-INSETS-51, 6, 20, 20)];
        if ([title isEqualToString:Localized(@"JX_MessageFree")]) {
            _messageFreeSwitch = switchView;
            if ([user.offlineNoPushMsg intValue] == 1) {
                [_messageFreeSwitch setOn:YES];
            }else {
                [_messageFreeSwitch setOn:NO];
            }
        }
        
        switchView.onTintColor = THEMECOLOR;
        
        [switchView addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventTouchUpInside];
        
        [btn addSubview:switchView];
        //取消调用switchAction
        btn.didTouch = @selector(hideKeyboard);
        
    }else if(click){
        btn.frame = CGRectMake(btn.frame.origin.x -20, btn.frame.origin.y, btn.frame.size.width, btn.frame.size.height);
        
        UIImageView* iv;
        iv = [[UIImageView alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH-INSETS-20-3, 15, 20, 20)];
        iv.image = [UIImage imageNamed:@"set_list_next"];
        [btn addSubview:iv];
        //        [iv release];
    }
    return btn;
}

-(UITextField*)createTextField:(UIView*)parent default:(NSString*)s hint:(NSString*)hint{
    UITextField* p = [[UITextField alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH/2,INSETS,JX_SCREEN_WIDTH/2,HEIGHT-INSETS*2)];
    p.delegate = self;
    p.autocorrectionType = UITextAutocorrectionTypeNo;
    p.autocapitalizationType = UITextAutocapitalizationTypeNone;
    p.enablesReturnKeyAutomatically = YES;
    p.borderStyle = UITextBorderStyleNone;
    p.returnKeyType = UIReturnKeyDone;
    p.clearButtonMode = UITextFieldViewModeAlways;
    p.textAlignment = NSTextAlignmentRight;
    p.userInteractionEnabled = YES;
    p.text = s;
    p.placeholder = hint;
    p.font = g_factory.font14;
    [parent addSubview:p];
//    [p release];
    return p;
}

-(UILabel*)createLabel:(UIView*)parent default:(NSString*)s{
    UILabel* p = [[UILabel alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH/2,INSETS,JX_SCREEN_WIDTH/2 - INSETS - 20 - 5,HEIGHT-INSETS*2)];
    p.userInteractionEnabled = NO;
    p.text = s;
    p.font = g_factory.font15;
    p.textAlignment = NSTextAlignmentRight;
    [parent addSubview:p];
//    [p release];
    return p;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.view endEditing:YES];
    return YES;
}

-(void)actionAddFriend:(UIView*)sender{
    
    // 验证XMPP是否在线
    if(g_xmpp.isLogined != 1){
        [g_xmpp showXmppOfflineAlert];
        return;
    }
    
    if([user.isBeenBlack boolValue]){
        [g_App showAlert:Localized(@"TO_BLACKLIST")];
        return;
    }
    switch (_friendStatus) {
        case friend_status_black:{
            //            [g_server addAttention:user.userId  toView:self];
            [self onDelBlack];
//            [self viewDisMissAction];
            
        }
            break;
        case friend_status_none:
        case friend_status_see:
            [g_server addAttention:user.userId fromAddType:self.fromAddType toView:self];
            break;
//        case friend_status_see:
//            [self doSayHello];
//            break;
        case friend_status_friend:{//发消息
            if([user haveTheUser])
                [user insert];
            else
                [user update];
            
            [self actionQuit];
            [g_notify postNotificationName:kActionRelayQuitVC object:nil];
            
            JXChatViewController *chatVC=[JXChatViewController alloc];
            chatVC.title = user.userNickname;
            chatVC.chatPerson = self.user;
            chatVC = [chatVC init];
//            [g_App.window addSubview:chatVC.view];
            [g_navigation pushViewController:chatVC animated:YES];
        }
            break;
    }
}

-(void)doSayHello{//打招呼
    _xmppMsgId = [self.user doSendMsg:XMPP_TYPE_SAYHELLO content:Localized(@"JXUserInfoVC_Hello")];
}

-(void)onSendTimeout:(NSNotification *)notifacation//超时未收到回执
{
//    NSLog(@"onSendTimeout");
    [_wait stop];
//    [g_App showAlert:Localized(@"JXAlert_SendFilad")];
    [JXMyTools showTipView:Localized(@"JXAlert_SendFilad")];
}

-(void)newReceipt:(NSNotification *)notifacation{//新回执
//    NSLog(@"newReceipt");
    JXMessageObject *msg     = (JXMessageObject *)notifacation.object;
    if(msg == nil)
        return;
    if(![msg isAddFriendMsg])
        return;
    if(![msg.toUserId isEqualToString:self.user.userId])
        return;
    [_wait stop];
    if([msg.type intValue] == XMPP_TYPE_SAYHELLO){//打招呼
        [g_App showAlert:Localized(@"JXAlert_SayHiOK")];
    }
    
    if([msg.type intValue] == XMPP_TYPE_BLACK){//拉黑
        user.status = [NSNumber numberWithInt:friend_status_black];
        _friendStatus = [user.status intValue];
        [[JXXMPP sharedInstance].blackList addObject:user.userId];
        [user update];
        [self showAddFriend];
        [g_App showAlert:Localized(@"JXAlert_AddBlackList")];
        
        [g_notify postNotificationName:kXMPPNewFriendNotifaction object:nil];
//        [JXMessageObject msgWithFriendStatus:user.userId status:_friendStatus];
//        [user notifyDelFriend];
    }
    
    if([msg.type intValue] == XMPP_TYPE_DELSEE){//删除关注，弃用
        _friendStatus = friend_status_none;
        [self showAddFriend];
        [JXMessageObject msgWithFriendStatus:user.userId status:_friendStatus];
        [g_App showAlert:Localized(@"JXAlert_CencalFollow")];
    }
    
    if([msg.type intValue] == XMPP_TYPE_DELALL){//删除好友
        _friendStatus = friend_status_none;
        [self showAddFriend];
        
        [g_notify postNotificationName:kXMPPNewFriendNotifaction object:nil];
        [g_App showAlert:Localized(@"JXAlert_DeleteFirend")];
    }
    
    if([msg.type intValue] == XMPP_TYPE_NOBLACK){//取消拉黑
        user.status = [NSNumber numberWithInt:friend_status_friend];
        [user updateStatus];
        
        _friendStatus = friend_status_friend;
        [self showAddFriend];
        if ([[JXXMPP sharedInstance].blackList containsObject:user.userId]) {
            [[JXXMPP sharedInstance].blackList removeObject:user.userId];
            [JXMessageObject msgWithFriendStatus:user.userId status:friend_status_friend];
        }
        [g_App showAlert:Localized(@"JXAlert_MoveBlackList")];
        
        [g_notify postNotificationName:kXMPPNewFriendNotifaction object:nil];
    }
    if([msg.type intValue] == XMPP_TYPE_FRIEND){//无验证加好友
        if (![g_myself.telephone isEqualToString:@"18938880001"]) {
            [g_App showAlert:Localized(@"JX_AddSuccess")];
        }
        user.status = [NSNumber numberWithInt:2];
        [g_notify postNotificationName:kXMPPNewFriendNotifaction object:nil];
    }
}

-(void)showAddFriend{
//    _btn.hidden = NO;
    switch (_friendStatus) {
        case friend_status_hisBlack:
            break;
        case friend_status_black://黑名单则不显示
            [_btn setTitle:Localized(@"JXUserInfoVC_CancelBlackList") forState:UIControlStateNormal];
            break;
        case friend_status_none:
        case friend_status_see:
            if([user.isBeenBlack boolValue])
                [_btn setTitle:Localized(@"TO_BLACKLIST") forState:UIControlStateNormal];
            else
                [_btn setTitle:Localized(@"JX_AddFriend") forState:UIControlStateNormal];
            break;
        case friend_status_friend:
            if([user.isBeenBlack boolValue])
                [_btn setTitle:Localized(@"TO_BLACKLIST") forState:UIControlStateNormal];
            else
                [_btn setTitle:Localized(@"JXUserInfoVC_SendMseeage") forState:UIControlStateNormal];
            break;
    }
}

-(void)onMyBlog{
    userWeiboVC* vc = [userWeiboVC alloc];
    vc.user = user;
    vc.isGotoBack = YES;
    vc = [vc init];
//    [g_window addSubview:vc.view];
    [g_navigation pushViewController:vc animated:YES];
    
}

-(void)actionMap{
    
    
    if (_longitude <=0 && _latitude <= 0) {
        [g_App showAlert:Localized(@"JX_NotShareLocation")];
        return;
    }
    
    JXMapData * mapData = [[JXMapData alloc] init];
    mapData.latitude = [NSString stringWithFormat:@"%f",_latitude];
    mapData.longitude = [NSString stringWithFormat:@"%f",_longitude];
    NSArray * locations = @[mapData];
    if (g_config.isChina) {
        JXLocationVC * vc = [JXLocationVC alloc];
        vc.locations = [NSMutableArray arrayWithArray:locations];
        vc.locationType = JXLocationTypeShowStaticLocation;
        vc = [vc init];
        [g_navigation pushViewController:vc animated:YES];
    }else {
        _gooMap = [JXGoogleMapVC alloc];
        _gooMap.locations = [NSMutableArray arrayWithArray:locations];
        _gooMap.locationType = JXGooLocationTypeShowStaticLocation;
        _gooMap = [_gooMap init];
        [g_navigation pushViewController:_gooMap animated:YES];
    }
    
//    JXLocationVC* vc = [JXLocationVC alloc];
//    vc.isSend = NO;
//    vc.locationType = JXLocationTypeShowStaticLocation;
//    NSMutableArray * locationsArray = [[NSMutableArray alloc]init];
//
//    JXMapData* p = [[JXMapData alloc]init];
//    p.latitude = [NSString stringWithFormat:@"%f",_latitude];
//    p.longitude = [NSString stringWithFormat:@"%f",_longitude];
//    p.title = _name.text;
//    p.subtitle = _city.text;
//    [locationsArray addObject:p];
//    vc.locations = locationsArray;
//
//    vc = [vc init];
////    [g_window addSubview:vc.view];
//    [g_navigation pushViewController:vc animated:YES];

}
-(void)reportUserView{
    JXReportUserVC * reportVC = [[JXReportUserVC alloc] init];
    reportVC.user = user;
    reportVC.delegate = self;
//    [g_window addSubview:reportVC.view];
    [g_navigation pushViewController:reportVC animated:YES];
    
}

- (void)report:(JXUserObject *)reportUser reasonId:(NSNumber *)reasonId {
    [g_server reportUser:reportUser.userId roomId:nil webUrl:nil reasonId:reasonId toView:self];
}

- (void)onMore{
    int n = _friendStatus;
    //标题数组
    [_titleArr removeAllObjects];
    [_titleArr addObject:Localized(@"JXUserInfoVC_Report")];
    [_titleArr addObject:Localized(@"JX_SetNotesAndDescriptions")];
    if(n == friend_status_friend){
        if(n == friend_status_black)
            [_titleArr addObject:Localized(@"JXUserInfoVC_CancelBlackList")];
        else
            if(![user.isBeenBlack boolValue]) {
                [_titleArr addObject:Localized(@"JXUserInfoVC_AddBlackList")];
            }
        if(![user.isBeenBlack boolValue]){
            if(n == friend_status_friend)
                [_titleArr addObject:Localized(@"JXUserInfoVC_DeleteFirend")];
            else
                [_titleArr addObject:Localized(@"JX_AddFriend")];
        }
    }
    
//    //模糊背景
//    _bgBlackAlpha = [[UIView alloc]initWithFrame:CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT)];
//    _bgBlackAlpha.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.1];
//    [self.view addSubview:_bgBlackAlpha];
////    [_bgBlackAlpha release];
    
    //自定义View
    _selectView = [[JX_SelectMenuView alloc] initWithTitle:_titleArr image:@[] cellHeight:CellHeight];
    _selectView.alpha = 0.0;
    _selectView.delegate = self;
    [self.view addSubview:_selectView];
//    [_selectView release];
    //动画
    [UIView animateWithDuration:0.3 animations:^{
        _selectView.alpha = 1;
    }];
}

- (void)didMenuView:(JX_SelectMenuView *)MenuView WithIndex:(NSInteger)index {
    long n = _friendStatus;//好友状态
//    if(n>[_titleArr count]-1)
//        return;
    switch (index) {
        case 0:
            [self reportUserView];
            [self viewDisMissAction];
            break;
        case 1:
            [self onRemark];
            [self viewDisMissAction];
            break;
        case 2:
            if(n == friend_status_black){
                [self onDelBlack];
                [self viewDisMissAction];
            }else{
                [self onAddBlack];
                [self viewDisMissAction];
            }
            break;
        case 3:
            if(n == friend_status_see || n == friend_status_friend){
                //                [self onCancelSee];
                //                [self viewDisMissAction];
                [self onDeleteFriend];
                [self viewDisMissAction];
            }else{
                [self actionAddFriend:nil];
                [self viewDisMissAction];
            }
            
            break;
            
        default:
            [self viewDisMissAction];
            break;
    }

}

//- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    UITouch * touch = touches.anyObject;
//    if (_selectView == nil) {
//        return;
//    }
//    CGPoint location = [touch locationInView:_selectView];
//    //不在选择范围内
//    if (location.x < 0 || location.x > _selectView.frame.size.width || location.y < 0 || location.y > _selectView.frame.size.height) {
//        [self viewDisMissAction];
//        return;
//    }
//    int num = (location.y - TopHeight)/CellHeight;
//    long n = _friendStatus;//好友状态
//    if(n>[_titleArr count]-1)
//        return;
//    switch (num) {
//        case 0:
//            [self reportUserView];
//            [self viewDisMissAction];
//            break;
//        case 1:
//            [self onRemark];
//            [self viewDisMissAction];
//            break;
//        case 2:
//            if(n == friend_status_black){
//                [self onDelBlack];
//                [self viewDisMissAction];
//            }else{
//                [self onAddBlack];
//                [self viewDisMissAction];
//            }
//            break;
//        case 3:
//            if(n == friend_status_see || n == friend_status_friend){
////                [self onCancelSee];
////                [self viewDisMissAction];
//                [self onDeleteFriend];
//                [self viewDisMissAction];
//            }else{
//                [self actionAddFriend:nil];
//                [self viewDisMissAction];
//            }
//
//            break;
//            
//        default:
//            [self viewDisMissAction];
//            break;
//    }
//}

- (void)viewDisMissAction{
    [UIView animateWithDuration:0.4 animations:^{
        _bgBlackAlpha.alpha = 0.0;
    } completion:^(BOOL finished) {
        [_selectView removeFromSuperview];
        _selectView = nil;
        [_bgBlackAlpha removeFromSuperview];
    }];
}

#pragma mark ---------------创建设置好友备注页面----------------
-(void)onRemark{
//    JXInputValueVC* vc = [JXInputValueVC alloc];
//    vc.value = user.remarkName;
//    vc.title = Localized(@"JXUserInfoVC_SetName");
//    vc.delegate  = self;
//    vc.isLimit = YES;
//    vc.didSelect = @selector(onSaveNickName:);
//    vc = [vc init];
////    [g_window addSubview:vc.view];
//    [g_navigation pushViewController:vc animated:YES];
    
    JXSetNoteAndLabelVC *vc = [[JXSetNoteAndLabelVC alloc] init];
    vc.title = @"设置备注和标签";
    vc.delegate = self;
    vc.didSelect = @selector(refreshLabel:);
    vc.user = self.user;
    [g_navigation pushViewController:vc animated:YES];
}


- (void)refreshLabel:(JXUserObject *)user {

    self.user.remarkName = user.remarkName;
    self.user.describe = user.describe;
    
//    CGSize sizeN = [user.remarkName sizeWithAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:16]}];
//    _remarkName.frame = CGRectMake(_remarkName.frame.origin.x, _remarkName.frame.origin.y, sizeN.width, _remarkName.frame.size.height);
//    _sex.frame = CGRectMake(CGRectGetMaxX(_remarkName.frame)+3, _sex.frame.origin.y, _sex.frame.size.width, _sex.frame.size.height);
//
//    _remarkName.text = user.remarkName.length > 0 ? user.remarkName : user.userNickname;

    [self setLabelAndDescribe];
    
    [g_server setFriendName:self.user.userId noteName:user.remarkName describe:user.describe toView:self];
}


-(void)onSaveNickName:(JXInputValueVC*)vc{
    _remarkName.text = vc.value;
    user.remarkName = vc.value;
    [g_server setFriendName:user.userId noteName:vc.value describe:nil toView:self];
}

-(void)onAddBlack{
    [g_server addBlacklist:user.userId toView:self];
}

-(void)onDelBlack{
    [g_server delBlacklist:user.userId toView:self];
}

-(void)onCancelSee{
    [g_server delAttention:user.userId toView:self];
}

-(void)onDeleteFriend{
//    [g_server delAttention:user.userId toView:self];
    [g_server delFriend:user.userId toView:self];
}

-(void)doMakeFriend{
    _friendStatus = friend_status_friend;
//    user.status = [NSNumber numberWithInt:_friendStatus];
//    if([user haveTheUser])
//        [user update];
//    else
//        [user insert];
    [self.user doSendMsg:XMPP_TYPE_FRIEND content:nil];
    [JXMessageObject msgWithFriendStatus:user.userId status:_friendStatus];
    [self showAddFriend];
}

-(void)showUserQRCode{
    JXQRCodeViewController * qrVC = [[JXQRCodeViewController alloc] init];
    qrVC.type = QRUserType;
    qrVC.userId = user.userId;
    qrVC.account = user.account;
    qrVC.nickName = user.userNickname;
//    [g_window addSubview:qrVC.view];
    [g_navigation pushViewController:qrVC animated:YES];
}

- (NSString *)dateTimeDifferenceWithStartTime:(NSNumber *)compareDate {
    NSInteger timeInterval = [[NSDate date] timeIntervalSince1970] - [compareDate integerValue];
    long temp = 0;
    NSString *result;
    if (timeInterval < 60) {
        result = [NSString stringWithFormat:@"%d%@",(int)timeInterval,Localized(@"SECONDS_AGO")];
    }
    else if((temp = timeInterval/60) <60){
        result = [NSString stringWithFormat:@"%ld%@",temp,Localized(@"MINUTES_AGO")];
    }
    
    else if((temp = temp/60) <24){
        result = [NSString stringWithFormat:@"%ld%@",temp,Localized(@"JX_HoursAgo")];
    }
    
    else if((temp = temp/24) <30){
        result = [NSString stringWithFormat:@"%ld%@",temp,Localized(@"JX_DaysAgo")];
    }
    
    else if((temp = temp/30) <12){
        result = [NSString stringWithFormat:@"%ld%@",temp,Localized(@"JX_MonthAgo")];
    }
    else{
        temp = temp/12;
        result = [NSString stringWithFormat:@"%ld%@",temp,Localized(@"JX_YearsAgo")];
    }
    
    return  result;
}


@end
