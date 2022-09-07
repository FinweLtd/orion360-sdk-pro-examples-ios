//
//  ViewController.h
//  PanoramaTestApp
//
//  Created by Tapani Jämsä on 2.9.2022.
//  Copyright © 2022 Finwe Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleInteractiveMediaAds/GoogleInteractiveMediaAds.h>

NS_ASSUME_NONNULL_BEGIN

@interface ViewController : UIViewController
// UI Outlets
@property(nonatomic, weak) IBOutlet UIView *videoView;

// MOE:strip_line [START companion_view_header]
@property(nonatomic, weak) IBOutlet UIView *companionView;
@end

NS_ASSUME_NONNULL_END

@interface OrionContentPlayhead : NSObject<IMAContentPlayhead>
-(void)updateCurrentTime:(CGFloat) newTime;
@end
