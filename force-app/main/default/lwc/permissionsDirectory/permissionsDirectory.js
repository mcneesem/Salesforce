import { LightningElement , api , wire } from 'lwc';
import isAccessible from '@salesforce/apex/PermissionsDirectoryController.isAccessible';
import getPermissions from '@salesforce/apex/PermissionsDirectoryController.getPermissions';

export default class PermissionsDirectory extends LightningElement {
    @api recordId;

    isAccessible = false;
    @wire(isAccessible)
    wireIsAccessible({ error , data }) {
        if ( error ) {
            this.error = error;
            this.isAccessible = false;
        } else if ( data ) {
            this.isAccessible = data;
            this.error = undefined;
        }
    }

    //
    // CALLBACKS
    //

    //connectedCallback() {
    //    //console.log( 'permissionsDirectory.connectedCallback' );
    //}

    renderedCallback() {
        //console.log( 'permissionsDirectory.renderedCallback' );
        //
        // re-focus on filter input field...
        this.refs?.filter?.focus();
        //if ( this.refs && this.refs.filter ) {
        //    this.refs.filter.focus();
        //}
    }

    //disconnectedCallback() {
    //    //console.log( 'permissionsDirectory.disconnectedCallback' );
    //}

    errorCallback( error , stack ) {
        console.log( 'permissionsDirectory.errorCallback ~ error=' + JSON.stringify( error ) );
        console.log( 'permissionsDirectory.errorCallback ~ stack=' + JSON.stringify( stack ) );
    }

    //
    // ERROR
    //

    _error = null;
    get error() {
        return this._error;
    }
    set error( value ) {
        this._error = value;
    }

    //
    // LOADING / SPINNER
    //

    _isLoading;
    get isLoading() {
        return this._isLoading;
    }
    set isLoading( value ) {
        this._isLoading = value;
    }
    
    get spinnerClass() {
        return ( this.isLoading ? 'slds-show' : 'slds-hide' );
    }

    //
    // LOADING SECTIONS
    //

    _loadingSections = {};
    get loadingSections() {
        if ( !!!this._loadingSections ) {
            this._loadingSections = {};
        }
        return this._loadingSections;
    }

    startLoadingSection( section ) {
        this.isLoading = true;
        this.loadingSections[section] = true;
    }
    stopLoadingSection( section ) {
        this.loadingSections[section] = false;
        // check if any sections are still loading...
        let isAnySectionLoading = false;
        for ( const [key, value] of Object.entries( this.loadingSections ) ) {
            if ( value ) {
                isAnySectionLoading = true;
            }
        }
        this.isLoading = isAnySectionLoading;
    }

    //
    // ACCORDIAN SECTIONS
    //

    _openSections = [];
    get openSections() {
        if ( !!!this._openSections ) {
            this._openSections = [];
        }
        return this._openSections;
    }
    set openSections( value ) {
        this._openSections = value;
    }

    handleSectionToggle( event ) {
        // identify newly opened sections...
        let oldOpenSections = this.openSections;
        this.openSections = event.detail.openSections;
        let newlyOpenedSections = this.openSections.filter(
            (section) => (
                !oldOpenSections.includes( section )
            )
        );
        // only call apex for the newly opened sections...
        if ( newlyOpenedSections && newlyOpenedSections.length > 0 ) {
            for ( let i=0; i < newlyOpenedSections.length ; i++ ) {
                this.getPermissionsByType( newlyOpenedSections[i] );
            }
        }
    }

    //
    // FILTER
    //

    _filter = '';
    get filter() {
        if ( !!!this._filter ) {
            this._filter = '';
        }
        return this._filter;
    }
    set filter( value ) {
        this._filter = value;
    }

    get isFiltered() {
        return ( this.filter && ( this.filter.length > 1 ) );
    }

    filterChanged( event ) {
        // capture the current filter input...
        this.filter = event.detail.value;
        // handle the scenario where a valid search occurs before a section is opened...
        // ~ ensure all sections have been loaded at least once...
        if ( this.isFiltered ) {
            if ( !this.hasUserPermissions ) {
                this.getPermissionsByType( 'UserPermissions' );
            }
            if ( !this.hasObjectPermissions ) {
                this.getPermissionsByType( 'ObjectPermissions' );
            }
            if ( !this.hasCustomPermissions ) {
                this.getPermissionsByType( 'CustomPermissions' );
            }
        }
    }

    //
    // USER PERMISSIONS
    //

    _userPermissions = null;
    get userPermissions() {
        if ( !!!this._userPermissions ) {
            this._userPermissions = [];
        }
        return this._userPermissions;
    }
    set userPermissions( value ) {
        this._userPermissions = value;
    }

    get hasUserPermissions() {
        return ( this.userPermissions && ( this.userPermissions.length > 0 ) );
    }

    //
    // OBJECT PERMISSIONS
    //

    _objectPermissions = null;
    get objectPermissions() {
        if ( !!!this._objectPermissions ) {
            this._objectPermissions = [];
        }
        return this._objectPermissions;
    }
    set objectPermissions( value ) {
        this._objectPermissions = value;
    }

    get hasObjectPermissions() {
        return ( this.objectPermissions && ( this.objectPermissions.length > 0 ) );
    }

    //
    // CUSTOM PERMISSIONS
    //

    _customPermissions = null;
    get customPermissions() {
        if ( !!!this._customPermissions ) {
            this._customPermissions = [];
        }
        return this._customPermissions;
    }
    set customPermissions( value ) {
        this._customPermissions = value;
    }

    get hasCustomPermissions() {
        return ( this.customPermissions && ( this.customPermissions.length > 0 ) );
    }

    //
    // IMPERATIVE APEX CALLOUT
    //

    getPermissionsByType( type ) {
        this.startLoadingSection( type );
        getPermissions({
            recordId : this.recordId ,
            permissionType : type ,
        })
        .then(response => {
            this.error = undefined;
            if ( type == 'UserPermissions' ) {
                this.userPermissions = response;
            } else if ( type == 'ObjectPermissions' ) {
                this.objectPermissions = response;
            } else if ( type == 'CustomPermissions' ) {
                this.customPermissions = response;
            }
        })
        .catch(error => {
            this.error = error;
            this.stopLoadingSection( type );
        })
        .finally(() => {
            this.stopLoadingSection( type );
            //
            // allow the loading spinner to remain visible for 3/4 of a second (750ms)...
            //setTimeout(
            //    function() {
            //        this.stopLoadingSection( type );
            //    }.bind( this ) ,
            //    750
            //);
        });
    }

    //
    //
    //

}