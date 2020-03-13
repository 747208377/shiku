//
//  JXRedPacketListVC.m
//  shiku_im
//
//  Created by p on 2018/6/5.
//  Copyright © 2018年 Reese. All rights reserved.
//

#import "JXRedPacketListVC.h"
#import "JXRPacketListCell.h"

@interface JXRedPacketListVC ()

@property (nonatomic, strong) UIButton *getBtn;
@property (nonatomic, strong) UIButton *sendBtn;

@property (nonatomic, strong) NSMutableArray *array;
@property (nonatomic, assign) int selIndex;

@end

@implementation JXRedPacketListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _array = [NSMutableArray array];
    self.isShowFooterPull = YES;
    self.isShowHeaderPull = YES;
    
    UIView *headView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, JX_SCREEN_WIDTH, 150)];
    headView.backgroundColor = HEXCOLOR(0xCD4331);
    [self.view addSubview:headView];
    
    self.tableView.frame = CGRectMake(0, CGRectGetMaxY(headView.frame), JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT - CGRectGetMaxY(headView.frame));
    
    UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, JX_SCREEN_TOP - 32, 50, 20)];
    [closeBtn setTitle:Localized(@"JX_Close") forState:UIControlStateNormal];
    [closeBtn setTitleColor:HEXCOLOR(0xFBD49E) forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:15.0];
    [closeBtn addTarget:self action:@selector(closeBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [headView addSubview:closeBtn];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, JX_SCREEN_TOP - 32, JX_SCREEN_WIDTH, 20)];
    title.textAlignment = NSTextAlignmentCenter;
    title.text = Localized(@"JX_RedPacketRecord");
    title.textColor = HEXCOLOR(0xFBD49E);
    title.font = [UIFont systemFontOfSize:17.0];
    [headView addSubview:title];
    
    _getBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, headView.frame.size.height - 30, headView.frame.size.width / 2, 30)];
    [_getBtn setTitle:Localized(@"PACKETS_RECEIVED") forState:UIControlStateNormal];
    [_getBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [_getBtn setTitleColor:HEXCOLOR(0xFBD49E) forState:UIControlStateSelected];
    _getBtn.selected = YES;
    _getBtn.tag = 1000;
    _getBtn.titleLabel.font = [UIFont systemFontOfSize:13.0];
    [_getBtn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
    [headView addSubview:_getBtn];
    
    _sendBtn = [[UIButton alloc] initWithFrame:CGRectMake(headView.frame.size.width / 2, headView.frame.size.height - 30, headView.frame.size.width / 2, 30)];
    [_sendBtn setTitle:Localized(@"ENVELOPES_ISSUED") forState:UIControlStateNormal];
    [_sendBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [_sendBtn setTitleColor:HEXCOLOR(0xFBD49E) forState:UIControlStateSelected];
    _sendBtn.selected = NO;
    _sendBtn.tag = 1001;
    _sendBtn.titleLabel.font = [UIFont systemFontOfSize:13.0];
    [_sendBtn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
    [headView addSubview:_sendBtn];
    
    _selIndex = 0;
    _page = 0;
    
    [self getServerData];
}

- (void)closeBtnAction:(UIButton *)btn {
    [self actionQuit];
}

- (void)btnAction:(UIButton *)btn {
    _getBtn.selected = !_getBtn.selected;
    _sendBtn.selected = !_sendBtn.selected;
    _page = 0;
    if (btn.tag == 1000) {
        _selIndex = 0;
    }else {
        _selIndex = 1;
    }
    [self getServerData];
}

- (void)scrollToPageUp {
    _page = 0;
    [self getServerData];
}
- (void)scrollToPageDown {
    _page ++;
    [self getServerData];
}

- (void) getServerData {
    
    if (_selIndex == 0) {
        [g_server redPacketGetRedReceiveListIndex:_page toView:self];
    }else {
        [g_server redPacketGetSendRedPacketListIndex:_page toView:self];
    }
}


#pragma mark  --------------------TableView-------------------------

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [_array count];
}

-(JXRPacketListCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    //领取过红包的用户，使用JXRPacketListCell展示
    NSString * cellName = @"RPacketListCell";
    JXRPacketListCell * cell = [tableView dequeueReusableCellWithIdentifier:cellName];
    if(cell==nil){
        
        cell = [[NSBundle mainBundle] loadNibNamed:@"JXRPacketListCell" owner:self options:nil][0];
    }
    NSDictionary *dict = _array[indexPath.row];
    cell.headImageWidthCon.constant = 0;
    //用户名
    cell.nameLabel.text = dict[@"sendName"];
    if(_selIndex == 1) {
        NSString *str;
        int type = [dict[@"type"] intValue];
        if (type == 1) {
            str = Localized(@"JX_UsualGift");
        }
        if (type == 2) {
            str = Localized(@"JX_LuckGift");
        }
        if (type == 3) {
            str = Localized(@"JX_MesGift");
        }
        cell.nameLabel.text = str;
    }
    //日期
    NSTimeInterval  getTime = [dict[@"time"] longLongValue];
    if (_selIndex == 1) {
        getTime = [dict[@"sendTime"] longLongValue];
    }
    NSDate * date = [NSDate dateWithTimeIntervalSince1970:getTime];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:8*60*60]];//中国专用
    cell.timeLabel.text = [dateFormatter stringFromDate:date];
    //金额
    cell.moneyLabel.text = [NSString stringWithFormat:@"%.2f %@",[dict[@"money"] doubleValue],Localized(@"JX_ChinaMoney")];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
}

-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
    [_wait stop];
    [self stopLoading];
    
    if (_page == 0) {
        [_array removeAllObjects];
        [_array addObjectsFromArray:array1];
    }else {
        [_array addObjectsFromArray:array1];
    }
    
    [self.tableView reloadData];

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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
