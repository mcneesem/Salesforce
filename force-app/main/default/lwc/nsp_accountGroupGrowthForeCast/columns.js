const COLUMNS = [
    { label: 'Related Client', fieldName: 'account', type: 'text', wrapText: true, hideDefaultActions: true, cellAttributes: { alignment: 'left' }, },
    { label: 'Growth Type', fieldName: 'GrowthType', type: 'text', wrapText: true, hideDefaultActions: true, cellAttributes: { alignment: 'left' }, },
    { label: 'Current Quarter/Year', fieldName: 'currentMonth', type: 'text', wrapText: false, hideDefaultActions: true, cellAttributes: { alignment: 'center' }, },
    { label: 'Current Quarter', fieldName: 'Current_Quarter', type: 'number', editable: { fieldName: 'editable' }, wrapText: false, hideDefaultActions: true, cellAttributes: { class: { fieldName: 'textColor' }, alignment: 'center' }, },
    { label: 'Current Quarter + 1', fieldName: 'Current_Quarter1', type: 'number', editable: { fieldName: 'editable' }, wrapText: true, hideDefaultActions: true, cellAttributes: { class: { fieldName: 'textColor' }, alignment: 'center' }, },
    { label: 'Current Quarter + 2', fieldName: 'Current_Quarter2', type: 'number', editable: { fieldName: 'editable' }, wrapText: true, hideDefaultActions: true, cellAttributes: { class: { fieldName: 'textColor' }, alignment: 'center' }, },
    { label: 'Current Quarter + 3', fieldName: 'Current_Quarter3', type: 'number', editable: { fieldName: 'editable' }, wrapText: true, hideDefaultActions: true, cellAttributes: { class: { fieldName: 'textColor' }, alignment: 'center' }, },
    { label: 'Total WSEE', fieldName: 'total', type: 'number', wrapText: false, hideDefaultActions: true, cellAttributes: { class: { fieldName: 'textColor' }, alignment: 'center' }, },

];

export { COLUMNS }