import { LightningElement, wire, track, api } from 'lwc';
import getAccountTeam from '@salesforce/apex/RETEducationController.getAccountTeam';

export default class Nsp_assetAccountTeam extends LightningElement {

@track tableAccountTeam = false;
@api recordId;
@track accountMap = {};

@wire(getAccountTeam, {recordID: '$recordId'})
getAccountTeam(result) {   
    this.accountMap = [];
for (var accountTeam in result.data) {       
    this.accountMap.push({ key: accountTeam, value: result.data[accountTeam] });      
}   
if(Object.keys(this.accountMap).length !== 0 ){           
    this.tableAccountTeam = true;
}      
}
}