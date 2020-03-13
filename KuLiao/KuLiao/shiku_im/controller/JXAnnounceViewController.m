//
//  JXAnnounceViewController.m
//  shiku_im
//
//  Created by 1 on 2018/8/17.
//  Copyright © 2018年 Reese. All rights reserved.
//

#import "JXAnnounceViewController.h"
#import "selectProvinceVC.h"
#import "selectValueVC.h"
#import "ImageResize.h"
#import "searchData.h"
#import "JXAnnounceCell.h"

#define HEIGHT 54
#define STARTTIME_TAG 1
#define IMGSIZE 100

@interface JXAnnounceViewController ()<UITextViewDelegate>
@property(nonatomic, assign) BOOL isShow;
@property(nonatomic, assign) BOOL isEdit;
@property (nonatomic, strong) UIView *baseView;
@property (nonatomic, strong) UIView *bigView;
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) JXLabel* relLabel;

@end

@implementation JXAnnounceViewController
@synthesize delegate,didSelect,value;

- (id)init
{
    self = [super init];
    if (self) {
        self.isGotoBack   = YES;
        self.heightFooter = 0;
        self.heightHeader = JX_SCREEN_TOP;
        [self createHeadAndFoot];
        self.isShowHeaderPull = NO;
        self.isShowFooterPull = NO;
        self.tableView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
        int height = 44;
        self.bigView = [[UIView alloc] initWithFrame:self.view.bounds];
        self.bigView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
        self.bigView.hidden = YES;
        [self.tableView addSubview:self.bigView];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyBoard)];
        [self.bigView addGestureRecognizer:tap];
        
        self.baseView = [[UIView alloc] initWithFrame:CGRectMake(40, JX_SCREEN_HEIGHT/4-.5, JX_SCREEN_WIDTH-80, 162)];
        self.baseView.backgroundColor = [UIColor whiteColor];
        self.baseView.layer.masksToBounds = YES;
        self. baseView.layer.cornerRadius = 4.0f;
        [self.bigView addSubview:self.baseView];
        int n = 20;
        UILabel *titLabel = [[UILabel alloc] initWithFrame:CGRectMake(INSETS, n, self.bigView.frame.size.width - INSETS*2, 20)];
        titLabel.textColor = HEXCOLOR(0x595959);
        titLabel.text = Localized(@"JX_Announcement");
        titLabel.font = SYSFONT(16);
        [self.baseView addSubview:titLabel];
        
        n = n + height;
        self.name = [self createTextField:self.baseView default:self.value hint:nil];
        self.name.backgroundColor = [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1];
//        _name.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
//        CGRect frame = self.name.frame;
//        CGSize constraintSize = CGSizeMake(frame.size.width - 20, MAXFLOAT);
//        CGSize size = [self.name sizeThatFits:constraintSize];
        self.name.textColor = HEXCOLOR(0x595959);
        self.name.frame = CGRectMake(10, n, self.baseView.frame.size.width - INSETS*2, 35.5);
        self.name.delegate = self;
        
        n = n + INSETS + height;
        self.topView = [[UIView alloc] initWithFrame:CGRectMake(0, n, self.baseView.frame.size.width, 44)];
        [self.baseView addSubview:self.topView];

        // 两条线
        UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.baseView.frame.size.width, 0.5)];
        topLine.backgroundColor = HEXCOLOR(0xD6D6D6);
        [self.topView addSubview:topLine];
        UIView *botLine = [[UIView alloc] initWithFrame:CGRectMake(self.baseView.frame.size.width/2, 0, 0.5, self.topView.frame.size.height)];
        botLine.backgroundColor = HEXCOLOR(0xD6D6D6);
        [self.topView addSubview:botLine];
        
        // 取消
        UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(topLine.frame), self.baseView.frame.size.width/2, botLine.frame.size.height)];
        [cancelBtn setTitle:Localized(@"JX_Cencal") forState:UIControlStateNormal];
        [cancelBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [cancelBtn.titleLabel setFont:SYSFONT(15)];
        [cancelBtn addTarget:self action:@selector(hideBigView) forControlEvents:UIControlEventTouchUpInside];
        [self.topView addSubview:cancelBtn];
        // 确定
        UIButton *sureBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.baseView.frame.size.width/2, CGRectGetMaxY(topLine.frame), self.baseView.frame.size.width/2, botLine.frame.size.height)];
        [sureBtn setTitle:Localized(@"JX_Confirm") forState:UIControlStateNormal];
        [sureBtn setTitleColor:HEXCOLOR(0x383893) forState:UIControlStateNormal];
        [sureBtn.titleLabel setFont:SYSFONT(15)];
        [sureBtn addTarget:self action:@selector(onRelease) forControlEvents:UIControlEventTouchUpInside];
        [self.topView addSubview:sureBtn];
        // 发布
        self.relLabel = [self createLabel:self.tableHeader default:Localized(@"JX_Publish") selector:@selector(onSave)];
        self.relLabel.textColor = THESIMPLESTYLE ? [UIColor blackColor] : [UIColor whiteColor];
        self.relLabel.font = SYSFONT(15);
        self.relLabel.textAlignment = NSTextAlignmentRight;
        self.relLabel.frame = THE_DEVICE_HAVE_HEAD ? CGRectMake(JX_SCREEN_WIDTH -90, 20+10+23, 80, 25) : CGRectMake(JX_SCREEN_WIDTH -90, 20+10, 80, 25);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


#pragma mark - tableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict = self.dataArray[indexPath.row];
    CGSize size = [dict[@"text"] boundingRectWithSize:CGSizeMake(JX_SCREEN_WIDTH-40, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:g_factory.font14} context:nil].size;
    
    return 100 + size.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"JXAnnounceCell";
    JXAnnounceCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[JXAnnounceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (self.dataArray.count > 0) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        dict = self.dataArray[indexPath.row];
        [g_server getHeadImageSmall:[NSString stringWithFormat:@"%@",dict[@"userId"]] userName:dict[@"nickname"] imageView:cell.icon];
        cell.name.text = [NSString stringWithFormat:@"%@",dict[@"nickname"]];
        NSTimeInterval startTime = [dict[@"time"] longLongValue];
        cell.time.text = [TimeUtil getTimeStrStyle1:startTime];
        cell.content.text = dict[@"text"];
        [cell setCellHeightWithText:dict[@"text"]];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}



- (NSArray*)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    // delete action
    if (self.isAdmin) { // 是群主或管理员添加删除功能
        UITableViewRowAction *editAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"编辑"  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
                                              {
                                                  [tableView setEditing:NO animated:YES];  // 退出编辑模式，隐藏左滑菜单
                                                  self.index = indexPath.row;
                                                  
                                                  self.isEdit = YES;
                                                  self.bigView.hidden = NO;
                                                  self.relLabel.userInteractionEnabled = NO;
                                                  
                                                  self.name.text = self.dataArray[indexPath.row][@"text"];
                                                  [self.name becomeFirstResponder];
                                                  [self textViewDidChange:self.name];
                                              }];
        editAction.backgroundColor = [UIColor grayColor];   // 编辑按钮颜色

        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:Localized(@"JX_Delete")  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
                {
                    [tableView setEditing:NO animated:YES];  // 退出编辑模式，隐藏左滑菜单
                    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                    dict = self.dataArray[indexPath.row];
                    NSString *roomId = [NSString stringWithFormat:@"%@",dict[@"roomId"]];
                    NSString *noticeId = [NSString stringWithFormat:@"%@",dict[@"id"]];
                    self.index = indexPath.row;
                    [g_server roomDeleteNotice:roomId noticeId:noticeId ToView:self];
                }];
        deleteAction.backgroundColor = [UIColor redColor];   // 删除按钮颜色

    return @[deleteAction,editAction];
    }
    return @[];
}


- (void)hideBigView {
    [self hideKeyBoard];
    self.bigView.hidden = YES;
    self.relLabel.userInteractionEnabled = YES;
    [self resetBigView];
}

- (void)hideKeyBoard {
    if ([self.name isFirstResponder]) {
        [self.name resignFirstResponder];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (self.isLimit) {
        if (self.limitLen <= 0) {
            self.limitLen = 15;
        }
        if(textView.text.length > self.limitLen && ![text isEqualToString:@""]){
            if (!self.isShow) {
                self.isShow = YES;
                [g_App showAlert:Localized(@"JX_InputLimit")];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    self.isShow = NO;
                });
            }
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    
    return YES;
}


- (void)textViewDidChange:(UITextView *)textView {
    
    int maxHeight = 66.f;
    
    CGRect frame = textView.frame;
    CGSize constraintSize = CGSizeMake(JX_SCREEN_WIDTH-80-INSETS*2, MAXFLOAT);
    CGSize size = [textView sizeThatFits:constraintSize];
    if (size.height >= maxHeight)
    {
        size.height = maxHeight;
        textView.scrollEnabled = YES;   // 允许滚动
    }
    else
    {
        textView.scrollEnabled = NO;    // 不允许滚动
    }
    
    textView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, size.height);
    self.baseView.frame = CGRectMake(40, JX_SCREEN_HEIGHT/4+35-size.height, JX_SCREEN_WIDTH-80, 162-35+size.height);
    self.topView.frame = CGRectMake(0, 118-35+size.height, self.baseView.frame.size.width, 40);

}

-(UITextView*)createTextField:(UIView*)parent default:(NSString*)s hint:(NSString*)hint{
    UITextView* p = [[UITextView alloc] initWithFrame:CGRectMake(0,INSETS,JX_SCREEN_WIDTH,HEIGHT)];
    p.delegate = self;
    p.autocorrectionType = UITextAutocorrectionTypeNo;
    p.autocapitalizationType = UITextAutocapitalizationTypeNone;
    p.enablesReturnKeyAutomatically = YES;
    p.scrollEnabled = NO;
    //    p.borderStyle = UITextBorderStyleNone;
    p.returnKeyType = UIReturnKeyDone;
    p.showsVerticalScrollIndicator = NO;
    p.showsHorizontalScrollIndicator = NO;
    //    p.clearButtonMode = UITextFieldViewModeAlways;
    p.textAlignment = NSTextAlignmentLeft;
    p.userInteractionEnabled = YES;
    p.backgroundColor = [UIColor whiteColor];
    p.text = s;
    //    p.placeholder = hint;
    //    p.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, HEIGHT-INSETS*2)];
    //    p.leftViewMode = UITextFieldViewModeAlways;
    p.font = g_factory.font16;
    [parent addSubview:p];
    return p;
}

-(JXLabel*)createLabel:(UIView*)parent default:(NSString*)s selector:(SEL)selector{
    JXLabel* p = [[JXLabel alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH/2,INSETS,JX_SCREEN_WIDTH/2 -20,HEIGHT-INSETS*2)];
    p.userInteractionEnabled = NO;
    p.text = s;
    p.font = g_factory.font14;
    p.textAlignment = NSTextAlignmentLeft;
    p.didTouch = selector;
    p.delegate = self;
    [parent addSubview:p];
    return p;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.view endEditing:YES];
    return YES;
}

- (void)onRelease {
    if([_name.text isEqualToString:@""]){
        [g_App showAlert:Localized(@"JX_AnnouncementNoNull")];
        return;
    }
    [self hideBigView];
    if (self.isEdit) {

        NSString *roomId = [NSString stringWithFormat:@"%@",self.dataArray[self.index][@"roomId"]];
        NSString *noticeId = [NSString stringWithFormat:@"%@",self.dataArray[self.index][@"id"]];
        [g_server updateNotice:roomId noticeId:noticeId noticeContent:self.name.text toView:self];
    }else {
        self.room.note = _name.text;
        [g_server updateRoomNotify:self.room toView:self];
    }
}


-(void)onSave{
    if (!self.isAdmin) {
        [g_App showAlert:Localized(@"JXRoomMemberVC_NotAdminCannotDoThis")];
        return;
    }
    self.isEdit = NO;
    self.name.text = nil;
    self.bigView.hidden = NO;
    self.relLabel.userInteractionEnabled = NO;
    [self.name becomeFirstResponder];
}

- (void)resetBigView {
    self.name.frame = CGRectMake(10, 64, self.baseView.frame.size.width - INSETS*2, 35.5);
    self.baseView.frame = CGRectMake(40, JX_SCREEN_HEIGHT/4-.5, JX_SCREEN_WIDTH-80, 162);
    self.topView.frame = CGRectMake(0, 118, self.baseView.frame.size.width, 40);
}

-(void)didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
    [_wait stop];
    if( [aDownload.action isEqualToString:act_roomDeleteNotice]){
        [self.dataArray removeObjectAtIndex:self.index];
        [self.tableView reloadData];
        self.value = [self.dataArray.firstObject objectForKey:@"text"];
        if (delegate && [self.delegate respondsToSelector:didSelect]) {
            [delegate performSelectorOnMainThread:didSelect withObject:self waitUntilDone:NO];
        }
    }
    if( [aDownload.action isEqualToString:act_roomSet]){
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        NSNumber *time = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
        [dict setObject:self.room.roomId forKey:@"roomId"];
        [dict setObject:self.room.roomId forKey:@"id"];
        [dict setObject:MY_USER_ID forKey:@"userId"];
        [dict setObject:self.name.text forKey:@"text"];
        [dict setObject:time forKey:@"time"];
        [dict setObject:MY_USER_NAME forKey:@"nickname"];
//        [self.dataArray insertObject:dict atIndex:0];
//        [self.tableView reloadData];
        [g_server getRoom:self.room.roomId toView:self];
        if (delegate && [self.delegate respondsToSelector:didSelect]) {
            [delegate performSelectorOnMainThread:didSelect withObject:self waitUntilDone:NO];
        }
    }
    if( [aDownload.action isEqualToString:act_roomGet]){
        [self.dataArray removeAllObjects];
        NSArray *arr = [dict objectForKey:@"notices"];
        [self.dataArray addObjectsFromArray:arr];
        [self.tableView reloadData];
    }
    if ([aDownload.action isEqualToString:act_updateNotice]) {
        [self.dataArray[self.index] setValue:self.name.text forKey:@"text"];
        self.value = self.name.text;
        [g_server showMsg:@"修改成功"];
        [self.tableView reloadData];
        if (delegate && [self.delegate respondsToSelector:didSelect]) {
            [delegate performSelectorOnMainThread:didSelect withObject:self waitUntilDone:NO];
        }
    }
}

-(int)didServerResultFailed:(JXConnection*)aDownload dict:(NSDictionary*)dict{
    [_wait stop];
    return show_error;
}

-(int)didServerConnectError:(JXConnection*)aDownload error:(NSError *)error{
    [_wait stop];
    return show_error;
}

-(void)didServerConnectStart:(JXConnection*)aDownload{
    [_wait start];
}


@end
