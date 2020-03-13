//
//  JXSetShikuNumVC.m
//  shiku_im
//
//  Created by p on 2019/4/11.
//  Copyright © 2019年 Reese. All rights reserved.
//

#import "JXSetShikuNumVC.h"

#define HEIGHT 50

@interface JXSetShikuNumVC () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *textField;

@end

@implementation JXSetShikuNumVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.isGotoBack   = YES;
    self.title = [NSString stringWithFormat:@"%@%@",Localized(@"JXSettingVC_Set"),Localized(@"JX_Communication")];
    
    self.heightFooter = 0;
    self.heightHeader = JX_SCREEN_TOP;
    //self.view.frame = CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT);
    [self createHeadAndFoot];
    self.tableBody.backgroundColor = HEXCOLOR(0xf0eff4);
    self.tableBody.scrollEnabled = YES;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 20, 100, 100)];
    imageView.layer.cornerRadius = imageView.frame.size.width / 2;
    imageView.layer.masksToBounds = YES;
    [g_server getHeadImageLarge:g_myself.userId userName:g_myself.userNickname imageView:imageView];
    [self.tableBody addSubview:imageView];
    
    UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(imageView.frame) + 20, imageView.frame.origin.y, 200, imageView.frame.size.height)];
    name.font = [UIFont systemFontOfSize:18.0];
    name.text = g_myself.userNickname;
    [self.tableBody addSubview:name];
    
    _textField = [[UITextField alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(imageView.frame) + 50, JX_SCREEN_WIDTH - 40, 50)];
    _textField.delegate = self;
    [_textField becomeFirstResponder];
    _textField.keyboardType = UIKeyboardTypeASCIICapable;
    [self.tableBody addSubview:_textField];
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(_textField.frame.origin.x, CGRectGetMaxY(_textField.frame), _textField.frame.size.width, 2.0)];
    line.backgroundColor = THEMECOLOR;
    [self.tableBody addSubview:line];
    
    UILabel *tip = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(line.frame), line.frame.size.width, 60)];
    tip.font = [UIFont systemFontOfSize:15.0];
    tip.textColor = [UIColor lightGrayColor];
    tip.text = Localized(@"JX_CommunicationOnlySetOne");
    [self.tableBody addSubview:tip];
    
    UIButton* _btn = [UIFactory createCommonButton:Localized(@"JX_Confirm") target:self action:@selector(onConfirm)];

    _btn.layer.cornerRadius = 5;
    _btn.clipsToBounds = YES;
    _btn.custom_acceptEventInterval = 1.0f;
    _btn.frame = CGRectMake(INSETS, CGRectGetMaxY(tip.frame) + 20, WIDTH, HEIGHT);
    [self.tableBody addSubview:_btn];
    
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    [self.tableBody addGestureRecognizer:tap];
}

- (void)tapAction{
    
    [self.view endEditing:YES];
}

- (void)onConfirm {
    self.user.account = _textField.text;
    g_myself.account = self.user.account;
    [g_server updateShikuNum:self.user toView:self];
}

-(BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string{
    
    NSUInteger lengthOfString = string.length;//lengthOfString的值始终为1
    
    for(NSInteger loopIndex =0; loopIndex < lengthOfString; loopIndex++) {
        unichar character = [string characterAtIndex:loopIndex];
        //将输入的值转化为ASCII值（即内部索引值），可以参考ASCII表            // 48-57;{0,9};65-90;{A..Z};97-122:{a..z}
        if(character <48) return NO;// 48 unichar for 0
        if(character >57&& character <65) return NO;
        if(character >90&& character <97) return NO;
        if(character >122) return NO;
        
    }
    return YES;
}


-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
    [_wait stop];
    
    if( [aDownload.action isEqualToString:act_UserUpdate] ){
        self.user.setAccountCount = [NSString stringWithFormat:@"%ld",([g_myself.setAccountCount integerValue] + 1)];
        g_myself.setAccountCount = self.user.setAccountCount;
        if ([self.delegate respondsToSelector:@selector(setShikuNum:updateSuccessWithAccount:)]) {
            [self.delegate setShikuNum:self updateSuccessWithAccount:self.user.account];
            
            [self actionQuit];
        }
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


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
