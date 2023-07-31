/*
 *
* @description  :  Controller class for  vf component to get the Date/time in user's time zone instead of in GMT.
* @date 06/08/2023
* Author : Harsha Khiroya
* Name : NSP_SAEmail_DateTimeController
*/

public class NSP_SAEmail_DateTimeController {
    
	public DateTime date_time {get;set;}
    public String defined_format {get;set;}
    public DateTime endDate {get;set;}
    
    public String getFormattedDatetime() {
       return date_time.format(defined_format, 'CST'); //Specify Time zone like IST,CST
    }
    
    public String getStartTime(){
        return date_time.format('hh:mm aa');
    }
    
    public String getEndTime(){
        return endDate.format('hh:mm aa');
    }
    
}