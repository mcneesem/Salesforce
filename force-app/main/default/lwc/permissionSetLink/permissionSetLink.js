import { LightningElement , api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class PermissionSetLink extends NavigationMixin( LightningElement ) {

    _permissionSet;
    @api
    get permissionSet() {
        return this._permissionSet;
    }
    set permissionSet( value ) {
        this._permissionSet = value;
    }

    //
    // ERROR
    //

    get error() {
        return ( this.isPermissionSet ? null : 'Invalid Permission Set.' );
    }

    //
    // VALIDATION
    //

    get isPermissionSet() {
        return ( this.permissionSet && this.permissionSet.Id && this.permissionSet.Label );
    }

    get isPermissionSetGroup() {
        return ( this.isPermissionSet && this.permissionSet.PermissionSetGroupId );
    }

    get isProfile() {
        return ( this.isPermissionSet && this.permissionSet.ProfileId && this.permissionSet.Profile && this.permissionSet.Profile.Name );
    }

    //
    // LABEL
    //

    get label() {
        let local = null;
        if ( this.isPermissionSet ) {
            local = this.permissionSet.Label;
            if ( this.isProfile ) {
                local = this.permissionSet.Profile.Name;
            }
        }
        return local;
    }

    //
    // TYPE
    //

    get type() {
        let local = null;
        if ( this.isPermissionSet ) {
            local = 'Permission Set';
            if ( this.isPermissionSetGroup ) {
                local = 'Permission Set Group';
            } else if ( this.isProfile ) {
                local = 'Profile';
            }
        }
        return local;
    }

    //
    // DATA-ID
    //

    get dataId() {
        let local = null;
        if ( this.isPermissionSet ) {
            local = this.permissionSet.Id;
            if ( this.isPermissionSetGroup ) {
                local = this.permissionSet.PermissionSetGroupId;
            } else if ( this.isProfile ) {
                local = this.permissionSet.ProfileId;
            }
        }
        return local;
    }

    //
    // NAVIGATE
    //

    handleNavigate( event ) {
        // extract the Id of the PS, PSG, or Profile from the lick that was clicked...
        let artifactId = null;
        if ( event && event.currentTarget && event.currentTarget.dataset ) {
            artifactId = event.currentTarget.dataset.id;
        }
        if ( artifactId ) {
            // generate a URL to the chosen artifact...
            this[NavigationMixin.GenerateUrl]({
                type : 'standard__recordPage' ,
                attributes : {
                    recordId : event.currentTarget.dataset.id ,
                    actionName : 'view' ,
                },
            })
            .then(url => {
                // open page in a seperate tab...
                window.open( url , "_blank" );
            })
            .catch(error => {
                this.error = error;
            })
            .finally(() => {
            });
        }
    }

}