//
//  JXServerListVC.m
//  shiku_im
//
//  Created by p on 2017/9/8.
//  Copyright © 2017年 Reese. All rights reserved.
//

#import "JXServerListVC.h"

@interface JXServerListVC () <UITextFieldDelegate>

@property (nonatomic, strong) NSMutableArray *array;
@property (nonatomic, strong) UITextField *seekTextField;

@end

@implementation JXServerListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.heightHeader = JX_SCREEN_TOP;
    self.heightFooter = 0;
    self.isGotoBack = YES;
    //self.view.frame = CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT-JX_SCREEN_BOTTOM);
    [self createHeadAndFoot];
    self.isShowHeaderPull = NO;
    self.isShowFooterPull = NO;
    self.title = Localized(@"JX_SetupServer");
    _array = [NSMutableArray array];
    _array = [NSMutableArray arrayWithContentsOfFile:SERVER_LIST_DATA];
    
    [self customView];
    
}


- (void) customView {
    
//    self.tableView.frame = CGRectMake(0, self.tableView.frame.origin.y + 50,self.tableView.frame.size.width, self.tableView.frame.size.height - 50);
//
//    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, self.tableView.frame.origin.y - 50, 200, 50)];
//    label.font = [UIFont systemFontOfSize:15.0];
//    label.text = @"开启多点登录";
//    [self.view addSubview:label];
//
//    UISwitch * switchView = [[UISwitch alloc]initWithFrame:CGRectMake(JX_SCREEN_WIDTH-INSETS-51, self.tableView.frame.origin.y - 35, 20, 20)];
//    BOOL isMultipleLogin = [[g_default objectForKey:kISMultipleLogin] boolValue];
//    [switchView setOn:isMultipleLogin];
//    [switchView addTarget:self action:@selector(switchViewAction:) forControlEvents:UIControlEventValueChanged];
//    [self.view addSubview:switchView];
    
    
    UIButton* btn = [UIFactory createButtonWithTitle:Localized(@"JX_Confirm") titleFont:[UIFont systemFontOfSize:15] titleColor:THESIMPLESTYLE ? [UIColor blackColor] : [UIColor whiteColor] normal:nil highlight:nil];
    [btn addTarget:self action:@selector(isOK) forControlEvents:UIControlEventTouchUpInside];
    btn.frame = CGRectMake(JX_SCREEN_WIDTH-50, JX_SCREEN_TOP - 38, 50, 30);
    [self.tableHeader addSubview:btn];
    
    //搜索输入框
    UIView *backView = [[UIView alloc] initWithFrame:CGRectMake(0, JX_SCREEN_TOP, JX_SCREEN_WIDTH, 50)];
//    backView.backgroundColor = HEXCOLOR(0xf0f0f0);
    [self.view addSubview:backView];
    
    
    _seekTextField = [[UITextField alloc] initWithFrame:CGRectMake(15, 10, backView.frame.size.width - 30, 30)];
    _seekTextField.textColor = [UIColor blackColor];
    [_seekTextField setFont:SYSFONT(14)];
    _seekTextField.backgroundColor = HEXCOLOR(0xf0f0f0);
    _seekTextField.leftViewMode = UITextFieldViewModeAlways;
    _seekTextField.borderStyle = UITextBorderStyleNone;
    _seekTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _seekTextField.delegate = self;
    _seekTextField.returnKeyType = UIReturnKeyGoogle;
    [backView addSubview:_seekTextField];
    
    _seekTextField.text = _array.firstObject;
    _seekTextField.clearButtonMode = UITextFieldViewModeAlways;
    
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 49.5, JX_SCREEN_WIDTH, .5)];
    lineView.backgroundColor = HEXCOLOR(0xdcdcdc);
    [backView addSubview:lineView];
    
    self.tableView.tableHeaderView = backView;
    
}

//- (void)switchViewAction:(UISwitch *)switchView {
//
//    [g_default setObject:[NSNumber numberWithBool:switchView.isOn] forKey:kISMultipleLogin];
//
//    [g_default synchronize];
//}

-(void)isOK {
    
    _array = [[NSMutableArray alloc] initWithContentsOfFile:SERVER_LIST_DATA];
    if (!_array) {
        _array = [NSMutableArray array];
    }
    
    for (NSString *str in _array) {
        if ([str isEqualToString:_seekTextField.text]) {
            
            [_array removeObject:str];
            
            break;
        }
    }

    [_array insertObject:_seekTextField.text atIndex:0];
    
    [_array writeToFile:SERVER_LIST_DATA atomically:YES];

    
    
    g_config.apiUrl = _seekTextField.text;
    
    [_seekTextField resignFirstResponder];
//    [self actionQuit];
    
    [JXMyTools showTipView:@"切换服务器后将退出程序，请重启APP"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self exitApplication];
    });
    
}

-(void)exitApplication {
    
    UIWindow * window = g_window;
    [UIView animateWithDuration:2.0 animations:^{
        window.alpha = 0;
        window.frame = CGRectMake(0,window.bounds.size.width,0,0);
    } completion:^(BOOL finished) {
        exit(0);
    }];
}


#pragma mark   ---------tableView协议----------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    NSString* cellName = [NSString stringWithFormat:@"serverListCell"];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellName];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellName];
        cell.textLabel.font = [UIFont systemFontOfSize:15.0];
    }
    
    if (indexPath.row >= _array.count) {
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, JX_SCREEN_WIDTH, 40)];
        label.text = Localized(@"JX_Clear");
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:15.0];
        [cell.contentView addSubview:label];
        
    }else{
        
        cell.textLabel.text = _array[indexPath.row];
    }
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 40 - 5, JX_SCREEN_WIDTH, .5)];
    line.backgroundColor = HEXCOLOR(0xf0f0f0);
    [cell.contentView addSubview:line];
    
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    if (_array.count > 0) {
        return _array.count + 1;
    }else {
        return _array.count;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row >= _array.count) {
        
        [_array removeAllObjects];
        
        [_array writeToFile:SERVER_LIST_DATA atomically:YES];
        
        
        [_table reloadData];
        
    }else{
        
        _seekTextField.text = _array[indexPath.row];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_seekTextField resignFirstResponder];
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
