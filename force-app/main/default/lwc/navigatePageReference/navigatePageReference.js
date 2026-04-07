import { LightningElement , api } from "lwc";

export default class NavigatePageReference extends LightningElement {
    _pageReference;
    @api
    get pageReference() {
        return this._pageReference;
    }
    set pageReference( value ) {
        this._pageReference = value;
        if ( this._pageReference ) {
            this.dispatchEvent(
                new CustomEvent(
                    "navigate" ,
                    {
                        bubbles: true ,
                        composed: true ,
                        detail: this._pageReference ,
                    }
                )
            );
        }
    }
}
//