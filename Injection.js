function print_tag(person_id, instance_id, child_or_parent, checkout) {
    if($('input#print').val() != '1') { return false; }
    if(!child_or_parent) { child_or_parent['both'] = 1; }
    var people_ids_json = '';
    if (person_id instanceof Array) {
        people_ids_json = JSON.stringify(person_id);
        var parent_xml = family_label_xml;
    } else {
        people_ids_json = '';
        var parent_xml = parent_label_xml;
    }
    update_link_container_style(person_id, 'in_override', checkout, '', true);
    window.location = 'breezeprint:print?person_id=' + person_id + '&instance_id=' + instance_id + '&people_ids_json=' + people_ids_json + '&parent=' + child_or_parent['parent'] + '&child=' + child_or_parent['child'] + '&both=' + child_or_parent['both'] + '&no_tags=' + child_or_parent['no_tags'] + '&additional=' + child_or_parent['additional'] + '&checkout=' + checkout;
}

//v3 injection routines
function load_printer_list() {
    return new Promise(function(resolve, reject) {

       // if it's not a printed event, simply let the user know that printing is disabled for the event
       if(check_in_print == 0) {
           change_printer_view('disabled');
           resolve(false); // resolving false signals that the printer list should not be displayed
           return false;
       }
       
       printer_list_changed = false;
       resolve(true);
       return true;
    });
}

function send_to_printer(print_options) {
    
    // and ensure printers are populated (don't need response as function is populating global printer_name; just want to ensure the function completes before continuing)
    load_printer_list().then(function(response) {
                             
         // if response is false, something went wrong and it should not attempt to print
         if(response == false) { return false; }
         
         window.location = 'breezeprint:print?person_id=' + print.options.response.id + '&instance_id=' + instance_id + '&people_ids_json=&parent=' + print_options.response.print.parent + '&child=' + print_options.response.print.child + '&both=' + print_options.response.print.both + '&no_tags=' + print_options.response.print.no_tags + '&additional=' + print_options.response.print.additional + '&checkout=' + checkout;

     });
    
}
