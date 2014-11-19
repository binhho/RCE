//
//  ViewController.m
//  RCE-Demo
//
//  Created by admin on 11/14/14.
//  Copyright (c) 2014 Pyco. All rights reserved.
//

#import "ViewController.h"
#import "Album.h"
#import "AlbumRepository.h"
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import "EditorViewController.h"
#import "CreatorViewController.h"

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>{
    AlbumRepository *_albumRepository;
}

@property (nonatomic, weak) IBOutlet UITableView *ibAlbumTableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _albumRepository = [AlbumRepository new];
    [_albumRepository loadAlbums:^(NSError *error) {
        if (error == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.ibAlbumTableView reloadData];
            });
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)ibaCreateAlbumButtonTouchUpInside:(id)sender{
    UIAlertView *alert = [[UIAlertView alloc] bk_initWithTitle:@"Create ALbum" message:@"Key the album name"];
    [alert bk_addButtonWithTitle:@"CLose" handler:nil];
    __weak typeof(self)wSelf             = self;
    __weak typeof(_albumRepository)wRepo = _albumRepository;
    [alert bk_addButtonWithTitle:@"Create" handler:^{
        if ([[alert textFieldAtIndex:0].text length]) {
            Album *album = [[Album alloc] init];
            album.name   = [alert textFieldAtIndex:0].text;
            [_albumRepository addAlbum:album completed:^(NSError *error) {
                [wRepo saveAlbums:^(NSError *error) {
                    
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [wSelf.ibAlbumTableView reloadData];
                });
            }];
        }
    }];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _albumRepository.albums.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellId = @"AlbumCellID";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    
    Album *album = _albumRepository.albums[indexPath.row];
    cell.textLabel.text = album.name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    /*
    Album *album                     = _albumRepository.albums[indexPath.row];
    UIStoryboard *main               = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    EditorViewController *controller = (EditorViewController*)[main instantiateViewControllerWithIdentifier:@"editorVC"];
    controller.album                 = album;
    [self.navigationController pushViewController:controller animated:YES];
     */
    
    Album *album                      = _albumRepository.albums[indexPath.row];
    UIStoryboard *main                = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    CreatorViewController *controller = (CreatorViewController*)[main instantiateViewControllerWithIdentifier:@"creatorVC"];
    controller.album                  = album;
    [self.navigationController pushViewController:controller animated:YES];
}

@end
