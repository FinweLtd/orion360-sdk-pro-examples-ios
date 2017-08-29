//
//  ViewController.m
//  Hello Orion360 AppleTV
//
//  Created by Hannu Limma on 29/08/2017.
//  Copyright © 2017 Finwe Ltd. All rights reserved.
//

#import "ViewController.h"
#import <orion360-sdk-pro-ios/OrionView.h>

@interface ViewController ()<OrionViewDelegate, OrionVideoContentDelegate>
@property (nonatomic) OrionView* orionView;
@property (nonatomic) OrionVideoContent* videoContent;
@property (nonatomic) OrionViewport* viewport;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!_orionView)
    {
        _orionView = [[OrionView alloc] init];
        _orionView.delegate = self;
        _orionView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        
        // check license
        NSString *licenseFile = [NSString stringWithFormat:@"license.key.lic"];
        NSString* path = [[NSBundle mainBundle] pathForResource:licenseFile ofType:nil];
        BOOL isDirectory;
        BOOL fileExistsAtPath = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
        if (fileExistsAtPath)
        {
            NSURL *licenseUrl = [NSURL fileURLWithPath:path];
            [_orionView setLicenseFileUrl:licenseUrl];
        }
        else
        {
            NSLog(@"No license file, please check install that full features.");
        }
        [self.view addSubview:_orionView];
        
        _orionView.overrideSilentSwitch = YES;
        _orionView.alpha = 0.0f;
        
        _videoContent = [[OrionVideoContent alloc] init];
        _videoContent.delegate = self;
        
        _videoContent.uriArray = [[NSArray alloc] initWithObjects:[NSURL URLWithString:@"https://player.vimeo.com/external/187645100.m3u8?s=2fb48fc8005cebe2f10255fdc2fa1ed6da59ea53"], nil];
        
        [_orionView addOrionContent:_videoContent];
        _viewport = [[OrionViewport alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) lockInPosition:NO];
        _viewport.viewportConfig.fullScreenEnabled = YES;
        
        [_orionView addOrionViewport:_viewport orionContent:_videoContent];
    }
}


-(void)orionVideoContentReadyToPlayVideo:(OrionVideoContent *)orionVideoContent
{
    [UIView animateWithDuration:0.2f animations:^(void){
        _orionView.alpha = 1.0f;
    } completion:^(BOOL finished){
        [orionVideoContent play:0.0f];
    }];
}


-(void)orionVideoContentDidReachEnd:(OrionVideoContent *)orionVideoContent
{
    [orionVideoContent seekTo:0.0f];
}


@end
