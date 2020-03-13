//
//  PSRegisterBaseVC.m
//  shiku_im
//
//  Created by flyeagleTang on 14-6-10.
//  Copyright (c) 2014年 Reese. All rights reserved.
//

#import "PSRegisterBaseVC.h"
//#import "selectTreeVC.h"
#import "selectValueVC.h"
#import "selectProvinceVC.h"
#import "ImageResize.h"
#import "resumeData.h"
#import "JXActionSheetVC.h"
#import "JXCameraVC.h"

#define HEIGHT 50
#define IMGSIZE 100


@interface PSRegisterBaseVC ()<UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate,JXActionSheetVCDelegate,JXCameraVCDelegate>

@end

@implementation PSRegisterBaseVC
@synthesize resumeId;
@synthesize resume;
@synthesize user;

- (id)init
{
    self = [super init];
    if (self) {
//        self.isGotoBack   = !self.isRegister;
        self.isGotoBack   = YES;
        if(self.isRegister){
            resume.telephone   = user.telephone;
            self.title = [NSString stringWithFormat:@"3.%@",Localized(@"JX_BaseInfo")];
        }
        else
            self.title = Localized(@"JX_BaseInfo");
        self.heightFooter = 0;
        self.heightHeader = JX_SCREEN_TOP;
        //self.view.frame = CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT);
        [self createHeadAndFoot];
        self.tableBody.backgroundColor = HEXCOLOR(0xf0eff4);
        self.tableBody.scrollEnabled = YES;
        int h = 0;
        NSString* s;
        
        JXImageView* iv;
        iv = [[JXImageView alloc]init];
        iv.frame = self.tableBody.bounds;
        iv.delegate = self;
        iv.didTouch = @selector(hideKeyboard);
        [self.tableBody addSubview:iv];
//        [iv release];
        
        _head = [[JXImageView alloc]initWithFrame:CGRectMake((JX_SCREEN_WIDTH-IMGSIZE)/2, INSETS, IMGSIZE, IMGSIZE)];
        _head.layer.cornerRadius = 6;
        _head.layer.masksToBounds = YES;
        _head.didTouch = @selector(pickImage);
        _head.delegate = self;
        _head.image = [UIImage imageNamed:@"avatar_normal"];
        if(self.isRegister)
            s = user.userId;
        else
            s = g_myself.userId;
        [g_server getHeadImageSmall:s userName:resume.name imageView:_head];
        [self.tableBody addSubview:_head];
//        [_head release];
        h = INSETS*2+IMGSIZE;
        
        
        NSString* workExp = [g_constant.workexp objectForKey:[NSNumber numberWithInt:resume.workexpId]];
        NSString* diploma = [g_constant.diploma objectForKey:[NSNumber numberWithInt:resume.diplomaId]];
        NSString* city = [g_constant getAddressForInt:resume.provinceId cityId:resume.cityId areaId:resume.areaId];
        
        iv = [self createButton:Localized(@"JX_Name") drawTop:YES drawBottom:YES must:YES click:nil];
        iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
        _name = [self createTextField:iv default:resume.name hint:Localized(@"JX_InputName")];
        h+=iv.frame.size.height;
        
        iv = [self createButton:Localized(@"JX_Sex") drawTop:NO drawBottom:YES must:YES click:nil];
        iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
        _sex = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:Localized(@"JX_Wuman"),Localized(@"JX_Man"),nil]];
        _sex.frame = CGRectMake(JX_SCREEN_WIDTH -100 - INSETS,INSETS+3,100,HEIGHT-INSETS*2-6);
        _sex.selectedSegmentIndex = resume.sex;
        //样式
//        _sex.segmentedControlStyle= UISegmentedControlStyleBar;
        _sex.tintColor = THEMECOLOR;
        _sex.layer.cornerRadius = 5;
        _sex.layer.borderWidth = 1.5;
        _sex.layer.borderColor = [THEMECOLOR CGColor];
        _sex.clipsToBounds = YES;
        //设置文字属性
        _sex.selectedSegmentIndex = [user.sex boolValue];
        _sex.apportionsSegmentWidthsByContent = NO;
        [iv addSubview:_sex];
//        [_sex release];
        h+=iv.frame.size.height;
        
        if (!resume.birthday) {
            resume.birthday = [[NSDate date] timeIntervalSince1970];
        }
        
        iv = [self createButton:Localized(@"JX_BirthDay") drawTop:NO drawBottom:YES must:YES click:nil];
        iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
        _birthday = [self createTextField:iv default:[TimeUtil getDateStr:resume.birthday] hint:Localized(@"JX_BirthDay")];
        h+=iv.frame.size.height;
        
        if(!self.isRegister){
            iv = [self createButton:Localized(@"JX_WorkingYear") drawTop:NO drawBottom:YES must:YES click:@selector(onWorkexp)];
            iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
            _workexp = [self createLabel:iv default:workExp];
            h+=iv.frame.size.height;
            
            iv = [self createButton:Localized(@"JX_HighSchool") drawTop:NO drawBottom:YES must:YES click:@selector(onDiploma)];
            iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
            _dip = [self createLabel:iv default:diploma];
            h+=iv.frame.size.height;
            
            iv = [self createButton:Localized(@"JX_Address") drawTop:NO drawBottom:YES must:YES click:@selector(onCity)];
            iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
            _city = [self createLabel:iv default:city];
            h+=iv.frame.size.height;
        }else {
            if ([g_config.registerInviteCode intValue] != 0) {
                iv = [self createButton:Localized(@"JX_InvitationCode") drawTop:NO drawBottom:YES must:YES click:nil];
                iv.frame = CGRectMake(0, h, JX_SCREEN_WIDTH, HEIGHT);
                _inviteCode = [self createTextField:iv default:nil hint:Localized(@"JX_EnterInvitationCode")];
                h+=iv.frame.size.height;
            }
        }
        
        h+=INSETS;
        UIButton* _btn;
        if(self.isRegister)
            _btn = [UIFactory createCommonButton:Localized(@"JX_NextStep") target:self action:@selector(onInsert)];
        else
            _btn = [UIFactory createCommonButton:Localized(@"JX_Update") target:self action:@selector(onUpdate)];
        _btn.layer.cornerRadius = 5;
        _btn.custom_acceptEventInterval = .25f;
        _btn.clipsToBounds = YES;
        _btn.frame = CGRectMake(INSETS, h, WIDTH, HEIGHT);
        [self.tableBody addSubview:_btn];
        
        _date = [[JXDatePicker alloc] initWithFrame:CGRectMake(0, JX_SCREEN_HEIGHT-200, JX_SCREEN_WIDTH, 200)];
        _date.date = [NSDate dateWithTimeIntervalSince1970:resume.birthday];
        _date.datePicker.datePickerMode = UIDatePickerModeDate;
        _date.delegate = self;
        _date.didChange = @selector(onDate:);
        _date.didSelect = @selector(onDate:);
    }
    return self;
}

-(void)dealloc{
//    NSLog(@"PSRegisterBaseVC.dealloc");
//    [_image release];
    self.resumeId = nil;
    self.user = nil;
    self.resume = nil;
    
    [_date removeFromSuperview];
//    [_date release];
//    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    if(textField == _birthday){
        [self hideKeyboard];
        [g_window addSubview:_date];
        _date.hidden = NO;
        return NO;
    }else{
        _date.hidden = YES;
        return YES;
    }
}

- (IBAction)onDate:(id)sender {
    NSDate *selected = [_date date];
    _birthday.text = [TimeUtil formatDate:selected format:@"yyyy-MM-dd"];
    //    _date.hidden = YES;
}

-(void) didServerResultSucces:(JXConnection*)aDownload dict:(NSDictionary*)dict array:(NSArray*)array1{
    [_wait stop];
    
    if( [aDownload.action isEqualToString:act_Config]){
        
        [g_config didReceive:dict];
        
        [user copyFromResume:resume];
        [g_server registerUser:user inviteCode:_inviteCode.text workexp:resume.workexpId diploma:resume.diplomaId isSmsRegister:self.isSmsRegister toView:self];
    }
    
    if( [aDownload.action isEqualToString:act_UploadHeadImage] ){
        _head.image = _image;
//        [_image release];
        _image = nil;
        
        if(self.isRegister){
        }else{
            [g_server delHeadImage:user.userId];
            [g_App showAlert:Localized(@"JXAlert_UpdateOK")];
        }
        [g_notify postNotificationName:kUpdateUserNotifaction object:self userInfo:nil];
        [g_notify postNotificationName:kRegisterNotifaction object:self userInfo:nil];
        [self actionQuit];
    }
    if( [aDownload.action isEqualToString:act_Register] ){
        [g_default setBool:NO forKey:kTHIRD_LOGIN_AUTO];
        [g_server doLoginOK:dict user:user];
        self.user = g_server.myself;

        self.resumeId   = [[dict objectForKey:@"cv"] objectForKey:@"resumeId"];
//        [g_server autoLogin:self];
        [g_server getUser:[[dict objectForKey:@"userId"] stringValue] toView:self];

    }
    if([aDownload.action isEqualToString:act_UserGet]){

        if ([dict objectForKey:@"settings"]) {
            g_server.myself.chatRecordTimeOut = [NSString stringWithFormat:@"%@",[[dict objectForKey:@"settings"] objectForKey:@"chatRecordTimeOut"]];
            g_server.myself.chatSyncTimeLen = [NSString stringWithFormat:@"%@",[[dict objectForKey:@"settings"] objectForKey:@"chatSyncTimeLen"]];
            g_server.myself.groupChatSyncTimeLen = [NSString stringWithFormat:@"%@",[[dict objectForKey:@"settings"] objectForKey:@"groupChatSyncTimeLen"]];
            g_server.myself.friendsVerify = [NSString stringWithFormat:@"%@",[[dict objectForKey:@"settings"] objectForKey:@"friendsVerify"]];
            g_server.myself.isEncrypt = [NSString stringWithFormat:@"%@",[[dict objectForKey:@"settings"] objectForKey:@"isEncrypt"]];
            g_server.myself.isTyping = [NSString stringWithFormat:@"%@",[[dict objectForKey:@"settings"] objectForKey:@"isTyping"]];
            g_server.myself.isVibration = [NSString stringWithFormat:@"%@",[[dict objectForKey:@"settings"] objectForKey:@"isVibration"]];
            g_server.myself.multipleDevices = [NSString stringWithFormat:@"%@",[[dict objectForKey:@"settings"] objectForKey:@"multipleDevices"]];
            g_server.myself.isUseGoogleMap = [NSString stringWithFormat:@"%@",[[dict objectForKey:@"settings"] objectForKey:@"isUseGoogleMap"]];
            
        }
        
        
        [g_server uploadHeadImage:user.userId image:_image toView:self];
        
    }
    
    if( [aDownload.action isEqualToString:act_resumeUpdate] ){
        if(_image)
            [g_server uploadHeadImage:g_myself.userId image:_image toView:self];
        else{
            g_myself.userNickname = _name.text;
            g_myself.sex = [NSNumber numberWithInteger:_sex.selectedSegmentIndex];
            g_myself.birthday = _date.date;
            g_myself.cityId = [NSNumber numberWithInt:[_city.text intValue]];
            [g_App showAlert:Localized(@"JXAlert_UpdateOK")];
            [g_notify postNotificationName:kUpdateUserNotifaction object:self userInfo:nil];
            [self actionQuit];
        }
    }
    if ([aDownload.action isEqualToString:act_registerSDK]) {
        [g_default setBool:YES forKey:kTHIRD_LOGIN_AUTO];
        g_server.openId = nil;
        [g_server doLoginOK:dict user:user];
        self.user = g_server.myself;
        
        self.resumeId   = [[dict objectForKey:@"cv"] objectForKey:@"resumeId"];
        [g_server getUser:[[dict objectForKey:@"userId"] stringValue] toView:self];
    }
}

-(int) didServerResultFailed:(JXConnection*)aDownload dict:(NSDictionary*)dict{
    [_wait stop];
    if( [aDownload.action isEqualToString:act_UploadHeadImage] ){
        _head.image = _image;
        //        [_image release];
        _image = nil;
        
        if(self.isRegister){
        }else{
            [g_server delHeadImage:user.userId];
            [g_App showAlert:Localized(@"JXAlert_UpdateOK")];
        }
        [g_notify postNotificationName:kUpdateUserNotifaction object:self userInfo:nil];
        [g_notify postNotificationName:kRegisterNotifaction object:self userInfo:nil];
        [self actionQuit];
    }
    return show_error;
}

-(int) didServerConnectError:(JXConnection*)aDownload error:(NSError *)error{//error为空时，代表超时
    [_wait stop];
    if( [aDownload.action isEqualToString:act_UploadHeadImage] ){
        _head.image = _image;
        //        [_image release];
        _image = nil;
        
        if(self.isRegister){
        }else{
            [g_server delHeadImage:user.userId];
            [g_App showAlert:Localized(@"JXAlert_UpdateOK")];
        }
        [g_notify postNotificationName:kUpdateUserNotifaction object:self userInfo:nil];
        [g_notify postNotificationName:kRegisterNotifaction object:self userInfo:nil];
        [self actionQuit];
    }
    return show_error;
}

-(void) didServerConnectStart:(JXConnection*)aDownload{
    [_wait start];
}

-(JXImageView*)createButton:(NSString*)title drawTop:(BOOL)drawTop drawBottom:(BOOL)drawBottom must:(BOOL)must click:(SEL)click{
    JXImageView* btn = [[JXImageView alloc] init];
    btn.backgroundColor = [UIColor whiteColor];
    btn.userInteractionEnabled = YES;
    if(click)
        btn.didTouch = click;
    else
        btn.didTouch = @selector(hideKeyboard);
    btn.delegate = self;
    [self.tableBody addSubview:btn];
//    [btn release];
    
    if(must){
        UILabel* p = [[UILabel alloc] initWithFrame:CGRectMake(INSETS, 5, 20, HEIGHT-5)];
        p.text = @"*";
        p.font = g_factory.font18;
        p.backgroundColor = [UIColor clearColor];
        p.textColor = [UIColor redColor];
        p.textAlignment = NSTextAlignmentCenter;
        [btn addSubview:p];
//        [p release];
    }
    
    JXLabel* p = [[JXLabel alloc] initWithFrame:CGRectMake(30, 0, 130, HEIGHT)];
    p.text = title;
    p.font = g_factory.font15;
    p.backgroundColor = [UIColor clearColor];
    p.textColor = [UIColor blackColor];
    [btn addSubview:p];
//    [p release];
    
    if(drawTop){
        UIView* line = [[UIView alloc] initWithFrame:CGRectMake(0,0,JX_SCREEN_WIDTH,0.5)];
        line.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
        [btn addSubview:line];
//        [line release];
    }
    
    if(drawBottom){
        UIView* line = [[UIView alloc]initWithFrame:CGRectMake(0,HEIGHT-0.5,JX_SCREEN_WIDTH,0.5)];
        line.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
        [btn addSubview:line];
//        [line release];
    }
    
    if(click){
        UIImageView* iv;
        iv = [[UIImageView alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH-INSETS-20-3, 13, 20, 20)];
        iv.image = [UIImage imageNamed:@"set_list_next"];
        [btn addSubview:iv];
//        [iv release];
    }
    return btn;
}

-(UITextField*)createTextField:(UIView*)parent default:(NSString*)s hint:(NSString*)hint{
    UITextField* p = [[UITextField alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH/2,INSETS,JX_SCREEN_WIDTH/2,HEIGHT-INSETS*2)];
    p.delegate = self;
    p.autocorrectionType = UITextAutocorrectionTypeNo;
    p.autocapitalizationType = UITextAutocapitalizationTypeNone;
    p.enablesReturnKeyAutomatically = YES;
    p.borderStyle = UITextBorderStyleNone;
    p.returnKeyType = UIReturnKeyDone;
    p.clearButtonMode = UITextFieldViewModeAlways;
    p.textAlignment = NSTextAlignmentRight;
    p.userInteractionEnabled = YES;
    p.text = s;
    p.placeholder = hint;
    p.font = g_factory.font15;
    [parent addSubview:p];
//    [p release];
    return p;
}

-(UILabel*)createLabel:(UIView*)parent default:(NSString*)s{
    UILabel* p = [[UILabel alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH/2 -30 ,INSETS,JX_SCREEN_WIDTH/2,HEIGHT-INSETS*2)];
    p.userInteractionEnabled = NO;
    p.text = s;
    p.font = g_factory.font15;
    p.textAlignment = NSTextAlignmentRight;
    [parent addSubview:p];
//    [p release];
    return p;
}

-(void)onWorkexp{
    if([self hideKeyboard])
        return;
    
    selectValueVC* vc = [selectValueVC alloc];
    vc.values = g_constant.workexp_name;
    vc.selNumber = resume.workexpId;
    vc.numbers   = g_constant.workexp_value;
    vc.delegate  = self;
    vc.didSelect = @selector(onSelWorkExp:);
    vc.quickSelect = YES;
    vc = [vc init];
//    [g_window addSubview:vc.view];
    [g_navigation pushViewController:vc animated:YES];
}

-(void)onDiploma{
    if([self hideKeyboard])
        return;
    
    selectValueVC* vc = [selectValueVC alloc];
    vc.values = g_constant.diploma_name;
    vc.selNumber = resume.diplomaId;
    vc.numbers   = g_constant.diploma_value;
    vc.delegate  = self;
    vc.didSelect = @selector(onSelDiploma:);
    vc.quickSelect = YES;
    vc = [vc init];
//    [g_window addSubview:vc.view];
    [g_navigation pushViewController:vc animated:YES];
}

-(void)onCity{
    if([self hideKeyboard])
        return;
    
    selectProvinceVC* vc = [selectProvinceVC alloc];
    vc.delegate = self;
    vc.didSelect = @selector(onSelCity:);
    vc.showCity = YES;
    vc.showArea = NO;
    vc.parentId = 1;
    vc = [vc init];
//    [g_window addSubview:vc.view];
    [g_navigation pushViewController:vc animated:YES];
}

-(void)onSelCity:(selectProvinceVC*)sender{
    resume.cityId = sender.cityId;
    resume.provinceId = sender.provinceId;
    resume.areaId = sender.areaId;
    resume.countryId = 1;
    _city.text = sender.selValue;
}

-(void)onSelDiploma:(selectValueVC*)sender{
    resume.diplomaId = sender.selNumber;
    _dip.text = sender.selValue;
}

-(void)onSelWorkExp:(selectValueVC*)sender{
    resume.workexpId = sender.selNumber;
    _workexp.text = sender.selValue;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    _image = [ImageResize image:[info objectForKey:@"UIImagePickerControllerEditedImage"] fillSize:CGSizeMake(640, 640)];
//    [_image retain];
    _head.image = _image;
//    [picker.view removeFromSuperview];
    [picker dismissViewControllerAnimated:YES completion:nil];
    //	[self dismissModalViewControllerAnimated:YES];
//	[picker release];
}

- (void) pickImage
{
    [self hideKeyboard];
    
    JXActionSheetVC *actionVC = [[JXActionSheetVC alloc] initWithImages:@[] names:@[Localized(@"JX_ChoosePhoto"),Localized(@"JX_TakePhoto")]];
    actionVC.delegate = self;
    [self presentViewController:actionVC animated:NO completion:nil];
    
	UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
	ipc.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
	ipc.delegate = self;
	ipc.allowsEditing = YES;
    ipc.modalPresentationStyle = UIModalPresentationFullScreen;
//    [g_window addSubview:ipc.view];
    if (IS_PAD) {
        UIPopoverController *pop =  [[UIPopoverController alloc] initWithContentViewController:ipc];
        [pop presentPopoverFromRect:CGRectMake((self.view.frame.size.width - 320) / 2, 0, 300, 300) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }else {
        [self presentViewController:ipc animated:YES completion:nil];
    }
}
- (void)actionSheet:(JXActionSheetVC *)actionSheet didButtonWithIndex:(NSInteger)index {
    if (index == 0) {
        UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
        ipc.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
        ipc.delegate = self;
        ipc.allowsEditing = YES;
        //选择图片模式
        ipc.modalPresentationStyle = UIModalPresentationCurrentContext;
        //    [g_window addSubview:ipc.view];
        if (IS_PAD) {
            UIPopoverController *pop =  [[UIPopoverController alloc] initWithContentViewController:ipc];
            [pop presentPopoverFromRect:CGRectMake((self.view.frame.size.width - 320) / 2, 0, 300, 300) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }else {
            [self presentViewController:ipc animated:YES completion:nil];
        }
        
    }else {
        JXCameraVC *vc = [JXCameraVC alloc];
        vc.cameraDelegate = self;
        vc.isPhoto = YES;
        vc = [vc init];
        [self presentViewController:vc animated:YES completion:nil];
    }
}

- (void)cameraVC:(JXCameraVC *)vc didFinishWithImage:(UIImage *)image {
    _image = [ImageResize image:image fillSize:CGSizeMake(640, 640)];
    //    [_image retain];
    _head.image = _image;
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
//    [picker.view removeFromSuperview];
    [picker dismissViewControllerAnimated:YES completion:nil];
//    [picker release];
    //	[self dismissModalViewControllerAnimated:YES];
}

-(void)onUpdate{
    if(![self getInputValue])
        return;
//    NSString* s = [g_server jsonFromObject:[resume setDataToDict]];
//    [g_server updateResume:resumeId nodeName:@"p" text:s toView:self];
}

-(void)onInsert{
    if(![self getInputValue])
        return;
    
    [g_server getSetting:self];
}

-(BOOL)getInputValue{
    if(_image==nil && self.isRegister){
        [g_App showAlert:Localized(@"JX_SetHead")];
        return NO;
    }
    if([_name.text length]<=0){
        [g_App showAlert:Localized(@"JX_InputName")];
        return NO;
    }
    if(!self.isRegister){
        if(resume.workexpId<=0){
            [g_App showAlert:Localized(@"JX_InputWorking")];
            return NO;
        }
        if(resume.diplomaId<=0){
            [g_App showAlert:Localized(@"JX_School")];
            return NO;
        }
        if(resume.cityId<=0){
            [g_App showAlert:Localized(@"JX_Live")];
            return NO;
        }
    }else {
        if ([g_config.registerInviteCode intValue] == 1) {
            if ([_inviteCode.text length] <= 0) {
                [g_App showAlert:Localized(@"JX_EnterInvitationCode")];
                return NO;
            }
        }
    }
    resume.name = _name.text;
    resume.birthday = [_date.date timeIntervalSince1970];
    resume.sex = _sex.selectedSegmentIndex;
    return  YES;
}

-(BOOL)hideKeyboard{
    BOOL b = _name.editing || _pwd.editing || _repeat.editing;
    _date.hidden = YES;
    [self.view endEditing:YES];
    return b;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.view endEditing:YES];
    return YES;
}


@end
