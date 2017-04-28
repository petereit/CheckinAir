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
//#import "FWCNameTagView.h"
//#import "FWCParentTagView.h"

@interface FWCViewController ()

@end

@implementation FWCViewController

@synthesize webView;
@synthesize labelPrinter;

bool printingLabel = false;
NSDictionary *nametag_fields;
NSMutableDictionary *queryStringDictionary;


NSString *subdomain;

-(BOOL)prefersStatusBarHidden{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults valueForKey:@"SettingsShowStatusBar"];
}

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
    pi.orientation = UIPrintInfoOrientationLandscape;
    
    
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
        
        //Determine if labels are to be printed
        
        //Get print_parent value
        NSString *print_parent = [self.webView stringByEvaluatingJavaScriptFromString:
                                      @"(function() "
                                      "  {return $('input#print_parent').val();})"
                                      "();"];
        
        
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
        
        //Iterate through fields. If PROMPT is assigned, display UIAlertController
        Boolean displayPrompt = false;
        for(id field in nametag_fields){
            if([[nametag_fields objectForKey:field]  isEqual: @"PROMPT"]){
                displayPrompt = true;
                break;
            }
        }
        if(displayPrompt){
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Info to Include:" message:NULL preferredStyle:UIAlertControllerStyleAlert];
            [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.secureTextEntry = NO;
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction * action) {[self processLabels:print_parent prompt:@"BLANK"];}];
            UIAlertAction *userPrompt = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                UITextField *prompt = alertController.textFields.firstObject;
                if (![prompt.text isEqualToString:@""]) {
                    
                    [self processLabels:print_parent prompt:prompt.text];
                }
            }];
            [alertController addAction:cancelAction];
            [alertController addAction:userPrompt];
            [self presentViewController:alertController animated:YES completion:nil];
        } else {
            [self processLabels:print_parent prompt:@"BLANK"];
        }
        
        // Cancel the event, so the webview doesn't load the url
        return NO;
        
    }
    return YES;
}

- (void)processLabels:(NSString *)printParent prompt:(NSString *)prompt
{

    NSArray *children = [[queryStringDictionary objectForKey:@"person_id"] componentsSeparatedByString:@","];
    NSMutableArray *childrenNames = [[NSMutableArray alloc] init];
    NSDictionary *person;
    
    NSMutableData *pdfData = [NSMutableData data];
    BOOL init = false;
    
    CGContextRef pdfContext = UIGraphicsGetCurrentContext();
    
    for (NSString *child in children) {
        FWCNameTagView *childTag = [[[NSBundle mainBundle] loadNibNamed:@"FWCNameTagView" owner:self options:nil] lastObject];
        
        childTag.bounds = CGRectMake(0, 0, 3.75 * 216.0, 2.4375 * 216.0);
        childTag.code = [self.webView stringByEvaluatingJavaScriptFromString:@"(function() {return code;})();"];
//            childTag.user_prompt = [self.webView stringByEvaluatingJavaScriptFromString:@"(function() {return user_prompt;})();"];
        childTag.user_prompt = prompt;
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

    if([printParent  isEqual: @"1"]){
        if(children.count > 1){
            FWCFamilyTagView *familyTag = [[[NSBundle mainBundle] loadNibNamed:@"FWCFamilyTagView" owner:self options:nil] lastObject];
            
            //familyTag.bounds = CGRectMake(0, 0, 4.0 * 216.0, 2.4375 * 216.0);
            familyTag.bounds = CGRectMake(0, 0, 3.75 * 216.0, 2.4375 * 216.0);
            familyTag.code = [self.webView stringByEvaluatingJavaScriptFromString:@"(function() {return code;})();"];
            familyTag.user_prompt = [self.webView stringByEvaluatingJavaScriptFromString:@"(function() {return user_prompt;})();"];
            [familyTag assign_substitutions:nametag_fields person:person];
            familyTag.family_names_1.text = [childrenNames componentsJoinedByString:@"\n"];
            familyTag.family_names_2.text = familyTag.family_names_1.text;
            if (!init) {
                UIGraphicsBeginPDFContextToData(pdfData, familyTag.bounds, nil);
                pdfContext = UIGraphicsGetCurrentContext();
                init = true;
            }
            UIGraphicsBeginPDFPage();
            [familyTag.layer renderInContext:pdfContext];
        } else {
            FWCParentTagView *parentTag = [[[NSBundle mainBundle] loadNibNamed:@"FWCParentTagView" owner:self options:nil] lastObject];
            
            parentTag.bounds = CGRectMake(0, 0, 3.75 * 216.0, 2.4375 * 216.0);
            parentTag.code = [self.webView stringByEvaluatingJavaScriptFromString:@"(function() {return code;})();"];
            parentTag.user_prompt = [self.webView stringByEvaluatingJavaScriptFromString:@"(function() {return user_prompt;})();"];
            [parentTag assign_substitutions:nametag_fields person:person];
//                parentTag.child_names_1.text = [childrenNames componentsJoinedByString:@"\n"];
//                parentTag.child_names_2.text = parentTag.child_names_1.text;
            if (!init) {
                UIGraphicsBeginPDFContextToData(pdfData, parentTag.bounds, nil);
                pdfContext = UIGraphicsGetCurrentContext();
                init = true;
            }
            UIGraphicsBeginPDFPage();
            [parentTag.layer renderInContext:pdfContext];
        }
    }

    UIGraphicsEndPDFContext();
    
    [self printLabels:pdfData];
    
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
     "script.text = \"function print_tag(person_id, instance_id, child_or_parent, checkout) { "
     "if(!child_or_parent) { child_or_parent = 'both'; }"
     "var people_ids_json = '';"
     "if (person_id instanceof Array) {"
     "   people_ids_json = JSON.stringify(person_id);"
     "   var parent_xml = family_label_xml;"
     "} else {"
     "   people_ids_json = '';"
     "   var parent_xml = parent_label_xml;"
     "}"
     "update_link_container_style(person_id, 'in_override', checkout, '', true);"
     "window.location = 'breezeprint:print?person_id=' + person_id + '&instance_id=' + instance_id + '&people_ids_json=' + people_ids_json + '&child_or_parent=' + child_or_parent + '&checkout=' + checkout;"
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
    
    CGSize customPaperSize = CGSizeMake(4.0 * 72.0, 2.4375 * 72.0);

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
