//
//  JXGroupMessagesSelectFriendVC.m
//  shiku_im
//
//  Created by p on 2018/5/25.
//  Copyright © 2018年 Reese. All rights reserved.
//

#import "JXGroupMessagesSelectFriendVC.h"
#import "JXCell.h"
#import "UIImage+Color.h"
#import "QCheckBox.h"
#import "JXChatViewController.h"
#import "JXSelectLabelsVC.h"
#import "JXLabelObject.h"
#import "BMChineseSort.h"

@interface JXGroupMessagesSelectFriendVC () <UITextFieldDelegate, JXSelectLabelsVCDelegate>
@property (nonatomic, strong) NSMutableArray *array;
@property (nonatomic, strong) UITextField *seekTextField;
@property (nonatomic, strong) NSMutableArray *searchArray;
@property (nonatomic, strong) NSSet * existSet;
@property (nonatomic, strong) NSMutableArray *selUserIdArray;
@property (nonatomic, strong) NSMutableArray *selUserNameArray;
@property (nonatomic, strong) UIButton *nextBtn;

@property (nonatomic, strong) UIView *tableHeadView;
@property (nonatomic, strong) UILabel *selectLabelTip;
@property (nonatomic, strong) UILabel *selectLabels;
@property (nonatomic, strong) NSMutableArray *selLabelsArr;
//排序后的出现过的拼音首字母数组
@property(nonatomic,strong)NSMutableArray *indexArray;
//排序好的结果数组
@property(nonatomic,strong)NSMutableArray *letterResultArr;
@property (nonatomic, strong) NSMutableArray *checkBoxArr;

@end

@implementation JXGroupMessagesSelectFriendVC

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
    _searchArray = [NSMutableArray array];
    _selUserIdArray = [NSMutableArray array];
    _selUserNameArray = [NSMutableArray array];
    _selLabelsArr = [NSMutableArray array];
    _checkBoxArr = [NSMutableArray array];
    self.title = Localized(@"JX_SelectReceiver");
    
    UIButton *allSelect = [UIButton buttonWithType:UIButtonTypeSystem];
    [allSelect setTitle:Localized(@"JX_CheckAll") forState:UIControlStateNormal];
    [allSelect setTitle:Localized(@"JX_Cencal") forState:UIControlStateSelected];
    [allSelect setTitleColor:THESIMPLESTYLE ? [UIColor blackColor] : [UIColor whiteColor] forState:UIControlStateNormal];
//    [allSelect setBackgroundImage:[UIImage createImageWithColor:[UIColor clearColor]] forState:UIControlStateNormal];
//    [allSelect setBackgroundImage:[UIImage createImageWithColor:[UIColor clearColor]] forState:UIControlStateSelected];
    allSelect.tintColor = [UIColor clearColor];
    allSelect.frame = CGRectMake(JX_SCREEN_WIDTH - 70, JX_SCREEN_TOP - 34, 70, 24);
    [allSelect addTarget:self action:@selector(allSelect:) forControlEvents:UIControlEventTouchUpInside];
    [self.tableHeader addSubview:allSelect];
    
    self.nextBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.tableFooter.frame.size.width, 48)];
    self.nextBtn.titleLabel.font = [UIFont systemFontOfSize:15.0];
    [self.nextBtn setTitle:Localized(@"JX_NextStep") forState:UIControlStateNormal];
    [self.nextBtn setTitleColor:THEMECOLOR forState:UIControlStateNormal];
    [self.nextBtn addTarget:self action:@selector(nextBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.tableFooter addSubview:self.nextBtn];
    
    
    //搜索输入框
    _tableHeadView = [[UIView alloc] initWithFrame:CGRectMake(0, JX_SCREEN_TOP, JX_SCREEN_WIDTH, 50)];
//    backView.backgroundColor = HEXCOLOR(0xf0f0f0);
    [self.view addSubview:_tableHeadView];
    
//    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(backView.frame.size.width-5-45, 5, 45, 30)];
//    [cancelBtn setTitle:Localized(@"JX_Cencal") forState:UIControlStateNormal];
//    [cancelBtn setTitleColor:THEMECOLOR forState:UIControlStateNormal];
//    [cancelBtn addTarget:self action:@selector(cancelBtnAction) forControlEvents:UIControlEventTouchUpInside];
//    cancelBtn.titleLabel.font = SYSFONT(14);
//    [backView addSubview:cancelBtn];
    
    
    _seekTextField = [[UITextField alloc] initWithFrame:CGRectMake(15, 10, _tableHeadView.frame.size.width - 30, 30)];
    _seekTextField.placeholder = Localized(@"JX_EnterKeyword");
    _seekTextField.textColor = [UIColor blackColor];
    [_seekTextField setFont:SYSFONT(14)];
    _seekTextField.backgroundColor = HEXCOLOR(0xf0f0f0);
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_search"]];
    UIView *leftView = [[UIView alloc ]initWithFrame:CGRectMake(0, 0, 30, 30)];
    //    imageView.center = CGPointMake(leftView.frame.size.width/2, leftView.frame.size.height/2);
    imageView.center = leftView.center;
    [leftView addSubview:imageView];
    _seekTextField.leftView = leftView;
    _seekTextField.leftViewMode = UITextFieldViewModeAlways;
    _seekTextField.borderStyle = UITextBorderStyleNone;
    _seekTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _seekTextField.delegate = self;
    _seekTextField.returnKeyType = UIReturnKeyGoogle;
    [_tableHeadView addSubview:_seekTextField];
    [_seekTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 49.5, JX_SCREEN_WIDTH, .5)];
    lineView.backgroundColor = HEXCOLOR(0xdcdcdc);
    [_tableHeadView addSubview:lineView];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(lineView.frame), JX_SCREEN_WIDTH, 54)];
    [btn addTarget:self action:@selector(selectLabels:) forControlEvents:UIControlEventTouchUpInside];
    [_tableHeadView addSubview:btn];
    
    _selectLabelTip = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, btn.frame.size.width, btn.frame.size.height)];
    _selectLabelTip.font = [UIFont systemFontOfSize:16.0];
    _selectLabelTip.text = Localized(@"JX_SelectTagGroup");
    [btn addSubview:_selectLabelTip];
    
    _selectLabels = [[UILabel alloc] initWithFrame:CGRectMake(15, CGRectGetMaxY(_selectLabelTip.frame), btn.frame.size.width, btn.frame.size.height - CGRectGetMaxY(_selectLabelTip.frame))];
    _selectLabels.font = [UIFont systemFontOfSize:15.0];
    _selectLabels.text = @"[标签1，标签2]";
    _selectLabels.textColor = [UIColor lightGrayColor];
    [btn addSubview:_selectLabels];
    
    lineView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(btn.frame) + 4.5, JX_SCREEN_WIDTH, .5)];
    lineView.backgroundColor = HEXCOLOR(0xdcdcdc);
    [_tableHeadView addSubview:lineView];
    
    _tableHeadView.frame = CGRectMake(_tableHeadView.frame.origin.x, _tableHeadView.frame.origin.y, _tableHeadView.frame.size.width, CGRectGetMaxY(lineView.frame));
    self.tableView.tableHeaderView = _tableHeadView;
    
    [self getArrayData];
    
}

- (void)selectLabels:(UIButton *)btn {
    
    JXSelectLabelsVC *vc = [[JXSelectLabelsVC alloc] init];
    vc.delegate = self;
    vc.selLabels = [NSMutableArray arrayWithArray:_selLabelsArr];
    [g_navigation pushViewController:vc animated:YES];
}

- (void)selectLabelsVC:(JXSelectLabelsVC *)selectLabelsVC selectLabelsArray:(NSMutableArray *)array {
    _selLabelsArr = [NSMutableArray arrayWithArray:array];
    
    NSMutableString *nameStr = [NSMutableString string];
    for (NSInteger i = 0; i < array.count; i ++) {
        JXLabelObject *labelObj = array[i];
        if (i == 0) {
            [nameStr appendFormat:@"[\"%@",labelObj.groupName];
        }else if (i == array.count - 1) {
            [nameStr appendFormat:@",%@\"]",labelObj.groupName];
        }else {
            [nameStr appendFormat:@",%@",labelObj.groupName];
        }
        if (array.count == 1) {
            [nameStr appendString:@"\"]"];
        }
    }
    
    self.selectLabels.text = nameStr;
    if (nameStr.length > 0) {
        self.selectLabelTip.frame = CGRectMake(self.selectLabelTip.frame.origin.x, self.selectLabelTip.frame.origin.y, self.selectLabelTip.frame.size.width, 27);
        self.selectLabels.frame = CGRectMake(self.selectLabels.frame.origin.x, CGRectGetMaxY(_selectLabelTip.frame), self.selectLabels.frame.size.width, 27);
    }else {
        self.selectLabelTip.frame = CGRectMake(self.selectLabelTip.frame.origin.x, self.selectLabelTip.frame.origin.y, self.selectLabelTip.frame.size.width, 54);
        self.selectLabels.frame = CGRectMake(self.selectLabels.frame.origin.x, CGRectGetMaxY(_selectLabelTip.frame), self.selectLabels.frame.size.width, 0);
    }
}

- (void)allSelect:(UIButton *)btn {
    btn.selected = !btn.selected;
    
    [_selUserIdArray removeAllObjects];
    [_selUserNameArray removeAllObjects];
    if (btn.selected) {
        NSArray *array;
        if (_seekTextField.text.length > 0) {
            array = _searchArray;
        }else {
            array = _array;
        }
        for (JXUserObject *user in array) {
            [_selUserIdArray addObject:user.userId];
            [_selUserNameArray addObject:user.userNickname];
        }
    }
    
    [self.nextBtn setTitle:[NSString stringWithFormat:@"%@(%ld)",Localized(@"JX_NextStep"),_selUserIdArray.count] forState:UIControlStateNormal];
    [_checkBoxArr removeAllObjects];
    [self.tableView reloadData];
}

- (void)nextBtnAction:(UIButton *)btn {
    
    NSMutableArray *selUserIdArray = [NSMutableArray array];
    NSMutableArray *selUserNameArray = [NSMutableArray array];
    
    [selUserIdArray addObjectsFromArray:_selUserIdArray];
    [selUserNameArray addObjectsFromArray:_selUserNameArray];
    for (NSInteger i = 0; i < self.selLabelsArr.count; i ++) {
        JXLabelObject *labelObj = self.selLabelsArr[i];
        NSArray *labelUserIds = [labelObj.userIdList componentsSeparatedByString:@","];
        for (NSInteger j = 0; j < labelUserIds.count; j ++) {
            NSString *labelUserId = labelUserIds[j];
            NSString *labelUserName = [JXUserObject getUserNameWithUserId:labelUserId];
            BOOL flag = NO;
            NSMutableArray *array = [NSMutableArray arrayWithArray:selUserIdArray];
            for (NSInteger m = 0; m < array.count; m ++) {
                NSString *selUserId = array[m];
                if ([labelUserId isEqualToString:selUserId]) {
                    flag = YES;
                    break;
                }
            }
            
            if (!flag) {
                [selUserIdArray addObject:labelUserId];
                [selUserNameArray addObject:labelUserName];
            }
        }
    }
    
    if (!selUserIdArray.count) {
        [g_App showAlert:Localized(@"JX_SelectGroupUsers")];
        return;
    }
    
    JXChatViewController *vc = [[JXChatViewController alloc] init];
    vc.userIds = selUserIdArray;
    vc.userNames = selUserNameArray;
    vc.isGroupMessages = YES;
    [g_navigation pushViewController:vc animated:YES];
}

- (void) cancelBtnAction {
    _seekTextField.text = nil;
    [_seekTextField resignFirstResponder];
    [self getArrayData];
}

- (void)didSelectedCheckBox:(QCheckBox *)checkbox checked:(BOOL)checked{
    JXUserObject *user;
    if (_seekTextField.text.length > 0) {
        user = _searchArray[checkbox.tag % 10000];
    }else{
        user = [[self.letterResultArr objectAtIndex:checkbox.tag / 10000] objectAtIndex:checkbox.tag % 10000];
    }
    
    if(checked){
        BOOL flag = NO;
        for (NSInteger i = 0; i < _selUserIdArray.count; i ++) {
            NSString *selUserId = _selUserIdArray[i];
            if ([selUserId isEqualToString:user.userId]) {
                flag = YES;
                return;
            }
        }
        [_selUserIdArray addObject:user.userId];
        [_selUserNameArray addObject:user.userNickname];
    }
    else{
        [_selUserIdArray removeObject:user.userId];
        [_selUserNameArray removeObject:user.userNickname];
    }
    if (_selUserIdArray.count <= 0) {
        [self.nextBtn setTitle:[NSString stringWithFormat:@"%@",Localized(@"JX_NextStep")] forState:UIControlStateNormal];
    }else {
        [self.nextBtn setTitle:[NSString stringWithFormat:@"%@(%ld)",Localized(@"JX_NextStep"),_selUserIdArray.count] forState:UIControlStateNormal];
    }
}

- (void) textFieldDidChange:(UITextField *)textField {
    
    if (textField.text.length <= 0) {
        [self getArrayData];
        return;
    }
    
    [_searchArray removeAllObjects];

    for (NSInteger i = 0; i < _array.count; i ++) {
        JXUserObject * user = _array[i];
        NSString *userStr = [user.userNickname lowercaseString];
        NSString *textStr = [textField.text lowercaseString];
        if ([userStr rangeOfString:textStr].location != NSNotFound) {
            [_searchArray addObject:user];
        }
    }
    
    [_checkBoxArr removeAllObjects];
    [self.tableView reloadData];
}

-(void)getArrayData{
    _array=[[JXUserObject sharedInstance] fetchAllUserFromLocal];
    //选择拼音 转换的 方法
    BMChineseSortSetting.share.sortMode = 2; // 1或2
    //排序 Person对象
    [BMChineseSort sortAndGroup:_array key:@"userNickname" finish:^(bool isSuccess, NSMutableArray *unGroupArr, NSMutableArray *sectionTitleArr, NSMutableArray<NSMutableArray *> *sortedObjArr) {
        if (isSuccess) {
            self.indexArray = sectionTitleArr;
            self.letterResultArr = sortedObjArr;
            [_checkBoxArr removeAllObjects];
            [self.tableView reloadData];
        }
    }];

//    //根据Person对象的 name 属性 按中文 对 Person数组 排序
//    self.indexArray = [BMChineseSort IndexWithArray:_array Key:@"userNickname"];
//    self.letterResultArr = [BMChineseSort sortObjectArray:_array Key:@"userNickname"];
//    [self.tableView reloadData];
}

#pragma mark   ---------tableView协议----------------
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_seekTextField.text.length > 0) {
        return 1;
    }
    return [self.indexArray count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (_seekTextField.text.length > 0) {
        return Localized(@"JXFriend_searchTitle");
    }
    return [self.indexArray objectAtIndex:section];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_seekTextField.text.length > 0) {
        return _searchArray.count;
    }
    return [[self.letterResultArr objectAtIndex:section] count];
}

-(NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView{
    if (_seekTextField.text.length > 0) {
        return nil;
    }
    return self.indexArray;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index{
    return index;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray * tempArray;
    
    if (_seekTextField.text.length > 0) {
        tempArray = _searchArray;
    }else{
        tempArray = [self.letterResultArr objectAtIndex:indexPath.section];
    }
    
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
    
    JXUserObject *user=tempArray[indexPath.row];
    
    btn.tag = indexPath.section * 10000 + indexPath.row;
    BOOL flag = NO;
    for (NSInteger i = 0; i < _selUserIdArray.count; i ++) {
        NSString *selUserId = _selUserIdArray [i];
        if ([user.userId isEqualToString:selUserId]) {
            flag = YES;
            break;
        }
    }
    btn.checked = flag;
    
    [_checkBoxArr addObject:btn];
    //            cell = [[JXCell alloc] init];
    [_table addToPool:cell];
    cell.title = user.userNickname;
    //            cell.subtitle = user.userId;
    cell.bottomTitle = [TimeUtil formatDate:user.timeCreate format:@"MM-dd HH:mm"];
    cell.userId = user.userId;
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

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
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
