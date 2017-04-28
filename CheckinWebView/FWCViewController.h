//
//  FWCViewController.h
//  CheckinWebView
//
//  Created by Mark Petereit on 7/18/14.
//  Copyright (c) 2014 Family Worship Center. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FWCNameTagView.h"
#import "FWCParentTagView.h"
//#import "FWCFamilyTagView.h"

@interface FWCViewController : UIViewController <UIWebViewDelegate, NSURLConnectionDelegate, UIPrintInteractionControllerDelegate, UIPrinterPickerControllerDelegate>{
    NSMutableData *_responseData;
}
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) UIPrinter *labelPrinter;
//@property (strong, nonatomic) UIPrinter *documentPrinter;

@property (strong, nonatomic) IBOutlet FWCNameTagView *childLabel;
@property (strong, nonatomic) IBOutlet FWCParentTagView *parentLabel;
@property (strong, nonatomic) IBOutlet FWCFamilyTagView *familyLabel;

- (void)processLabels:(NSString *)printParent prompt:(NSString *)prompt;

@end
