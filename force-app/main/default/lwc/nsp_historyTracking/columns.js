const columns = [

    { label: 'Field', fieldName: 'NSP_Field_Label__c', type: 'text', sortable: true, wraptext: true },
    { label: 'Old Value', fieldName: 'NSP_Old_Value__c', type: 'longText', sortable: true, wraptext: true },
    { label: 'New Value', fieldName: 'NSP_New_Value__c', type: 'longText', sortable: true, wraptext: true },
    {
        label: 'Modified Date', fieldName: 'NSP_Modified_Date__c', type: 'date',
        sortable: true, wraptext: true, typeAttributes: {
            day: 'numeric',
            month: 'short',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: true
        }
    },
    { label: 'Modified By', fieldName: 'lastModifiedName', type: 'text', sortable: true, wraptext: true },
];

const payPeriodcolumns = [
    {
        label: 'Pay Frequency',
        fieldName: 'nameUrl',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'urlName' },
            target: '_blank'
        },
        sortable: true
    },
    { label: 'Field', fieldName: 'Field', type: 'text', sortable: true, wraptext: true },
    { label: 'Old Value', fieldName: 'OldValue', type: 'longText', sortable: true, wraptext: true },
    { label: 'New Value', fieldName: 'NewValue', type: 'longText', sortable: true, wraptext: true },
    {
        label: 'Modified Date', fieldName: 'CreatedDate', type: 'date',
        sortable: true, wraptext: true, typeAttributes: {
            day: 'numeric',
            month: 'short',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: true
        }
    },
    { label: 'Modified By', fieldName: 'lastModifiedName', type: 'text', sortable: true, wraptext: true },
];
export { columns, payPeriodcolumns }