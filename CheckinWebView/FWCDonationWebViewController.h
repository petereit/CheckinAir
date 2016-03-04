//
//  FWCDonationWebViewController.h
//  CheckinAir
//
//  Created by Mark Petereit on 8/15/14.
//  Copyright (c) 2014 Family Worship Center. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FWCDonationWebViewController : UIViewController <UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;

@end
