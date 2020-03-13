//
//  RITLPhotosItemsCollectionViewController.m
//  RITLPhotoDemo
//
//  Created by YueWen on 2018/3/7.
//  Copyright © 2018年 YueWen. All rights reserved.
//

#import "RITLPhotosCollectionViewController.h"
#import "RITLPhotosPreviewController.h"
#import "RITLPhotosHorBrowseViewController.h"

#import "RITLPhotosCell.h"
#import "RITLPhotosBottomView.h"
#import "RITLPhotosBrowseAllDataSource.h"
#import "RITLPhotosBrowseDataSource.h"
#import "RITLPhotosConfiguration.h"

#import "PHAsset+RITLPhotos.h"
#import "NSString+RITLPhotos.h"
#import "PHPhotoLibrary+RITLPhotoStore.h"
#import "UICollectionView+RITLIndexPathsForElements.h"
#import "UICollectionViewCell+RITLPhotosAsset.h"

#import "RITLKit.h"
#import "UIView+RITLFrameChanged.h"
#import "Masonry.h"
#import <Photos/Photos.h>
#import "UIImage+Tint.h"

//Data
#import "RITLPhotosMaker.h"
#import "RITLPhotosDataManager.h"
#import "RITLPhotosConfiguration.h"




typedef NSString RITLDifferencesKey;
static RITLDifferencesKey *const RITLDifferencesKeyAdded = @"RITLDifferencesKeyAdded";
static RITLDifferencesKey *const RITLDifferencesKeyRemoved = @"RITLDifferencesKeyRemoved";

@interface UICollectionView (RITLPhotosCollectionViewController)

- (NSArray <NSIndexPath *>*)indexPathsForElementsInRect:(CGRect)rect;

@end


@interface RITLPhotosCollectionViewController ()<UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout,
UIViewControllerPreviewingDelegate,
UICollectionViewDataSourcePrefetching,
RITLPhotosCellActionTarget>

// Library
@property (nonatomic, strong) PHPhotoLibrary *photoLibrary;
// Datamanager
@property (nonatomic, strong) RITLPhotosDataManager *dataManager;

// data
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) PHAssetCollection *assetCollection;
@property (nonatomic, strong) PHFetchResult <PHAsset *> *assets;

@property (nonatomic, strong) PHCachingImageManager* imageManager;
@property (nonatomic, assign) CGRect previousPreheatRect;

// view
@property (nonatomic, strong) RITLPhotosBottomView *bottomView;
@property (nonatomic, strong) UILabel *tintLable; // 无权限提醒

@property (nonatomic, assign) BOOL isEdit;

@end

@implementation RITLPhotosCollectionViewController

static NSString *const reuseIdentifier = @"photo";

+ (RITLPhotosCollectionViewController *)photosCollectionController
{
    return RITLPhotosCollectionViewController.new;
}


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        
        self.previousPreheatRect = CGRectZero;
        self.dataManager = [RITLPhotosDataManager sharedInstance];
    }
    
    return self;
}


- (void)resetCachedAssets
{
    [self.imageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}


- (PHAssetCollection *)assetCollection
{
    if (!_assetCollection) {
        
        _assetCollection = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil].firstObject;
    }
    
    return _assetCollection;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    //设置navigationController 背景颜色
    UIImage *iv = [[UIImage alloc] init];
    if (THESIMPLESTYLE) {
        iv = [[UIImage imageNamed:@"navBarBackground"] imageWithTintColor:[UIColor whiteColor]];
    }else {
        iv = [g_theme themeTintImage:@"navBarBackground"];
    }
    [self.navigationController.navigationBar setBackgroundImage:iv forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];

    //进行KVO观察
    [self.dataManager addObserver:self forKeyPath:@"count" options:NSKeyValueObservingOptionNew context:nil];
    [self.dataManager addObserver:self forKeyPath:@"hightQuality" options:NSKeyValueObservingOptionNew context:nil];
    
    
    // NavigationItem
    UIBarButtonItem *barbtn=[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(Localized(@"JX_Cencal"), @"") style:UIBarButtonItemStyleDone target:self action:@selector(dismissPhotoControllers)];
    [barbtn setTintColor:THESIMPLESTYLE ? [UIColor blackColor] : [UIColor blackColor]];
    self.navigationItem.rightBarButtonItem = barbtn;
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(8, JX_SCREEN_TOP - 38, 31, 31)];
    [btn setBackgroundImage:THESIMPLESTYLE ? [UIImage imageNamed:@"photo_title_back_black"] : [UIImage imageNamed:@"photo_title_back"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(actionQuit) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barBtn = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.leftBarButtonItem = barBtn;

    // Register cell classes
    [self.collectionView registerClass:[RITLPhotosCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    self.bottomView = RITLPhotosBottomView.new;
    self.bottomView.previewButton.enabled = false;
    self.bottomView.sendButton.enabled = false;
    
    [self.bottomView.previewButton addTarget:self
                                      action:@selector(pushPreviewViewController)
                            forControlEvents:UIControlEventTouchUpInside];
    
    [self.bottomView.fullImageButton addTarget:self
                                        action:@selector(hightQualityShouldChanged:)
                              forControlEvents:UIControlEventTouchUpInside];
    
    [self.bottomView.sendButton addTarget:self
                                   action:@selector(pushPhotosMaker)
                         forControlEvents:UIControlEventTouchUpInside];
    
    self.bottomView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.8];
    
    // Do any additional setup after loading the view.
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.bottomView];
    [self.view addSubview:self.tintLable];
    // Layout
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.bottom.left.right.offset(0);
        make.height.mas_equalTo(RITL_DefaultTabBarHeight - 3);
    }];
    
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.left.top.right.offset(0);
        make.bottom.equalTo(self.bottomView.mas_top).offset(0);
    }];
    
    [self.tintLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(JX_SCREEN_TOP+20);
        make.left.offset(30);
        make.right.offset(-30);
        make.height.mas_equalTo(60);
    }];

    //加载数据
    if (self.localIdentifier) {
        //加载
        self.assetCollection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[self.localIdentifier] options:nil].firstObject;
    }
    
    //进行权限检测
    [PHPhotoLibrary authorizationStatusAllow:^{
        
        self.imageManager = [PHCachingImageManager new];
        self.photoLibrary = PHPhotoLibrary.sharedPhotoLibrary;
        
        [self resetCachedAssets];
        
        self.assets = [PHAsset fetchAssetsInAssetCollection:self.assetCollection options:nil];
        
        //reload
        self.collectionView.hidden = true;
        [self.collectionView reloadData];
        
        // 拥有照片访问权限
        self.tintLable.hidden = YES;
        self.bottomView.hidden = NO;
        
        //设置itemTitle
//        self.navigationItem.title = self.assetCollection.localizedTitle;
        self.navigationItem.title = Localized(@"JX_Photo");
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
        
        //计算行数,并滑动到最后一行
        self.collectionView.hidden = false;
        
        [self collectionViewScrollToBottomAnimatedNoneHandler:^NSInteger(NSInteger row) {
            
            return row;
        }];
        
        // 滚动到底部
        [self.collectionView setContentOffset:CGPointMake(0, self.collectionView.contentSize.height - self.collectionView.frame.size.height) animated:YES];
    } denied:^{
        // 没有照片访问权限
        self.tintLable.hidden = NO;
        self.bottomView.hidden = YES;
    }];
    
    [self changedBottomViewStatus];
}


- (void)actionQuit {
    [self dismissPhotoControllers];
}


- (void)dealloc
{
    if (self.isViewLoaded) {
        [self.dataManager removeObserver:self forKeyPath:@"count"];
        [self.dataManager removeObserver:self forKeyPath:@"hightQuality"];
    }

    [self.dataManager removeAllPHAssets];
    NSLog(@"[%@] is dealloc",NSStringFromClass(self.class));
}


- (void)collectionViewScrollToBottomAnimatedNoneHandler:(NSInteger(^)(NSInteger row))handler
{
    //获得所有的数据个数
    NSInteger itemCount = self.assets.count;
    
    if (itemCount < 4) { return; }
    
    //获得行数
    NSInteger row = itemCount % 4 == 0 ? itemCount / 4 : itemCount / 4 + 1;
    
    if (handler) { row = handler(row); }
    
    //item
    CGFloat itemHeight = (RITL_SCREEN_WIDTH - 3.0f * 3) / 4;
    
    //进行高度换算
    CGFloat height = row * itemHeight;
    height += 3.0 * (row - 1);
    
    //扩展contentSize
    self.collectionView.ritl_contentSizeHeight = height;
    
    //底部bottom
    CGFloat bottomHeight = RITL_DefaultTabBarHeight;
    
    //可以显示的区域
    CGFloat showSapce = RITL_SCREEN_HEIGHT - RITL_DefaultNaviBarHeight - bottomHeight;
    
    //进行单位换算
    self.collectionView.ritl_contentOffSetY = MIN(MAX(0,height - showSapce),-1 * RITL_DefaultNaviBarHeight);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.isEdit) {
        self.imageManager = [PHCachingImageManager new];
        self.photoLibrary = PHPhotoLibrary.sharedPhotoLibrary;
        
        [self resetCachedAssets];
        
        self.assets = [PHAsset fetchAssetsInAssetCollection:self.assetCollection options:nil];
        [self.collectionView reloadData];
        // 滚动到底部
        [self.collectionView setContentOffset:CGPointMake(0, self.collectionView.contentSize.height - self.collectionView.frame.size.height) animated:YES];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - *************** cache ***************

- (void)updateCachedAssets
{
    if (!self.isViewLoaded || self.view.window == nil) { return; }
    
    //没有权限，关闭
    if (PHPhotoLibrary.authorizationStatus != PHAuthorizationStatusAuthorized) { return; }
    
    //可视化
    CGRect visibleRect = CGRectMake(self.collectionView.ritl_contentOffSetX, self.collectionView.ritl_contentOffSetY, self.collectionView.ritl_width, self.collectionView.ritl_height);
    
    //进行拓展
    CGRect preheatRect = CGRectInset(visibleRect, 0, -0.5 * visibleRect.size.height);
    
    //只有可视化的区域与之前的区域有显著的区域变化才需要更新
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    if (delta <= self.view.ritl_height / 3.0) { return; }
    
    //获得比较后需要进行预加载以及需要停止缓存的区域
    NSDictionary *differences = [self differencesBetweenRects:self.previousPreheatRect new:preheatRect];
    NSArray <NSValue *> *addedRects = differences[RITLDifferencesKeyAdded];
    NSArray <NSValue *> *removedRects = differences[RITLDifferencesKeyRemoved];
    
    ///进行提前缓存的资源
    NSArray <PHAsset *> *addedAssets = [[[addedRects ritl_map:^id _Nonnull(NSValue * _Nonnull rectValue) {
        return [self.collectionView indexPathsForElementsInRect:rectValue.CGRectValue];
        
    }] ritl_reduce:@[] reduceHandler:^NSArray * _Nonnull(NSArray * _Nonnull result, NSArray <NSIndexPath *>*_Nonnull items) {
        return [result arrayByAddingObjectsFromArray:items];
        
    }] ritl_map:^id _Nonnull(NSIndexPath *_Nonnull index) {
        return [self.assets objectAtIndex:index.item];
        
    }];
    
    ///提前停止缓存的资源
    NSArray <PHAsset *> *removedAssets = [[[removedRects ritl_map:^id _Nonnull(NSValue * _Nonnull rectValue) {
        return [self.collectionView indexPathsForElementsInRect:rectValue.CGRectValue];
        
    }] ritl_reduce:@[] reduceHandler:^NSArray * _Nonnull(NSArray * _Nonnull result, NSArray <NSIndexPath *>* _Nonnull items) {
        return [result arrayByAddingObjectsFromArray:items];
        
    }] ritl_map:^id _Nonnull(NSIndexPath *_Nonnull index) {
        return [self.assets objectAtIndex:index.item];
    }];
    
    CGSize thimbnailSize = [self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout sizeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    
    //更新缓存
    [self.imageManager startCachingImagesForAssets:addedAssets targetSize:thimbnailSize contentMode:PHImageContentModeAspectFill options:nil];
    [self.imageManager stopCachingImagesForAssets:removedAssets targetSize:thimbnailSize contentMode:PHImageContentModeAspectFill options:nil];
    
    //记录当前位置
    self.previousPreheatRect = preheatRect;
}


- (NSDictionary <RITLDifferencesKey*,NSArray<NSValue *>*> *)differencesBetweenRects:(CGRect)old new:(CGRect)new
{
    if (CGRectIntersectsRect(old, new)) {//如果区域交叉
        
        NSMutableArray <NSValue *> * added = [NSMutableArray arrayWithCapacity:10];
        if (CGRectGetMaxY(new) > CGRectGetMaxY(old)) {//表示上拉
            [added addObject:[NSValue valueWithCGRect:CGRectMake(new.origin.x, CGRectGetMaxY(old), new.size.width, CGRectGetMaxY(new) - CGRectGetMaxY(old))]];
        }
        
        if(CGRectGetMinY(old) > CGRectGetMinY(new)){//表示下拉
            
            [added addObject:[NSValue valueWithCGRect:CGRectMake(new.origin.x, CGRectGetMinY(new), new.size.width, CGRectGetMinY(old) - CGRectGetMinY(new))]];
        }
        
        NSMutableArray <NSValue *> * removed = [NSMutableArray arrayWithCapacity:10];
        if (CGRectGetMaxY(new) < CGRectGetMaxY(old)) {//表示下拉
            [removed addObject:[NSValue valueWithCGRect:CGRectMake(new.origin.x, CGRectGetMaxY(new), new.size.width, CGRectGetMaxY(old) - CGRectGetMaxY(new))]];
        }
        
        if (CGRectGetMinY(old) < CGRectGetMinY(new)) {//表示上拉
            
            [removed addObject:[NSValue valueWithCGRect:CGRectMake(new.origin.x, CGRectGetMinY(old), new.size.width, CGRectGetMinY(new) - CGRectGetMinY(old))]];
        }
        
        return @{RITLDifferencesKeyAdded:added,
                 RITLDifferencesKeyRemoved:removed};
    }else {
        
        return @{RITLDifferencesKeyAdded:@[[NSValue valueWithCGRect:new]],
                 RITLDifferencesKeyRemoved:@[[NSValue valueWithCGRect:old]]};
    }
}

#pragma mark - Dismiss

- (void)dismissPhotoControllers
{
    if(self.navigationController.presentingViewController){//如果是模态弹出
        
        [self.navigationController dismissViewControllerAnimated:true completion:nil];
        
    }else if(self.navigationController){
        
        [self.navigationController popViewControllerAnimated:true];
    }
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assets ? self.assets.count : 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    RITLPhotosCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    //Asset
    PHAsset *asset = [self.assets objectAtIndex:indexPath.item];
    
    //Size
    CGSize size = [self collectionView:collectionView layout:collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath];
    
    PHImageRequestOptions *options = PHImageRequestOptions.new;
    options.networkAccessAllowed = true;
    
    // Configure the cell
    cell.representedAssetIdentifier = asset.localIdentifier;
    [self.imageManager requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        
        if ([cell.representedAssetIdentifier isEqualToString:asset.localIdentifier] && result) {
            
            cell.actionTarget = self;
            cell.asset = asset;
            cell.indexPath = indexPath;
            cell.imageView.image = result;
            cell.messageView.hidden = (asset.mediaType == PHAssetMediaTypeImage);
            if (self.isEdit && indexPath.row == self.assets.count -1) {
                // 当编辑图片返回时 默认选中，这里是模拟用户点击选择按钮
                [cell.chooseButton sendActionsForControlEvents:UIControlEventTouchUpInside];
                self.isEdit = NO;
            }
            if (@available(iOS 9.1,*)) {//Live图片
                
                cell.liveBadgeImageView.hidden = !(asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive);
            }
            
            if(!RITLPhotosConfiguration.defaultConfiguration.containVideo){//是否允许选择视频-不允许选择视频，去掉选择符
                
                cell.chooseButton.hidden = (asset.mediaType == PHAssetMediaTypeVideo);
            }
            if(!RITLPhotosConfiguration.defaultConfiguration.containImage){//是否允许选择图片-不允许选择图片，去掉选择符
                
                cell.chooseButton.hidden = (asset.mediaType == PHAssetMediaTypeImage);
            }
            BOOL isSelected = [self.dataManager.assetIdentiers containsObject:asset.localIdentifier];
            //进行属性隐藏设置
            cell.indexLabel.hidden = !isSelected;
            
            if (isSelected) {
                
                cell.indexLabel.text = @([self.dataManager.assetIdentiers indexOfObject:asset.localIdentifier] + 1).stringValue;
            }
            
            if (cell.imageView.hidden) { return; }
            
            cell.messageLabel.text = [NSString timeStringWithTimeDuration:asset.duration];
        }
    }];
    
    //注册3D Touch
    if (@available(iOS 9.0,*)) {
        if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable){
            
            [self registerForPreviewingWithDelegate:self sourceView:cell];
        }
    }
    return cell;
}



#pragma mark <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateCachedAssets];
}


#pragma mark <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat sizeHeight = (MIN(RITL_SCREEN_WIDTH,RITL_SCREEN_HEIGHT) - 3.0f * 3) / 4;
    
    return CGSizeMake(sizeHeight, sizeHeight);
}


- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 3.f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 3.f;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //获取当前的资源
    PHAsset *asset = [self.assets objectAtIndex:indexPath.item];
    //跳出控制器
    [self pushHorAllBrowseViewControllerWithAsset:asset];
}



#pragma mark - <UIViewControllerPreviewingDelegate>

- (nullable UIViewController *)previewingContext:(id <UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location NS_AVAILABLE_IOS(9_0)
{
    //获取当前cell的indexPath
    NSIndexPath * indexPath = [self.collectionView indexPathForCell:(RITLPhotosCell *)previewingContext.sourceView];
    
    NSUInteger item = indexPath.item;
    
    //获得当前的资源
    PHAsset *asset = self.assets[item];
    
    if (asset.mediaType != PHAssetMediaTypeImage)
    {
        return nil;
    }
    
    RITLPhotosPreviewController * viewController = [RITLPhotosPreviewController previewWithShowAsset:asset];
    
    return viewController;
}


- (void)previewingContext:(id <UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit NS_AVAILABLE_IOS(9_0)
{
    //获取当前cell的indexPath
    NSIndexPath * indexPath = [self.collectionView indexPathForCell:(RITLPhotosCell *)previewingContext.sourceView];
    
    //获取当前的资源
    PHAsset *asset = [self.assets objectAtIndex:indexPath.item];
    
    //跳出控制器
    [self pushHorAllBrowseViewControllerWithAsset:asset];
}


#pragma mark - Browse All Assets Display

/// Push 出所有的资源浏览
- (void)pushHorAllBrowseViewControllerWithAsset:(PHAsset *)asset
{
    [self.navigationController pushViewController:({
        
        RITLPhotosHorBrowseViewController *browerController = RITLPhotosHorBrowseViewController.new;
        RITLPhotosBrowseAllDataSource *dataSource = RITLPhotosBrowseAllDataSource.new;
        dataSource.collection = self.assetCollection;
        dataSource.asset = asset;
        
        browerController.dataSource = dataSource;
        browerController.backHandler = ^(BOOL isEdit) {
            self.isEdit = isEdit;
//            NSArray * arr = self.assets;
//
//            [self.collectionView reloadData];
        };
        
        browerController;
        
    }) animated:true];
}


/// Push出已经选择的资源浏览
- (void)pushPreviewViewController
{
    [self.navigationController pushViewController:({
        
        RITLPhotosHorBrowseViewController *browerController = RITLPhotosHorBrowseViewController.new;
        
        RITLPhotosBrowseDataSource *dataSource = RITLPhotosBrowseDataSource.new;
        dataSource.assets = self.dataManager.assets;
        
        browerController.dataSource = dataSource;
        browerController.backHandler = ^(BOOL isEdit) {
            [self.collectionView reloadData];
        };
        
        browerController;
        
    }) animated:true];
}

#pragma mark - Send

- (void)pushPhotosMaker {   
    [RITLPhotosMaker.sharedInstance startMakePhotosComplete:^{
       
        [self dismissPhotoControllers];
    }];
}

#pragma mark - collectionView

-(UICollectionView *)collectionView
{
    if(_collectionView == nil)
    {
        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:[[UICollectionViewFlowLayout alloc]init]];
        
        //protocol
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        
        //property
        _collectionView.backgroundColor = [UIColor whiteColor];
    }
    
    return _collectionView;
}

- (UILabel *)tintLable {
    if (!_tintLable) {
        _tintLable = [[UILabel alloc] init];
        _tintLable.font = SYSFONT(16);
        _tintLable.text = [NSString stringWithFormat:@"请在iPhone的“设置-隐私-照片”选项中，允许%@访问你的手机相册",APP_NAME];
        _tintLable.textAlignment = NSTextAlignmentCenter;
        _tintLable.numberOfLines = 0;
        _tintLable.hidden = YES;
    }
    return _tintLable;
}


#pragma mark - <RITLPhotosCellActionTarget>

- (void)photosCellDidTouchUpInSlide:(RITLPhotosCell *)cell asset:(PHAsset *)asset indexPath:(NSIndexPath *)indexPath complete:(RITLPhotosCellStatusAction)animated
{
    if (self.dataManager.count >= RITLPhotosConfiguration.defaultConfiguration.maxCount &&
        ![self.dataManager containAsset:asset]/*是添加*/) {
        
        [g_server showMsg:Localized(@"JX_CannotSelectMorePhotos")];
        
        return;
        
    }//不能进行选择
    
    NSInteger index = [self.dataManager addOrRemoveAsset:asset].integerValue;
    
    animated(RITLPhotosCellAnimatedStatusPermit,index > 0,MAX(0,index));
    
    if (index < 0) {//表示进行了取消操作
        [self.collectionView reloadData];
    }
}


#pragma mark - <KVO>

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"count"] && [object isEqual:self.dataManager]) {
        
        [self changedBottomViewStatus];
    }
    
    else if([keyPath isEqualToString:@"hightQuality"] && [object isEqual:self.dataManager]){
        
        BOOL hightQuality = [change[NSKeyValueChangeNewKey] boolValue];
        self.bottomView.fullImageButton.selected = hightQuality;
    }
}


#pragma mark - 检测

/// 检测底部视图的状态
- (void)changedBottomViewStatus
{
    NSInteger count = self.dataManager.count;
    
    self.bottomView.previewButton.enabled = !(count == 0);
    UIControlState state = (count == 0 ? UIControlStateDisabled : UIControlStateNormal);
    NSString *title;
    if(!RITLPhotosConfiguration.defaultConfiguration.isRichScan){
        title = (count == 0 ? Localized(@"JX_Send") : [NSString stringWithFormat:@"%@(%@)",Localized(@"JX_Send"),@(count)]);
    }else {
        title = Localized(@"JX_Finish");
    }
    [self.bottomView.sendButton setTitle:title forState:state];
    self.bottomView.sendButton.enabled = !(count == 0);
}


#pragma mark - action

- (void)hightQualityShouldChanged:(UIButton *)sender
{
    self.dataManager.hightQuality = !self.dataManager.hightQuality;
}


@end

