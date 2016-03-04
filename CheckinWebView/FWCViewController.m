//
//  FWCViewController.m
//  CheckinWebView
//
//  Created by Mark Petereit on 7/18/14.
//  Copyright (c) 2014 Family Worship Center. All rights reserved.
//

@import JavaScriptCore;

#import "FWCViewController.h"
#import "SVProgressHUD.h"
#import "FWCNameTagView.h"
#import "FWCParentTagView.h"

@interface FWCViewController ()

@end

@implementation FWCViewController

@synthesize webView;
@synthesize labelPrinter;

bool printingLabel = false;
NSDictionary *nametag_fields;
NSMutableDictionary *queryStringDictionary;

NSString *subdomain;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    subdomain = [defaults valueForKey:@"SettingsSubdomain"];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@.breezechms.com/login", subdomain]];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    queryStringDictionary = [[NSMutableDictionary alloc] init];

    [SVProgressHUD showWithStatus:@"Loading..." maskType:SVProgressHUDMaskTypeBlack];

    [self.webView loadRequest:requestObj];
}

- (UIViewController *)printerPickerControllerParentViewController:(UIPrinterPickerController *)printerPickerController{
    return self;
}

- (BOOL)printerPickerController:(UIPrinterPickerController *)printerPickerController
              shouldShowPrinter:(UIPrinter *)printer{
    
    if (printer.supportedJobTypes & UIPrinterJobTypeLabel) {
        return true;
    }

    return false;
}

-(void)printLabels:(NSMutableData*)pdfData
{
    UIPrintInfo *pi = [UIPrintInfo printInfo];
    pi.outputType = UIPrintInfoOutputGrayscale;
    pi.jobName = @"Label";
    pi.orientation = UIPrintInfoOrientationPortrait;
    
    UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
    pic.delegate = self;
    pic.printInfo = pi;
    pic.showsPageRange = NO;
    pic.showsNumberOfCopies = NO;
    pic.printingItem = pdfData;
    
    if ([pic respondsToSelector:@selector(printToPrinter:completionHandler:)]) {
        if(self.labelPrinter == nil){
            UIPrinterPickerController *picker = [UIPrinterPickerController printerPickerControllerWithInitiallySelectedPrinter:nil];
            picker.delegate = self;
            [picker presentAnimated:true completionHandler:^(UIPrinterPickerController *printerPickerController,
                                                             BOOL userDidSelect,
                                                             NSError *error) {
                if(userDidSelect){
                    self.labelPrinter = printerPickerController.selectedPrinter;
                    [pic printToPrinter:self.labelPrinter completionHandler:^(UIPrintInteractionController *printInteractionController, BOOL completed, NSError *error) {
                        NSLog(@"Error: %@", error);
                    }];
                }
            }];
        } else {
            [pic printToPrinter:self.labelPrinter completionHandler:^(UIPrintInteractionController *printInteractionController, BOOL completed, NSError *error) {
                NSLog(@"Error: %@", error);
            }];
        }
    } else {
        [pic presentAnimated:YES completionHandler:^(UIPrintInteractionController *pic2, BOOL completed, NSError *error) {
            // indicate done or error
        }];
    }
    
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"shouldStartLoadWithRequest: %@", [[request URL] absoluteString]);

    NSString *urlStr = [NSString stringWithString:[[request URL] absoluteString]];
    
    NSString *protocolPrefix = @"breezeprint:print?";
    
    //process only our custom protocol
    if ([[urlStr lowercaseString] hasPrefix:protocolPrefix])
    {
        
        //strip protocol from the URL. We will get input to call a native method
        urlStr = [urlStr substringFromIndex:protocolPrefix.length];
        
        //Decode the url string
        urlStr = [urlStr stringByRemovingPercentEncoding];
        
        NSArray *urlComponents = [urlStr componentsSeparatedByString:@"&"];
        
        for (NSString *keyValuePair in urlComponents)
        {
            NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
            NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
            NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
            
            [queryStringDictionary setObject:value forKey:key];
        }
        
        //Get nametag fields from Breeze
        NSData *objectData = [[self.webView stringByEvaluatingJavaScriptFromString:
                                        @"(function() "
                                         "  {return JSON.stringify(nametag_fields);})"
                                         "();"]
                              dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError *error = nil;
        
        id object = [NSJSONSerialization
                     JSONObjectWithData:objectData
                     options:0
                     error:&error];
        
        if(error) { /* JSON was malformed, act appropriately here */ }
        
        // validate dictionary
        if([object isKindOfClass:[NSDictionary class]])
        {
            nametag_fields = object;
        }

        NSArray *children = [[queryStringDictionary objectForKey:@"person_id"] componentsSeparatedByString:@","];
        NSMutableArray *childrenNames = [[NSMutableArray alloc] init];
        NSDictionary *person;
        
        NSMutableData *pdfData = [NSMutableData data];
        BOOL init = false;
        
        CGContextRef pdfContext = UIGraphicsGetCurrentContext();
        
        for (NSString *child in children) {
            FWCNameTagView *childTag = [[[NSBundle mainBundle] loadNibNamed:@"FWCNameTagView" owner:self options:nil] lastObject];

            childTag.code = [self.webView stringByEvaluatingJavaScriptFromString:@"(function() {return code;})();"];
            childTag.user_prompt = [self.webView stringByEvaluatingJavaScriptFromString:@"(function() {return user_prompt;})();"];
            childTag.logoText = [self.webView stringByEvaluatingJavaScriptFromString:@"(function() {return $('div#logo_base64_container').text();})();"];
            childTag.instance_id = [queryStringDictionary objectForKey:@"instance_id"];
            childTag.people_ids_json = [queryStringDictionary objectForKey:@"people_ids_json"];
            [childTag create_tag:nametag_fields person_id:child];
            [childrenNames addObject:childTag.child_name.text];
            if (person == nil) {
                person = childTag.person;
            }
            if (!init) {
                UIGraphicsBeginPDFContextToData(pdfData, childTag.bounds, nil);
                pdfContext = UIGraphicsGetCurrentContext();
                init = true;
            }
            UIGraphicsBeginPDFPage();
            [childTag.layer renderInContext:pdfContext];

        }

        FWCFamilyTagView *parentTag = [[[NSBundle mainBundle] loadNibNamed:@"FWCFamilyTagView" owner:self options:nil] lastObject];
        parentTag.code = [self.webView stringByEvaluatingJavaScriptFromString:@"(function() {return code;})();"];
        parentTag.user_prompt = [self.webView stringByEvaluatingJavaScriptFromString:@"(function() {return user_prompt;})();"];
        [parentTag assign_substitutions:nametag_fields person:person];
        parentTag.family_names_1.text = [childrenNames componentsJoinedByString:@"\n"];
        parentTag.family_names_2.text = parentTag.family_names_1.text;
        UIGraphicsBeginPDFPage();
        [parentTag.layer renderInContext:pdfContext];

        UIGraphicsEndPDFContext();

        [self printLabels:pdfData];
        
        // Cancel the event, so the webview doesn't load the url
        return NO;
        
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidFinishLoad");
    
    // get JSContext from UIWebView instance
    JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    
    // enable error logging
    [context setExceptionHandler:^(JSContext *context, JSValue *value) {
        NSLog(@"WEB JS: %@", value);
    }];
    
    [self.webView stringByEvaluatingJavaScriptFromString:@"$('select#printer_list').data('found', 'true');"];
    
    [self.webView stringByEvaluatingJavaScriptFromString:@"var script = document.createElement('script');"
     "script.type = 'text/javascript';"
     "script.text = \"function print_tag(person_id, instance_id, child_or_parent) { "
     "if(!child_or_parent) { child_or_parent = 'both'; } "
     "var people_ids_json = ''; "
     "if (person_id instanceof Array) {"
     "    people_ids_json = JSON.stringify(person_id);"
     "} else { "
     "    people_ids_json = '';"
     "} "
     "window.location = 'breezeprint:print?person_id=' + person_id + '&instance_id=' + instance_id + '&people_ids_json=' + people_ids_json + '&child_or_parent=' + child_or_parent;"
     "}\";"
     "document.getElementsByTagName('head')[0].appendChild(script);"];
    [SVProgressHUD dismiss];
}

- (CGFloat)printInteractionController:(UIPrintInteractionController *)printInteractionController cutLengthForPaper:(UIPrintPaper *)paper {
    
    return 4 * 72;
}

- (UIPrintPaper *)printInteractionController:(UIPrintInteractionController *)pic
                                 choosePaper:(NSArray *)paperList {
    // custom method & properties...
    CGSize customPaperSize = CGSizeMake(2.4375 * 72.0, 4.0 * 72.0);
    //CGSize pageSize = [self pageSizeForDocumentType:self.document.type];
    return [UIPrintPaper bestPaperForPageSize:customPaperSize
                          withPapersFromArray:paperList];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)setupClick:(UIBarButtonItem *)sender {
}

@end
