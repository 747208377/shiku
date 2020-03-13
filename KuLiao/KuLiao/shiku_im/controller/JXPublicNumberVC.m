//
//  JXPublicNumberVC.m
//  shiku_im
//
//  Created by p on 2018/6/4.
//  Copyright © 2018年 Reese. All rights reserved.
//

#import "JXPublicNumberVC.h"
#import "JXCell.h"
#import "JXChatViewController.h"
#import "JXSearchUserVC.h"
#import "JXTransferNoticeVC.h"

@interface JXPublicNumberVC ()
@property (nonatomic, strong) NSMutableArray *array;
@end

@implementation JXPublicNumberVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.heightHeader = JX_SCREEN_TOP;
    self.heightFooter = 0;
    self.isGotoBack   = YES;
    self.isShowHeaderPull = NO;
    self.isShowFooterPull = NO;
    _array = [NSMutableArray array];
    self.title = Localized(@"JX_PublicNumber");
    [self createHeadAndFoot];
    [self setupSearchPublicNumber];

    [self getServerData];
}

- (void)setupSearchPublicNumber {
//    UIButton *moreBtn = [UIFactory createButtonWithImage:@"search_publicNumber"
//                                          highlight:nil
//                                             target:self
//                                           selector:@selector(searchPublicNumber)];
//    moreBtn.custom_acceptEventInterval = 1.0f;
//    moreBtn.frame = CGRectMake(JX_SCREEN_WIDTH - 40, JX_SCREEN_TOP - 34, 24, 24);
//    [self.tableHeader addSubview:moreBtn];
}


//- (void)searchPublicNumber {
//    JXSearchUserVC *searchUserVC = [JXSearchUserVC alloc];
//    searchUserVC.type = JXSearchTypePublicNumber;
//    searchUserVC = [searchUserVC init];
//    [g_navigation pushViewController:searchUserVC animated:YES];
//}

- (void)getServerData {
    
    self.array = [[JXUserObject sharedInstance] fetchSystemUser];

    [self.tableView reloadData];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _array.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JXUserObject *user = _array[indexPath.row];
    
    
    
    JXCell *cell=nil;
    NSString* cellName = @"JXCell";
    cell = [tableView dequeueReusableCellWithIdentifier:cellName];
    
    if(cell==nil){
        
        cell = [[JXCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellName];
        [_table addToPool:cell];
        
    }
    
    cell.title = user.userNickname;
    
    cell.index = (int)indexPath.row;
    cell.delegate = self;
//    cell.didTouch = @selector(onHeadImage:);
    [cell setForTimeLabel:[TimeUtil formatDate:user.timeCreate format:@"MM-dd HH:mm"]];
    cell.timeLabel.frame = CGRectMake(JX_SCREEN_WIDTH - 120-20, 9, 115, 20);
    cell.userId = user.userId;
    [cell.lbTitle setText:cell.title];
    
    cell.dataObj = user;
    //    cell.headImageView.tag = (int)indexPath.row;
    //    cell.headImageView.delegate = cell.delegate;
    //    cell.headImageView.didTouch = cell.didTouch;
    
    cell.isSmall = YES;
    [cell headImageViewImageWithUserId:nil roomId:nil];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    JXCell* cell = (JXCell*)[tableView cellForRowAtIndexPath:indexPath];
    
    cell.selected = NO;
    JXUserObject *user = _array[indexPath.row];
    
    if ([user.userId intValue] == [SHIKU_TRANSFER intValue]) {
        JXTransferNoticeVC *noticeVC = [[JXTransferNoticeVC alloc] init];
        [g_navigation pushViewController:noticeVC animated:YES];
        return;
    }
    
    JXChatViewController *sendView=[JXChatViewController alloc];
    
    sendView.scrollLine = 0;
    sendView.title = user.userNickname;
    sendView.chatPerson = user;
    sendView = [sendView init];
    [g_navigation pushViewController:sendView animated:YES];
    sendView.view.hidden = NO;
}



// 进入编辑模式，按下出现的编辑按钮后,进行删除操作
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        JXUserObject *user = _array[indexPath.row];
        [_array removeObject:user];
        [_table deleteRow:(int)indexPath.row section:(int)indexPath.section];
        [g_server delAttention:user.userId toView:self];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    JXUserObject *user = _array[indexPath.row];

    if ([user.userId intValue] == 10000) {
        return NO;
    }
    return YES;
}

// 定义编辑样式
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

// 修改编辑按钮文字
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return Localized(@"JX_Delete");
}

//服务器返回数据
-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
    
    if ([aDownload.action isEqualToString:act_AttentionDel]) {
        [_wait stop];
    }
}



-(int) didServerResultFailed:(JXConnection*)aDownload dict:(NSDictionary*)dict{
    [_wait hide];
    return show_error;
}

-(int) didServerConnectError:(JXConnection*)aDownload error:(NSError *)error{//error为空时，代表超时
    [_wait hide];
    return show_error;
}

-(void) didServerConnectStart:(JXConnection*)aDownload{
    [_wait start];
}


@end
