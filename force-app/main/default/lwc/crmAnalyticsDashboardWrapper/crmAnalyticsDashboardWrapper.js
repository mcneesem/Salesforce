import { LightningElement, api, wire } from 'lwc';
import getDashboardSettings from '@salesforce/apex/CRMAnalyticsDashboardController.getDashboardSettings';

export default class CrmAnalyticsDashboardWrapper extends LightningElement {
    @api dashboardField = 'Dashboard_Id__c';
    _settings;
    error;

    @wire(getDashboardSettings) wiredDashboard({data, error}) {
        if (data) {
            this._settings = data;
        } else if (error) {
            this.error = "An error has occurred (crmAnalyticsDashboardWrapper).";
        }
    }

    get dashboardId() {
        return this._settings ? this._settings[this.dashboardField] : undefined;
    }
}