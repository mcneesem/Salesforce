import { LightningElement , api } from 'lwc';

export default class ErrorPanel extends LightningElement {
    @api error;
    @api parent;

    privateTitle;
    @api
    get title() {
        let newTitle = 'ERROR';
        if ( this.error && this.error.status ) {
            newTitle = this.error.status + ' ' + newTitle;
        }
        if ( this.parent ) {
            newTitle = newTitle + ' (' + this.parent + ')';
        }
        this.privateTitle = newTitle;
        return this.privateTitle;
    }
    set title( value ) {
        this.privateTitle = value;
    }

}
//