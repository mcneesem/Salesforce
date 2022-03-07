/*
* @Description: This Apex class describes to do nothing when NSP_Trigger_Switch__c custom setting validations are turned ON, And this class is called in
* 				 Process builders so that Process builders will not fire during data migration.
* @Created Date: 02/01/2022
*
* */
public class NSP_DO_NOTHING {
    /*
* @Description: This method describes to do nothing when NSP_Trigger_Switch__c custom setting validations are turned ON, And this class is called in
* 				 Process builders so that Process builders will not fire during data migration.
* @Created Date: 02/01/2022
* @param : No Parameters passed  
* @return void    
*/
    @InvocableMethod
    public static void doNothing() {
    }
}