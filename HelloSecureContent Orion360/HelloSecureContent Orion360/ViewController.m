//
//  ViewController.m
//  Hello Orion360
//
//  Created by Hannu Limma on 21/06/2017.
//  Modified by Esko Malm on 16/09/2022.
//  Copyright © 2017-2022 Finwe Ltd. All rights reserved.
//

#import "ViewController.h"
#import <orion360-sdk-pro-ios/OrionView.h>
#import <orion360-sdk-pro-ios/OrionMediaURL.h>

typedef NS_ENUM(NSUInteger, PlayContentType) {
    PlayContentTypePublic,
    PlayContentTypeSecuredCanned,
    PlayContentTypeSecuredCustom
};

@interface ViewController ()<OrionViewDelegate, OrionVideoContentDelegate>
@property (nonatomic) OrionView* orionView;
@property (nonatomic) OrionVideoContent* videoContent;
@property (nonatomic) OrionViewport* viewport;

@property (nonatomic) PlayContentType playContentType;
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

        // Select one content type to play.
        //_playContentType = PlayContentTypePublic;
        //_playContentType = PlayContentTypeSecuredCanned;
        _playContentType = PlayContentTypeSecuredCustom;

        if (_playContentType == PlayContentTypePublic)
        {
            // Public content that is not secured.
            _videoContent.uriArray = [[NSArray alloc] initWithObjects:[NSURL URLWithString:@"https://player.vimeo.com/external/187645100.m3u8?s=2fb48fc8005cebe2f10255fdc2fa1ed6da59ea53"], nil];
        }
        else if (_playContentType == PlayContentTypeSecuredCanned)
        {
            // Secured content requiring file level policy (CANNED).
            OrionMediaURL *mediaURL = [OrionMediaURL URLWithString:@"https://d15i6zsi2io35f.cloudfront.net/Orion360_test_video_1920x960.mp4"];

            // Use either one of the file level policy options (CANNED).
            [mediaURL setCookieHeader:[self getCookieHeader:NO]];
            //[mediaURL setCookieArray:[NSArray arrayWithObjects:[self getExpiresCookie], [self getSignatureCookie], [self getKeyPairIdCookie], nil]];

            // Trying to access without a valid cookie setting will fail (403 Forbidden).
            _videoContent.uriArray = [[NSArray alloc] initWithObjects:mediaURL, nil];
        }
        else if (_playContentType == PlayContentTypeSecuredCustom)
        {
            // Secured content requiring directory level policy (CUSTOM).
            OrionMediaURL *mediaURL = [OrionMediaURL URLWithString:@"https://d15i6zsi2io35f.cloudfront.net/Orion360_test_video_1920x960.m3u8"];

            // Use either one of the directory level policy options (CUSTOM).
            //[mediaURL setCookieHeader:[self getCookieHeader:YES]];
            [mediaURL setCookieArray:[NSArray arrayWithObjects:[self getPolicyCookie], [self getPolicySignatureCookie], [self getKeyPairIdCookie], nil]];

            // Trying to access without a valid cookie setting will fail (403 Forbidden).
            _videoContent.uriArray = [[NSArray alloc] initWithObjects:mediaURL, nil];
        }

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


// Helper functions for accessing secured content.
- (NSString*)getCookieHeader:(BOOL)isCustomPolicy
{
    NSString *cookieHeader = nil;
    if (isCustomPolicy) {
        // Policy for access control: CUSTOM
        cookieHeader = @"CloudFront-Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly9kMTVpNnpzaTJpbzM1Zi5jbG91ZGZyb250Lm5ldC8qIiwiQ29uZGl0aW9uIjp7IkRhdGVMZXNzVGhhbiI6eyJBV1M6RXBvY2hUaW1lIjoyMTQ3NDgzNjQ3fX19XX0_; CloudFront-Signature=Lc6cKuiY6wFqY7Gz7PEMdI7ZCeYgc9HazxgVP4xwtNzSWy0j3nwUeQtom15sG2JyX51v9h-BEAWBbH2buPIcaZp2FyOKOZBDd3~R-Wzk7lKHtCqakUCL8BSXtiDqCrCK9kR8gyqXDQLC6RId2QRKCt7hQTnR81pGWYZ8DOwXIKGop9PGoogPGmUBlj1pMN0OvDNtQBlK~W2vNfBl~bruZqNq798PbfJD-mQNB9Ohan67~3E-pMMk9MajeJ5Paxm04hk67xl0WorHyK7NCBn8wE~6KsTOvApbKlBInga8Q80hYwhYMOZmJU-6Z2GzviwqVdWIfmQuG8I~lpNLMBSbxg__; CloudFront-Key-Pair-Id=K37HI3P0TW0W7Q; Domain=d15i6zsi2io35f.cloudfront.net; Path=/*; Secure";
    } else {
        // Policy for access control: CANNED
        cookieHeader = @"CloudFront-Expires=2147483647; CloudFront-Signature=uI3ott-V5IiFW-ZTgXg7AAN0iIC4Y2dnz0BLCLrPs7icTx3qghkz1HqZ9p0LnHShdEg8awMEsg5ev~ClXGBu52x80jIxI6tjBoH8ivZ3Ddt09TvNq95Q0ij2-1TsbHyxevJ3Iex29TCTMEG7Y36AWf9~IJzzJHKzp~SiflEAn-sPR0Z-9hdrQmkgalx5qSiu~Und7GM6qV2WMxwzrcGd7q8AV9N7IKnyJR-fqjOA7mEmOnQrT4iCCdkEcxmlgBxC3wRpmw53mbPP2OVr4c~b~dwB7XYr-gDbjtoSXCFwb6Ds~SdXx0hjmCbY1EynN8wGslfsYpHmiuyLFUnABOhzNQ__; CloudFront-Key-Pair-Id=K37HI3P0TW0W7Q; Domain=d15i6zsi2io35f.cloudfront.net; Path=/*; Secure";
    }

  return cookieHeader;
}

NSString* CLOUDFRONT_EXPIRES_KEY = @"CloudFront-Expires";
NSString* CLOUDFRONT_EXPIRES_VALUE = @"2147483647";
NSString* CLOUDFRONT_SIGNATURE_KEY = @"CloudFront-Signature";
NSString* CLOUDFRONT_FILE_SIGNATURE_VALUE = @"uI3ott-V5IiFW-ZTgXg7AAN0iIC4Y2dnz0BLCLrPs7icTx3qghkz1HqZ9p0LnHShdEg8awMEsg5ev~ClXGBu52x80jIxI6tjBoH8ivZ3Ddt09TvNq95Q0ij2-1TsbHyxevJ3Iex29TCTMEG7Y36AWf9~IJzzJHKzp~SiflEAn-sPR0Z-9hdrQmkgalx5qSiu~Und7GM6qV2WMxwzrcGd7q8AV9N7IKnyJR-fqjOA7mEmOnQrT4iCCdkEcxmlgBxC3wRpmw53mbPP2OVr4c~b~dwB7XYr-gDbjtoSXCFwb6Ds~SdXx0hjmCbY1EynN8wGslfsYpHmiuyLFUnABOhzNQ__";
NSString* CLOUDFRONT_DIRECTORY_SIGNATURE_VALUE = @"Lc6cKuiY6wFqY7Gz7PEMdI7ZCeYgc9HazxgVP4xwtNzSWy0j3nwUeQtom15sG2JyX51v9h-BEAWBbH2buPIcaZp2FyOKOZBDd3~R-Wzk7lKHtCqakUCL8BSXtiDqCrCK9kR8gyqXDQLC6RId2QRKCt7hQTnR81pGWYZ8DOwXIKGop9PGoogPGmUBlj1pMN0OvDNtQBlK~W2vNfBl~bruZqNq798PbfJD-mQNB9Ohan67~3E-pMMk9MajeJ5Paxm04hk67xl0WorHyK7NCBn8wE~6KsTOvApbKlBInga8Q80hYwhYMOZmJU-6Z2GzviwqVdWIfmQuG8I~lpNLMBSbxg__";

NSString* CLOUDFRONT_POLICY_KEY = @"CloudFront-Policy";
NSString* CLOUDFRONT_DIRECTORY_POLICY_VALUE = @"eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly9kMTVpNnpzaTJpbzM1Zi5jbG91ZGZyb250Lm5ldC8qIiwiQ29uZGl0aW9uIjp7IkRhdGVMZXNzVGhhbiI6eyJBV1M6RXBvY2hUaW1lIjoyMTQ3NDgzNjQ3fX19XX0_";
NSString* CLOUDFRONT_KEY_PAIR_ID_KEY = @"CloudFront-Key-Pair-Id";
NSString* CLOUDFRONT_KEY_PAIR_ID_VALUE = @"K37HI3P0TW0W7Q";
NSString* DOMAIN_VALUE = @"d15i6zsi2io35f.cloudfront.net";
NSString* PATH_VALUE = @"/";

- (NSHTTPCookie*)getExpiresCookie
{
    NSDictionary *expiresDictionary = @{
        NSHTTPCookieName : CLOUDFRONT_EXPIRES_KEY,
        NSHTTPCookieValue : CLOUDFRONT_EXPIRES_VALUE,
        NSHTTPCookieDomain : DOMAIN_VALUE,
        NSHTTPCookiePath : PATH_VALUE,
        NSHTTPCookieSecure : @YES
    };
    return [self getCookie:expiresDictionary];
}

- (NSHTTPCookie*)getSignatureCookie
{
    NSDictionary *signatureDictionary = @{
        NSHTTPCookieName : CLOUDFRONT_SIGNATURE_KEY,
        NSHTTPCookieValue : CLOUDFRONT_FILE_SIGNATURE_VALUE,
        NSHTTPCookieDomain : DOMAIN_VALUE,
        NSHTTPCookiePath : PATH_VALUE,
        NSHTTPCookieSecure : @YES
    };
    return [self getCookie:signatureDictionary];
}

- (NSHTTPCookie*)getPolicyCookie
{
    NSDictionary *policyDictionary = @{
        NSHTTPCookieName : CLOUDFRONT_POLICY_KEY,
        NSHTTPCookieValue : CLOUDFRONT_DIRECTORY_POLICY_VALUE,
        NSHTTPCookieDomain : DOMAIN_VALUE,
        NSHTTPCookiePath : PATH_VALUE,
        NSHTTPCookieSecure : @YES
    };
    return [self getCookie:policyDictionary];
}

- (NSHTTPCookie*)getPolicySignatureCookie
{
    NSDictionary *policySignatureDictionary = @{
        NSHTTPCookieName : CLOUDFRONT_SIGNATURE_KEY,
        NSHTTPCookieValue : CLOUDFRONT_DIRECTORY_SIGNATURE_VALUE,
        NSHTTPCookieDomain : DOMAIN_VALUE,
        NSHTTPCookiePath : PATH_VALUE,
        NSHTTPCookieSecure : @YES
    };
    return [self getCookie:policySignatureDictionary];
}

- (NSHTTPCookie*)getKeyPairIdCookie
{
    NSDictionary *keyPairIdDictionary = @{
        NSHTTPCookieName : CLOUDFRONT_KEY_PAIR_ID_KEY,
        NSHTTPCookieValue : CLOUDFRONT_KEY_PAIR_ID_VALUE,
        NSHTTPCookieDomain : DOMAIN_VALUE,
        NSHTTPCookiePath : PATH_VALUE,
        NSHTTPCookieSecure : @YES
    };
    return [self getCookie:keyPairIdDictionary];
}

- (NSHTTPCookie*)getCookie:(NSDictionary*)properties
{
    return [[NSHTTPCookie alloc] initWithProperties:properties];
}

@end
