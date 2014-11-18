//
//  EditorViewController.m
//  RCE-Demo
//
//  Created by admin on 11/14/14.
//  Copyright (c) 2014 Pyco. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "EditorViewController.h"
#import "Album.h"
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import <BlocksKit/UIActionSheet+BlocksKit.h>
#import "AppDelegate.h"
#import "RecordCell.h"
#import "Record.h"
#import "UIImage+Resize.h"

#define MESSAGE_TEXT_SIZE_WITH_FONT(text, font) \
[text boundingRectWithSize:CGSizeMake(self.ibRecordsTableView.frame.size.width - 20, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil]

@interface EditorViewController () <UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>{
    __weak IBOutlet UIImageView *_ibAvatarImageView;
}

@property (nonatomic, weak) IBOutlet UITableView *ibRecordsTableView;
@property (nonatomic, strong) UIImagePickerController *imgPickerVC;

@end

@implementation EditorViewController

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
    self.title = _album.name;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(ibaAddRecord:)];
    __weak typeof (self)wSelf = self;
    [_album loadRecords:^(NSError *error) {
        if (_album.records.count) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [wSelf.ibRecordsTableView reloadData];
            });
        }
    }];
    
    _ibAvatarImageView.layer.borderWidth   = 1.0;
    _ibAvatarImageView.layer.borderColor   = [[UIColor whiteColor] CGColor];
    _ibAvatarImageView.layer.cornerRadius  = 50;
    _ibAvatarImageView.layer.masksToBounds = YES;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
}

- (void)startEditAtRecord:(Record*)record{
    [self.ibRecordsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[_album.records indexOfObject:record] inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)keyboardWillShown:(NSNotification*)notification{
    NSDictionary* info = [notification userInfo];
    CGSize kbSize      = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    self.ibRecordsTableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - kbSize.height);
}

- (void)keyboardWillHide:(NSNotification*)notification{    
//    [self.ibRecordsTableView scrollRectToVisible:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) animated:YES];
    self.ibRecordsTableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}

- (IBAction)ibaAddRecord:(id)sender{
    UIActionSheet *sheet = [UIActionSheet bk_actionSheetWithTitle:@"Record Type"];
    [sheet bk_addButtonWithTitle:@"Text Record" handler:^{
        [self addTextRecord];
    }];
    
    [sheet bk_addButtonWithTitle:@"Photo Record" handler:^{
        [self addPhotoRecord];
    }];
    [sheet bk_addButtonWithTitle:self.ibRecordsTableView.editing?@"Done":@"Edit" handler:^{
        if (self.ibRecordsTableView.editing) {
            self.ibRecordsTableView.editing = NO;
            [_album saveRecords:nil];
        }
        else{
            self.ibRecordsTableView.editing = YES;
        }
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
    __weak typeof(self)wSelf    = self;
    __weak typeof(_album)wAlbum = _album;
    [alert bk_addButtonWithTitle:@"Record Text" handler:^{
        if ([[alert textFieldAtIndex:0].text length]) {
            
            Record *record     = [[Record alloc] init];
            record.type        = Type_RecordText;
            record.textContent = [alert textFieldAtIndex:0].text;
            
            [wAlbum addRecord:record completed:^(NSError *error) {
                [wAlbum saveRecords:nil];
               dispatch_async(dispatch_get_main_queue(), ^{
                   [wSelf.ibRecordsTableView reloadData];
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
    
    __weak typeof(self)wSelf    = self;
    __weak typeof(_album)wAlbum = _album;
    
    Record *record              = [[Record alloc] init];
    record.type                 = Type_RecordPhoto;
    record.imgWidth             = resizedImgSize.width;
    record.imgHeight            = resizedImgSize.height;
    
    [wAlbum addPhotoRecord:record withData:UIImagePNGRepresentation(image) completed:^(NSError *error) {
        [wAlbum saveRecords:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [wSelf.ibRecordsTableView reloadData];
        });
    }];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _album.records.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    Record *record = _album.records[indexPath.row];
    switch (record.type) {
        case Type_RecordText:{
            CGSize textSize = MESSAGE_TEXT_SIZE_WITH_FONT(record.textContent, [UIFont systemFontOfSize:13.0f]).size;
            return textSize.height + 30;
        }
            break;
        case Type_RecordPhoto:{
            CGSize imageSize = CGSizeMake(record.imgWidth, record.imgHeight);
            CGSize resizedSize = [UIImage scaledSizeFromSize:imageSize toWidth:(tableView.frame.size.width - 20)];
            return resizedSize.height + 20;
        }
            break;
            
        default:
            break;
    }
    
    return 0.0f;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    Record *record = _album.records[indexPath.row];
    switch (record.type) {
        case Type_RecordText:{
            CGSize textSize = MESSAGE_TEXT_SIZE_WITH_FONT(record.textContent, [UIFont systemFontOfSize:13.0f]).size;
            return textSize.height + 30;
        }
            break;
        case Type_RecordPhoto:{
            CGSize imageSize = CGSizeMake(record.imgWidth, record.imgHeight);
            CGSize resizedSize = [UIImage scaledSizeFromSize:imageSize toWidth:(tableView.frame.size.width - 20)];
            return resizedSize.height + 20;
        }
            break;
            
        default:
            break;
    }
    
    return 0.0f;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellId = @"RecordCellID";
    RecordCell *cell        = (RecordCell*)[tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[RecordCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath{
    [_album reorderBetweenIndex:sourceIndexPath.row andIndex:destinationIndexPath.row completed:nil];
}

- (void)configureCell:(RecordCell*)cell atIndexPath:(NSIndexPath*)indexPath{
    cell.contentTextView.text = @"";
    cell.photoImageView.image = nil;
    Record *record            = _album.records[indexPath.row];
    cell.record               = record;
    cell.editorVC             = self;
    
    switch (record.type) {
        case Type_RecordText:{
            CGSize textSize            = MESSAGE_TEXT_SIZE_WITH_FONT(record.textContent, [UIFont systemFontOfSize:13.0f]).size;
            cell.contentTextView.frame = CGRectMake(10, 10, self.ibRecordsTableView.frame.size.width - 20, textSize.height + 10);
            cell.contentTextView.text  = record.textContent;
        }
            break;
        case Type_RecordPhoto:{
            CGSize imageSize          = CGSizeMake(record.imgWidth, record.imgHeight);
            CGSize resizedSize        = [UIImage scaledSizeFromSize:imageSize toWidth:(self.ibRecordsTableView.frame.size.width - 20)];
            cell.photoImageView.frame = CGRectMake(10, 10, resizedSize.width, resizedSize.height);
            
            [_album getImageDataForRecord:record completde:^(NSData *data) {
                if (data) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        cell.photoImageView.image = [UIImage imageWithData:data];
                    });
                }
            }];
        }
            break;
            
        default:
            break;
    }
}

@end
