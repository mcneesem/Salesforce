/**
* Represents the User trigger helper which handles all the logic.
*/
public class NSP_UserTriggerHelper {
    /**
* Iterates throught the list of new User and passes the required attributes to other methods.
* @param newList List of New Contact.
* @return void
*                
*/
    public void beforeInsertUser(List < User > newList) {
          updatePhoneNumber(newList);
     }
    
    /**
* Iterates throught the list of new User and passes the required attributes to other methods.
* @param newMap List of New User.
* @param oldMap List of the User record before update.
* @return void
*                
*/
    public void beforeUpdateUser(Map < Id, User > newMap, Map < Id, User > oldMap) {
        updatePhoneNum(newMap.Values(), oldMap);
    }
    
    /**
* Method Name : updatePhoneNumber 
* Description : Method to format Phone number on insert
* Author : Raksha       Date : 22/02/2022
* @param currentRecordsList List of New User.  
* @return void  
*/
    public void updatePhoneNumber(List < User > currentRecordsList) {
        for (User contact: currentRecordsList) {
            if(contact.Phone != null) {
            Pattern nonAlphanumeric = Pattern.compile('[^a-zA-Z0-9]');
            String initialNum = nonAlphanumeric.matcher(contact.Phone).replaceAll('').replace('ext', 'x');
            Pattern numFormat10Dig = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{4})');
            Pattern numFormat10Ext = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{4})(x\\d{3})?$');
            Pattern numFormat11Dig;
            Pattern numFormat11Ext;
            if (initialNum.startsWith('1')) {
                numFormat11Dig = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{5})');
                numFormat11Ext = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{5})(x\\d{3})?$');
                if (numFormat11Dig.matcher(initialNum).matches() || numFormat11Ext.matcher(initialNum).matches()) {
                    contact.NSP_Formatted_Phone_Num__c = formatPhoneNumbers(contact.Phone);
                } else if (numFormat10Dig.matcher(initialNum).matches() || numFormat10Ext.matcher(initialNum).matches()) {
                    contact.NSP_Formatted_Phone_Num__c = formatPhoneNumbers(contact.Phone);
                } else {
                    contact.NSP_Formatted_Phone_Num__c = contact.Phone;
                }
            } else if (numFormat10Dig.matcher(initialNum).matches() || numFormat10Ext.matcher(initialNum).matches()) {
                contact.NSP_Formatted_Phone_Num__c = formatPhoneNumbers(contact.Phone);
            } else {
                contact.NSP_Formatted_Phone_Num__c = contact.Phone;
            }
         }  
        }
    }
    
    /**
* Method Name : updatePhoneNum 
* Description : Method to format Phone number on update
* Author : Raksha       Date : 22/02/2022
* @param currentRecordsList List of New User.  
* @return void  
*/
    public void updatePhoneNum(List < User > newContactList, Map < Id, User > contactOldMap) {
        for (User newContact: newContactList) {
            User oldContact = contactOldMap != null ? contactOldMap.get(newContact.Id) : null;
            if (newContact.Phone != oldContact.Phone && newContact.Phone != null) {
                Pattern nonAlphanumeric = Pattern.compile('[^a-zA-Z0-9]');
                String initialNum = nonAlphanumeric.matcher(newContact.Phone).replaceAll('').replace('ext', 'x');
                Pattern numFormat10Dig = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{4})');
                Pattern numFormat10Ext = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{4})(x\\d{3})?$');
                Pattern numFormat11Dig;
                Pattern numFormat11Ext;
                if (initialNum.startsWith('1')) {
                    numFormat11Dig = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{5})');
                    numFormat11Ext = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{5})(x\\d{3})?$');
                    if (numFormat11Dig.matcher(initialNum).matches() || numFormat11Ext.matcher(initialNum).matches()) {
                        newContact.NSP_Formatted_Phone_Num__c = formatPhoneNumbers(newContact.Phone);
                    } else if (numFormat10Dig.matcher(initialNum).matches() || numFormat10Ext.matcher(initialNum).matches()) {
                        newContact.NSP_Formatted_Phone_Num__c = formatPhoneNumbers(newContact.Phone);
                    } else {
                        newContact.NSP_Formatted_Phone_Num__c = newContact.Phone;
                    }
                } else if (numFormat10Dig.matcher(initialNum).matches() || numFormat10Ext.matcher(initialNum).matches()) {
                    newContact.NSP_Formatted_Phone_Num__c = formatPhoneNumbers(newContact.Phone);
                } else {
                    newContact.NSP_Formatted_Phone_Num__c = newContact.Phone;
                }
            }
            if (newContact.Phone == null) {
                newContact.NSP_Formatted_Phone_Num__c = null;
            }
        }
    }
    
    /**
* Method Name : formatPhoneNumbers 
* Description : Method to format Phone number
* Author : Raksha       Date : 22/02/2022
* @param String input called from updatePhoneNum.  
* @return String  
*/
    public String formatPhoneNumbers(String input) {
        String requiredOutput;
        input = input.replaceAll('\\(', '').replaceAll('\\)', '');
        input = input.replaceAll('-', '');
        String trimString = input.deleteWhitespace();
        List < String > parts = new List < String > ();
        if (trimString.contains('ext')) {
            parts = trimString.split('ext');
            requiredOutput = formatCommonPattern(parts.get(0).trim()) + ' x' + parts.get(1);
        } else if (trimString.contains('x')) {
            parts = trimString.split('x');
            requiredOutput = formatCommonPattern(parts.get(0).trim()) + ' x' + parts.get(1);
        } else {
            requiredOutput = formatCommonPattern(trimString);
        }
        return requiredOutput;
    }
    /**
* Method Name : formatCommonPattern 
* Description : Method to construct common pattern and format Phone number
* Author : Raksha       Date : 22/02/2022
* @param String input called from formatPhoneNumbers.  
* @return String  
*/
    public String formatCommonPattern(String input) {
        if (input.length() == 10) {
            String number1 = input.replaceFirst('(\\d{3})(\\d{3})(\\d+)', '($1) $2-$3');
            return number1;
        }
        String substring = input.length() > 10 ? input.substring(input.length() - 10) : input;
        String codeNumber = substring.replaceFirst('(\\d{3})(\\d{3})(\\d+)', '+1 ($1) $2-$3');
        return codeNumber;
    }
}