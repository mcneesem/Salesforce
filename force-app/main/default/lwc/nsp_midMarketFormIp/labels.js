import clientProject from '@salesforce/label/c.NSP_ClientProjectInformationSection';
import meetingDetails from '@salesforce/label/c.NSP_Meeting_Details';
import assignments from '@salesforce/label/c.NSP_Assignments';
import preDiscovery from '@salesforce/label/c.NSP_Pre_Discovery';
import clientInfo from '@salesforce/label/c.NSP_Client_Information';
import onBoarding from '@salesforce/label/c.NSP_On_boarding';
import employees from '@salesforce/label/c.NSP_Employees';
import payroll from '@salesforce/label/c.NSP_Payroll';
import benefits from '@salesforce/label/c.NSP_Benefits';
import retirementServices from '@salesforce/label/c.NSP_Retirement_Services';
import humanResources from '@salesforce/label/c.NSP_Human_Resources';
import workersSafety from '@salesforce/label/c.NSP_Workers_Safety';
import businessPerformance from '@salesforce/label/c.NSP_Business_Performance_Solutions';
import automation from '@salesforce/label/c.NSP_Automation';
import auditLog from '@salesforce/label/c.NSP_Audit_Log';
import systemInfo from '@salesforce/label/c.NSP_SystemInformation';
import attachments from '@salesforce/label/c.NSP_Attachments';

const SECTION_LABELS = {
  NSP_non_Insperity_paid_emps_contractors__c:
    'Does the client have any non-Insperity paid employees, contractors, or 1099’s?',
  clientProject,
  meetingDetails,
  assignments,
  preDiscovery,
  clientInfo,
  onBoarding,
  employees,
  payroll,
  benefits,
  retirementServices,
  humanResources,
  workersSafety,
  businessPerformance,
  automation,
  auditLog,
  systemInfo,
  attachments,
};

export { SECTION_LABELS };
