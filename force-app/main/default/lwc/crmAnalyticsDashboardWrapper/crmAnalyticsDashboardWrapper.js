import { LightningElement, api, wire } from 'lwc';
import getDashboardSettings from '@salesforce/apex/CRMAnalyticsDashboardController.getDashboardSettings';

export default class CrmAnalyticsDashboardWrapper extends LightningElement {
    @api dashboardField;
    @api dashboardHeight;
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
        let response;
        if ( this._settings
            && this.dashboardField
            && Object.hasOwn( this._settings , this.dashboardField )
            )
        {
            response = this._settings[this.dashboardField];
        }
        return response;
    }
}