import cancelButton from '@salesforce/label/c.NSP_Cancel';
import copyButton from '@salesforce/label/c.NSP_Copy_Button';

const BUTTON_CONFIG = [
  {
    name: 'cancel',
    label: cancelButton,
  },
  {
    name: 'copy',
    label: copyButton,
    variant: 'brand',
  },
];

const SEARCH_CATEGORIES = [
  { label: 'Account Name', value: 'Account__r.Name' },
  { label: 'AIMS Client #', value: 'NSP_AIMS_ClientNo__c' },
];

export { BUTTON_CONFIG, SEARCH_CATEGORIES };
