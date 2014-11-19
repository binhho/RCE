//
//  CreatorViewController.m
//  RCE-Demo
//
//  Created by admin on 11/18/14.
//  Copyright (c) 2014 Pyco. All rights reserved.
//

#import "CreatorViewController.h"
#import "Album.h"
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import <BlocksKit/UIActionSheet+BlocksKit.h>
#import "AppDelegate.h"
#import "Record.h"
#import "UIImage+Resize.h"

#define kSeparatorHeight    10.0f //Space Between 2 UI elements.
#define kUIElementBaseTag   1000
#define kFakeUIElementBase  4000

#define MESSAGE_TEXT_SIZE_WITH_FONT(text, font) \
[text boundingRectWithSize:CGSizeMake(self.ibMainScrollView.frame.size.width - 20, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil]

@interface CreatorViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, UIGestureRecognizerDelegate>{
    NSMutableArray *_uiElements;
    CGPoint _previousLocation;
}

@property (nonatomic, strong) UIImagePickerController *imgPickerVC;
@property (nonatomic, weak) IBOutlet UIScrollView *ibMainScrollView;
@property (nonatomic, weak) IBOutlet UIPanGestureRecognizer *ibPanGestureReg;

@end

@implementation CreatorViewController

@synthesize imgPickerVC = _imgPickerVC;

- (UIImagePickerController*)imgPickerVC{
    if (_imgPickerVC == nil) {
        _imgPickerVC            = [[UIImagePickerController alloc] init];
        _imgPickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        _imgPickerVC.delegate   = self;
    }
    
    return _imgPickerVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationController.navigationBar.translucent = NO;
    
    self.title                             = _album.name;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(ibaAddRecord:)];
    
    _previousLocation = CGPointZero;
    
    [_album loadRecords:^(NSError *error) {
        if (_album.records.count) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self reloadData];
            });
        }
    }];
}

- (IBAction)ibaAddRecord:(id)sender{
    UIActionSheet *sheet = [UIActionSheet bk_actionSheetWithTitle:@"Record Type"];
    [sheet bk_addButtonWithTitle:@"Text Record" handler:^{
        [self addTextRecord];
    }];
    
    [sheet bk_addButtonWithTitle:@"Photo Record" handler:^{
        [self addPhotoRecord];
    }];
    [sheet bk_addButtonWithTitle:@"Cancel" handler:nil];
    AppDelegate *app = ((AppDelegate*)[UIApplication sharedApplication].delegate);
    [sheet showInView:app.window];
}

- (void)addPhotoRecord{
    [self.navigationController presentViewController:self.imgPickerVC animated:YES completion:nil];
}

- (void)addTextRecord{
    UIAlertView *alert = [[UIAlertView alloc] bk_initWithTitle:@"Create Text Record" message:@"Content"];
    [alert bk_addButtonWithTitle:@"CLose" handler:nil];
    __weak typeof(_album)wAlbum = _album;
    [alert bk_addButtonWithTitle:@"Record Text" handler:^{
        if ([[alert textFieldAtIndex:0].text length]) {
            
            Record *record     = [[Record alloc] init];
            record.type        = Type_RecordText;
            record.textContent = [alert textFieldAtIndex:0].text;
            
            [wAlbum addRecord:record completed:^(NSError *error) {
                [wAlbum saveRecords:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    //TODO: reload
                });
            }];
        }
    }];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    //Caculate Image Size
    CGSize originalImgSize      = image.size;
    CGSize resizedImgSize       = [UIImage scaledSizeFromSize:originalImgSize toWidth:414];
    
    __weak typeof(_album)wAlbum = _album;
    
    Record *record              = [[Record alloc] init];
    record.type                 = Type_RecordPhoto;
    record.imgWidth             = resizedImgSize.width;
    record.imgHeight            = resizedImgSize.height;
    
    [wAlbum addPhotoRecord:record withData:UIImagePNGRepresentation(image) completed:^(NSError *error) {
        [wAlbum saveRecords:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            //TODO: reload
        });
    }];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -

- (CGSize)totalContentSize{
    if (_album.records.count) {
        CGFloat height = kSeparatorHeight;
        for (Record *record in _album.records) {
            switch (record.type) {
                case Type_RecordText:{
                    CGSize textSize = MESSAGE_TEXT_SIZE_WITH_FONT(record.textContent, [UIFont systemFontOfSize:13.0f]).size;
                    height          += textSize.height;
                }
                    break;
                case Type_RecordPhoto:{
                    CGSize imageSize   = CGSizeMake(record.imgWidth, record.imgHeight);
                    CGSize resizedSize = [UIImage scaledSizeFromSize:imageSize toWidth:(self.ibMainScrollView.frame.size.width - 20)];
                    height             += resizedSize.height;
                }
                    break;
                    
                default:
                    break;
            }
            height += kSeparatorHeight;
        }
        
        return CGSizeMake(self.view.frame.size.width, height);
    }
    
    return CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
}

- (CGFloat)topCoordinateAtIndex:(NSInteger)index{
    if (index > _album.records.count) {
        return 0.0f;
    }
    if (_album.records.count == 0) {
        return 0.0f;
    }
    CGFloat height = kSeparatorHeight;
    for (NSInteger recordIndex = 0; recordIndex < index; recordIndex++) {
        Record *record = _album.records[recordIndex];
        switch (record.type) {
            case Type_RecordText:{
                CGSize textSize = MESSAGE_TEXT_SIZE_WITH_FONT(record.textContent, [UIFont systemFontOfSize:13.0f]).size;
                height          += textSize.height;
            }
                break;
            case Type_RecordPhoto:{
                CGSize imageSize   = CGSizeMake(record.imgWidth, record.imgHeight);
                CGSize resizedSize = [UIImage scaledSizeFromSize:imageSize toWidth:(self.ibMainScrollView.frame.size.width - 20)];
                height             += resizedSize.height;
            }
                break;
                
            default:
                break;
        }
        height += kSeparatorHeight;
    }
    
    return height;
}

- (void)scrollToRecordIndex:(NSInteger)index{
    [self.ibMainScrollView scrollRectToVisible:CGRectMake(0, [self topCoordinateAtIndex:index], self.ibMainScrollView.frame.size.width, self.ibMainScrollView.frame.size.height) animated:YES];
}

- (void)reloadData{
    for (NSInteger elementIndex = 0; elementIndex < _album.records.count; elementIndex++) {
        Record *record = _album.records[elementIndex];
        switch (record.type) {
            case Type_RecordText:{
                UITextView *textview            = [[UITextView alloc] initWithFrame:CGRectZero];
                textview.backgroundColor        = [UIColor grayColor];
                textview.font                   = [UIFont systemFontOfSize:13.0f];
                textview.textColor              = [UIColor darkGrayColor];
                textview.text                   = record.textContent;
                textview.editable               = NO;
                textview.userInteractionEnabled = YES;
                textview.delegate               = self;
                [self.ibMainScrollView addSubview:textview];
                CGSize textSize = MESSAGE_TEXT_SIZE_WITH_FONT(record.textContent, [UIFont systemFontOfSize:13.0f]).size;
                textview.frame  = CGRectMake(10, [self topCoordinateAtIndex:elementIndex], textSize.width, textSize.height);
                textview.tag    = kUIElementBaseTag + elementIndex;
                [_uiElements addObject:textview];
                UILongPressGestureRecognizer *reg = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestureLongPressed:)];
                reg.delegate                      = self;
                [reg setMinimumPressDuration:0.5f];
                [textview addGestureRecognizer:reg];
            }
                break;
            case Type_RecordPhoto:{
                UIImageView *imageView           = [[UIImageView alloc] initWithFrame:CGRectZero];
                imageView.backgroundColor        = [UIColor clearColor];
                imageView.userInteractionEnabled = YES;
                imageView.tag                    = kUIElementBaseTag + elementIndex;
                [self.ibMainScrollView addSubview:imageView];
                
                CGSize imageSize   = CGSizeMake(record.imgWidth, record.imgHeight);
                CGSize resizedSize = [UIImage scaledSizeFromSize:imageSize toWidth:(self.ibMainScrollView.frame.size.width - 20)];
                imageView.frame    = CGRectMake(10, [self topCoordinateAtIndex:elementIndex], resizedSize.width, resizedSize.height);
                
                [_album getImageDataForRecord:record completde:^(NSData *data) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        imageView.image = [UIImage imageWithData:data];
                    });
                }];
                UILongPressGestureRecognizer *reg = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestureLongPressed:)];
                [reg setMinimumPressDuration:0.5f];
                [imageView addGestureRecognizer:reg];
                
                [_uiElements addObject:imageView];
            }
                break;
                
            default:
                break;
        }
    }
    self.ibMainScrollView.contentSize = [self totalContentSize];
}

- (NSInteger)recordIndexAtLocationPoint:(CGPoint)point{
    for (NSInteger index = 0; index < _album.records.count - 1; index++) {
        if ([self topCoordinateAtIndex:index] > point.y && [self topCoordinateAtIndex:index + 1]) {
            return index;
        }
    }
    return 0;
}

- (IBAction)ibaPan:(UIPanGestureRecognizer*)recognizer{
    CGPoint currentlocation = [recognizer locationInView:self.view];
    NSLog(@"Move : %@", NSStringFromCGPoint(currentlocation));
}

- (void)gestureLongPressed:(UILongPressGestureRecognizer*)regconizer{
    if (regconizer.state == UIGestureRecognizerStateBegan) {
        id sender = regconizer.view;
        _previousLocation = [regconizer locationInView:self.ibMainScrollView];
        if ([sender isKindOfClass:[UITextView class]]) {
            //Make a copy
            UITextView *senderTextView      = (UITextView*)regconizer.view;
            UITextView *textView            = [[UITextView alloc] initWithFrame:CGRectZero];
            textView.backgroundColor        = senderTextView.backgroundColor;
            textView.font                   = senderTextView.font;
            textView.textColor              = senderTextView.textColor;
            textView.text                   = senderTextView.text;
            textView.editable               = NO;
            textView.userInteractionEnabled = YES;
            textView.tag                    = kFakeUIElementBase + textView.tag;
            [self.ibMainScrollView addSubview:textView];
            textView.frame = senderTextView.frame;
        }
        else if ([sender isKindOfClass:[UIImageView class]]){
            UIImageView *senderImageView = (UIImageView*)regconizer.view;
            UIImageView *imageView       = [[UIImageView alloc] initWithFrame:CGRectZero];
            imageView.tag                = kFakeUIElementBase + senderImageView.tag;
            imageView.image              = senderImageView.image;
            [self.ibMainScrollView addSubview:imageView];
            imageView.frame                 = senderImageView.frame;
            senderImageView.image           = nil;
            senderImageView.backgroundColor = [UIColor grayColor];
        }
    }
    else if (regconizer.state == UIGestureRecognizerStateChanged){
        id sender = regconizer.view;
        CGPoint newLocation = [regconizer locationInView:self.ibMainScrollView];
        NSLog(@"newLocation : %@", NSStringFromCGPoint(newLocation));
        //TODO: Check current touch position to scroll the scrollview
        if (newLocation.y < 300.0 && self.ibMainScrollView.contentOffset.y > 0) {
            NSLog(@"index %ld", (long)[self recordIndexAtLocationPoint:newLocation]);
            [self scrollToRecordIndex:[self recordIndexAtLocationPoint:newLocation] - 1];
        }
        if ([sender isKindOfClass:[UITextView class]]) {
            //Detect sender view
            UITextView *textView = (UITextView*)[self.ibMainScrollView viewWithTag:regconizer.view.tag + kFakeUIElementBase];
            textView.center = CGPointMake(textView.center.x + (newLocation.x - _previousLocation.x), textView.center.y + (newLocation.y - _previousLocation.y));
        }
        else if ([sender isKindOfClass:[UIImageView class]]){
            UIImageView *imageView = (UIImageView*)[self.ibMainScrollView viewWithTag:regconizer.view.tag + kFakeUIElementBase];
            imageView.center = CGPointMake(imageView.center.x + (newLocation.x - _previousLocation.x), imageView.center.y + (newLocation.y - _previousLocation.y));
        }
        
        _previousLocation = newLocation;
    }
    else if (regconizer.state == UIGestureRecognizerStateEnded){
        id sender = regconizer.view;
        if ([sender isKindOfClass:[UITextView class]]) {
            //Detect sender view
            UITextView *textView = (UITextView*)[self.ibMainScrollView viewWithTag:regconizer.view.tag + kFakeUIElementBase];
            textView.center = [regconizer locationInView:self.ibMainScrollView];
            [textView removeFromSuperview];
        }
        else if ([sender isKindOfClass:[UIImageView class]]){
            UIImageView *imageView = (UIImageView*)[self.ibMainScrollView viewWithTag:regconizer.view.tag + kFakeUIElementBase];
            imageView.center = [regconizer locationInView:self.ibMainScrollView];
            
            UIImageView *originalImgView = (UIImageView*)[self.ibMainScrollView viewWithTag:(imageView.tag - kFakeUIElementBase)];
            originalImgView.image = imageView.image;
            
            [imageView removeFromSuperview];
        }
    }
}

- (void)reframeFromRecordIndex:(NSInteger)fromIndex toInsertRecordAtIndex:(NSInteger)toIndex{
    UIView *topview    = nil;
    UIView *bottomView = nil;
    if (fromIndex < toIndex) {
        
    }
    else if (fromIndex > toIndex){
        
    }
}

#pragma mark - Long

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    return YES;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if([text isEqualToString:@"\n"]){
        [textView resignFirstResponder];
    }
    
    return YES;
}

@end
