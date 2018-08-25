var xml_layout;
var people_table;
var mode;
var live_search_delay_timeout;
var filter_by_tag_ids_json = '';
var child_text_label_xml = '';
var child_image_label_xml = '';
var parent_label_xml = '';
var family_label_xml = '';
var child_label_xml = '';
var child_label = '';
var nametag_fields = '';
var pathArray = window.location.pathname.split( '/' );
var instance_id = pathArray[3];
var code = '';
var used_codes = [];
var code_three = '';
var used_codes_three = [];
var user_prompt = 'BLANK';
var by_family = false;
var disable_thumbnail = false;
var load_checkin_people_from_instance_id_request;
var clear_screen_timer;
var global_checked_in_num = 0;
var global_anonymous_num = 0;
var family_people_ids_to_print = [];
var field_ids_json = [];

function frameworkInitShim() {
    
    setTimeout(function(){
               
               if($('input#print').val() > 0) {
               dymo.label.framework.trace = 0; //true
               dymo.label.framework.init(startupCode); //init, then invoke a callback
               } else {
               startupCode();
               }
               
               }, 500);
    
}

window.onload = frameworkInitShim;

function startupCode() {
    
    $('h1#short_date').on('click', function(e) {
                          $("a#events_panel_trigger").trigger( "click" );
                          });
    
    // get labels
    var child_text_label_xml_path = 'js/dymo/labels/child_text_10_2_14.label';
    var child_image_label_xml_path = 'js/dymo/labels/child_img_10_2_14.label';
    var parent_label_xml_path = 'js/dymo/labels/parent_9_30_14.label';
    var family_label_xml_path = 'js/dymo/labels/family_10_6_14b.label';
    
    // get tags - very important to explicitly state that they should be in HTML format so that browser doesn't try to be fancy and store them as an object - DYMO won't know what to do with them then
    $.ajax({
           url: "../../../../../../../../"+child_text_label_xml_path,
           dataType: 'html',
           cache: true,
           success: function(labelXml){
           
           child_text_label_xml = labelXml;
           
           }
           });
    
    $.ajax({
           url: "../../../../../../../../"+child_image_label_xml_path,
           dataType: 'html',
           cache: true,
           success: function(labelXml){
           
           child_image_label_xml = labelXml;
           
           }
           });
    
    $.ajax({
           url: "../../../../../../../../"+parent_label_xml_path,
           dataType: 'html',
           cache: true,
           success: function(labelXml){
           
           parent_label_xml = labelXml;
           
           }
           });
    
    $.ajax({
           url: "../../../../../../../../"+family_label_xml_path,
           dataType: 'html',
           cache: true,
           success: function(labelXml){
           
           family_label_xml = labelXml;
           
           }
           });
    
    // get nametag fields (if this fails it results in weird placeholder labels coming through)
    $.ajax({
           url: '../../../../ajax/nametag_fields_by_instance_id',
           dataType: 'json',
           async: false, // force it to finish before moving on
           type: 'POST',
           data: {
           instance_id: instance_id
           },
           success: function(fields){
           nametag_fields = fields;
           field_ids_json = JSON.stringify(fields.field_ids);
           },
           error: function (request, status, error) {
           alert('Warning: The name tag template failed to load successfully.  Please refresh this page to try again.');
           }
           });
    
    $('ul#alphabet_filter').scrollToFixed();
    
    $('form.ui-listview-filter').hide();
    
    $('h3.date_label').on('click', function() {
                          $('div.date_field_container').slideDown();
                          $('input.date').focus();
                          });
    
    /*
     $('input.date').blur(function() {
     $('span.date_heading').text($('input.date').val());
     $('div.date_field_container').slideUp();
     $('div.events_loading').show();
     $('ul.events').hide();
     update_events_list($('input.date').val());
     });
     */
    
    $('select#print').on('change', function() {
                         if($(this).val() == 'on') { $('.print_option').show(); } else { $('.print_option').hide(); }
                         });
    
    $('a#check_in_family').on('click', function(e) {
                              e.preventDefault();
                              
                              // close pop up (happen first for snappy response)
                              $("div#family_checkin").popup("close", {transition: 'slidedown'});
                              
                              // CHECK SELECTED IN
                              var selected_action = 'in';
                              var selected_people_ids = [];
                              var instance_id = '';
                              var selected_checkout = '';
                              var selected_rows = $('div#family_checkin').find('a.in');
                              $.each(selected_rows, function(index, value) {
                                     var person_id = $(value).data('person_id');
                                     if(!selected_checkout) { if($(this).hasClass('checkout') == true) { selected_checkout = 1; } }
                                     if($(value).data('instance_id')) { instance_id = $(value).data('instance_id'); }
                                     if(person_id) { selected_people_ids.push(person_id); }
                                     });
                              
                              if(selected_people_ids.length > 0) {
                              
                              var instance_id_to_pass = instance_id; // instance_id disappears in callback
                              
                              // if checking in and a printed event, apply pending status to all checked in family members
                              if(selected_action == 'in' && $('input#print').val() == '1') {
                              $.each($(selected_people_ids), function(index, person_id) {
                                     update_link_container_style(person_id, 'pending', selected_checkout, '', true);
                                     });
                              }
                              
                              $.ajax({
                                     url: '../../../../ajax/check_people_ids_into_out_of_instance_id',
                                     type: 'POST',
                                     dataType: 'html',
                                     data: {
                                     people_ids_json: JSON.stringify(selected_people_ids),
                                     instance_id: instance_id,
                                     action: selected_action,
                                     checkout: selected_checkout
                                     },
                                     success: function(datetime){
                                     
                                     reset_printer_variables()
                                     
                                     // highlight correct rows
                                     $.each($(selected_people_ids), function(index, person_id) {
                                            
                                            //var link_container = $('table#people_list').find('a[data-person_id="'+person_id+'"]');
                                            
                                            if(selected_action != 'in' || $('input#print').val() != '1') {
                                            update_link_container_style(person_id, selected_action, selected_checkout, datetime, true);
                                            }
                                            
                                            update_quantity();
                                            print_tag(person_id, instance_id_to_pass, 'child', selected_checkout); // print nametag for child
                                            
                                            });
                                     
                                     print_tag(selected_people_ids, instance_id_to_pass, 'parent', selected_checkout); // print nametag for parent
                                     
                                     if(mode == 'search') {
                                     clear_screen_timer = setTimeout(function() { $('input#filter_people').val(''); $('input#filter_people').focus(); }, 5000);
                                     }
                                     
                                     },
                                     error: function(xhr, textStatus, errorThrown) {
                                     alert('Sorry, we were not able to save this change.  Please ensure that you are connected to the internet and then refresh this page.')
                                     }
                                     });
                              
                              }
                              
                              // CHECK UN-SELECTED OUT
                              var unselected_action = 'remove';
                              var unselected_people_ids = [];
                              var instance_id = '';
                              var unselected_checkout = '';
                              var unselected_rows = $('div#family_checkin').find('a.out');
                              $.each(unselected_rows, function(index, value) {
                                     var person_id = $(value).data('person_id');
                                     if(!unselected_checkout) { if($(this).hasClass('checkout') == true) { unselected_checkout = 1; } }
                                     if($(value).data('instance_id')) { instance_id = $(value).data('instance_id'); }
                                     if(person_id) { unselected_people_ids.push(person_id); }
                                     });
                              
                              if(unselected_people_ids.length > 0) {
                              
                              $.ajax({
                                     url: '../../../../ajax/check_people_ids_into_out_of_instance_id',
                                     type: 'POST',
                                     dataType: 'html',
                                     data: {
                                     people_ids_json: JSON.stringify(unselected_people_ids),
                                     instance_id: instance_id,
                                     action: unselected_action,
                                     checkout: unselected_checkout
                                     },
                                     success: function(datetime){
                                     
                                     $.each($(unselected_people_ids), function(index, person_id) {
                                            
                                            //var link_container = $('table#people_list').find('a[data-person_id="'+person_id+'"]');
                                            update_link_container_style(person_id, unselected_action, unselected_checkout, datetime, true);
                                            update_quantity();
                                            
                                            });
                                     
                                     },
                                     error: function(xhr, textStatus, errorThrown) {
                                     alert('Sorry, we were not able to save this change.  Please ensure that you are connected to the internet and then refresh this page.')
                                     }
                                     });
                              
                              }
                              
                              // REMOVE
                              var removed_action = 'out';
                              var removed_people_ids = [];
                              var instance_id = '';
                              var removed_checkout = '';
                              var unselected_rows = $('div#family_checkin').find('a.remove');
                              $.each(unselected_rows, function(index, value) {
                                     var person_id = $(value).data('person_id');
                                     if(!removed_checkout) { if($(this).hasClass('checkout') == true) { removed_checkout = 1; } }
                                     if($(value).data('instance_id')) { instance_id = $(value).data('instance_id'); }
                                     if(person_id) { removed_people_ids.push(person_id); }
                                     });
                              
                              if(removed_people_ids.length > 0) {
                              
                              $.ajax({
                                     url: '../../../../ajax/check_people_ids_into_out_of_instance_id',
                                     type: 'POST',
                                     dataType: 'html',
                                     data: {
                                     people_ids_json: JSON.stringify(removed_people_ids),
                                     instance_id: instance_id,
                                     action: removed_action,
                                     checkout: removed_checkout
                                     },
                                     success: function(datetime){
                                     
                                     // highlight correct rows
                                     $.each($(removed_people_ids), function(index, person_id) {
                                            
                                            //var link_container = $('table#people_list').find('a[data-person_id="'+person_id+'"]');
                                            update_link_container_style(person_id, removed_action, removed_checkout, datetime, true);
                                            update_quantity();
                                            
                                            });
                                     
                                     },
                                     error: function(xhr, textStatus, errorThrown) {
                                     alert('Sorry, we were not able to save this change.  Please ensure that you are connected to the internet and then refresh this page.')
                                     }
                                     });
                              
                              }
                              
                              });
    
    $('div#family_checkin').on('click', 'a.checkin', function(event) {
                               var action = $(this).data('action');
                               var link_container = $(this).closest('a');
                               var checkout = 0; if($(this).hasClass('checkout') == true) { checkout = 1; }
                               update_link_container_style(link_container, action, checkout);
                               });
    
    $('table#people_list').on('click', 'a.checkin', function(event) {
                              event.preventDefault();
                              
                              if(mode == 'search') {
                              if (typeof clear_screen_timer != 'undefined') {
                              clearTimeout(clear_screen_timer);
                              }
                              }
                              
                              var person_id = $(this).data('person_id');
                              var instance_id = $(this).data('instance_id');
                              var action = $(this).data('action');
                              var link_container = $(this).closest('a');
                              var family_id = $(this).closest('tr').data('family_id');
                              var family_members = 0;
                              
                              // prevent double click if already processing
                              if($('input#print').val() == '1') { // if printed event
                              var is_spinner = people_table.$('tr').find('a[data-person_id="'+person_id+'"]').find('i.icon-spinner').length;
                              
                              // and if icon is a spinner, then stop
                              if(is_spinner) { return false; }
                              
                              }
                              
                              // get number of family members
                              family_members = people_table.$('tr[data-family_id="'+family_id+'"]').length;
                              
                              if(family_id && by_family) {
                              
                              // empty table in family div
                              $('div#family_checkin_container').find('tbody').html(''); // clear family
                              $('div#family_checkin_loading_container').show();
                              
                              // if in search mode, load family via ajax
                              if(mode == 'search') {
                              
                              // search for people
                              load_checkin_people_from_instance_id_request = $.ajax({
                                                                                    url: '../../../../ajax/load_checkin_people_from_instance_id',
                                                                                    dataType: 'json',
                                                                                    type: 'POST',
                                                                                    data: {
                                                                                    instance_id: instance_id,
                                                                                    filter_by_tag_ids_json: filter_by_tag_ids_json,
                                                                                    family_id: family_id
                                                                                    },
                                                                                    success: function(result){
                                                                                    
                                                                                    $('div#family_checkin_loading_container').hide();
                                                                                    update_people_list(result, true, 'family_people_list');
                                                                                    
                                                                                    // pre-check selected family member
                                                                                    precheck_selected_family_member(person_id, checkout);
                                                                                    
                                                                                    }
                                                                                    });
                              
                              // if in list mode, load family by copying existing rows
                              } else {
                              
                              $('div#family_checkin_loading_container').hide();
                              
                              // for each family member, copy row into family div
                              $.each(people_table.$('tr[data-family_id="'+family_id+'"]'), function(index, value) {
                                     var row = $(this).clone(true);
                                     $(row).show(); // make row visible
                                     $('div#family_checkin_container').find('table').append(row);
                                     });
                              
                              }
                              
                              // pre-check selected family member
                              precheck_selected_family_member(person_id, checkout);
                              
                              // display family div
                              $("div#family_checkin").popup("open", {transition: 'slidedown'});
                              
                              if(mode == 'search') {
                              if (typeof clear_screen_timer != 'undefined') {
                              clearTimeout(clear_screen_timer);
                              }
                              }
                              
                              // halt further progress
                              return false;
                              }
                              
                              // if removing, confirm want to remove
                              if(action == 'remove') {
                              var r=confirm("Are you sure you want to remove this attendance record?");
                              if (r!=true) { return false; }
                              }
                              
                              // find out if event is checkout event
                              var checkout = 0;
                              if($(this).hasClass('checkout') == true) {
                              checkout = 1;
                              }
                              
                              // if checking in AND not family (as that would have stopped previously) AND a printed event, set icon to pending
                              if(action == 'in' && $('input#print').val() == '1') {
                              update_link_container_style(person_id, 'pending', checkout, '', true);
                              
                              // otherwise apply normal styling
                              } else {
                              update_link_container_style(person_id, action, checkout, '', true);
                              }
                              
                              // print
                              if(action == 'in') {
                              reset_printer_variables();
                              print_tag(person_id, instance_id, 'both', checkout);
                              }
                              
                              $.ajax({
                                     url: '../../../../ajax/check_person_id_into_out_of_instance_id',
                                     type: 'POST',
                                     dataType: 'html',
                                     data: {
                                     person_id: person_id,
                                     instance_id: instance_id,
                                     action: action,
                                     checkout: checkout
                                     },
                                     success: function(datetime){
                                     
                                     if(datetime == "duplicate") {
                                     alert('Person already checked in on another device.');
                                     
                                     } else {
                                     
                                     if(action == 'in') {
                                     if(checkout) {
                                     $(link_container).closest('div').find('.check_in_time').text(datetime);
                                     }
                                     }
                                     
                                     if(action == 'out') {
                                     if(checkout) {
                                     $(link_container).closest('div').find('.check_out_time').text(datetime);
                                     }
                                     }
                                     
                                     }
                                     
                                     if(mode == 'search') {
                                     clear_screen_timer = setTimeout(function() { $('input#filter_people').val(''); $('input#filter_people').focus(); }, 5000);
                                     }
                                     
                                     },
                                     error: function(xhr, textStatus, errorThrown) {
                                     alert('Sorry, we were not able to save this change.  Please ensure that you are connected to the internet and then refresh this page.')
                                     }
                                     });
                              
                              update_quantity();
                              
                              });
    
    // load instance
    $('ul.events').on('click', 'a.load_instance', function() {
                      var instance_id = $(this).data('instance_id');
                      window.location.href = "../../../../../../checkin/index/"+instance_id;
                      });
    
    
    
}

function precheck_selected_family_member(person_id, checkout) {
    
    if(person_id) {
        
        var selected_family_link_container = $('div#family_checkin_container').find('a[data-person_id="'+person_id+'"]');
        
        if(!checkout) { if($(selected_family_link_container).hasClass('checkout') == true) { checkout = 1; } }
        
        if(checkout) {
            
            if($(selected_family_link_container).hasClass('out') && !$(selected_family_link_container).hasClass('remove')) {
                
                $(selected_family_link_container).removeClass('out');
                $(selected_family_link_container).addClass('in');
                $(selected_family_link_container).data('action', 'out');
                
                $(selected_family_link_container).find('i.icon-play').addClass('icon-stop');
                $(selected_family_link_container).find('i.icon-play').removeClass('icon-play');
                
                //$(link_container).closest('div').find('.check_in_time').text('...');
                //$(link_container).closest('div').find('.check_in_time').show();
                
            }
            
        } else {
            $(selected_family_link_container).removeClass('out');
            $(selected_family_link_container).addClass('in');
            $(selected_family_link_container).data('action', 'out');
            
        }
    }
    
}

function print_tag(person_id, instance_id, child_or_parent, checkout) {
    
    if($('input#print').val() != '1') { return false; } // if not set to print, return false
    
    if(!child_or_parent) { child_or_parent = 'both'; }
    
    var people_ids_json = '';
    if (person_id instanceof Array) {
        people_ids_json = JSON.stringify(person_id);
        var parent_xml = family_label_xml;
    } else {
        people_ids_json = '';
        var parent_xml = parent_label_xml;
    }
    
    $.ajax({
           url: '../../../../ajax/get_check_in_person_from_id',
           dataType: 'json',
           type: 'POST',
           data: {
           person_id: person_id,
           instance_id: instance_id,
           fetch_instance: '1',
           people_ids_json: people_ids_json,
           field_ids_json: field_ids_json
           },
           success: function(person){
           
           // set the checkbox as clicked
           update_link_container_style(person_id, 'in_override', checkout, '', true);
           
           // create child label
           if(child_or_parent == 'both' || child_or_parent == 'child') {
           if(nametag_fields.child_image && nametag_fields.child_image != "0") { child_label_xml = child_image_label_xml; } else { child_label_xml = child_text_label_xml; } // determine if text or image
           child_label = dymo.label.framework.openLabelXml(child_label_xml);
           child_label = assign_substitutions(child_label, person);
           print(child_label);
           }
           
           // create parent label
           if(child_or_parent == 'both' || child_or_parent == 'parent') {
           if($('input#print_parent').val() == '1') {
           parent_label = dymo.label.framework.openLabelXml(parent_xml);
           parent_label = assign_substitutions(parent_label, person);
           print(parent_label);
           }
           }
           
           }
           });
    
}

function print(label) {
    
    // check specified printer
    var selected_printer_name = $('select#printer_list :selected').text();
    var selected_printer_type = $('select#printer_list :selected').data('printer_type');
    
    if(selected_printer_name == 'None') { return false; }
    
    switch (selected_printer_type) {
            
        case "local":
            //case "DYMO LabelWriter 450":
            //case "DYMO LabelWriter 450 Turbo":
            //case "DYMO LabelWriter 450 Twin Turbo":
            
            // if print locally
            var labelPrinter = selected_printer_name;
            label.print(labelPrinter);
            break;
            
        default:
            
            if(!selected_printer_name) { alert('No Printer Selected'); return false; }
            
            // if print to station
            var label_xml = label.getLabelXml();
            var label_xml_file = "";
            
            // save label xml to file (too big to pass directly)
            $.ajax({
                   type: "POST",
                   url: "../../../../../../../../ajax/save_label_xml",
                   async: false,
                   data: {
                   label_xml: label_xml
                   },
                   success: function(label_xml_file_response) {
                   label_xml_file = label_xml_file_response;
                   }
                   });
            
            // pass file reference to pusher
            $.ajax({
                   type: "POST",
                   url: "../../../../../../../../ajax/print_to_station",
                   data: {
                   station_name: selected_printer_name,
                   label_xml_file: label_xml_file
                   },
                   success: function(response) {
                   // success
                   }
                   });
            
            break;
            
    }
    
}

function generate_job_id() {
    return '_' + Math.random().toString(36).substr(2, 9);
}

function update_date(passed_date) {
    
    var monthNames = [ "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                      "Jul", "Aug", "Sept", "Oct", "Nov", "Dec" ];
    
    var event_date = new Date(passed_date);
    
    var year = event_date.getFullYear();
    var month = event_date.getMonth()+1;
    var day = event_date.getDate();
    
    var date_formatted_name = monthNames[month-1] + ' ' + day + ', ' + year;
    var date_formatted_num = month + '/' + day + '/' + year;
    var short_date_formatted_name = monthNames[month-1] + ' ' + day;
    
    // set date text
    $('h1#short_date').html(short_date_formatted_name);
    $('span.date_button_text').html(short_date_formatted_name);
    
    // set highlight on calendar
    $('input#ctrlgrp').val(month+'/'+day+'/'+year);
    
}



function update_printer_status(instance_id, oid) {
    
    $('div#search_by_name').hide();
    
    // if printer event
    if($('input#print').val() > 0) {
        
        // show searching for printer status
        $('div.people_loading').html('<i class="icon-spinner icon-spin"></i> Finding Printer...');
        
        // add none as option
        $('select#printer_list')
        .append($("<option></option>")
                .attr("value","none")
                .text("None"));
        
        // add local printers to list (delay is needed so that finding printer status message is displayed)
        setTimeout(function() {
                   
                   // get local printers
                   list_local_printers();
                   
                   // add print stations to list
                   list_printer_stations(oid);
                   
                   // chrome alert - delay so list_printer_stations has time to run (this will simultaneously w/ previous functions so need extra delay)
                   setTimeout(function() {
                              
                              $('div.people_loading').hide();
                              if(mode == 'search') { $('div#search_by_name').show(); }
                              
                              // if no printers found, display chrome NPAPI alert
                              var has_printer = $('select#printer_list').data('found');
                              if(!has_printer) {
                              try { $("div#chrome_alert").popup("open", {transition: 'slidedown'}); } catch(err) { }
                              }
                              
                              $('div.people_loading').html('<i class="icon-spinner icon-spin"></i> Loading People...'); // switch back to loading people
                              
                              },4500);
                   
                   },200);
        
        // if not printer event
    } else {
        
        if(mode == 'search') { $('div#search_by_name').show(); }
        
        // hide print icon
        $('div.people_loading').hide();
        $('#print_status').hide();
        
    }
    
}

function list_local_printers() {
    
    var labelPrinter = "";
    var printer_found = "";
    // var printer_is_connected = "";
    var printers = dymo.label.framework.getPrinters();
    
    $.each(printers, function(index, printer) {
           
           var printer_id = index;
           var printer_name = printer.name;
           printer_found = 1;
           //printer_is_connected = printer.isConnected; // don't trust this
           
           $('span#printer_list_none_found').hide();
           $('span#printer_list_container').show();
           $('select#printer_list')
           .append($("<option></option>")
                   .attr("value",printer_id)
                   .text(printer_name)
                   .data('printer_type', 'local'));
           
           $('select#printer_list').val(printer_id);
           
           });
    
    try { $('select#printer_list').selectmenu('refresh'); } catch(err) { }
    
    // for updating print station view
    // if printer is found
    if(printer_found) {
        
        $('select#printer_list').data('found', 'true');
        
        // show options on print station page
        try {
            print_station_success('Ready to Print');
            $('select#printer_list').show();
            $('a#test_print').show();
        } catch(err) { }
        
        // show option on check in page
        try {
            $('div#become_print_station_container').show();
        } catch(err) { }
        
        
        
        // if printer not found (software not found)
    } else {
        
        try { print_station_error('DYMO Software Not Found', 'We were not able to detect the DYMO Label Software as being installed on this computer.  If it is, please try uninstalling and reinstalling the software.  More information on the DYMO Label Software is available <a href="http://www.breezechms.com/docs#checkin_print_setup" target="_blank">on our documentation</a>.'); } catch(err) { }
        
    }
    
    
}

var visible_add_person_field_ids = []; // add person fields that can be referenced elsewhere

function load_instance_by_instance_id(instance_id, oid) {
    
    if($('table#people_list').hasClass('initialized')) {
        try { people_table.fnDestroy(); } catch(err) { }
        $("table#people_list > tbody").html("");
    }
    
    $('div.select_event').hide();
    $('div.no_people_found_container').hide();
    $('div.people_loading').show();
    $('ul.people').hide();
    $("#events_panel").panel("close");
    
    $('button#add_new_person').data('instance_id', instance_id);
    
    // update event-specific data
    $.ajax({
           url: '../../../../ajax/event_instance_json_by_instance_id_via_post',
           dataType: 'json',
           type: 'POST',
           async: false, // need to complete this before moving on to get variables
           data: {
           instance_id: instance_id
           },
           success: function(result){
           
           // get and load check in options
           $.ajax({
                  url: '../../../../ajax/get_event_check_in_options',
                  dataType: 'json',
                  type: 'POST',
                  async: false,
                  data: {
                  instance_id: instance_id
                  },
                  success: function(result){
                  
                  // mode
                  if(result.mode == 'search') {
                  
                  mode = result.mode;
                  
                  $('button#search').attr('disabled', 'disabled');
                  $('button#search').text('Enabled');
                  $('button#search').button('refresh');
                  
                  $('button#list').removeAttr('disabled');
                  $('button#list').text('Enable');
                  $('button#list').button('refresh');
                  
                  }
                  
                  // add person fields
                  if(result.add_person_fields) {
                  if(result.selected_fields_json) {
                  var selected_fields = $.parseJSON(result.selected_fields_json);
                  $('div.checkin_add_person_field_container').hide();
                  $.each(selected_fields, function(key, value) {
                         $('div[data-field_id="'+value+'"]').show();
                         visible_add_person_field_ids.push(value);
                         });
                  }
                  }
                  
                  if(result.by_family == 1) { by_family = true; }
                  if(result.disable_thumbnail == 1) { disable_thumbnail = true; }
                  
                  $('input#check_out').val(result.check_out);
                  
                  $('input#print').val(result.check_in_print);
                  
                  if(result.check_in_print < 1) {
                  $('span#printing_disabled').show();
                  $('span#printing_enabled').hide();
                  }
                  
                  $('input#label_path').val(result.label.path);
                  $('input#print_custom_code').val(result.check_in_print_custom_code);
                  $('input#print_group').val(result.check_in_print_group);
                  $('input#print_phone').val(result.check_in_print_phone);
                  $('input#print_auto_code').val(result.check_in_print_auto_code);
                  $('input#print_date_time').val(result.check_in_print_date_time);
                  $('input#print_parent').val(result.check_in_print_parent);
                  $('input#print_parent_tape').val(result.check_in_print_parent_tape);
                  $('input#print_tape_name').val(result.check_in_tape_name);
                  $('input#print_tape_autocode').val(result.check_in_tape_autocode);
                  $('input#print_tape_custom_code').val(result.check_in_tape_custom_code);
                  $('input#print_custom_field_id').val(result.print_custom_field_id);
                  
                  if(result.check_in == 'tags') {
                  $('div#add_person_tag_container').show();
                  $('button#add_new_person').data('include_tags', '1');
                  } else {
                  $('div#add_person_tag_container').remove(); // remove so it can't be used even when show() command tries to hit it
                  $('button#add_new_person').data('include_tags', '0');
                  }
                  
                  // update printer status (if printing is enabled for event)
                  if(result.check_in_print > 0) {
                  update_printer_status(instance_id, oid);
                  }
                  
                  }
                  });
           
           
           var timestamp = result.start_datetime.split(/[- :]/);
           var event_date = new Date(timestamp[0], timestamp[1]-1, timestamp[2], timestamp[3], timestamp[4], timestamp[5]);
           
           $('.event_title').text(result.name);
           update_date(event_date);
           update_events_list(result.start_datetime, false);
           
           }
           });
    
    // LIST MODE - Show people in list if in list mode
    if(mode != "search") {
        
        // don't return family id unless really needed (faster without needing to fetch family ids)
        var exclude_by_family = 1;
        if(by_family) { exclude_by_family = 0; }
        
        load_checkin_people_from_instance_id_request = $.ajax({
                                                              url: '../../../../ajax/load_checkin_people_from_instance_id',
                                                              dataType: 'json',
                                                              type: 'POST',
                                                              data: {
                                                              instance_id: instance_id,
                                                              filter_by_tag_ids_json: filter_by_tag_ids_json,
                                                              exclude_by_family: exclude_by_family
                                                              },
                                                              success: function(result){
                                                              
                                                              update_people_list(result, false, 'people_list');
                                                              
                                                              }
                                                              });
        
        // listen for typing - table search
        $('input#filter_people').on('keyup', function(e) {
                                    var input = $(this).val();
                                    if (typeof people_table != 'undefined') { people_table.fnFilter(input); } // verify exists prior to running
                                    });
        
        // SEARCH MODE - Search mode
    } else {
        
        // set initial view - clear loading message and alphabet bar
        $('ul#alphabet_filter').hide();
        
        // if printer event, show/hide messages after printer loads
        if($('input#print').val() < 1) {
            $('div.people_loading').hide();
            $('div#search_by_name').show();
        }
        
        $('input#filter_people').attr("placeholder", "Search for First or Last Name");
        $('div#no_people_found_on_search_container').hide();
        
        // listen for typing - ajax search
        $('input#filter_people').on('keyup', function(e) {
                                    
                                    if (typeof clear_screen_timer != 'undefined') {
                                    clearTimeout(clear_screen_timer)
                                    }
                                    
                                    // hide no people found notice
                                    $('div#no_people_found_on_search_container').hide();
                                    
                                    // get input
                                    var input = $(this).val();
                                    
                                    // if input is enough characters to search
                                    if(input.length > 2) {
                                    
                                    // don't return family id unless really needed (adds a lot of load to ajax search to return it when it doesn't need it)
                                    var exclude_by_family = 1;
                                    if(by_family) { exclude_by_family = 0; }
                                    
                                    // show loading message and clear list
                                    $('div.people_loading').show();
                                    $('div#search_by_name').hide();
                                    $('table#people_list').html('<tbody></tbody>');
                                    
                                    // make sure search message is accurate and not still on finding printer
                                    $('div.people_loading').html('<i class="icon-spinner icon-spin"></i> Loading People...'); // switch back to loading people
                                    
                                    // abort previous search if still running
                                    if(load_checkin_people_from_instance_id_request) { load_checkin_people_from_instance_id_request.abort(); }
                                    
                                    // clear previous timeout
                                    try {
                                    clearTimeout(live_search_delay_timeout);
                                    } catch(err) {
                                    // nada
                                    }
                                    
                                    // delay so doesn't search between every keystroke if typer is decently quick
                                    live_search_delay_timeout = setTimeout(function(){
                                                                           
                                                                           // search for people
                                                                           load_checkin_people_from_instance_id_request = $.ajax({
                                                                                                                                 url: '../../../../ajax/load_checkin_people_from_instance_id',
                                                                                                                                 dataType: 'json',
                                                                                                                                 type: 'POST',
                                                                                                                                 data: {
                                                                                                                                 instance_id: instance_id,
                                                                                                                                 filter_by_tag_ids_json: filter_by_tag_ids_json,
                                                                                                                                 search_query: input,
                                                                                                                                 exclude_by_family: exclude_by_family
                                                                                                                                 },
                                                                                                                                 success: function(result){
                                                                                                                                 
                                                                                                                                 update_people_list(result, true, 'people_list');
                                                                                                                                 
                                                                                                                                 }
                                                                                                                                 });
                                                                           
                                                                           }, 1700);
                                    
                                    
                                    
                                    // if input does not enough characters to search
                                    } else {
                                    
                                    $('div.people_loading').hide();
                                    $('div#search_by_name').show();
                                    $('div#no_people_found_on_search_container').hide();
                                    $('#people_list').html('');
                                    
                                    }
                                    
                                    
                                    });
        
    }
    
    // update tags
    $.ajax({
           url: '../../../../ajax/get_tags_json_by_instance_id',
           dataType: 'json',
           type: 'POST',
           data: {
           instance_id: instance_id
           },
           success: function(tags){
           
           $('select#add_person_tag').find('option').remove();
           
           var options = $("select#add_person_tag");
           $.each(tags, function() {
                  options.append($("<option />").val(this.id).html(this.name));
                  });
           
           $('select#add_person_tag').selectmenu('refresh');
           
           }
           });
    
    
}

function change_icon(element, icon) {
    
    setTimeout(function() { // prioritizes this change which helps prevent double check in (see http://stackoverflow.com/questions/9083594/call-settimeout-without-delay)
               
               // if not updating to spinner status and out_override is applied, don't change icon (this prevents Pusher from prematurely updating icon before "ajax/get_check_in_person_from_id" returns
               if(icon != 'icon-spinner' && $(element).closest('a').hasClass('out_override')) { return false; } // if out_override has control, don't change status
               
               // remove all icons
               $(element).removeClass('icon-play');
               $(element).removeClass('icon-stop');
               $(element).removeClass('icon-remove');
               $(element).removeClass('icon-ok');
               $(element).removeClass('icon-spinner');
               $(element).removeClass('icon-spin');
               
               // add in passed icon
               $(element).addClass(icon);
               
               // if spinner icon, set in motion
               if(icon == 'icon-spinner') {
               $(element).addClass('icon-spin');
               } else {
               $(element).css('transform', 'none'); // fix perpetual scroll issue in IE/Edge (http://stackoverflow.com/questions/32265720/spinning-icons-strange-behavior-on-ie)
               }
               
               }, 0);
    
}

function update_checkin_checkout_time(element, action, datetime) {
    
    switch(action) {
            
        case 'in':
            if(datetime) {
                $(element).closest('div').find('.check_in_time').text(datetime);
                $(element).closest('div').find('.check_in_time').show();
            }
            break;
            
        case 'remove':
            $(element).closest('div').find('.check_in_time').hide();
            $(element).closest('div').find('.check_out_time').hide();
            break;
            
        case 'out':
            if(datetime) {
                $(element).closest('div').find('.check_out_time').text(datetime);
                $(element).closest('div').find('.check_out_time').show();
                
                // if no previously established check in time
                if(!$(element).closest('div').find('.check_in_time').is(":visible")) {
                    $(element).closest('div').find('.check_in_time').text(datetime);
                    $(element).closest('div').find('.check_in_time').show();
                }
            }
            break;
            
    }
    
}

function change_checkbox_status(element, status) {
    
    switch(status) {
            
        case 'remove':
            
            $(element).removeClass('in');
            $(element).removeClass('out');
            $(element).addClass('remove');
            $(element).data('action', 'remove');
            
            break;
            
        case 'out':
            
            $(element).removeClass('remove');
            $(element).removeClass('in');
            $(element).addClass('out');
            $(element).data('action', 'in');
            
            break;
            
        case 'in':
            
            $(element).removeClass('out');
            $(element).removeClass('remove');
            $(element).addClass('in');
            $(element).data('action', 'out');
            
            break;
            
        case 'pending':
            $(element).removeClass('in');
            $(element).addClass('out');
            $(element).addClass('out_override'); // the out_override class prevents the icon from being updated until in_override is called (which allows us to ignore Pusher's confirmation and instead wait for "ajax/get_check_in_person_from_id" to return)
            break;
            
    }
    
}

function update_people_list(result, hide_alphabet, table_id_to_populate) {
    
    var people_in_list = countProperties(result);
    
    if(!people_in_list) {
        if(!$('div#search_by_name').is(":visible") && $('input#filter_people').val()) { // if search by name message is not visible and there is search content
            $('div#no_people_found_on_search_container').show(); // show no people found message
        }
        $('table#people_list').hide();
    } else {
        $('table#people_list').show();
        $('div#no_people_found_on_search_container').hide();
    }
    
    if(hide_alphabet) { $('ul#alphabet_filter').hide(); }
    
    $('div.people_loading').hide();
    $('ul.people').empty();
    $('ul.people').show();
    
    var check_out = $('input#check_out').val();
    
    var new_letter = '';
    var ignore_leter = 'none'; // must be set to non-blank
    var letter_index = 0;
    
    if(people_in_list > 500) {
        
        $("div#switch_modes").popup("open", {transition: 'slidedown'});
        
    }
    
    $.each(result, function() {
           
           if(!this.family_id) { this.family_id = 0; }
           
           // set profile picture into correct variable
           if(this.profile_picture.thumb_path) { this.profile_picture = this.profile_picture.thumb_path; }
           
           if((this.last_name.charAt(0).toUpperCase() != new_letter) && (this.last_name.charAt(0).toUpperCase() != ignore_leter) && /^[a-zA-Z]$/.test(this.last_name.charAt(0).toUpperCase())) {
           new_letter = this.last_name.charAt(0).toUpperCase();
           letter_index++;
           ignore_leter = new_letter;
           if($.trim(new_letter)) { /* require there to be a letter */
           $('li.'+new_letter+'_letter').removeClass('hide');
           }
           } else {
           new_letter = '';
           }
           
           // retain ability to check out
           if(check_out > 0) {
           
           tr += '<tr data-family_id="'+this.family_id+'">';
           
           
           tr += '<td>';
           if(new_letter) { tr += '<a id="'+new_letter+'" class="anchor"></a>'; }
           tr += '<div class="pull-left"><label class="control-label check_in_name" for="inputEmail"><img src="../../../../../../../../../'+this.profile_picture+'" class="profile">'+this.last_name+', '+this.first_name+'</label></div><div class="pull-right check_container">';
           
           tr += '<div class="check_in_out_times" style="display: inline-block; color: #aaa; text-align: right; margin-right: 2em;">';
           
           if(this.check_in_datetime) {
           tr += '<span class="check_in_time">'+this.check_in_datetime+'</span>';
           } else {
           tr += '<span class="check_in_time hide">--:--</span>';
           }
           
           tr += '<br />&nbsp;';
           
           if(this.check_out_datetime) {
           tr += '<span class="check_out_time">'+this.check_out_datetime+'</span>';
           } else {
           tr += '<span class="check_out_time hide">--:--</span>';
           }
           
           tr += '</div>';
           
           if(this.checked_in) {
           
           if(this.check_out_datetime) {
           tr += '<a href="#" class="checkin checkout remove" data-action="remove" data-person_id="'+this.id+'" data-instance_id="'+instance_id+'"><span class="icon-stack"><i class="icon-sign-blank icon-stack-base"></i><i class="front_icon icon-remove icon-light"></i></span></a>';
           } else {
           tr += '<a href="#" class="checkin checkout in" data-action="out" data-person_id="'+this.id+'" data-instance_id="'+instance_id+'"><span class="icon-stack"><i class="icon-sign-blank icon-stack-base"></i><i class="front_icon icon-stop icon-light"></i></span></a>';
           }
           
           }
           
           if(!this.checked_in) { tr += '<a href="#" class="checkin checkout out" data-action="in" data-person_id="'+this.id+'" data-instance_id="'+instance_id+'"><span class="icon-stack"><i class="icon-sign-blank icon-stack-base"></i><i class="front_icon icon-play icon-light"></i></span></a>'; }
           
           tr += '</div></div></td>';
           tr += '<td class="hide">'+this.last_name+', '+this.first_name+'</td>';
           tr += '</tr>';
           $('#' + table_id_to_populate + ' > tbody:last').append(tr);
           
           // check in only
           } else {
           
           var tr = '';
           tr += '<tr data-family_id="'+this.family_id+'">';
           
           tr += '<td>';
           if(new_letter) { tr += '<a id="'+new_letter+'" class="anchor"></a>'; }
           tr += '<div class="pull-left"><label class="control-label check_in_name" for="inputEmail"><img src="../../../../../../../../../'+this.profile_picture+'" class="profile">'+this.last_name+', '+this.first_name+'</label></div><div class="pull-right check_container">';
           
           if(this.checked_in) { tr += '<a href="#" class="checkin in" data-action="out" data-person_id="'+this.id+'" data-instance_id="'+instance_id+'"><span class="icon-stack"><i class="icon-sign-blank icon-stack-base"></i><i class="front_icon icon-ok icon-light"></i></span></a>'; }
           if(!this.checked_in) { tr += '<a href="#" class="checkin out" data-action="in" data-person_id="'+this.id+'" data-instance_id="'+instance_id+'"><span class="icon-stack"><i class="icon-sign-blank icon-stack-base"></i><i class="front_icon icon-ok icon-light"></i></span></a>'; }
           
           tr += '</td><td class="hide">'+this.last_name+', '+this.first_name+'</td>';
           tr += '</tr>';
           $('#' + table_id_to_populate + ' > tbody:last').append(tr);
           
           }
           
           
           });
    
    var percent = (100/letter_index) - 0.5;
    if(percent > 10) { percent = 10; }
    $('ul#alphabet_filter').find('li').width(percent+'%');
    
    // if no results found, show none found message
    if(!result) {
        $('a#manage_tags').attr('href','../../../../../../../events/tags/'+instance_id);
        $('div.no_people_found_container').show();
        
        // otherwise show filter
    } else {
        $('form.ui-listview-filter').show();
    }
    
    // initialize datatable AFTER table loads
    $('table#people_list').addClass('initialized');
    
    if(mode != 'search') {
        var zero_records_notice = "<i class='icon-user'></i> No People Found";
    } else {
        var zero_records_notice = "&nbsp;"; // not needed if search mode
    }
    
    // only initialize if not in search mode
    people_table = $('table#people_list').dataTable( {
                                                    "bPaginate": false,
                                                    "bLengthChange": false,
                                                    "bFilter": true,
                                                    "bSort": false,
                                                    "bInfo": false,
                                                    "bDestroy": true,
                                                    "bAutoWidth": false,
                                                    "oLanguage": {
                                                    "sZeroRecords": zero_records_notice
                                                    },
                                                    "aoColumns": [
                                                                  { "bSearchable": false },
                                                                  { "bVisible": false }
                                                                  ],
                                                    // when table loads
                                                    "fnCreatedRow": function( nRow, aData, iDataIndex ) {
                                                    
                                                    },
                                                    // for each found row
                                                    "fnRowCallback": function( nRow, aData, iDisplayIndex, iDisplayIndexFull ) {
                                                    
                                                    
                                                    },
                                                    // runs after each search
                                                    "fnDrawCallback": function( oSettings ) {
                                                    var num_records_found = oSettings.aiDisplay.length;
                                                    }
                                                    
                                                    } );
    
    // don't run if in search mode (don't want ajax to run every time character is typed in)
    if(mode != 'search') { update_quantity(); }
    
    
    // open profiles with long click if enabled
    
    if($('input#profile_access').val() == 'true') {
        
        var labels = $('div.content_container').find('label.check_in_name');
        
        $.each(labels, function(index, label) {
               
               $(label).bind( "taphold", function() {
                             
                             var person_id = $(label).closest('tr').find('a.checkin').data('person_id');
                             var address = '../../../../../../../../../../../people/view/'+person_id;
                             
                             if( /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ) {
                             
                             window.location.href = address;
                             
                             } else {
                             
                             $('a#new_window_link').attr('href', address);
                             document.getElementById('new_window_link').click();
                             
                             }
                             
                             });
               
               });
        
    }
    
}

function update_quantity() {
    
    // determine if tags are being filtered (if they are, do not include anonymous in count)
    try {
        var filtered_tags = $("form#filter").find('input:checkbox:checked').length;
    } catch(err) {
        var filtered_tags = 0;
    }
    
    // if in search mode or if no one is on the list (undefined people table), get number via ajax
    if(mode == 'search' || typeof people_table == 'undefined') {
        
        $.ajax({
               url: '../../../../ajax/checkin_update_quantity',
               dataType: 'json',
               type: 'POST',
               data: {
               instance_id: instance_id
               },
               success: function(quantity){
               
               // anonymous
               var checked_in = quantity.check_in;
               var anonymous = quantity.anonymous;
               
               // set into global vars so can be accessed from anonymous setter
               global_checked_in_num = checked_in;
               global_anonymous_num = anonymous;
               
               // total
               var total_quantity = Number(anonymous) + Number(checked_in);
               
               // if filtering by tag, do not include anonymous in count
               if(filtered_tags) { total_quantity = Number(checked_in); }
               
               // output total
               $('span#event_quantity').text(' ('+total_quantity+')');
               $('div#additional_quantity').text(anonymous + ' Anonymous People Added');
               $('div#total_quantity').text(total_quantity);
               
               // update title
               document.title = $('h1#short_date').text() + ' ' + $('#event_title').text() + ' (' + total_quantity + ')';
               
               }
               });
        
        // if in list mode, count the selected rows
    } else {
        
        // anonymous
        var anonymous = $('input#additional_quantity_reference').val();
        
        // checked in
        var checked_in_checked_out = people_table.$('tr').find('a.remove').length;
        var checked_in_only = people_table.$('tr').find('a.in').length;
        var checked_in = Number(checked_in_checked_out) + Number(checked_in_only);
        
        // total
        var total_quantity = Number(anonymous) + Number(checked_in);
        
        // if filtering by tag, do not include anonymous in count
        if(filtered_tags) { total_quantity = Number(checked_in); }
        
        // output total
        $('span#event_quantity').text(' ('+total_quantity+')');
        $('div#additional_quantity').text(anonymous + ' Anonymous People Added');
        $('div#total_quantity').text(total_quantity);
        
        // update title
        document.title = $('h1#short_date').text() + ' ' + $('#event_title').text() + ' (' + total_quantity + ')';
        
    }
    
}

// checked in people (NOT anonymous)
function get_checked_in_quantity() {
    
    if(mode == 'search' || typeof people_table == 'undefined') { // check in or if list is empty
        
        var checked_in_quantity = Number(global_checked_in_num);
        
    } else {
        
        var checked_in_checked_out = people_table.$('tr').find('a.remove').length;
        var checked_in_only = people_table.$('tr').find('a.in').length;
        var checked_in_quantity = Number(checked_in_checked_out) + Number(checked_in_only);        
        
    }
    
    return checked_in_quantity;
    
}

function update_events_list(date, openpanel) {
    
    $.ajax({
           url: '../../../../ajax/event_instances_by_date',
           dataType: 'json',
           type: 'POST',
           data: {
           date: date
           },
           success: function(result){
           
           $('div.events_loading').hide();
           $('ul.events').empty();
           $('ul.events').show();
           
           $.each(result, function() {
                  $("ul.events").append('<li><a href="#" class="load_instance" data-instance_id="'+this.id+'">'+this.name+'</a></li>');
                  });   
           
           if(result.length == 0) {
           $("ul.events").append('<li>Sorry, no events could be found on this date.</li>');
           }
           
           $("ul.events").listview().listview("refresh");
           
           if(openpanel == true) { $("#events_panel").panel("open"); }
           
           }
           });
    
}

function assign_substitutions(label, person) {
    
    // set name (not user-defined on layout template)
    try { label.setObjectText("child_name", person.first_name + ' ' + person.last_name); } catch(err) { }
    
    $.each(nametag_fields, function(placeholder, field) {
           
           switch(field) {
           
           case "0":       
           try { label.setObjectText(placeholder, ''); } catch(err) { }
           break;
           
           case "BIRTHDATE":
           
           try { 
           
           if(person.details.birthdate) {
           
           var birthdate_object = new Date(person.details.birthdate);
           var timezone_offset = birthdate_object.getTimezoneOffset();
           var birthdate_object_utc = new Date(birthdate_object.getTime() + timezone_offset*60000);
           var birthdate_formatted = birthdate_object_utc.format("m/d/yy");   
           
           label.setObjectText(placeholder, birthdate_formatted);
           
           } else {
           label.setObjectText(placeholder, '');
           }
           
           } catch(err) { }
           
           break;
           
           case "CODE":
           try { label.setObjectText(placeholder, code); } catch(err) { }
           break;
           
           case "CODE3":
           try { 
           var code_3 = code_three;
           if(code_3 == '666') { code_3 = '2' + Math.floor(Math.random() * 90 + 10); } // don't allow 666
           label.setObjectText(placeholder, code_3);
           } catch(err) { }
           break;
           
           case "CHILDLIST":
           try {
           var children_list = [];
           
           $.each(person.people, function(index, individual) {
                  
                  try {
                  children_list.push(individual.first_name + ' ' + individual.last_name);
                  } catch(e) {
                  // failed
                  }
                  
                  });
           
           var children_list_string = children_list.join('\n');
           label.setObjectText(placeholder, children_list_string);
           } catch(err) { }
           break;
           
           case "CHILD":     
           try { 
           label.setObjectText(placeholder, person.first_name + ' ' + person.last_name);
           } catch(err) { }
           break;
           
           case "PARENTMOBILES":     
           try { 
           label.setObjectText(placeholder, person.parent_mobiles);
           } catch(err) { }
           break;
           
           case "PARENTS":
           try { 
           if(person.details.parents) { person.parents = person.details.parents; } // if family tag and it doesn't yet exist, pull it from details
           label.setObjectText(placeholder, person.parents);
           } catch(err) { }
           break;
           
           case "CELL":   
           try { 
           var cell_phone = person.details.mobile; if(!cell_phone) { cell_phone = ''; }
           label.setObjectText(placeholder, cell_phone); 
           } catch(err) { }
           break;
           
           case "TAG":  
           try {
           var group = person.group;
           label.setObjectText(placeholder, group);
           } catch(err) { }
           break;
           
           case "PROMPT":
           try {
           // set to BLANK instead of '' so that user can opt to not include anything and it won't repeatedly prompt for something
           if(user_prompt == "BLANK") { user_prompt = prompt("Info to Include:"); }
           if(user_prompt != "BLANK") {
           try { label.setObjectText(placeholder, user_prompt); } catch(err) { }
           } else {
           try { label.setObjectText(placeholder, ''); } catch(err) { }
           }
           } catch(err) { }
           break;
           
           case "DATE":
           try { 
           var currentdate = new Date();
           var date_time = currentdate.format("m/dd/yy");
           label.setObjectText(placeholder, date_time);
           } catch(err) { }
           break;
           
           case "TIME":
           try { 
           var currentdate = new Date();
           var date_time = currentdate.format("h:MM:ss tt");
           label.setObjectText(placeholder, date_time);
           } catch(err) { }
           break;
           
           case "DATETIME":
           try { 
           var currentdate = new Date();
           var date_time = currentdate.format("m/dd/yy - h:MM:ss tt");
           label.setObjectText(placeholder, date_time);
           } catch(err) { }
           break;
           
           default:
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
           
           });
    
    
    return label;
    
}

function update_link_container_style(person_id, action, checkout, datetime, main_table) {
    
    if(main_table) {
        var link_container = people_table.$('tr').find('a[data-person_id="'+person_id+'"]');
    } else {
        var link_container = person_id;
    }
    
    switch(action) {
            
        case 'out':
            
            if(checkout && checkout != '0') {
                
                change_checkbox_status(link_container, 'remove');
                change_icon($(link_container).find('.front_icon'), 'icon-remove');
                update_checkin_checkout_time(link_container, action, datetime);
                
            } else {
                
                change_checkbox_status(link_container, 'out');
                
            }
            
            break;
            
        case 'remove':
            
            if(checkout && checkout != '0') {
                
                change_checkbox_status(link_container, 'out');
                change_icon($(link_container).find('.front_icon'), 'icon-play');
                update_checkin_checkout_time(link_container, action);
                
            } else {
                
                change_checkbox_status(link_container, 'out');
                
            }            
            
            break;
            
        case 'in':
        case 'in_override':
            
            if(action == 'in_override') { $(link_container).removeClass('out_override'); } // remove override so it can process normally (has to happen here in beginning and not in function so timing is correct)
            
            if(checkout && checkout != '0') {
                
                change_checkbox_status(link_container, 'in');
                change_icon($(link_container).find('.front_icon'), 'icon-stop');
                update_checkin_checkout_time(link_container, action, datetime);
                
            } else {
                
                change_checkbox_status(link_container, 'in');
                change_icon($(link_container).find('.front_icon'), 'icon-ok');
                
            }
            
            break;
            
        case 'pending':
            
            change_checkbox_status(link_container, 'pending');
            change_icon($(link_container).find('.front_icon'), 'icon-spinner');
            
            break;
            
            
            
    }
    
    
}

function reset_printer_variables() {
    
    // generate code
    code = (Math.floor(Math.random()*9000) + 1000).toString();
    
    // if code has already been used, generate a new one.  Do this until unused code has been found
    while ($.inArray(code, used_codes) > -1) {
        code = (Math.floor(Math.random()*9000) + 1000).toString();
    }
    
    // add new code to used list
    used_codes.push(code);
    
    // generate three digit code
    code_three = (Math.floor(Math.random()*900) + 100).toString();
    
    // if code has already been used, generate a new one.  Do this until unused code has been found
    while ($.inArray(code_three, used_codes_three) > -1) {
        code_three = (Math.floor(Math.random()*900) + 100).toString();
    }
    
    // add new code to used list
    used_codes_three.push(code_three);
    
    user_prompt = 'BLANK';
}

function debounce(func, wait, immediate) {
    var timeout;
    return function() {
        var context = this, args = arguments;
        var later = function() {
            timeout = null;
            if (!immediate) func.apply(context, args);
        };
        var callNow = immediate && !timeout;
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
        if (callNow) func.apply(context, args);
    };
};

function countProperties(obj) {
    var count = 0;
    
    for(var prop in obj) {
        if(obj.hasOwnProperty(prop))
            ++count;
    }
    
    return count;
}

// if in search mode, load quantity after page loads as it won't trigger at beginning otherwise
$( document ).ready(function() {
                    if(mode == 'search') { update_quantity(); }
                    });
