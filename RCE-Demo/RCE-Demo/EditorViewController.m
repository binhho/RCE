//
//  EditorViewController.m
//  RCE-Demo
//
//  Created by admin on 11/14/14.
//  Copyright (c) 2014 Pyco. All rights reserved.
//

#import "EditorViewController.h"
#import "Album.h"
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import <BlocksKit/UIActionSheet+BlocksKit.h>
#import "AppDelegate.h"
#import "RecordCell.h"
#import "Record.h"

#define MESSAGE_TEXT_WIDTH_MAX               280

#define MESSAGE_TEXT_SIZE_WITH_FONT(text, font) \
[text boundingRectWithSize:CGSizeMake(self.ibRecordsTableView.frame.size.width - 20, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil]

@interface EditorViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *ibRecordsTableView;

@end

@implementation EditorViewController

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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)ibaAddRecord:(id)sender{
    UIActionSheet *sheet = [UIActionSheet bk_actionSheetWithTitle:@"Record Type"];
    [sheet bk_addButtonWithTitle:@"Text Record" handler:^{
        [self addTextRecord];
    }];
    
    [sheet bk_addButtonWithTitle:@"Photo Record" handler:^{
        
    }];
    [sheet bk_addButtonWithTitle:@"Cancel" handler:nil];
    AppDelegate *app = ((AppDelegate*)[UIApplication sharedApplication].delegate);
    [sheet showInView:app.window];
}

- (void)addTextRecord{
    UIAlertView *alert = [[UIAlertView alloc] bk_initWithTitle:@"Create Text Record" message:@"Content"];
    [alert bk_addButtonWithTitle:@"CLose" handler:nil];
    __weak typeof(self)wSelf = self;
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
        case Type_RecordPhoto:
            return 44.0f;
            break;
            
        default:
            break;
    }
    
    return 0.0f;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellId = @"RecordCellID";
    RecordCell *cell = (RecordCell*)[tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[RecordCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    else{
        NSLog(@"re-use cell");
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(RecordCell*)cell atIndexPath:(NSIndexPath*)indexPath{
    cell.contentTextView.text = @"";
    Record *record            = _album.records[indexPath.row];
    switch (record.type) {
        case Type_RecordText:{
            cell.contentTextView.frame = CGRectMake(10, 10, cell.contentView.frame.size.width - 20, cell.contentView.frame.size.height - 20);
            cell.contentTextView.text = record.textContent;
        }
            break;
        case Type_RecordPhoto:
            
            break;
            
        default:
            break;
    }
}

@end
