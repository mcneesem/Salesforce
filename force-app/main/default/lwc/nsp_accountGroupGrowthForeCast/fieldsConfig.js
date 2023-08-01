const DYNAMIC_FIELDS = {
    "Organic": {
        "Current_Quarter": "NSP_Organic_Current_Quarter__c",
        "Current_Quarter1": "NSP_Organic_Current_Quarter_1__c",
        "Current_Quarter2": "NSP_Organic_Current_Quarter_2__c",
        "Current_Quarter3": "NSP_Organic_Current_Quarter_3__c",
    },
    "Reduction": {
        "Current_Quarter": "NSP_Reduction_Current_Quarter__c",
        "Current_Quarter1": "NSP_Reduction_Current_Quarter_1__c",
        "Current_Quarter2": "NSP_Reduction_Current_Quarter_2__c",
        "Current_Quarter3": "NSP_Reduction_Current_Quarter_3__c",
    },
    "Acquisition": {
        "Current_Quarter": "NSP_Acquisition_Current_Quarter__c",
        "Current_Quarter1": 'NSP_Acquisition_Current_Quarter_1__c',
        "Current_Quarter2": 'NSP_Acquisition_Current_Quarter_2__c',
        "Current_Quarter3": 'NSP_Acquisition_Current_Quarter_3__c',
    }

};

const REDUCTION_FIELDS = [
    "NSP_Reduction_Current_Quarter__c",
    "NSP_Reduction_Current_Quarter_1__c",
    "NSP_Reduction_Current_Quarter_2__c",
    "NSP_Reduction_Current_Quarter_3__c",
];

const GROWTH_TYPE = {
    reduction: 'Reduction',
    organic: 'Organic',
    acquisition:'Acquisition',
    total:'Total'
}

export { DYNAMIC_FIELDS, REDUCTION_FIELDS , GROWTH_TYPE};