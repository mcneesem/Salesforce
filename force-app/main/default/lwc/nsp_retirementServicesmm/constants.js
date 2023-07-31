import retirmentServices from '@salesforce/label/c.NSP_Retirement_Services';

const LABEL = { retirmentServices };

const CLASS_BY_ORDER = {
  1: 'level-1',
  2: 'level-2',
  3: 'level-3',
};

const SELECTEDVALUE = [
  'Requested',
  'Requested - Not Collected',
  'Requested - Not collected',
];

export { LABEL, CLASS_BY_ORDER, SELECTEDVALUE };
