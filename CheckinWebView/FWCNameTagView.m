//
//  FWCNameTagView.m
//  CheckinAir
//
//  Created by Mark Petereit on 2/19/16.
//  Copyright © 2016 Family Worship Center. All rights reserved.
//

#import "FWCNameTagView.h"

NSMutableData *_responseData;
NSString *subdomain;

@implementation FWCNameTagView

-(void) create_tag:(NSDictionary *)nametag_fields person_id:(NSString *)person_id{
    self.nametag_fields = nametag_fields;
    self.person_id = person_id;

    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    subdomain = [defaults valueForKey:@"SettingsSubdomain"];

    NSString *myServerUrl = [NSString stringWithFormat:@"https://%@.breezechms.com/ajax/get_check_in_person_from_id", subdomain];
    NSURL *requestURL = [NSURL URLWithString:myServerUrl];
//    NSURL *requestURL = [NSURL URLWithString:[myServerUrl
//                                              stringByAddingPercentEncodingWithAllowedCharacters:
//                                              [NSCharacterSet URLHostAllowedCharacterSet]]];
    NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:requestURL
                                                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                        timeoutInterval:60.0];
    //do post request for parameter passing
    [theRequest setHTTPMethod:@"POST"];

    [theRequest setValue:@"xml" forHTTPHeaderField:@"Content-Type"];

    NSString *post = [NSString stringWithFormat:@"person_id=%@&instance_id=%@&fetch_instance=1&people_ids_jason=%@",
                      person_id,
                      self.instance_id,
                      self.people_ids_json];

    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%d",[postData length]];
    
    [theRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [theRequest setHTTPBody:postData];
    
    NSData *data = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:nil error:nil];

    NSError *error = nil;
    
    id object = [NSJSONSerialization
                 JSONObjectWithData:data
                 options:0
                 error:&error];
    
    if(error) { /* JSON was malformed, act appropriately here */ }
    
    // validate dictionary
    if([object isKindOfClass:[NSDictionary class]])
    {
        self.person = object;
        
        [self assign_substitutions:_nametag_fields person:self.person];
        if (self.child_image.image == nil){
            //no image set
            [self.imageStackView removeArrangedSubview:self.child_image];
            [self.child_image removeFromSuperview];
            [self layoutIfNeeded];
        }
        else{
            //image set
        }
    }
    else
    {
        /* there's no guarantee that the outermost object in a JSON
         packet will be a dictionary; if we get here then it wasn't,
         so 'object' shouldn't be treated as an NSDictionary; probably
         you need to report a suitable error condition */
    }


//    NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:[myServerUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
//                                                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
//                                                        timeoutInterval:60.0];
//    //do post request for parameter passing
//    [theRequest setHTTPMethod:@"POST"];
//    
//    //set the content type to JSON
//    [theRequest setValue:@"xml" forHTTPHeaderField:@"Content-Type"];
//    
//    //pass API key as a http header request
//    [theRequest addValue:@"99b2215a514b3d7450aa088f1afb63f4" forHTTPHeaderField:@"Api-key"];
//    
//    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
//    
//    if( theConnection )
//    {
//        _responseData = [NSMutableData data];
//    }
//    else
//    {
//        NSLog(@"theConnection is NULL");
//    }
    
}

-(void) assign_substitutions:(NSDictionary *)nametag_fields person:(NSDictionary *)person{
    
    // set name (not user-defined on layout template)
    @try {
        NSLog(@"%@ %@", [person valueForKey:@"first_name"], [person valueForKey:@"last_name"]);
        self.child_name.text = [NSString stringWithFormat:@"%@ %@", [person valueForKey:@"first_name"], [person valueForKey:@"last_name"]];
    }
    @catch (NSException *exception) {} @finally {}
    
    NSArray *fields = [NSArray arrayWithObjects: @"0", @"CODE", @"CODE3", @"CHILDLIST", @"CHILD", @"PARENTMOBILES", @"PARENTS", @"CELL", @"TAG", @"PROMPT", @"DATE", @"TIME", @"DATETIME", nil];
    
    for (NSString *field in nametag_fields) {
        NSUInteger index = [fields indexOfObject:[nametag_fields valueForKey:field]];
        switch (index) {
            case 0: //"0"
                @try { [self setValue:@"" forKeyPath:[NSString stringWithFormat:@"%@.text", field]]; } @catch (NSException *exception) {} @finally {}
                break;
            case 1: //"CODE"
                @try { [self setValue:self.code forKeyPath:[NSString stringWithFormat:@"%@.text", field]]; } @catch (NSException *exception) {} @finally {}
                break;
            case 2: //"CODE3"
                @try {
                    NSString *code_3 = [self.code substringFromIndex:1];
                    
                    // don't allow 666
                    if([code_3 isEqual: @"666"]){
                        srand48(time(0));
                        double r = drand48();
                        code_3 = [NSString stringWithFormat:@"2%f", floor(r * 90 +10)];
                    }
                    [self setValue:code_3 forKeyPath:[NSString stringWithFormat:@"%@.text", field]];
                  } @catch (NSException *exception) {} @finally {}

                break;
            case 3: //"CHILDLIST"
                @try {
                    NSMutableArray *children_list = [NSMutableArray array];
                    NSDictionary *children = [person valueForKey:@"people"];
                    for(NSDictionary *individual in children){
                        [children_list addObject:[NSString stringWithFormat:@"%@ %@", [individual valueForKey:@"first_name"], [individual valueForKey:@"last_name"]]];
                    }
                    NSString *children_list_string = [children_list componentsJoinedByString:@"\n"];
                    [self setValue:children_list_string forKeyPath:[NSString stringWithFormat:@"%@.text", field]];
                } @catch (NSException *exception) {} @finally {}

                break;
            case 4: //"CHILD"
                @try {
                    [self setValue:[NSString stringWithFormat:@"%@ %@", [person valueForKey:@"first_name"], [person valueForKey:@"last_name"]] forKeyPath:[NSString stringWithFormat:@"%@.text", field]];
                } @catch (NSException *exception) {} @finally {}
                break;
            case 5: //"PARENTMOBILES
                @try {
                    [self setValue:[person valueForKey:@"parent_mobiles"] forKeyPath:[NSString stringWithFormat:@"%@.text", field]];
                } @catch (NSException *exception) {} @finally {}
                break;
            case 6: //"PARENTS"
                @try {
                    [self setValue:[person valueForKey:@"parents"] forKeyPath:[NSString stringWithFormat:@"%@.text", field]];
                } @catch (NSException *exception) {} @finally {}
                break;
            case 7: //"CELL"
                @try {
                    NSDictionary *details = [person valueForKey:@"details"];
                    NSString *cell_phone = [details valueForKey:@"mobile"];
                    if (!cell_phone) {
                        cell_phone = @"";
                    }
                    [self setValue:cell_phone forKeyPath:[NSString stringWithFormat:@"%@.text", field]];
                } @catch (NSException *exception) {} @finally {}
                break;
            case 8: //"TAG"
                @try {
                    NSString *group = [person valueForKey:@"group"];
                    [self setValue:group forKeyPath:[NSString stringWithFormat:@"%@.text", field]];
                } @catch (NSException *exception) {} @finally {}
                break;
            case 9: //"PROMPT"
                @try {
                    if ([self.user_prompt isEqual: @"BLANK"]) {
                        //TODO: Set up UIAlertController
                        //user_prompt = prompt("Info to Include:");
                    }
                    if ([self.user_prompt isEqual: @"BLANK"]){
                        [self setValue:@"" forKeyPath:[NSString stringWithFormat:@"%@.text", field]];
                    } else {
                        [self setValue:self.user_prompt forKeyPath:[NSString stringWithFormat:@"%@.text", field]];
                    }
                } @catch (NSException *exception) {} @finally {}
                break;
            case 10: //"DATE"
                @try {
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    formatter.dateFormat = @"M/dd/yy";
                    NSString *date_time = [formatter stringFromDate:[NSDate date]];
                    [self setValue:date_time forKeyPath:[NSString stringWithFormat:@"%@.text", field]];
                } @catch (NSException *exception) {} @finally {}
                break;
            case 11: //"TIME"
                @try {
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    formatter.dateFormat = @"h:mm:ss a";
                    NSString *date_time = [formatter stringFromDate:[NSDate date]];
                    [self setValue:date_time forKeyPath:[NSString stringWithFormat:@"%@.text", field]];
                } @catch (NSException *exception) {} @finally {}
                break;
            case 12: //"DATETIME"
                @try {
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    formatter.dateFormat = @"M/dd/yy - h:mm:ss a";
                    NSString *date_time = [formatter stringFromDate:[NSDate date]];
                    [self setValue:date_time forKeyPath:[NSString stringWithFormat:@"%@.text", field]];
                } @catch (NSException *exception) {} @finally {}
                break;
            default:
                @try {
                    NSDictionary *all = [person objectForKey:@"all"];
                    NSString *fieldKey = [nametag_fields objectForKey:field];
                    if ([field  isEqual: @"child_image"]) {
                        if ([fieldKey  isEqual: @"profile"]) {
//                            NSString *picture_path = [person objectForKey:@"path"];
//                            NSString *full_picture_path = [NSString stringWithFormat:@"https://%@.breezechms.com/%@", subdomain, picture_path];
                            
                            //Pull base64-encoded photo
                            NSString *picture = [person objectForKey:@"encoded_image"];
                            
                            //Creating the data from your base64String
                            NSData *data = [[NSData alloc] initWithBase64EncodedString:picture options:0];
                            
                            //Now data is decoded. You can convert them to UIImage
                            UIImage *image = [UIImage imageWithData:data];
                            
                            [self setValue:image forKeyPath:[NSString stringWithFormat:@"%@.image", field]];

//                        } else {
//                            // images causing errors
//                            // set logo
//                            @try {
//                                // if picture is present
//                                if(fieldKey) {
//                                    
//                                    // get picture from stored container
//                                    //var picture = $('div#logo_base64_container').text();
//                                    
//                                    // if not found in stored container (first time through)
//                                    if(!picture) {
//                                        
//                                        // convert picture to base64 with PHP
//                                        $.ajax({
//                                        type: "POST",
//                                        url: "../../../../../../../../ajax/convert_image_to_base64",
//                                        async: false,
//                                        data: {
//                                        url: fieldKey
//                                        },
//                                        success: function(picture_encoded) {
//                                            picture = picture_encoded;
//                                            
//                                            // store to invisible container so doesn't need to be fetched via ajax each time
//                                            if(picture) { $('div#logo_base64_container').text(picture); }
//                                            
//                                        }
//                                        });
//                                    }
//                                    
//                                    // if picture successfully encoded
//                                    if(picture) { label.setObjectText(placeholder, picture); }
//                                
//                                }
//                                
//
//                            }
//                            @catch (NSException *exception) {
//                                <#Handle an exception thrown in the @try block#>
//                            }
//                            @finally {
//                                <#Code that gets executed whether or not an exception is thrown#>
//                            }
//                            try {
//                                
//                            } catch(err) { }
                        }
                    } else {
                        @try {
                            NSString *value = [all objectForKey:fieldKey];
                            [self setValue:value forKeyPath:[NSString stringWithFormat:@"%@.text", field]];
                            
                        } @catch (NSException *exception) {} @finally {}
                    }
                }
                @catch (NSException *exception) {
                    NSLog(@"Exception: %@", exception);
                }
                @finally { }
                break;
                /*
                 try {
                 // image
                 if(field == @"child_image") {
                 
                 if(fieldKey == @"profile") {
                 try {
                 NSString *picture_path = [person objectForKey:@"path"];
                 NSString *full_picture_path = @"https://" + subdomain + ".breezechms.com/" + picture_path;
                 
                 //Pull base64-encoded photo
                 NSString *picture = [person objectForKey:@"encoded_image"];
                 
                 //Creating the data from your base64String
                 NSData *data = [[NSData alloc] initWithData:[NSData
                 dataFromBase64String:picture]];
                 
                 //Now data is decoded. You can convert them to UIImage
                 UIImage *image = [UIImage imageWithData:data];
                 
                 [self setValue:image forKeyPath:[NSString stringWithFormat:@"%@.image", field]];
                 
                 } catch(err) { }
                 } else {
                 
                 // images causing errors
                 // set logo
                 try {
                 
                 // if picture is present
                 if(field) {
                 
                 // get picture from stored container
                 var picture = $('div#logo_base64_container').text();
                 
                 // if not found in stored container (first time through)
                 if(!picture) {
                 
                 // convert picture to base64 with PHP
                 $.ajax({
                 type: "POST",
                 url: "../../../../../../../../ajax/convert_image_to_base64",
                 async: false,
                 data: {
                 url: field
                 },
                 success: function(picture_encoded) {
                 picture = picture_encoded;
                 
                 // store to invisible container so doesn't need to be fetched via ajax each time
                 if(picture) { $('div#logo_base64_container').text(picture); }
                 
                 }
                 });
                 }
                 
                 // if picture successfully encoded
                 if(picture) { label.setObjectText(placeholder, picture); }
                 
                 }
                 
                 } catch(err) { }
                 }
                 
                 } else {
                 
                 try {
                 var value = '';
                 
                 // if in quotes, take actual value
                 if(field.charAt(0) == '"') {
                 value = field.substring(1, field.length-1);
                 
                 //otherwise assume it's a field id
                 } else { */

                 }
        }
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    [_responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    
    //NSLog(@"Response Data: %@", _responseData);
    
    //NSString* jsonResponse = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
    
    if(NSClassFromString(@"NSJSONSerialization"))
    {
        NSError *error = nil;
        
        id object = [NSJSONSerialization
                     JSONObjectWithData:_responseData
                     options:0
                     error:&error];
        
        if(error) { /* JSON was malformed, act appropriately here */ }
        
        // validate dictionary
        if([object isKindOfClass:[NSDictionary class]])
        {
            self.person = object;
            
//            NSString *code = [self.webView stringByEvaluatingJavaScriptFromString:@"(function() {return code;})();"];
//            NSString *user_prompt = [self.webView stringByEvaluatingJavaScriptFromString:@"(function() {return user_prompt;})();"];
//            
            //create child label
//            NSString *child_or_parent = [queryStringDictionary objectForKey:@"child_or_parent"];
//            if ([child_or_parent isEqual: @"both"] || [child_or_parent isEqual: @"child"]) {
//                self.childLabel = [[[NSBundle mainBundle] loadNibNamed:@"FWCNameTagView" owner:self options:nil] objectAtIndex:0];
                [self assign_substitutions:_nametag_fields person:self.person];
                if (self.child_image.image == nil){
                    //no image set
                    [self.imageStackView removeArrangedSubview:self.child_image];
                    [self.child_image removeFromSuperview];
                    [self layoutIfNeeded];
                }
                else{
                    //image set
                }
                
                
//            }
            
        }
        else
        {
            /* there's no guarantee that the outermost object in a JSON
             packet will be a dictionary; if we get here then it wasn't,
             so 'object' shouldn't be treated as an NSDictionary; probably
             you need to report a suitable error condition */
        }
    }
    else
    {
        // the user is using iOS 4; we'll need to use a third-party solution.
        // If you don't intend to support iOS 4 then get rid of this entire
        // conditional and just jump straight to
        // NSError *error = nil;
        // [NSJSONSerialization JSONObjectWithData:...
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
}

@end
