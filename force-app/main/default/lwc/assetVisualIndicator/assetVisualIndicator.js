import { LightningElement, api } from 'lwc';
// Asset visual Indicator settings
import Asset_Time_And_Attendance_Email from '@salesforce/label/c.ITA_Time_And_Attendance_Email';
import Asset_Time_And_Attendance_Phone from '@salesforce/label/c.ITA_Time_And_Attendance_Phone';

export default class AssetVisualIndicator extends LightningElement {
 @api recordId;
     label = {
         Asset_Time_And_Attendance_Email,
         Asset_Time_And_Attendance_Phone
     }

     get textWithPipe() {
      return 'Phone: '+ this.label.Asset_Time_And_Attendance_Phone + ' | ' + 'Email: ' + this.label.Asset_Time_And_Attendance_Email
  }
}