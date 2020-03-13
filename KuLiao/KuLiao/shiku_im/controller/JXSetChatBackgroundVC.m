//
//  JXSetChatBackgroundVC.m
//  shiku_im
//
//  Created by p on 2017/12/8.
//  Copyright © 2017年 Reese. All rights reserved.
//

#import "JXSetChatBackgroundVC.h"
#import "JXCameraVC.h"

#define HEIGHT 50

@interface JXSetChatBackgroundVC ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate,JXCameraVCDelegate>

@end

@implementation JXSetChatBackgroundVC

- (instancetype)init {
    if ([super init]) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isGotoBack = YES;
    self.title = Localized(@"JX_SettingUpChatBackground");
    self.heightHeader = JX_SCREEN_TOP;
    self.heightFooter = 0;
    //self.view.frame = CGRectMake(0, 0, JX_SCREEN_WIDTH, JX_SCREEN_HEIGHT);
    [self createHeadAndFoot];
    self.tableBody.backgroundColor = HEXCOLOR(0xf0eff4);
    self.tableBody.scrollEnabled = YES;
    
    int h=9;
    int w=JX_SCREEN_WIDTH;
    
    JXImageView* iv;
    iv = [self createButton:Localized(@"JX_SelectionFromHandsetAlbum") drawTop:YES drawBottom:YES icon:nil click:@selector(onPickPhoto)];
    iv.frame = CGRectMake(0,h, w, HEIGHT);
    h+=iv.frame.size.height;
    
    iv = [self createButton:Localized(@"JX_TakeAPicture") drawTop:NO drawBottom:YES icon:nil click:@selector(onCamera)];
    iv.frame = CGRectMake(0,h, w, HEIGHT);
    h+=iv.frame.size.height + 11;
    
    iv = [self createButton:Localized(@"JX_RestoreDefaultBackground") drawTop:YES drawBottom:YES icon:nil click:@selector(onDefault)];
    iv.frame = CGRectMake(0,h, w, HEIGHT);
}

// 从手机相册选择
- (void)onPickPhoto {
    
    UIImagePickerController *imgPicker=[[UIImagePickerController alloc]init];
    [imgPicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [imgPicker setDelegate:self];
    [imgPicker setAllowsEditing:NO];
    [self presentViewController:imgPicker animated:YES completion:^{}];
}

// 拍照
- (void)onCamera {
    JXCameraVC *vc = [JXCameraVC alloc];
    vc.cameraDelegate = self;
    vc.isPhoto = YES;
    vc = [vc init];
    [self presentViewController:vc animated:YES completion:nil];
}

// 恢复默认
- (void)onDefault {
    
    if (self.userId.length > 0) {
        [g_constant.userBackGroundImage removeObjectForKey:self.userId];
        BOOL isSuccess = [g_constant.userBackGroundImage writeToFile:backImage atomically:YES];
        
        [g_notify postNotificationName:kSetBackGroundImageView object:nil];
        if (isSuccess) {
            [g_App showAlert:Localized(@"JX_SetUpSuccess")];
        }else {
            [g_App showAlert:Localized(@"JX_SettingFailure")];
        }
        return;
    }
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:kChatBackgroundImagePath]) {
        [g_App showAlert:Localized(@"JX_SetUpSuccess")];
        return;
    }
    
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:kChatBackgroundImagePath error:&error];
    if (!error) {
        [g_App showAlert:Localized(@"JX_SetUpSuccess")];
    }else {
        [g_App showAlert:Localized(@"JX_SettingFailure")];
    }
}


#pragma mark ----------图片选择完成-------------
//UIImagePickerController代理方法
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    UIImage  * chosedImage=[info objectForKey:@"UIImagePickerControllerOriginalImage"];
    NSData *imageData = UIImageJPEGRepresentation(chosedImage, 1);
    BOOL isSuccess = NO;
    if (self.userId.length > 0) {
//        if ([self.delegate respondsToSelector:@selector(setChatBackgroundVC:image:)]) {
//            [self.delegate setChatBackgroundVC:self image:chosedImage];
//        }
        [g_constant.userBackGroundImage setObject:imageData forKey:self.userId];
        isSuccess = [g_constant.userBackGroundImage writeToFile:backImage atomically:YES];
        [g_notify postNotificationName:kSetBackGroundImageView object:chosedImage];

    }else {
        isSuccess = [imageData writeToFile:kChatBackgroundImagePath atomically:YES];
        
    }
    if (isSuccess) {
        [g_App showAlert:Localized(@"JX_SetUpSuccess")];
    }else {
        [g_App showAlert:Localized(@"JX_SettingFailure")];
    }
    
    
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:NO completion:^{
    }];
}

// 拍照
- (void)cameraVC:(JXCameraVC *)vc didFinishWithImage:(UIImage *)image {
    NSData *imageData = UIImageJPEGRepresentation(image, 1);
    BOOL isSuccess = NO;
    if (self.userId.length > 0) {
//        if ([self.delegate respondsToSelector:@selector(setChatBackgroundVC:image:)]) {
//            [self.delegate setChatBackgroundVC:self image:image];
//        }
        [g_constant.userBackGroundImage setObject:imageData forKey:self.userId];
        isSuccess = [g_constant.userBackGroundImage writeToFile:backImage atomically:YES];
        
        [g_notify postNotificationName:kSetBackGroundImageView object:image];
    }else {
        isSuccess = [imageData writeToFile:kChatBackgroundImagePath atomically:YES];
        
    }
    if (isSuccess) {
        [g_App showAlert:Localized(@"JX_SetUpSuccess")];
    }else {
        [g_App showAlert:Localized(@"JX_SettingFailure")];
    }
    
}

-(JXImageView*)createButton:(NSString*)title drawTop:(BOOL)drawTop drawBottom:(BOOL)drawBottom icon:(NSString*)icon click:(SEL)click{
    JXImageView* btn = [[JXImageView alloc] init];
    btn.backgroundColor = [UIColor whiteColor];
    btn.userInteractionEnabled = YES;
    btn.didTouch = click;
    btn.delegate = self;
    [self.tableBody addSubview:btn];
    //    [btn release];
    
    JXLabel* p = [[JXLabel alloc] initWithFrame:CGRectMake(25, 0, JX_SCREEN_WIDTH-100, HEIGHT)];
    p.text = title;
    p.font = g_factory.font16;
    p.backgroundColor = [UIColor clearColor];
    p.textColor = [UIColor blackColor];
    p.delegate = self;
    p.didTouch = click;
    [btn addSubview:p];
    
    if(icon){
        UIImageView* iv = [[UIImageView alloc] initWithFrame:CGRectMake(10, (HEIGHT-20)/2, 20, 20)];
        iv.image = [UIImage imageNamed:icon];
        [btn addSubview:iv];
    }
    
    if(drawTop){
        UIView* line = [[UIView alloc] initWithFrame:CGRectMake(0,0,JX_SCREEN_WIDTH,0.5)];
        line.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
        [btn addSubview:line];
    }
    
    if(drawBottom){
        UIView* line = [[UIView alloc] initWithFrame:CGRectMake(0,HEIGHT-0.5,JX_SCREEN_WIDTH,0.5)];
        line.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
        [btn addSubview:line];
    }
    
    if(click){
        UIImageView* iv;
        iv = [[UIImageView alloc] initWithFrame:CGRectMake(JX_SCREEN_WIDTH-INSETS-20-3, 13, 20, 20)];
        iv.image = [UIImage imageNamed:@"set_list_next"];
        [btn addSubview:iv];
    }
    
    return btn;
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
