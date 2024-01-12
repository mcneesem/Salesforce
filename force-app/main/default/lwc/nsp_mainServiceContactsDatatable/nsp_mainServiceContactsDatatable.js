import LightningDatatable from 'lightning/datatable';
import customAccName from './customAccountName.html';
import customSubClient from './customSubClients.html';
import customContName from './customContactName.html';
import customPName from './customContactPName.html';

export default class CustomTypeLightningDatatable extends LightningDatatable {
    static customTypes = {
        customAccountName: {
            template: customAccName,
            standardCellLayout: false,
            typeAttributes: ['account']
        },
        customSubClients: {
            template: customSubClient,
            standardCellLayout: true,
            typeAttributes: ['subClients']
        },
        customPreferredName: {
            template: customPName,
            standardCellLayout: true,
            typeAttributes: ['contact']
        },
        customContactName: {
            template: customContName,
            standardCellLayout: true,
            typeAttributes:  ['contact','contactName']
        },        
    }
}