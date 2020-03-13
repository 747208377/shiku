//
//  PSMyViewController
//  sjvodios
//
//  Created by  on 12-5-29.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "admobViewController.h"
//添加VC转场动画
#import "DMScaleTransition.h"
#import "JXImageScrollVC.h"
#import "JXActionSheetVC.h"
@protocol JXServerResult;

@interface PSMyViewController : admobViewController<JXServerResult,UIImagePickerControllerDelegate,UINavigationControllerDelegate,JXActionSheetVCDelegate>{
    JXImageView* _head;
//    int h1;
    UIImage* _image;
    UILabel* _userName;
    UILabel* _userDesc;
    UILabel* _friendLabel;
    UILabel* _groupLabel;
    BOOL _isSelected;
    JXImageView *_topImageVeiw;
}
@property (nonatomic, strong) DMScaleTransition *scaleTransition;
@property (nonatomic,assign) BOOL isRefresh;
@property (nonatomic,strong) UILabel * moneyLabel;
@property (nonatomic, assign) BOOL isAudioMeeting;

@property (nonatomic, assign) BOOL isXmppUpdate;

//-(void)doLogout;
//-(void)doRefresh;
-(void)refreshUserDetail;
@end
