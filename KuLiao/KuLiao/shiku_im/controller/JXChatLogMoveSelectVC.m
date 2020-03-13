//
//  JXChatLogMoveSelectVC.m
//  shiku_im
//
//  Created by p on 2019/6/5.
//  Copyright © 2019年 Reese. All rights reserved.
//

#import "JXChatLogMoveSelectVC.h"
#import "JXCell.h"
#import "QCheckBox.h"
#import "JXChatLogQRCodeVC.h"

@interface JXChatLogMoveSelectVC ()
@property (nonatomic, strong) NSMutableArray *array;
@property (nonatomic, strong) NSSet * existSet;
@property (nonatomic, strong) NSMutableArray *selUserIdArray;
@property (nonatomic, strong) NSMutableArray *selUserNameArray;
@property (nonatomic, strong) UIButton *nextBtn;
@property (nonatomic, strong) NSMutableArray *checkBoxArr;

@end

@implementation JXChatLogMoveSelectVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.heightHeader = JX_SCREEN_TOP;
    self.heightFooter = JX_SCREEN_BOTTOM;
    self.isGotoBack   = YES;
    //self.view.frame = g_window.bounds;
    self.isShowFooterPull = NO;
    [self createHeadAndFoot];
    
    _array = [NSMutableArray array];
    _selUserIdArray = [NSMutableArray array];
    _selUserNameArray = [NSMutableArray array];
    _checkBoxArr = [NSMutableArray array];
    self.title = Localized(@"JX_ChooseAChat");
    
    UIButton *allSelect = [UIButton buttonWithType:UIButtonTypeSystem];
    [allSelect setTitle:Localized(@"JX_CheckAll") forState:UIControlStateNormal];
    [allSelect setTitle:Localized(@"JX_Cencal") forState:UIControlStateSelected];
    [allSelect setTitleColor:THEMECOLOR forState:UIControlStateNormal];
    [allSelect setTitleColor:THEMECOLOR forState:UIControlStateSelected];
    allSelect.tintColor = [UIColor clearColor];
    allSelect.titleLabel.font = [UIFont systemFontOfSize:15.0];
    allSelect.frame = CGRectMake(0, 0, 70, 49);
    [allSelect addTarget:self action:@selector(allSelect:) forControlEvents:UIControlEventTouchUpInside];
    [self.tableFooter addSubview:allSelect];
    
    self.nextBtn = [[UIButton alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH - 70, 0, 70, 49)];
    self.nextBtn.titleLabel.font = [UIFont systemFontOfSize:15.0];
    [self.nextBtn setTitle:Localized(@"JX_Confirm") forState:UIControlStateNormal];
    [self.nextBtn setTitleColor:THEMECOLOR forState:UIControlStateNormal];
    [self.nextBtn addTarget:self action:@selector(nextBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.tableFooter addSubview:self.nextBtn];
    
    
    [self getArrayData];
    
}
- (void)allSelect:(UIButton *)btn {
    btn.selected = !btn.selected;
    
    [_selUserIdArray removeAllObjects];
    [_selUserNameArray removeAllObjects];
    if (btn.selected) {
        for (JXMsgAndUserObject *userObj in _array) {
            [_selUserIdArray addObject:userObj.user.userId];
            [_selUserNameArray addObject:userObj.user.userNickname];
        }
    }
    
    [_checkBoxArr removeAllObjects];
    [self.tableView reloadData];
}

- (void)nextBtnAction:(UIButton *)btn {
    
    if (!_selUserIdArray.count) {
        [g_App showAlert:Localized(@"JX_SelectGroupUsers")];
        return;
    }
    
    JXChatLogQRCodeVC *vc = [[JXChatLogQRCodeVC alloc] init];
    vc.selUserIdArray = [_selUserIdArray copy];
    [g_navigation pushViewController:vc animated:YES];
    
    [self actionQuit];
}
- (void)didSelectedCheckBox:(QCheckBox *)checkbox checked:(BOOL)checked{
    JXMsgAndUserObject *userObj = _array[checkbox.tag % 10000];
    
    if(checked){
        BOOL flag = NO;
        for (NSInteger i = 0; i < _selUserIdArray.count; i ++) {
            NSString *selUserId = _selUserIdArray[i];
            if ([selUserId isEqualToString:userObj.user.userId]) {
                flag = YES;
                return;
            }
        }
        [_selUserIdArray addObject:userObj.user.userId];
        [_selUserNameArray addObject:userObj.user.userNickname];
    }
    else{
        [_selUserIdArray removeObject:userObj.user.userId];
        [_selUserNameArray removeObject:userObj.user.userNickname];
    }

}

-(void)getArrayData{
    _array=[[JXMessageObject sharedInstance] fetchRecentChat];
    
}

#pragma mark   ---------tableView协议----------------

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _array.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    
    JXCell *cell=nil;
    NSString* cellName = [NSString stringWithFormat:@"selVC_%d",(int)indexPath.row];
    //    cell = [tableView dequeueReusableCellWithIdentifier:cellName];
    //    QCheckBox* btn;
    //    if (!cell) {
    cell = [[JXCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellName];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    QCheckBox* btn = [[QCheckBox alloc] initWithDelegate:self];
    btn.frame = CGRectMake(20, 15, 25, 25);
    [cell addSubview:btn];
    //    }
    
    JXMsgAndUserObject *userObj=_array[indexPath.row];
    
    btn.tag = indexPath.section * 10000 + indexPath.row;
    BOOL flag = NO;
    for (NSInteger i = 0; i < _selUserIdArray.count; i ++) {
        NSString *selUserId = _selUserIdArray [i];
        if ([userObj.user.userId isEqualToString:selUserId]) {
            flag = YES;
            break;
        }
    }
    btn.checked = flag;
    
    [_checkBoxArr addObject:btn];
    //            cell = [[JXCell alloc] init];
    [_table addToPool:cell];
    cell.title = userObj.user.userNickname;
    //            cell.subtitle = user.userId;
    cell.bottomTitle = [TimeUtil formatDate:userObj.user.timeCreate format:@"MM-dd HH:mm"];
    cell.userId = userObj.user.userId;
    cell.isSmall = YES;
    [cell headImageViewImageWithUserId:nil roomId:nil];
    
    cell.headImageView.frame = CGRectMake(cell.headImageView.frame.origin.x + 50, cell.headImageView.frame.origin.y, cell.headImageView.frame.size.width, cell.headImageView.frame.size.height);
    cell.lbTitle.frame = CGRectMake(cell.lbTitle.frame.origin.x + 50, cell.lbTitle.frame.origin.y, cell.lbTitle.frame.size.width, cell.lbTitle.frame.size.height);
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    QCheckBox *checkBox = nil;
    for (NSInteger i = 0; i < _checkBoxArr.count; i ++) {
        QCheckBox *btn = _checkBoxArr[i];
        if (btn.tag / 10000 == indexPath.section && btn.tag % 10000 == indexPath.row) {
            checkBox = btn;
            break;
        }
    }
    checkBox.selected = !checkBox.selected;
    [self didSelectedCheckBox:checkBox checked:checkBox.selected];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
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
