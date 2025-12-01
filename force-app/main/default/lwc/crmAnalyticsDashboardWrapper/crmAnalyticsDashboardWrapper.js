import { LightningElement, wire } from 'lwc';
import getDashboardSettings from '@salesforce/apex/CRMAnalyticsDashboardController.getDashboardSettings';

export default class CrmAnalyticsDashboardWrapper extends LightningElement {
    dashboardId;
    error;
    @wire(getDashboardSettings) wiredDashboard({data, error}) {
        if (data) {
            this.dashboardId = data.Dashboard_Id__c;
        } else if (error) {
            this.error = "An error has occurred (crmAnalyticsDashboardWrapper)."; 
        }
    }
}