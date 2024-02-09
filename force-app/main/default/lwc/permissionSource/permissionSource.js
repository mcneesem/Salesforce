import { LightningElement , api } from 'lwc';

export default class PermissionSource extends LightningElement {

    _permission;
    @api
    get permission() {
        return this._permission;
    }
    set permission( value ) {
        this._permission = value;
    }

    //
    // ERROR
    //

    get error() {
        return null;
    }

    //
    // LABEL
    //

    get label() {
        // default to api name when label is missing...
        let local = this.name;
        if ( this.permission ) {
            // use label when available...
            if ( this.permission.label ) {
                local = this.permission.label;
            }
            if ( true == false ) { // ...add option to show api names...
                // include api name when label differs...
                if ( ( local == this.permission.label ) && ( this.permission.label != this.permission.name ) ) {
                    local = local + ' (' + this.permission.name + ')';
                }
            }
        }
        return local;
    }

    //
    // NAME
    //

    get name() {
        let local = null;
        if ( this.permission ) {
            local = this.permission.name;
        }
        return local;
    }

    get nameClass() {
        return ( ( false && ( this.label != this.name ) ) ? 'slds-show_inline-block slds-p-left_xx-small' : 'slds-hide slds-p-left_xx-small' );
    }

    //
    // ALLOWS
    //

    get allows() {
        let local = null;
        if ( this.permission && this.permission.allows ) {
            local = this.permission.allows;
        }
        return local;
    }

}