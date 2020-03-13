//
//  JXRecordCodeVC.m
//  shiku_im
//
//  Created by Apple on 16/9/18.
//  Copyright © 2016年 Reese. All rights reserved.
//

#import "JXRecordCodeVC.h"
#import "JXRecordTBCell.h"
@interface JXRecordCodeVC ()

@end

@implementation JXRecordCodeVC
- (instancetype)init
{
    self = [super init];
    if (self) {
        //self.view.frame = CGRectMake(JX_SCREEN_WIDTH, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT);
        self.heightHeader = JX_SCREEN_TOP;
        self.heightFooter = 0;
        self.isGotoBack = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self customView];
    [self getServerData];
}
-(void)getServerData{
    [_wait start];
    [g_server getConsumeRecord:_page toView:self];
}
- (void)customView{
    
    self.title = Localized(@"JXRecordCodeVC_Title");
    [self createHeadAndFoot];
    
    _table.delegate = self;
    _table.dataSource = self;
    _table.separatorStyle = UITableViewCellSeparatorStyleNone;
    _table.allowsSelection = NO;
    
}

-(void)getDataObjFromArr:(NSMutableArray*)arr{
    [_table reloadData];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
//    [UIView animateWithDuration:0.3 animations:^{
//        self.view.frame = CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT);
//    }];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [_dataArr count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    JXRecordTBCell * cell = [tableView dequeueReusableCellWithIdentifier:@"JXRecordTBCell"];
    NSDictionary * cellModel = _dataArr[indexPath.row];
    if (cell == nil) {
        cell = [[NSBundle mainBundle] loadNibNamed:@"JXRecordTBCell" owner:self options:nil][0];
    }
    //描述
    cell.titleLabel.text = cellModel[@"desc"];
    //转换为日期
    NSTimeInterval  creatTime = [cellModel[@"time"]  doubleValue];
    NSDate * date = [NSDate dateWithTimeIntervalSince1970:creatTime];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:8*60*60]];//中国专用
    cell.timeLabel.text = [dateFormatter stringFromDate:date];
    //交易金额
    cell.moneyLabel.text = [NSString stringWithFormat:@"%@ %@",cellModel[@"money"],Localized(@"JX_ChinaMoney")];
    //是否退款
    cell.refundLabel.text = @"";
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
}

-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
    [_wait stop];
    [self stopLoading];
    //消费记录
    if ([aDownload.action isEqualToString:act_consumeRecord]) {
        //添加到数据源
        if (dict == nil) {
            return;
        }
        if ([dict[@"pageIndex"] intValue] == 0) {
            _dataArr = [[NSMutableArray alloc]initWithArray:dict[@"pageData"]];
            //            self.dataDict = [[NSMutableDictionary alloc]initWithDictionary:dict];
        }else if([dict[@"pageIndex"] intValue] <= [dict[@"pageCount"] intValue]){
            [_dataArr addObjectsFromArray:dict[@"pageData"]];
        }else{
            //没有更多数据
        }
        
        [self getDataObjFromArr:_dataArr];
        
    }
    
    
}

-(int) didServerResultFailed:(JXConnection*)aDownload dict:(NSDictionary*)dict{
    [_wait stop];
    [self stopLoading];
    return hide_error;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
