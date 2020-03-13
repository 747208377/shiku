//
//  JXSquareViewController.m
//  shiku_im
//
//  Created by 1 on 2018/11/7.
//  Copyright © 2018年 Reese. All rights reserved.
//



#import "JXSquareViewController.h"
#import "WeiboViewControlle.h"
#import "JXActionSheetVC.h"
#ifdef Meeting_Version
#import "JXSelectFriendsVC.h"
#import "JXAVCallViewController.h"
#endif

#ifdef Live_Version
#import "JXLiveViewController.h"
#endif

#import "JXScanQRViewController.h"
#import "JXNearVC.h"
#import "JXBlogRemind.h"
#import "JXTabMenuView.h"
#ifdef Meeting_Version
#ifdef Live_Version
#import "GKDYHomeViewController.h"
#import "JXSmallVideoViewController.h"
#endif
#endif
#import "ImageResize.h"
#import "JXChatViewController.h"
#import "JXCell.h"

/*
 *   如果要改变左右间隔
 *   减少间隔，则增加 SQUARE_HEIGHT
 *   增加间隔，则减少 SQUARE_HEIGHT
 */
#define SQUARE_HEIGHT      38      //图片宽高
#define INSET_IMAGE       15        // 字和图片的间距


typedef NS_ENUM(NSInteger, JXSquareType) {
    JXSquareTypeLife,           // 生活圈
    JXSquareTypeVideo,          // 视频会议
    JXSquareTypeVideoLive,      // 视频直播
    JXSquareTypeShortVideo,     // 短视频
    JXSquareTypeQrcode,         // 扫一扫
    JXSquareTypeNearby,         // 附近的人
};
@interface JXSquareViewController () <JXActionSheetVCDelegate,UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, strong) NSArray *titleArr;
@property (nonatomic, strong) NSArray *iconArr;
@property (nonatomic, assign) JXSquareType type;
@property (nonatomic, assign) BOOL isAudioMeeting;
@property (nonatomic, strong) UILabel *weiboNewMsgNum;
@property (nonatomic, strong) NSMutableArray *remindArray;
@property (nonatomic, strong) UIImageView *imgV;
@property (nonatomic, strong) UIImageView *topImageView;

@property (nonatomic, strong) NSMutableArray *subviews;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *array;
@property (nonatomic, assign) NSInteger page;
@property(nonatomic,strong) MJRefreshFooterView *footer;
@property(nonatomic,strong) MJRefreshHeaderView *header;

@end

@implementation JXSquareViewController

- (instancetype)init {
    if (self = [super init]) {
        self.title = Localized(@"JXMainViewController_Find");
        _array = [NSMutableArray array];
        self.heightFooter = 0;
        self.heightHeader = JX_SCREEN_TOP;
        [self createHeadAndFoot];
        self.tableBody.backgroundColor = HEXCOLOR(0xf0eff4);
        
        self.subviews = [[NSMutableArray alloc] init];
        
        [self setupViews];
        [g_notify addObserver:self selector:@selector(remindNotif:) name:kXMPPMessageWeiboRemind object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self getServerData];
}

- (void)getServerData {
    [g_server searchPublicWithKeyWorld:@"" limit:20 page:(int)_page toView:self];
}


-(void)dealloc{
    [g_notify removeObserver:self name:kXMPPMessageWeiboRemind object:nil];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self showNewMsgNoti];
}

- (void)showNewMsgNoti {
    _remindArray = [[JXBlogRemind sharedInstance] doFetchUnread];
    
    NSString *newMsgNum = [NSString stringWithFormat:@"%ld",_remindArray.count];
    if (_remindArray.count >= 10 && _remindArray.count <= 99) {
        self.weiboNewMsgNum.font = SYSFONT(12);
    }else if (_remindArray.count > 0 && _remindArray.count < 10) {
        self.weiboNewMsgNum.font = SYSFONT(13);
    }else if(_remindArray.count > 99){
        self.weiboNewMsgNum.font = SYSFONT(9);
    }

    self.weiboNewMsgNum.text = newMsgNum;
    [g_mainVC.tb setBadge:2 title:newMsgNum];
    self.weiboNewMsgNum.hidden = _remindArray.count <= 0;
}


- (void)setupViews {
    UIView *baseView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, JX_SCREEN_WIDTH, 0)];
    baseView.backgroundColor = [UIColor whiteColor];
    [self.tableBody addSubview:baseView];
    //顶部图片
    _topImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, JX_SCREEN_WIDTH, 180)];
    [baseView addSubview:_topImageView];
    CGFloat fl = (_topImageView.frame.size.width/_topImageView.frame.size.height);
    [_topImageView sd_setImageWithURL:[NSURL URLWithString:g_config.headBackgroundImg] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (error) {
            image = [UIImage imageNamed:@"Default_Gray"];
        }
        _topImageView.image = [ImageResize image:image fillSize:CGSizeMake((_topImageView.frame.size.height+200)*fl, _topImageView.frame.size.height+200)];
    }];
    
    UIView *boldLine = [[UIView alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(_topImageView.frame)+20, 3, 20)];
    boldLine.backgroundColor = THEMECOLOR;
    [baseView addSubview:boldLine];
    //热门应用
    CGSize size = [Localized(@"JX_TopicalApplication") boundingRectWithSize:CGSizeMake(MAXFLOAT, 20) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:SYSFONT(18)} context:nil].size;
    UILabel *hotLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(boldLine.frame)+10, CGRectGetMinY(boldLine.frame), size.width, 20)];
    hotLabel.text = Localized(@"JX_TopicalApplication");
    hotLabel.font = SYSFONT(17);
    [baseView addSubview:hotLabel];
    //更多应用敬请期待！
    UILabel *hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(hotLabel.frame)+10, CGRectGetMinY(boldLine.frame)+6, 160, 14)];
    hintLabel.text = Localized(@"JX_MoreApps");
    hintLabel.textColor = [UIColor grayColor];
    hintLabel.font = SYSFONT(12);
    [baseView addSubview:hintLabel];
    
    // 左右滑 菜单栏
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(hotLabel.frame)+20, JX_SCREEN_WIDTH, 0)];
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    [baseView addSubview:_scrollView];
    
    BOOL lifeCircle = YES;      // 生活圈
    BOOL videoMeeting = YES;    // 视频会议
    BOOL liveVideo = YES;       // 视频直播
    BOOL shortVideo = YES;      // 短视频
    BOOL peopleNearby = YES;    // 附近的人
    BOOL scan = YES;            // 扫一扫
    if (g_config.popularAPP) {
        lifeCircle = [[g_config.popularAPP objectForKey:@"lifeCircle"] boolValue];
        videoMeeting = [[g_config.popularAPP objectForKey:@"videoMeeting"] boolValue];
        liveVideo = [[g_config.popularAPP objectForKey:@"liveVideo"] boolValue];
        shortVideo = [[g_config.popularAPP objectForKey:@"shortVideo"] boolValue];
        peopleNearby = [[g_config.popularAPP objectForKey:@"peopleNearby"] boolValue];
        scan = [[g_config.popularAPP objectForKey:@"scan"] boolValue];
    }
    
    UIButton *button;
    // 图片在button中的左右间隙
    int  leftInset = (button.frame.size.width - SQUARE_HEIGHT)/2;
    int btnX = 0;
    int btnY = 0;

    if (lifeCircle) {
        // 生活圈
        button = [self createButtonWithFrame:CGRectMake(0, btnY, JX_SCREEN_WIDTH/5, 0) title:Localized(@"JX_LifeCircle") icon:@"square_life" index:JXSquareTypeLife];
        
        self.weiboNewMsgNum = [[UILabel alloc] initWithFrame:CGRectMake(button.frame.size.width-leftInset- SQUARE_HEIGHT - 13, 3, 20, 20)];
        self.weiboNewMsgNum.backgroundColor = [UIColor redColor];
        self.weiboNewMsgNum.font = SYSFONT(13);
        self.weiboNewMsgNum.textAlignment = NSTextAlignmentCenter;
        self.weiboNewMsgNum.layer.cornerRadius = self.weiboNewMsgNum.frame.size.width / 2;
        self.weiboNewMsgNum.layer.masksToBounds = YES;
        self.weiboNewMsgNum.hidden = YES;
        self.weiboNewMsgNum.textColor = [UIColor whiteColor];
        self.weiboNewMsgNum.text = @"99";
        [button addSubview:self.weiboNewMsgNum];
    }
    
#ifdef Meeting_Version
    if (videoMeeting) {
        // 视频会议
        btnX += button.frame.size.width;
        button = [self createButtonWithFrame:CGRectMake(btnX, btnY, JX_SCREEN_WIDTH/5, 0) title:Localized(@"JXSettingVC_VideoMeeting") icon:@"square_video" index:JXSquareTypeVideo];
    }
#endif
    
#ifdef Live_Version
    if (liveVideo) {
        // 视频直播
        btnX += button.frame.size.width;
        button = [self createButtonWithFrame:CGRectMake(btnX, btnY, JX_SCREEN_WIDTH/5, 0) title:Localized(@"JX_LiveVideo") icon:@"square_videochat" index:JXSquareTypeVideoLive];
    }
#endif

    if (shortVideo) {
        // 抖音模块
        btnX += button.frame.size.width;
        button = [self createButtonWithFrame:CGRectMake(btnX, btnY, JX_SCREEN_WIDTH/5, 0) title:Localized(@"JX_ShorVideo") icon:@"square_douyin" index:JXSquareTypeShortVideo];
    }

    if (peopleNearby) {
        // 附近的人
        btnX += button.frame.size.width;
        button = [self createButtonWithFrame:CGRectMake(btnX, btnY, JX_SCREEN_WIDTH/5, 0) title:Localized(@"JXNearVC_NearPer") icon:@"square_nearby" index:JXSquareTypeNearby];
    }
    
    if (scan) {
        // 扫一扫
        btnX += button.frame.size.width;
        button = [self createButtonWithFrame:CGRectMake(btnX, btnY, JX_SCREEN_WIDTH/5, 0) title:Localized(@"JX_Scan") icon:@"square_qrcode" index:JXSquareTypeQrcode];
    }
    
    CGRect scrollFrame = _scrollView.frame;
    scrollFrame.size.height = button.frame.size.height;
    _scrollView.frame = scrollFrame;

    _scrollView.contentSize = CGSizeMake(btnX+button.frame.size.width, 0);
    
    CGRect frame = baseView.frame;
    frame.size.height = CGRectGetMaxY(_scrollView.frame)+25;
    baseView.frame = frame;
    
    //热门公众号 以及列表
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(baseView.frame)+15, JX_SCREEN_WIDTH, 50)];
    headerView.backgroundColor = [UIColor whiteColor];
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(20, 20, 3, 20)];
    line.backgroundColor = THEMECOLOR;
    [headerView addSubview:line];
    
    UILabel *numLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(line.frame)+10, 20, 240, 20)];
    numLabel.text = Localized(@"JX_PopularPublicAccount");
    numLabel.font = SYSFONT(17);
    [headerView addSubview:numLabel];
    [self.tableBody addSubview:headerView];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(headerView.frame), JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT - JX_SCREEN_TOP - CGRectGetMaxY(headerView.frame)-JX_SCREEN_BOTTOM) style:UITableViewStylePlain];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.backgroundColor = HEXCOLOR(0xf0eff4);
//    _tableView.tableHeaderView = headerView;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.tableBody addSubview:_tableView];
    
    [self addHeader];
    [self addFooter];
    
}
- (void)stopLoading {
    
    [_footer endRefreshing];
    [_header endRefreshing];
}
- (void)addFooter
{
    if(_footer){
        //        [_footer free];
        //        return;
    }
    _footer = [MJRefreshFooterView footer];
    _footer.scrollView = _tableView;
    __weak JXSquareViewController *weakSelf = self;
    _footer.beginRefreshingBlock = ^(MJRefreshBaseView *refreshView) {
        
        [weakSelf scrollToPageDown];
        //        NSLog(@"%@----开始进入刷新状态", refreshView.class);
    };
    _footer.endStateChangeBlock = ^(MJRefreshBaseView *refreshView) {
        
        // 刷新完毕就会回调这个Block
        //        NSLog(@"%@----刷新完毕", refreshView.class);
    };
    _footer.refreshStateChangeBlock = ^(MJRefreshBaseView *refreshView, MJRefreshState state) {
        // 控件的刷新状态切换了就会调用这个block
        switch (state) {
            case MJRefreshStateNormal:
                //                NSLog(@"%@----切换到：普通状态", refreshView.class);
                break;
                
            case MJRefreshStatePulling:
                //                NSLog(@"%@----切换到：松开即可刷新的状态", refreshView.class);
                break;
                
            case MJRefreshStateRefreshing:
                //                NSLog(@"%@----切换到：正在刷新状态", refreshView.class);
                break;
            default:
                break;
        }
    };
}

- (void)addHeader
{
    if(_header){
        //        [_header free];
        //        return;
    }
    _header = [MJRefreshHeaderView header];
    _header.scrollView = _tableView;
    __weak JXSquareViewController *weakSelf = self;
    _header.beginRefreshingBlock = ^(MJRefreshBaseView *refreshView) {
        // 进入刷新状态就会回调这个Block
        [weakSelf scrollToPageUp];
    };
    _header.endStateChangeBlock = ^(MJRefreshBaseView *refreshView) {
        // 刷新完毕就会回调这个Block
        //        NSLog(@"%@----刷新完毕", refreshView.class);
    };
    _header.refreshStateChangeBlock = ^(MJRefreshBaseView *refreshView, MJRefreshState state) {
        // 控件的刷新状态切换了就会调用这个block
        switch (state) {
            case MJRefreshStateNormal:
                //                NSLog(@"%@----切换到：普通状态", refreshView.class);
                break;
                
            case MJRefreshStatePulling:
                //                NSLog(@"%@----切换到：松开即可刷新的状态", refreshView.class);
                break;
                
            case MJRefreshStateRefreshing:
                //                NSLog(@"%@----切换到：正在刷新状态", refreshView.class);
                break;
            default:
                break;
        }
    };
}

//顶部刷新获取数据
-(void)scrollToPageUp{
    
    _page = 0;
    [self getServerData];
}

-(void)scrollToPageDown{
    
    [self getServerData];
}

#pragma mark - tableView dataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _array.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_array.count == 1) {
        return 100;
    }
    return 54;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"JXCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    JXUserObject *user = _array[indexPath.row];
    if (_array.count == 1) {
        if ([cell isKindOfClass:[JXCell class]]) {
            cell = nil;
        }
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        cell.imageView.frame = CGRectMake(0.0, 0.0, SQUARE_HEIGHT, SQUARE_HEIGHT);
        CALayer *cellImageLayer = cell.imageView.layer;
        [cellImageLayer setCornerRadius:SQUARE_HEIGHT/2];
        [cellImageLayer setMasksToBounds:YES];
        [g_server getHeadImageSmall:user.userId userName:user.userNickname imageView:cell.imageView];
        cell.textLabel.text = user.userNickname;
    }else {
        JXCell *cell=nil;
        if(cell==nil){
            cell = [[JXCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        cell.title = user.userNickname;
        cell.index = (int)indexPath.row;
        cell.userId = user.userId;
        [cell.lbTitle setText:cell.title];
        cell.isSmall = YES;
        [cell headImageViewImageWithUserId:nil roomId:nil];
        return cell;

    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    JXUserObject *user = _array[indexPath.row];
    JXChatViewController *sendView=[JXChatViewController alloc];
    
    sendView.scrollLine = 0;
    sendView.title = user.userNickname;
    sendView.chatPerson = user;
    sendView = [sendView init];
    [g_navigation pushViewController:sendView animated:YES];


}

//服务端返回数据
-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
    [_wait hide];
    
    if( [aDownload.action isEqualToString:act_PublicSearch] ){
        [self stopLoading];
        
        if (array1.count < 20) {
            _footer.hidden = YES;
        }
        
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        if(_page == 0){
            [_array removeAllObjects];
            for (int i = 0; i < array1.count; i++) {
                JXUserObject *user = [[JXUserObject alloc] init];
                [user getDataFromDict:array1[i]];
                [arr addObject:user];
            }
            [_array addObjectsFromArray:arr];
        }else{
            if([array1 count]>0){
                for (int i = 0; i < array1.count; i++) {
                    JXUserObject *user = [[JXUserObject alloc] init];
                    [user getDataFromDict:array1[i]];
                    [arr addObject:user];
                }
                [_array addObjectsFromArray:arr];
            }
        }
        _page ++;
        [_tableView reloadData];
        [self setTableviewHeight];
    }
}

-(int) didServerResultFailed:(JXConnection*)aDownload dict:(NSDictionary*)dict{
    [_wait hide];
    [self stopLoading];
    return hide_error;
}

-(int) didServerConnectError:(JXConnection*)aDownload error:(NSError *)error{//error为空时，代表超时
    [_wait hide];
    [self stopLoading];
    return hide_error;
}

-(void) didServerConnectStart:(JXConnection*)aDownload{
    [_wait start];
}

- (void)setTableviewHeight {
    int height = _array.count <= 1 ? 100 : 54;
    CGRect frame = _tableView.frame;
    frame.size.height = height*_array.count;
    _tableView.frame = frame;
    
    self.tableBody.contentSize = CGSizeMake(0, CGRectGetMaxY(_tableView.frame) + JX_SCREEN_BOTTOM+15);
}


- (void)clickButtonWithTag:(NSInteger)btnTag {
    switch (btnTag) {
        case JXSquareTypeLife:{// 生活圈
            WeiboViewControlle *weiboVC = [WeiboViewControlle alloc];
            weiboVC.user = g_server.myself;
            weiboVC = [weiboVC init];
            [g_navigation pushViewController:weiboVC animated:YES];
        }
            break;
        case JXSquareTypeVideo:{// 视频会议
#ifdef Meeting_Version
            
            if(g_xmpp.isLogined != 1){
                [g_xmpp showXmppOfflineAlert];
                return;
            }
            
            NSString *str1;
            NSString *str2;
            str1 = Localized(@"JXSettingVC_VideoMeeting");
            str2 = Localized(@"JX_Meeting");
            
            JXActionSheetVC *actionVC = [[JXActionSheetVC alloc] initWithImages:@[@"meeting_tel",@"meeting_video"] names:@[str2,str1]];
            actionVC.delegate = self;
            [self presentViewController:actionVC animated:NO completion:nil];
#endif
        }
            break;
        case JXSquareTypeVideoLive:{ // 视频直播
#ifdef Live_Version
            
            JXLiveViewController *vc = [[JXLiveViewController alloc] init];
            [g_navigation pushViewController:vc animated:YES];
#endif
        }
            break;
        case JXSquareTypeShortVideo:{// 短视频
#ifdef Meeting_Version
#ifdef Live_Version
            JXSmallVideoViewController *vc = [[JXSmallVideoViewController alloc] init];
            [g_navigation pushViewController:vc animated:YES];
            return;
//            GKDYHomeViewController *vc = [[GKDYHomeViewController alloc] init];
//            [g_navigation pushViewController:vc animated:NO];
//            return;
#endif
#endif
            [JXMyTools showTipView:@"暂未开通，敬请期待"];
        }
            break;
        case JXSquareTypeQrcode:{// 扫一扫
            AVAuthorizationStatus authStatus =  [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)
            {
                [g_server showMsg:Localized(@"JX_CanNotopenCenmar")];
                return;
            }
            
            JXScanQRViewController * scanVC = [[JXScanQRViewController alloc] init];
            [g_navigation pushViewController:scanVC animated:YES];
        }
            break;
        case JXSquareTypeNearby:{// 附近的人
            JXNearVC * nearVc = [[JXNearVC alloc] init];
            [g_navigation pushViewController:nearVc animated:YES];
        }
            break;
            
        default:
            break;
    }

}



#ifdef Meeting_Version

- (void)actionSheet:(JXActionSheetVC *)actionSheet didButtonWithIndex:(NSInteger)index {
    if (index == 0) {
        [self onGroupAudioMeeting:nil];
    }else if(index == 1){
        [self onGroupVideoMeeting:nil];
    }
}

-(void)onGroupAudioMeeting:(JXMessageObject*)msg{
    self.isAudioMeeting = YES;
    [self onInvite];
}

-(void)onGroupVideoMeeting:(JXMessageObject*)msg{
    self.isAudioMeeting = NO;
    [self onInvite];
}

-(void)onInvite{
    NSMutableSet* p = [[NSMutableSet alloc]init];
    
    JXSelectFriendsVC* vc = [JXSelectFriendsVC alloc];
    vc.isNewRoom = NO;
    vc.isShowMySelf = NO;
    vc.type = JXSelectFriendTypeSelFriends;
    vc.existSet = p;
    vc.delegate = self;
    vc.didSelect = @selector(meetingAddMember:);
    vc = [vc init];
    [g_navigation pushViewController:vc animated:YES];
}

- (void) remindNotif:(NSNotification *)notif {
//    JXMessageObject *msg = notif.object;
//    _remindArray = [[JXBlogRemind sharedInstance] doFetchUnread];
//    if (_remindArray.count > 0) {
//        NSString *newMsgNum = [NSString stringWithFormat:@"%ld",_remindArray.count];
//        self.weiboNewMsgNum.hidden = NO;
//        self.weiboNewMsgNum.text = newMsgNum;
//        [g_mainVC.tb setBadge:2 title:newMsgNum];
//    }
    [self showNewMsgNoti];
    
}


-(void)meetingAddMember:(JXSelectFriendsVC*)vc{
    int type;
    if (self.isAudioMeeting) {
        type = kWCMessageTypeAudioMeetingInvite;
    }else {
        type = kWCMessageTypeVideoMeetingInvite;
    }
    for(NSNumber* n in vc.set){
        JXUserObject *user;
        if (vc.seekTextField.text.length > 0) {
            user = vc.searchArray[[n intValue] % 1000];
        }else{
            user = [[vc.letterResultArr objectAtIndex:[n intValue] / 1000] objectAtIndex:[n intValue] % 1000];
        }
        NSString* s = [NSString stringWithFormat:@"%@",user.userId];
        [g_meeting sendMeetingInvite:s toUserName:user.userNickname roomJid:MY_USER_ID callId:nil type:type];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (g_meeting.isMeeting) {
            return;
        }
        JXAVCallViewController *avVC = [[JXAVCallViewController alloc] init];
        avVC.roomNum = MY_USER_ID;
        avVC.isAudio = self.isAudioMeeting;
        avVC.isGroup = YES;
        avVC.toUserName = MY_USER_NAME;
        avVC.view.frame = [UIScreen mainScreen].bounds;
        [g_window addSubview:avVC.view];
        
    });
}
#endif


- (UIButton *)createButtonWithFrame:(CGRect)frame title:(NSString *)title icon:(NSString *)iconName index:(NSInteger)index {
    UIButton *button = [[UIButton alloc] init];
    button.frame = frame;
    button.tag = index;
    [button addTarget:self action:@selector(didButton:) forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:self action:@selector(didButtonDown:) forControlEvents:UIControlEventTouchDown];

    //长按事件
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didButtonLong:)];
    longPress.minimumPressDuration = 0.1; //定义按的时间
    [button addGestureRecognizer:longPress];
 
    [_scrollView addSubview:button];
    
//    CGFloat X = frame.origin.x;
//    CGFloat Y = frame.origin.y;
    CGFloat inset =(JX_SCREEN_WIDTH-SQUARE_HEIGHT*5)/10;   // 间隔
//    CGFloat originY = Y > 0 ? 20+51- INSET_IMAGE  : 20+51;
    CGFloat originY = 15;
    _imgV = [[UIImageView alloc] init];
    _imgV.frame = CGRectMake(inset, originY, SQUARE_HEIGHT, SQUARE_HEIGHT);
    _imgV.image = [UIImage imageNamed:iconName];
    _imgV.tag = index;
    [button addSubview:_imgV];
    [_subviews addObject:_imgV];
    
    CGSize size = [title boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:SYSFONT(15)} context:nil].size;
    UILabel *lab = [[UILabel alloc] init];
    lab.text = title;
    lab.textColor = HEXCOLOR(0x323232);
    lab.font = SYSFONT(15);
    lab.frame = CGRectMake(0, CGRectGetMaxY(_imgV.frame)+INSET_IMAGE, size.width, size.height);
    CGPoint center = lab.center;
    center.x = _imgV.center.x;
    lab.center = center;
    
    CGRect btnFrame = button.frame;
    btnFrame.size.height = originY+SQUARE_HEIGHT+size.height+INSET_IMAGE;
    button.frame = btnFrame;
    
    [button addSubview:lab];
    
    return button;
}

// 点击事件
- (void)didButton:(UIButton *)button {
    [self clickButtonWithTag:button.tag];
}

// 按下事件
- (void)didButtonDown:(UIButton *)button {
    for (UIView *sub in button.subviews) {
        if ([sub isKindOfClass:[UIImageView class]]) {
            sub.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:1.f];
            [UIView animateWithDuration:.3f animations:^{
                sub.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0];
            }];
        }
    }
}

// 长按事件
- (void)didButtonLong:(UILongPressGestureRecognizer *)tap {
    UIView *view= tap.view;
//    UIImageView * moveShipImageView = (UIImageView *)[self.view viewWithTag:view.tag];
    UIView *subview;
    for (UIView *sub in view.subviews) {
        if ([sub isKindOfClass:[UIImageView class]]) {
            sub.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:1.f];
            subview = sub;
        }
    }
    //(手势完成时)手指离开时
    if (tap.state == UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:.3f animations:^{
            subview.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.f];
        } completion:^(BOOL finished) {
//            CGPoint curPoint = [tap locationInView:self.view];
//            if ([moveShipImageView.layer.presentationLayer hitTest:curPoint]) {
                [self clickButtonWithTag:view.tag];
//            }else {
//
//            }
        }];
    }
}


@end
