import { LightningElement , api } from 'lwc';

export default class Helptext extends LightningElement {
    @api content;
    @api iconVariant; // bare, inverse, warning, error // default: bare
}
//