//
//  FilterView.m
//  MyPhoto
//
//  Created by 董宝龙 on 2016/10/24.
//  Copyright © 2016年 dbl. All rights reserved.
//
#define kScreenBounds   [UIScreen mainScreen].bounds
#define kScreenWidth  kScreenBounds.size.width*1.0
#define kScreenHeight kScreenBounds.size.height*1.0
#import "FilterView.h"
#import "GPUImage.h"

@interface FilterView ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>

@property (nonatomic , strong) UIButton * cancelButton;

@property (nonatomic , strong) UIButton * saveButton;

@property (nonatomic , strong) UIImageView * imageView;

@property (nonatomic , strong) UICollectionView * collectionView;

@property (nonatomic , strong) UIView * topView;

@property (nonatomic , strong) UIView * bottomView;

@property (nonatomic , strong) NSMutableArray * dataArray;

@property (nonatomic , strong) NSMutableArray * filterNameArray;

@property (nonatomic , strong) UIImage * originalImage;

@property (nonatomic , strong) UIImage * filterImage;

@end

@implementation FilterView

- (instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image{
    self = [super initWithFrame:frame];
    if (self) {
        self.originalImage = image;
        _dataArray = [[NSMutableArray alloc] init];
        _dataArray = [[NSMutableArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Filter" ofType:@"plist"]];
        _filterNameArray = [[NSMutableArray alloc] init];
        _filterNameArray = [[NSMutableArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FilterName" ofType:@"plist"]];
        
        _topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 30+128/4+10)];
        _topView.backgroundColor = [UIColor blackColor];
        [self addSubview:_topView];
        
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelButton.frame = CGRectMake(20, 30, 128/4, 128/4);
        [_cancelButton setImage:[UIImage imageNamed:@"错"] forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [_topView addSubview:_cancelButton];
        
        self.saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.saveButton.frame = CGRectMake(kScreenWidth-20-128/4, 30, 128/4, 128/4);
        [self.saveButton setImage:[UIImage imageNamed:@"对"] forState:UIControlStateNormal];
        [self.saveButton addTarget:self action:@selector(saveButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [_topView addSubview:self.saveButton];
        
        _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, kScreenHeight-80, kScreenWidth, 80)];
        _bottomView.backgroundColor = [UIColor blackColor];
        [self addSubview:_bottomView];
        
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_topView.frame), kScreenWidth, kScreenHeight - CGRectGetHeight(_topView.frame) - CGRectGetHeight(_bottomView.frame))];
        self.imageView.image = image;
        [self addSubview:self.imageView];
        
        UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.itemSize = CGSizeMake(50, 59);
        layout.minimumLineSpacing = 10;
        
        self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 80) collectionViewLayout:layout];
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
        [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        [_bottomView addSubview:self.collectionView];
    }
    return self;
}

#pragma mark - collectViewDelegate
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell * cell  = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
    for (UIView *ivew in cell.contentView.subviews) {
        [ivew removeFromSuperview];
    }
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 59/2-10, 50, 20)];
    label.text = _filterNameArray[indexPath.row];
    label.textColor = [UIColor blackColor];
    label.font = [UIFont systemFontOfSize:14];
    label.textAlignment = NSTextAlignmentCenter;
    [cell.contentView addSubview:label];
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _filterNameArray.count;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 10, 0, 10);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    [_imageView removeFromSuperview];
    [self updateImageFilter:_dataArray[indexPath.row]];

}

- (void)updateImageFilter:(NSString *)filterType {
    
    Class someClass = NSClassFromString(filterType);
    id obj = [[someClass alloc] init];
    //方向转为正常的
    [obj setInputRotation:kGPUImageRotateRight atIndex:0];
    
    [obj forceProcessingAtSize:self.originalImage.size];
    [obj useNextFrameForImageCapture];
    
    GPUImagePicture * stillImageSource = [[GPUImagePicture alloc]initWithImage:self.originalImage];
    [stillImageSource addTarget:obj];
    
    [stillImageSource processImage];
    
    UIImage * newImage = [obj imageFromCurrentFramebuffer];
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_topView.frame), kScreenWidth, kScreenHeight - CGRectGetHeight(_topView.frame) - CGRectGetHeight(_bottomView.frame))];
    self.imageView.image = newImage;
    [self addSubview:self.imageView];
    
    //****其中晕影、锐化、饱和度、对比度、曝光、亮度、形变、高斯模糊等都有一个属性可以设置，后面研究一下**** 更多效果请查看http://blog.csdn.net/gaojq_ios/article/details/46924491
}

- (void)saveButtonClick {
    NSLog(@"保存");
}

- (void)cancelButtonClick{
    NSLog(@"取消");
    [UIView animateWithDuration:0.35 animations:^{
        self.frame = CGRectMake(kScreenWidth, 0, kScreenWidth, kScreenHeight);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}


@end
