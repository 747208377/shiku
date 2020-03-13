//
//  RITLPhotosMaker.m
//  RITLPhotoDemo
//
//  Created by YueWen on 2018/5/18.
//  Copyright © 2018年 YueWen. All rights reserved.
//

#import "RITLPhotosMaker.h"
#import "RITLPhotosDataManager.h"
#import <Photos/Photos.h>
#import "JXMediaObject.h"

#define kCameraVideoPath [FileInfo getUUIDFileName:@"mp4"]


@interface RITLPhotosMaker ()

//@property (nonatomic, copy, nullable)RITLCompleteReaderHandle complete;
@property (nonatomic, strong) PHImageManager *imageManager;

@end

@implementation RITLPhotosMaker

- (instancetype)init
{
    if (self = [super init]) {
        
        self.thumbnailSize = CGSizeZero;
    }
    
    return self;
}

+ (instancetype)sharedInstance
{
    static __weak RITLPhotosMaker *instance;
    RITLPhotosMaker *strongInstance = instance;
    @synchronized(self){
        if (strongInstance == nil) {
            strongInstance = self.new;
            instance = strongInstance;
        }
    }
    return strongInstance;
}

/// 开始执行各种方法
- (void)startMakePhotosComplete:(RITLCompleteReaderHandle)complete
{
    if (!self.delegate) { return; }//代理对象不存在
    
    //identifers
    [self identifersCallBack];
    //assets
    [self assetsCallBack];
    //thumbnailImages
    [self thumbnailImagesCallBack];
    //images
    [self imagesCallBack];
    //data
    [self dataCallBack];
    
    if (complete) { complete(); }//OK
}


#pragma mark - 代理方法

- (void)identifersCallBack
{
    if ([self.delegate respondsToSelector:@selector(photosViewController:assetIdentifiers:)]) {
        
        [self.delegate photosViewController:self.bindViewController
                           assetIdentifiers:RITLPhotosDataManager.sharedInstance.assetIdentiers];
    }
}

- (void)assetsCallBack
{
    if ([self.delegate respondsToSelector:@selector(photosViewController:assets:)]) {
        
        [self.delegate photosViewController:self.bindViewController assets:RITLPhotosDataManager.sharedInstance.assets];
    }
}

- (void)thumbnailImagesCallBack
{
    if (CGSizeEqualToSize(self.thumbnailSize, CGSizeZero)) { return; }//不使用缩略图
    if (![self.delegate respondsToSelector:@selector(photosViewController:thumbnailImages:)]
        && ![self.delegate respondsToSelector:@selector(photosViewController:thumbnailImages:infos:)]) { return; }//不存在该代理方法
    
    //选中的资源对象
    NSArray <PHAsset *> *assets = RITLPhotosDataManager.sharedInstance.assets;
    
    //获得所有的图片资源
    NSMutableArray <UIImage *> *thumbnailImages = [NSMutableArray arrayWithCapacity:assets.count];
    NSMutableArray <NSDictionary *> *infos = [NSMutableArray arrayWithCapacity:assets.count];
    
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.synchronous = true;
    options.networkAccessAllowed = true;
    
    __block BOOL isSend = YES;
    //进行图片请求
    for (PHAsset *asset in assets) {
            if(asset.mediaType == PHAssetMediaTypeImage){
                // 普通图片
                [self.imageManager requestImageForAsset:asset targetSize:self.thumbnailSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    
                    if (!result && [info objectForKey:PHImageResultIsInCloudKey]) {
                        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
                        option.networkAccessAllowed = YES;
                        option.resizeMode = PHImageRequestOptionsResizeModeFast;
                        [[PHImageManager defaultManager] requestImageDataForAsset:asset
                                                                          options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                                                                              UIImage *resultImage = [UIImage imageWithData:imageData scale:0.1];
                                                                              [thumbnailImages addObject:resultImage];
                                                                          }];
                    }else {
                        [thumbnailImages addObject:result];
                    }
                    NSMutableDictionary *mInfo = [NSMutableDictionary dictionaryWithDictionary:info];
                    [infos addObject:mInfo];
                }];
                isSend = YES;
            }
        }
    
        
        
        if (isSend == YES && !RITLPhotosDataManager.sharedInstance.isHightQuality) {
            if ([self.delegate respondsToSelector:@selector(photosViewController:thumbnailImages:infos:)]) {
                
                [self.delegate photosViewController:self.bindViewController thumbnailImages:thumbnailImages infos:infos];
            }else {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
                [self.delegate photosViewController:self.bindViewController thumbnailImages:thumbnailImages];
    #pragma clang diagnostic pop
        }
    }
}



- (void)imagesCallBack {
    if (![self.delegate respondsToSelector:@selector(photosViewController:images:)]
          && ![self.delegate respondsToSelector:@selector(photosViewController:images:infos:)]) { return; }//不存在该代理方法
    
    //选中的资源对象
    NSArray <PHAsset *> *assets = RITLPhotosDataManager.sharedInstance.assets;
    
    //获得所有的图片资源
    NSMutableArray <UIImage *> *images = [NSMutableArray arrayWithCapacity:assets.count];
    NSMutableArray <NSDictionary *> *infos = [NSMutableArray arrayWithCapacity:assets.count];

    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.synchronous = true;
    options.networkAccessAllowed = true;
    
    BOOL isSend = NO;
    //进行图片请求
    for (PHAsset *asset in assets) {
        if(asset.mediaType == PHAssetMediaTypeImage){
            // 普通图片
            [self.imageManager requestImageForAsset:asset targetSize:CGSizeMake(asset.pixelWidth, asset.pixelHeight) contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                if (!result && [info objectForKey:PHImageResultIsInCloudKey]) {
                    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
                    option.networkAccessAllowed = YES;
                    option.resizeMode = PHImageRequestOptionsResizeModeFast;
                    [[PHImageManager defaultManager] requestImageDataForAsset:asset
                                                                      options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                                                                          UIImage *resultImage = [UIImage imageWithData:imageData];
                                                                          [images addObject:resultImage];
                                                                      }];
                }else {
                    [images addObject:result];
                }
                NSMutableDictionary *mInfo = [NSMutableDictionary dictionaryWithDictionary:info];
                [infos addObject:mInfo];
            }];
        isSend = YES;
        }
    }
    if (isSend == YES && RITLPhotosDataManager.sharedInstance.isHightQuality) {
        if ([self.delegate respondsToSelector:@selector(photosViewController:images:infos:)]) {
            [self.delegate photosViewController:self.bindViewController images:images infos:infos];
        }else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [self.delegate photosViewController:self.bindViewController images:images];
#pragma clang diagnostic pop
        }
    }
}


- (void)dataCallBack
{
    if (![self.delegate respondsToSelector:@selector(photosViewController:datas:)] && ![self.delegate respondsToSelector:@selector(photosViewController:media:)]) { return; }//不存在该代理方法

    //选中的资源对象
    NSArray <PHAsset *> *assets = RITLPhotosDataManager.sharedInstance.assets;
    //是否为原图
    BOOL hightQuality = RITLPhotosDataManager.sharedInstance.isHightQuality;

    //获得所有的图片资源
    __block NSMutableArray <id> *datas = [NSMutableArray arrayWithCapacity:assets.count];
    
    __block NSMutableArray *videoData = [NSMutableArray arrayWithCapacity:assets.count];

    PHImageRequestOptions *options = PHImageRequestOptions.new;
    options.deliveryMode = hightQuality ? PHImageRequestOptionsDeliveryModeHighQualityFormat : PHImageRequestOptionsDeliveryModeOpportunistic;
    options.synchronous = true;
    options.networkAccessAllowed = true;
    
    BOOL isSend = NO;
    for (PHAsset *asset in assets) {
        if (asset.mediaType == PHAssetMediaTypeVideo) {
            PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
            options.version = PHVideoRequestOptionsVersionOriginal;
            options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
            options.networkAccessAllowed = YES;
            
            [self.imageManager requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    AVURLAsset *urlAsset = (AVURLAsset *)asset;
                    //获取视频本地URL
                    NSURL *url = urlAsset.URL;
                    //本地URL存在并且没有保存在数据库
                    if (url) {
                        // 获取视频data
                        NSData *data = [NSData dataWithContentsOfURL:url];
                        //获取视频拍摄时间
                        NSDate *date = [self getAudioCreatDate:url];
                        //新建一个路径并写入视频data
                        NSString *dataPath = kCameraVideoPath;
                        [data writeToFile:dataPath atomically:YES];
                        // 获取视频时长
                        AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:nil];
                        NSInteger second = 0;
                        second = (NSInteger)urlAsset.duration.value / urlAsset.duration.timescale;
                        
                        JXMediaObject* p = [[JXMediaObject alloc] init];
                        p.userId = MY_USER_ID;
                        p.fileName = dataPath;
                        p.isVideo = [NSNumber numberWithBool:YES];
                        p.timeLen = [NSNumber numberWithInteger:second];
                        p.createTime = date;
                        p.photoPath = url.absoluteString;
                        [videoData addObject:p];
                        
                        if ([self.delegate respondsToSelector:@selector(photosViewController:media:)]) {
                            [self.delegate photosViewController:self.bindViewController media:p];
                        }
                    }
                });
            }];
        }else if(asset.mediaType == PHAssetMediaTypeImage){
            
            __block BOOL isGif = NO;
            // GIF 图片
            NSArray *resourceList = [PHAssetResource assetResourcesForAsset:asset];
            [resourceList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                PHAssetResource *resource = obj;
                PHAssetResourceRequestOptions *option = [[PHAssetResourceRequestOptions alloc]init];
                option.networkAccessAllowed = YES;
                if ([resource.uniformTypeIdentifier isEqualToString:@"com.compuserve.gif"]) {
                    // 拼接图片名为resource.originalFilename的路径
                    NSString *imagePath = [myTempFilePath stringByAppendingPathComponent:resource.originalFilename];
                    __block NSData *data = [[NSData alloc] init];
                    [[PHAssetResourceManager defaultManager] writeDataForAssetResource:resource toFile:[NSURL fileURLWithPath:imagePath] options:option completionHandler:^(NSError * _Nullable error) {
                        if (error) {
                            NSLog(@"error:%@",error);
                            if(error.code == -1){//文件已存在
                                data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:imagePath]];
                            }
                        } else {
                            data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:imagePath]];
                        }
                        
                        [datas addObject:data];
                    }];

                    if (data) {
                        isGif = YES;
                    }
                }
            }];
            if (!isGif) {
                // 普通图片
                [self.imageManager requestImageForAsset:asset targetSize:CGSizeMake(asset.pixelWidth, asset.pixelHeight) contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    if (!result && [info objectForKey:PHImageResultIsInCloudKey]) {
                        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
                        option.networkAccessAllowed = YES;
                        option.resizeMode = PHImageRequestOptionsResizeModeFast;
                        [[PHImageManager defaultManager] requestImageDataForAsset:asset
                                                                          options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                                                                              UIImage *resultImage = [UIImage imageWithData:imageData scale:hightQuality ? 1 : 0.4];
                                                                              [datas addObject:resultImage];
                                                                          }];
                    }else {
                        UIImage *resultImage = [UIImage imageWithData:UIImageJPEGRepresentation(result, hightQuality ? 1 : 0.4)];
                        [datas addObject:resultImage];
                    }
                }];
            }
        }
        isSend = YES;
    }
    if (isSend == YES) {
        if ([self.delegate respondsToSelector:@selector(photosViewController:datas:)]) {
            [self.delegate photosViewController:self.bindViewController datas:datas];
        }
    }
}


- (void)dealloc
{
    NSLog(@"[%@] is dealloc",NSStringFromClass(self.class));
}


- (PHImageManager *)imageManager
{
    if (PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusAuthorized && !_imageManager) {
        
        _imageManager = PHImageManager.new;
    }
    
    return _imageManager;
}

- (NSDate *)getAudioCreatDate:(NSURL*)URL {
    NSDate *creatDate;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *fileAttributes = [fm attributesOfItemAtPath:URL.path error:nil];
    if (fileAttributes) {
        if ((creatDate = [fileAttributes objectForKey:NSFileCreationDate])) {
            NSLog(@"date = %@",creatDate);
            return creatDate;
        }
    }
    return nil;
}


@end
