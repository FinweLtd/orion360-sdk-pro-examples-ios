//
//  ViewController.m
//  GoogleImaTwoIsolatedPlayers
//
//  Created by Tapani Jämsä on 2.9.2022.
//  Copyright © 2022 Finwe Ltd. All rights reserved.
//

#import "ViewController.h"
#import <orion360-sdk-pro-ios/OrionView.h>

// The content URL to play.
NSString *const contentURL = @"https://player.vimeo.com/external/186333842.m3u8?s=93e42bd5d8ccff2817bb1e8fff7985d3abd83df1";

#pragma mark IMA sample tags
// More sample tags here: https://developers.google.com/interactive-media-ads/docs/sdks/html5/client-side/tags

// Standard pre-roll
static NSString *const kPrerollTag = @"https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/single_ad_samples&sz=640x480&cust_params=sample_ct%3Dlinear&ciu_szs=300x250%2C728x90&gdfp_req=1&output=vast&unviewed_position_start=1&env=vp&impl=s&correlator=";

// Skippable
static NSString *const kSkippableTag = @"https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/single_preroll_skippable&sz=640x480&ciu_szs=300x250%2C728x90&gdfp_req=1&output=vast&unviewed_position_start=1&env=vp&impl=s&correlator=";

// Post-roll
static NSString *const kPostrollTag = @"https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/vmap_ad_samples&sz=640x480&cust_params=sample_ar%3Dpostonly&ciu_szs=300x250&gdfp_req=1&ad_rule=1&output=vmap&unviewed_position_start=1&env=vp&impl=s&correlator=";

// VMAP Pre-, Mid-, and Post-rolls, Single Ads
static NSString *const kPreMidPostSingleTag = @"https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/vmap_ad_samples&sz=640x480&cust_params=sample_ar%3Dpremidpost&ciu_szs=300x250&gdfp_req=1&ad_rule=1&output=vmap&unviewed_position_start=1&env=vp&impl=s&cmsid=496&vid=short_onecue&correlator=";

/*
https://developers.google.com/interactive-media-ads/docs/sdks/ios/client-side#5_implement_content_playhead_tracker_and_end-of-stream_observer
In order to play mid-roll ads, the IMA SDK needs to track the current position of your video content.
 */
@implementation OrionContentPlayhead
@synthesize currentTime;
-(void)updateCurrentTime:(CGFloat) newTime {
    currentTime = newTime;
}
@end


@interface ViewController ()<OrionViewDelegate, OrionVideoContentDelegate, IMAAdsLoaderDelegate, IMAAdsManagerDelegate>

// ORION
@property (nonatomic) OrionView* orionView;
@property (nonatomic) OrionVideoContent* videoContent;
@property (nonatomic) OrionViewport* viewport;
@property(nonatomic) OrionViewportController *contentPlayerViewController;

// IMA
/// Entry point for the SDK. Used to make ad requests.
@property(nonatomic) IMAAdsLoader *adsLoader;

/// Playhead used by the SDK to track content video progress and insert mid-rolls.
@property(nonatomic) OrionContentPlayhead *contentPlayhead;

/// Main point of interaction with the SDK. Created by the SDK as the result of an ad request.
@property(nonatomic, strong) IMAAdsManager *adsManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnteredForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnteredBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [self setupOrion];
    [self setupAdsLoader];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self requestAds];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

-(void) appEnteredForeground {
    [_adsManager resume];
}

//-(void) appEnteredBackground {
//}

#pragma mark Orion Setup

- (void) setupOrion {
    if (!_orionView)
    {
        _orionView = [[OrionView alloc] init];
        _orionView.delegate = self;
        _orionView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        
        // check license
        NSString* path = [[NSBundle mainBundle] pathForResource:@"license.key.lic" ofType:nil];
        NSURL *licenseUrl = [NSURL fileURLWithPath:path];
        [self.orionView setLicenseFileUrl:licenseUrl];
        
        
        //        _orionView.overrideSilentSwitch = YES;
        
        _videoContent = [[OrionVideoContent alloc] init];
        _videoContent.delegate = self;
        
        _videoContent.uriArray = [[NSArray alloc] initWithObjects:[NSURL URLWithString:contentURL], nil];
        
        [_orionView addOrionContent:_videoContent];
        _viewport = [[OrionViewport alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) lockInPosition:NO];
        _viewport.viewportConfig.fullScreenEnabled = YES;
        
        [_orionView addOrionViewport:_viewport orionContent:_videoContent];
        
        self.contentPlayhead = [[OrionContentPlayhead alloc] init];
        
        [self showContentPlayer];
    }
}

// Add the content video player as a child view controller.
- (void)showContentPlayer {
    [self.view addSubview:_orionView];
}

// Remove and detach the content video player.
- (void)hideContentPlayer {
    [_orionView removeFromSuperview];
}

#pragma mark IMA SDK Setup

- (void)setupAdsLoader {
    IMASettings *settings = [[IMASettings alloc] init];
    
    // Tell IMA SDK to use the language of the device
    NSString * deviceLanguage = [[NSLocale preferredLanguages] firstObject];
    settings.language = deviceLanguage;
    
    /*
     Manual Ad Break Playback (Part 1) - If you want to control ads manually
     https://developers.google.com/interactive-media-ads/docs/sdks/ios/client-side/manual_ad_playback
     */
//    // Tell the SDK that you want to control ad break playback.
//    settings.autoPlayAdBreaks = NO;
    
    self.adsLoader = [[IMAAdsLoader alloc] initWithSettings:settings];
    
    self.adsLoader.delegate = self;
}

- (void)requestAds {
    // Pass the main view as the container for ad display.
    IMAAdDisplayContainer *adDisplayContainer =
    [[IMAAdDisplayContainer alloc] initWithAdContainer:self.view
                                        viewController:self
                                        companionSlots:nil];
//     Create an ad request with our ad tag, display container, and optional user context.
    IMAAdsRequest *request = [[IMAAdsRequest alloc] initWithAdTagUrl:kPreMidPostSingleTag
                                                  adDisplayContainer:adDisplayContainer
                                                     contentPlayhead:self.contentPlayhead
                                                         userContext:nil];
    
    [self.adsLoader requestAdsWithRequest:request];
}

#pragma mark AdsLoader Delegates

- (void)adsLoader:(IMAAdsLoader *)loader adsLoadedWithData:(IMAAdsLoadedData *)adsLoadedData {
    // Initialize and listen to the ads manager loaded for this request.
    self.adsManager = adsLoadedData.adsManager;
    self.adsManager.delegate = self;
    
    [self.adsManager initializeWithAdsRenderingSettings:nil];
    
//    // Create ads rendering settings to tell the SDK to use the in-app browser.
//    IMAAdsRenderingSettings *adsRenderingSettings = [[IMAAdsRenderingSettings alloc] init];
//    adsRenderingSettings.linkOpenerPresentingController = self;
//    // Initialize the ads manager.
//    [self.adsManager initializeWithAdsRenderingSettings:adsRenderingSettings];
}

#pragma mark AdsManager Delegates

- (void)adsManager:(IMAAdsManager *)adsManager didReceiveAdEvent:(IMAAdEvent *)event {
    NSLog(@"AdsManager event (%@).", event.typeString);
    
    switch (event.type) {
        case kIMAAdEvent_LOADED:
//            if (![self.pictureInPictureController isPictureInPictureActive]) {
//                [adsManager start];
//            }
            // Play each ad once it has loaded.
            [adsManager start];
            break;
//        case kIMAAdEvent_PAUSE:
//            [self setPlayButtonType:PlayButton];
//            break;
//        case kIMAAdEvent_RESUME:
//            [self setPlayButtonType:PauseButton];
//            break;
//        case kIMAAdEvent_TAPPED:
//            [self showFullscreenControls:nil];
//            break;
            /*
             Manual Ad Break Playback (Part 2) - If you want to control ads manually
             https://developers.google.com/interactive-media-ads/docs/sdks/ios/client-side/manual_ad_playback
             */
//            // Listen for the AD_BREAK_READY event
//        case kIMAAdEvent_AD_BREAK_READY:
//            // Tell the SDK to play ads when you're ready. To skip this ad break,
//            // simply return from this handler without calling [adsManager start].
//            [adsManager start];
//            break;
        default:
            break;
    }
}

- (void)adsManager:(IMAAdsManager *)adsManager didReceiveAdError:(IMAAdError *)error {
  // Fall back to playing content.
  NSLog(@"AdsManager error: %@", error.message);
  [self showContentPlayer];
    [_videoContent play: _videoContent.currentTime];
}

- (void)adsManagerDidRequestContentPause:(IMAAdsManager *)adsManager {
  // Pause the content for the SDK to play ads.
    [_videoContent pause];
  [self hideContentPlayer];
}

- (void)adsManagerDidRequestContentResume:(IMAAdsManager *)adsManager {
  // Resume the content since the SDK is done playing ads (at least for now).
  [self showContentPlayer];
    [_videoContent play: _videoContent.currentTime];
}

#pragma mark Orion Delegates

// Notify IMA SDK when content is done for post-rolls.
- (void)orionVideoContentDidReachEnd:(OrionVideoContent*)orionVideoContent {
    [self.adsLoader contentComplete];
}

- (void)orionVideoContentDidUpdateProgress:(OrionVideoContent*)orionVideoContent currentTime:(CGFloat)currentTime availableTime:(CGFloat)availableTime totalDuration:(CGFloat)totalDuration {
    [self.contentPlayhead updateCurrentTime:currentTime];
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
