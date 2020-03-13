//
//  JXCourseListVC.m
//  shiku_im
//
//  Created by p on 2017/10/20.
//  Copyright © 2017年 Reese. All rights reserved.
//

#import "JXCourseListVC.h"
#import "JXCourseListCell.h"
#import "JXChatViewController.h"
#import "JXRelayVC.h"

@interface JXCourseListVC ()<JXRelayVCDelegate>

@property (nonatomic, strong) NSMutableArray *array;
@property (nonatomic, assign) NSInteger selectIndex;
@property (nonatomic, assign) NSInteger editIndex;
@property (nonatomic, assign) BOOL isMultiselect;
@property (nonatomic, strong) NSMutableArray *selArray;
@property (nonatomic, strong) NSMutableArray *selCourseIds;
@property (nonatomic, strong) NSMutableArray *allCourseArray;
@property (nonatomic, strong) UIButton *sendBtn;
@property (nonatomic, assign) int sendIndex;
@property (nonatomic, strong) ATMHud *chatWait;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation JXCourseListVC

- (void)dealloc {
    [g_notify removeObserver:self name:kUpdateCourseList object:nil];
    [_timer invalidate];
    _timer = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.heightHeader = JX_SCREEN_TOP;
    self.heightFooter = 0;
    self.isGotoBack = YES;
    //self.view.frame = CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT-JX_SCREEN_BOTTOM);
    [self createHeadAndFoot];
    
    self.title = Localized(@"JX_CourseList");
    _array = [NSMutableArray array];
    _selArray = [NSMutableArray array];
    _selCourseIds = [NSMutableArray array];
    _allCourseArray = [NSMutableArray array];
    _chatWait = [[ATMHud alloc] init];
    
    JXLabel *label = [[JXLabel alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH -90, JX_SCREEN_TOP - 34, 80, 25)];
    label.delegate = self;
    label.didTouch = @selector(multiselect:);
    label.text = Localized(@"JX_Multiselect");
    label.font = g_factory.font16;
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentRight;
    [self.tableHeader addSubview:label];
    self.isMultiselect = NO;
    
    _sendBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, JX_SCREEN_HEIGHT - 48, JX_SCREEN_WIDTH, 48)];
    _sendBtn.backgroundColor = THEMECOLOR;
    [_sendBtn setTitle:Localized(@"JX_Send") forState:UIControlStateNormal];
    [_sendBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _sendBtn.titleLabel.font = g_factory.font15;
    [_sendBtn addTarget:self action:@selector(sendCourseAction) forControlEvents:UIControlEventTouchUpInside];
    _sendBtn.hidden = YES;
    [self.view addSubview:_sendBtn];
    
    [g_notify addObserver:self selector:@selector(updateCourseList) name:kUpdateCourseList object:nil];
    [self getServerData];
}

- (void)updateCourseList {
    [_table reloadData];
}

- (void)multiselect:(JXLabel *)label {
    if ([label.text isEqualToString:Localized(@"JX_Cencal")]) {
        label.text = Localized(@"JX_Multiselect");
        self.isMultiselect = NO;
        _sendBtn.hidden = YES;
        [_table setFrame:CGRectMake(_table.frame.origin.x, _table.frame.origin.y, _table.frame.size.width, _table.frame.size.height + 48)];
        [self.selArray removeAllObjects];
        [self.selCourseIds removeAllObjects];
    }else {
        label.text = Localized(@"JX_Cencal");
        self.isMultiselect = YES;
        _sendBtn.hidden = NO;
        [_table setFrame:CGRectMake(_table.frame.origin.x, _table.frame.origin.y, _table.frame.size.width, _table.frame.size.height - 48)];
    }
    [_table reloadData];
}

- (void)sendCourseAction {
    
    NSString *courseId = self.selCourseIds.firstObject;
    [_chatWait start:Localized(@"JX_Loading")];
    [g_server userCourseGetWithCourseId:courseId toView:self];
    
}

-(void)getServerData{
    [g_server userCourseList:self];
}

#pragma mark   ---------tableView协议----------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSString* cellName = [NSString stringWithFormat:@"courseListCell_%ld",indexPath.row];
    JXCourseListCell *courseListCell = [tableView dequeueReusableCellWithIdentifier:cellName];
    if (!courseListCell) {
        courseListCell = [[JXCourseListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellName];
    }
    courseListCell.vc = self;
    courseListCell.indexNum = indexPath.row;
    courseListCell.isMultiselect = self.isMultiselect;
    NSDictionary *dict = _array[indexPath.row];
    [courseListCell setData:dict];
    
    courseListCell.selectionStyle = UITableViewCellSelectionStyleNone;
    return courseListCell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return _array.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    if (self.isMultiselect) {
        
        JXCourseListCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        NSInteger num = [self getSelNum:[cell.multiselectBtn.titleLabel.text integerValue] indexNum:indexPath.row];
        if (num > 0) {
            [cell.multiselectBtn setTitle:[NSString stringWithFormat:@"%ld",num] forState:UIControlStateNormal];
        }else {
            cell.multiselectBtn.titleLabel.text = @"";
            [cell.multiselectBtn setTitle:@"" forState:UIControlStateNormal];
        }
        
        return;
    }
    
    NSDictionary *dict = _array[indexPath.row];
    self.selectIndex = indexPath.row;
    [g_server userCourseGetWithCourseId:dict[@"courseId"] toView:self];
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return YES;
}
- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.editIndex = indexPath.row;
    UITableViewRowAction *deleteBtn = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:Localized(@"JX_Delete") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        NSDictionary *dict = _array[indexPath.row];
        [g_server userCourseDeleteWithCourseId:dict[@"courseId"] toView:self];
        [_array removeObject:dict];
        
    }];
    
    UITableViewRowAction *editBtn = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:Localized(@"JX_ModifyName") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:Localized(@"JX_CourseName") message:nil delegate:self cancelButtonTitle:Localized(@"JX_Cencal") otherButtonTitles:Localized(@"JX_Confirm"), nil];
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alertView show];
    }];
    
    return @[deleteBtn,editBtn];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        UITextField *tf = [alertView textFieldAtIndex:0];
        NSMutableDictionary *dict = _array[self.editIndex];
        if (tf.text.length <= 0) {
            [g_App showAlert:Localized(@"JX_InputCourseName")];
            return;
        }
        
        [g_server userCourseUpdateWithCourseId:dict[@"courseId"] MessageIds:nil CourseName:tf.text CourseMessageId:nil toView:self];
        dict[@"courseName"] = tf.text;
    }
}

- (NSInteger)getSelNum:(NSInteger)num indexNum:(NSInteger)indexNum{
    if (num > 0) {
        [self.selArray removeObject:[NSNumber numberWithInteger:num]];
        NSDictionary *dict = _array[indexNum];
        [self.selCourseIds removeObject:dict[@"courseId"]];
        return 0;
    }else {
        NSInteger index = 0;
        for (NSInteger i = 0; i < self.selArray.count; i ++) {
            NSInteger m = [self.selArray[i] integerValue];
            if (m != i + 1) {
                index = i + 1;
                break;
            }
        }
        
        if (index == 0) {
            [self.selArray addObject:[NSNumber numberWithInteger:self.selArray.count + 1]];
            NSDictionary *dict = _array[indexNum];
            [self.selCourseIds addObject:dict[@"courseId"]];
            return self.selArray.count;
        }else {
            [self.selArray insertObject:[NSNumber numberWithInteger:index] atIndex:index - 1];
            
            NSDictionary *dict = _array[indexNum];
            [self.selCourseIds insertObject:dict[@"courseId"] atIndex:index - 1];
            return index;
        }
    }
}

- (void)sendCourse:(NSTimer *) timer{
    
    JXMsgAndUserObject *obj = timer.userInfo;
    BOOL isRoom;
    if ([obj.user.roomFlag intValue] > 0  || obj.user.roomId.length > 0) {
        isRoom = YES;
    }else {
        isRoom = NO;
    }
    
    self.sendIndex ++;
    //    [_chatWait start:[NSString stringWithFormat:@"正在发送：%d/%ld",self.sendIndex,_array.count] inView:g_window];
    [_chatWait setCaption:[NSString stringWithFormat:@"%@：%d/%ld",Localized(@"JX_SendNow"),self.sendIndex,_allCourseArray.count]];
    [_chatWait update];
    
    JXMessageObject *msg= _allCourseArray[self.sendIndex - 1];
    msg.messageId = nil;
    msg.timeSend     = [NSDate date];
    msg.fromId = nil;
    msg.fromUserId   = MY_USER_ID;
    if(isRoom){
        msg.toUserId = obj.user.userId;
        msg.isGroup = YES;
        msg.fromUserName = g_myself.userNickname;
    }
    else{
        msg.toUserId     = obj.user.userId;
        msg.isGroup = NO;
    }
    //        msg.content      = relayMsg.content;
    //        msg.type         = relayMsg.type;
    msg.isSend       = [NSNumber numberWithInt:transfer_status_ing];
    msg.isRead       = [NSNumber numberWithBool:NO];
    msg.isReadDel    = [NSNumber numberWithInt:NO];
    //发往哪里
    if (isRoom) {
        [msg insert:obj.user.userId];
        [g_xmpp sendMessage:msg roomName:obj.user.userId];//发送消息
    }else {
        [msg insert:nil];
        [g_xmpp sendMessage:msg roomName:nil];//发送消息
    }
    
    if (_allCourseArray.count == self.sendIndex) {
        [_chatWait stop];
        [_timer invalidate];
        _timer = nil;
        [JXMyTools showTipView:Localized(@"JXAlert_SendOK")];
    }
}

- (void)relay:(JXRelayVC *)relayVC MsgAndUserObject:(JXMsgAndUserObject *)obj {
    
    [_chatWait start:[NSString stringWithFormat:@"%@：1/%ld",Localized(@"JX_SendNow"),_allCourseArray.count] inView:g_window];
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(sendCourse:) userInfo:obj repeats:YES];
}

-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{

    if ([aDownload.action isEqualToString:act_userCourseList]) {
        _array = [array1 mutableCopy];
        [self.tableView reloadData];
    }
    
    if ([aDownload.action isEqualToString:act_userCourseGet]) {
        
        NSMutableArray *array = [NSMutableArray array];
        for (NSInteger i = 0; i < array1.count; i ++) {
            NSDictionary *dict = array1[i];
            SBJsonParser * parser = [[SBJsonParser alloc] init] ;
            id content = [parser objectWithString:dict[@"message"]];
            JXMessageObject *msg = [[JXMessageObject alloc] init];
            
            [msg fromXmlDict:content];
            msg.messageId = content[@"messageId"];
            msg.isNotUpdateHeight = YES;
            
            if(![msg isVisible] && [msg.type intValue]!=kWCMessageTypeIsRead)
                continue;
            [dict setValue:msg forKey:@"message"];
            [array addObject:dict];
        }
        
        if (self.isMultiselect) {
            
            for (NSDictionary *dict in array) {
                [_allCourseArray addObject:dict[@"message"]];
            }
            
            [self.selCourseIds removeObjectAtIndex:0];
            if (self.selCourseIds.count > 0) {
                NSString *courseId = self.selCourseIds.firstObject;
                [g_server userCourseGetWithCourseId:courseId toView:self];
            }else {
                [_chatWait stop];
                JXRelayVC *vc = [[JXRelayVC alloc] init];
                vc.isCourse = YES;
                vc.relayDelegate = self;
//                [g_window addSubview:vc.view];
                [g_navigation pushViewController:vc animated:YES];
            }
            
        }else {
            JXChatViewController *sendView=[JXChatViewController alloc];
            NSDictionary *dict = _array[self.selectIndex];
            sendView.title = Localized(@"JX_CourseDetails");
            sendView.courseArray = array;
            sendView.courseId = dict[@"courseId"];
            sendView = [sendView init];
//            [g_App.window addSubview:sendView.view];
            [g_navigation pushViewController:sendView animated:YES];
        }
    }
    
    if ([aDownload.action isEqualToString:act_userCourseUpdate]) {
        [JXMyTools showTipView:Localized(@"JXAlert_UpdateOK")];
        [self.tableView reloadData];
    }
    
    if ([aDownload.action isEqualToString:act_userCourseDelete]) {
        [JXMyTools showTipView:Localized(@"JXAlert_DeleteOK")];
        [self.tableView reloadData];
    }
    
    [_wait stop];
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
