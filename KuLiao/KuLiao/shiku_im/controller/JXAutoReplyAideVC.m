//
//  JXAutoReplyAideVC.m
//  shiku_im
//
//  Created by p on 2019/5/14.
//  Copyright © 2019年 Reese. All rights reserved.
//

#import "JXAutoReplyAideVC.h"
#import "JXReplyAideKeyManageVC.h"
#import "UIImage+Color.h"

@interface JXAutoReplyAideVC ()

@property (nonatomic, strong) UIButton *addBtn;
@property (nonatomic, strong) UIButton *delBtn;
@property (nonatomic, strong) UIButton *replaceBtn;
@property (nonatomic, strong) UIView *keyView;
@property (nonatomic, strong) UIView *noKeyView;
@property (nonatomic, strong) UIButton *manageBtn;
@property (nonatomic, strong) NSMutableArray *keys;

@property (nonatomic, strong) UIView *baseView;
@property (nonatomic, strong) NSArray *groupHelperArr;


@end

@implementation JXAutoReplyAideVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.heightHeader = JX_SCREEN_TOP;
    self.heightFooter = 0;
    self.isGotoBack = YES;
    [self createHeadAndFoot];
    
    _keys = [[NSMutableArray alloc] init];
    
    self.title = self.model.name;
    

    [self customView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.groupHelperArr = [NSArray array];
    for (UIView *view in _keyView.subviews) {
        [view removeFromSuperview];
    }
    [g_server queryGroupHelper:self.roomId toView:self];
}

- (void)customView {
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 20, 50, 50)];
    imageView.layer.cornerRadius = 50 / 2;
    imageView.layer.masksToBounds = YES;
    [self.tableBody addSubview:imageView];
    
    [imageView sd_setImageWithURL:[NSURL URLWithString:self.model.iconUrl] placeholderImage:[UIImage imageNamed:@"avatar_normal"]];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(imageView.frame) + 10, imageView.frame.origin.y, 200, imageView.frame.size.height)];
    label.font = [UIFont systemFontOfSize:16.0];
    label.text = self.model.name;
    [self.tableBody addSubview:label];

    _addBtn = [[UIButton alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH - 65, 33, 50, 24)];
    _addBtn.custom_acceptEventInterval = 1.f;
    [_addBtn setTitle:@"添加" forState:UIControlStateNormal];
    [_addBtn setTitle:@"删除" forState:UIControlStateSelected];
    [_addBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_addBtn setBackgroundImage:[UIImage createImageWithColor:THEMECOLOR] forState:UIControlStateNormal];
    [_addBtn setBackgroundImage:[UIImage createImageWithColor:HEXCOLOR(0xFA2524)] forState:UIControlStateSelected];
    _addBtn.titleLabel.font = [UIFont systemFontOfSize:15.0];
    _addBtn.layer.cornerRadius = 3.0;
    _addBtn.layer.masksToBounds = YES;
    [_addBtn addTarget:self action:@selector(onAdd:) forControlEvents:UIControlEventTouchUpInside];
    [self.tableBody addSubview:_addBtn];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(15, CGRectGetMaxY(imageView.frame) + 20, JX_SCREEN_WIDTH - 15, .5)];
    lineView.backgroundColor = [UIColor lightGrayColor];
    [self.tableBody addSubview:lineView];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(15, CGRectGetMaxY(lineView.frame), JX_SCREEN_WIDTH - 30, 50)];
    label.font = [UIFont systemFontOfSize:14.0];
    label.numberOfLines = 0;
    label.textColor = [UIColor lightGrayColor];
    label.text = self.model.desc;
    [self.tableBody addSubview:label];
    
    lineView = [[UIView alloc] initWithFrame:CGRectMake(15, CGRectGetMaxY(label.frame), JX_SCREEN_WIDTH, .5)];
    lineView.backgroundColor = [UIColor lightGrayColor];
    [self.tableBody addSubview:lineView];
    
    
    UILabel *deveLab = [[UILabel alloc] initWithFrame:CGRectMake(15, CGRectGetMaxY(lineView.frame)+20, 200, 20)];
    deveLab.text = [NSString stringWithFormat:@"开发者:%@",self.model.developer];
    deveLab.font = SYSFONT(15);
    deveLab.textColor = [UIColor lightGrayColor];
    [self.tableBody addSubview:deveLab];
    
    UILabel *tintLab = [[UILabel alloc] initWithFrame:CGRectMake(15, CGRectGetMaxY(deveLab.frame), JX_SCREEN_WIDTH-30, 40)];
    tintLab.text = [NSString stringWithFormat:@"免责声明：本服务由%@提供。相关服务和责任将由该公司承担。如有问题请咨询该公司客服",self.model.developer];
    tintLab.textColor = [UIColor lightGrayColor];
    tintLab.font = SYSFONT(15);
    tintLab.numberOfLines = 0;
    [self.tableBody addSubview:tintLab];
    
    if (self.model.type == 1  || self.model.type == 2) {
        _baseView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(tintLab.frame)+20, JX_SCREEN_WIDTH, self.tableBody.frame.size.height-CGRectGetMaxY(tintLab.frame)-20)];
        [self.tableBody addSubview:_baseView];
        
        lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, JX_SCREEN_WIDTH, 30)];
        lineView.backgroundColor = HEXCOLOR(0xf0eff4);
        [_baseView addSubview:lineView];
        
        label = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, JX_SCREEN_WIDTH - 15, 30)];
        label.font = [UIFont systemFontOfSize:14.0];
        label.numberOfLines = 0;
        label.textColor = [UIColor lightGrayColor];
        label.text = @"已添加的关键字";
        [lineView addSubview:label];
        
        _manageBtn = [[UIButton alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH - 55, 0, 45, 30)];
        _manageBtn.titleLabel.font = [UIFont systemFontOfSize:15.0];
        [_manageBtn setTitle:@"管理" forState:UIControlStateNormal];
        [_manageBtn setTitleColor:THEMECOLOR forState:UIControlStateNormal];
        [_manageBtn addTarget:self action:@selector(keyManage) forControlEvents:UIControlEventTouchUpInside];
        [lineView addSubview:_manageBtn];
        
        _keyView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(lineView.frame), JX_SCREEN_WIDTH, 0)];
        [_baseView addSubview:_keyView];
        
        _noKeyView = [[UIView alloc] initWithFrame:CGRectMake(0, (_baseView.frame.size.height-140)/2, JX_SCREEN_WIDTH, 140)];
        [_baseView addSubview:_noKeyView];
        
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake((JX_SCREEN_WIDTH - 50) / 2, 0, 50, 50)];
        imageView.image = [UIImage imageNamed:@"酷聊120"];
        [_noKeyView addSubview:imageView];
        
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(imageView.frame), JX_SCREEN_WIDTH, 30)];
        label.font = [UIFont systemFontOfSize:14.0];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor lightGrayColor];
        label.text = @"还没有关键字哦~";
        [_noKeyView addSubview:label];
        
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake((JX_SCREEN_WIDTH - 150)/2, CGRectGetMaxY(label.frame) + 10, 150, 30)];
        btn.layer.cornerRadius = 3.0;
        btn.layer.masksToBounds = YES;
        btn.backgroundColor = THEMECOLOR;
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn setTitle:@"去添加" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(keyManage) forControlEvents:UIControlEventTouchUpInside];
        [_noKeyView addSubview:btn];
        
//        _noKeyView.frame = CGRectMake(_noKeyView.frame.origin.x, _noKeyView.frame.origin.y, _noKeyView.frame.size.width, CGRectGetMaxY(btn.frame));
//        _noKeyView.center = CGPointMake(_noKeyView.center.x, _keyView.frame.size.height / 2 - 50);
//        _noKeyView.hidden = YES;
    }
    
}

- (void)onAdd:(UIButton *)button {
    if (button.selected) {
        for (JXGroupHeplerModel *hModel in self.groupHelperArr) {
            if ([hModel.helperId isEqualToString:self.model.helperId]) {
                [g_server deleteGroupHelper:hModel.groupHelperId toView:self];
            }
        }
    }else {
        [g_server addGroupHelper:self.roomId roomJid:self.roomJid helperId:self.model.helperId toView:self];
    }
}

- (void)keyManage {
    
    JXReplyAideKeyManageVC *vc = [[JXReplyAideKeyManageVC alloc] init];
    vc.keys = self.keys;
    vc.roomId = self.roomId;
    vc.helperId = self.model.helperId;
    vc.model = self.model;
    [g_navigation pushViewController:vc animated:YES];
}

- (void)createKeys {
    
    CGFloat y = 0;
    for (NSInteger i = 0; i < _keys.count; i ++) {
        NSDictionary *dic = _keys[i];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, y, JX_SCREEN_WIDTH - 15, 50)];
        label.font = [UIFont systemFontOfSize:16.0];
        label.text = [dic objectForKey:@"keyWord"];
        [_keyView addSubview:label];
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(15, CGRectGetMaxY(label.frame), JX_SCREEN_WIDTH - 15, .5)];
        lineView.backgroundColor = [UIColor lightGrayColor];
        [_keyView addSubview:lineView];
        y = CGRectGetMaxY(lineView.frame);
    }
    _noKeyView.hidden = _keys.count > 0;
    
    _keyView.frame = CGRectMake(_keyView.frame.origin.x, _keyView.frame.origin.y, JX_SCREEN_WIDTH, y);
    
    self.tableBody.contentSize = CGSizeMake(0, CGRectGetMaxY(_keyView.frame));
    
}

-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
    [_wait stop];
    // 获取群助手
    if ([aDownload.action isEqualToString:act_queryGroupHelper]) {
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        for (int i = 0; i < array1.count; i++) {
            JXGroupHeplerModel *model = [[JXGroupHeplerModel alloc] init];
            [model getDataWithDict:array1[i]];
            [arr addObject:model];
        }
        _groupHelperArr = arr.copy;
        BOOL isHide = NO;
        for (JXGroupHeplerModel *hModel in _groupHelperArr) {
            if ([hModel.helperId isEqualToString:self.model.helperId]) {
                isHide = YES;
                _keys = hModel.keywords.mutableCopy;
                
                [self createKeys];
            }
        }
        _addBtn.selected = isHide;
        self.baseView.hidden = !isHide;
    }

    if ([aDownload.action isEqualToString:act_addGroupHelper]) {
        NSDictionary *dict = @{@"delete" : @0};
        [g_notify postNotificationName:kUpdateChatVCGroupHelperData object:dict];
        [g_server showMsg:@"添加成功"];
        self.addBtn.selected = YES;
        self.baseView.hidden = NO;
        [g_server queryGroupHelper:self.roomId toView:self];
    }
    if ([aDownload.action isEqualToString:act_deleteGroupHelper]) {
        NSDictionary *dict = @{@"delete" : @1};
        [g_notify postNotificationName:kUpdateChatVCGroupHelperData object:dict];
        [g_server showMsg:@"删除成功"];
        self.addBtn.selected = NO;
        self.baseView.hidden = YES;
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
    [_wait start];
}


@end
