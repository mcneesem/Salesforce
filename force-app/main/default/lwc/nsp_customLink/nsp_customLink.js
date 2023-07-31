import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class Nsp_customLink extends NavigationMixin(LightningElement) {
    @api recordId;
    @api recordName;
    @api index;
    @api subClient;
    @api recordsCount;

    handleClick(evt) {
        evt.preventDefault();
        let id = evt.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: id,
                actionName: 'view'
            }
        });
    }

    get getCount() {
        return this.recordsCount > this.index + 1;
    }
}