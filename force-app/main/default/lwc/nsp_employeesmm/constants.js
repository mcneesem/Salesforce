import employees from '@salesforce/label/c.NSP_Employees';

const LABEL = {employees};
const HELP_TEXT = {
    
    empWithTempStatus : 'Collect ee name/projected assignment end date. Explain benefits eligibility and Insperity Temp Policy. Cannot have temp to perm scenario - violation of the group health plan. All temp ees must be assigned to a project with a designated end date. NOTE: Classification for Benefits eligibility is ONLY – Full-time or Part-Time.',
    travelInternationallyForWork: 'The International Travel Notification form will need to be completed prior to each trip regardless of duration.',
}

const CLASS_BY_ORDER = {
    1 : 'level-1',
    2 : 'level-2',
    3 : 'level-3',
}

const SPECIALFIELDS = [];
const SELECTEDVALUE = ['Requested','Requested - Not Collected', 'Requested - Not collected'];

export { LABEL , CLASS_BY_ORDER,SPECIALFIELDS,SELECTEDVALUE, HELP_TEXT};