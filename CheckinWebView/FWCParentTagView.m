//
//  FWCParentTagView.m
//  CheckinAir
//
//  Created by Mark Petereit on 2/19/16.
//  Copyright © 2016 Family Worship Center. All rights reserved.
//

#import "FWCParentTagView.h"

@implementation FWCParentTagView

-(void) assign_substitutions:(NSDictionary *)nametag_fields person:(NSDictionary *)person{
    
    // set name (not user-defined on layout template)
    @try {
        self.child_names_1.text = [NSString stringWithFormat:@"%@ %@", [person valueForKey:@"first_name"], [person valueForKey:@"last_name"]];
        self.child_names_2.text = self.child_names_1.text;
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
                    if([fieldKey rangeOfString:@"\""].location == NSNotFound){
                        NSString *value = [all objectForKey:fieldKey];
                        [self setValue:value forKeyPath:[NSString stringWithFormat:@"%@.text", field]];
                    } else {
                        NSString *value = [fieldKey stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                        [self setValue:value forKeyPath:[NSString stringWithFormat:@"%@.text", field]];
                    }

                } @catch (NSException *exception) {} @finally {}
                /*
                 try {
                 // image
                 if(placeholder == 'child_image') {
                 
                 if(field == 'profile') {
                 try {
                 var picture_path = person.path;
                 var subdomain = window.location.hostname.match(/^.*?-?(\w*)\./)[1];
                 var full_picture_path = 'https://' + subdomain + '.breezechms.com/' + picture_path;
                 
                 var picture = person.encoded_image;
                 
                 label.setObjectText(placeholder, picture);
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
                 } else {
                 value = person.all[field];
                 }
                 
                 label.setObjectText(placeholder, value);
                 } catch(err) { }
                 
                 }
                 } catch(err) { }
                 break;
                 
                 }
                 */
                break;
        }
    }
}
@end
