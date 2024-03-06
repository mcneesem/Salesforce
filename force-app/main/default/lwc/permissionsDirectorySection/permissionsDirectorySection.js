import { LightningElement , api } from 'lwc';

export default class PermissionsDirectorySection extends LightningElement {

    //
    // ERROR
    //

    get error() {
        return null;
    }

    //
    // NAME
    //

    _name = '';
    @api
    get name() {
        if ( !!!this._name ) {
            this._name = '';
        }
        return this._name;
    }
    set name( value ) {
        this._name = value;
    }

    //
    // LABEL
    //

    _label = '';
    @api
    get label() {
        if ( !!!this._label ) {
            this._label = '';
        }
        return this._label;
    }
    set label( value ) {
        this._label = value;
    }

    get labelSection() {
        let local = '';
        if ( this.hasRenderPermissions ) {
            local = ' (' + this.renderPermissions.length + ')';
        }
        return this.label + local;
    }

    //
    // FILTER
    //

    _filter = '';
    @api
    get filter() {
        if ( !!!this._filter ) {
            this._filter = '';
        }
        return this._filter;
    }
    set filter( value ) {
        this._filter = value;
        this.rebuildRenderPermissions();
    }

    get isFiltered() {
        return ( this.filter && ( this.filter.length > 1 ) );
    }

    get containingFilter() {
        return ( this.isFiltered ? ' containing \'' + this.filter + '\'' : '' );
    }

    //
    // PERMISSIONS
    //

    _permissions = [];
    @api
    get permissions() {
        if ( !!!this._permissions ) {
            this._permissions = [];
        }
        return this._permissions;
    }
    set permissions( value ) {
        this._permissions = value;
        this.rebuildRenderPermissions();
    }

    get hasPermissions() {
        return ( this.permissions && ( this.permissions.length > 0 ) );
    }

    //
    // RENDER PERMISSIONS
    //

    _renderPermissions = [];
    get renderPermissions() {
        if ( !!!this._renderPermissions ) {
            this._renderPermissions = [];
        }
        return this._renderPermissions;
    }
    set renderPermissions( value ) {
        this._renderPermissions = value;
    }

    get hasRenderPermissions() {
        return ( this.renderPermissions && ( this.renderPermissions.length > 0 ) );
    }

    rebuildRenderPermissions() {
        let filteredPermissions = [];
        filteredPermissions = this.permissions;
        if ( this.isFiltered && this.hasPermissions ) {
            // rebuild the render permissions based on the new filter...
            filteredPermissions = this.permissions.filter(
                (permission) => (
                    ( permission.label && permission.label.toLowerCase().includes( this.filter.toLowerCase() ) ) // label-based filter...
                    || ( permission.name && permission.name.toLowerCase().includes( this.filter.toLowerCase() ) ) // api-based filter...
                )
            );
        }
        this.renderPermissions = filteredPermissions;
    }

    //
    // EXAMPLE PERMISSIONS DATA STRUCTURE
    //

    /*
    exampleObjectPermissions = [
        {
            name : 'InboundEmailLog__c' ,
            label : 'Inbound Email Log' ,
            allows : 'Read, Create, Edit, Delete, View All, Modify All' ,
            sources : [
                {
                    Id : '0PSXXXXXXXXXXXX' ,
                    Label : 'Exception Handlers' ,
                    PermissionSetGroupId : '0PGXXXXXXXXXXXXXXX' ,
                } ,
                {
                    Id : '0PSXXXXXXXXXXXX' ,
                    Label : 'XXX00eXXXXXXXXXXXX' ,
                    ProfileId : '00eXXXXXXXXXXXX' ,
                    Profile : {
                        Name : 'System Administrator' ,
                    } ,
                } ,
                {
                    Id : '0PSXXXXXXXXXXXX' ,
                    Label : 'Inbound Email Log Visibility' ,
                } ,
            ] ,
        } ,
        {
            name : 'FlowErrorLog__c' ,
            label : 'Flow Error Log' ,
            allows : 'Read, View All' ,
            sources : [
                {
                    Id : '0PSXXXXXXXXXXXX' ,
                    Label : 'Exception Handlers' ,
                    PermissionSetGroupId : '0PGXXXXXXXXXXXXXXX' ,
                } ,
                {
                    Id : '0PSXXXXXXXXXXXX' ,
                    Label : 'XXX00eXXXXXXXXXXXX' ,
                    ProfileId : '00eXXXXXXXXXXXX' ,
                    Profile : {
                        Name : 'System Admin Lite' ,
                    } ,
                } ,
                {
                    Id : '0PSXXXXXXXXXXXX' ,
                    Label : 'Flow Error Log Visibility' ,
                } ,
            ] ,
        } ,
    ];
    */

}