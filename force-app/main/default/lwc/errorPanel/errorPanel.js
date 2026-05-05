import { LightningElement , api } from "lwc";
import viewErrorPanel from "@salesforce/customPermission/View_Error_Panel";

export default class ErrorPanel extends LightningElement {
    @api error;
    @api parent;

    get hasPermission() {
        return ( viewErrorPanel === true );
    }

    privateTitle;
    @api
    get title() {
        let status = "";
        if ( this.error ) {
            status = ""
                + ( this.error.status ? this.error.status + " " : "" )
                + ( this.error.statusText ? this.error.statusText + " " : "" )
                ;
        }
        let newTitle = "ERROR" + ( status ? ": " + status : "" );
        if ( this.parent ) {
            newTitle = newTitle + " (" + this.parent + ")";
        }
        this.privateTitle = newTitle;
        return this.privateTitle;
    }
    set title( value ) {
        this.privateTitle = value;
    }

    //
    // https://developer.salesforce.com/docs/platform/lwc/guide/data-error.html#example-handle-errors-from-the-getrecord-wire-adapter
    //
    // Body Payload
    //
    // The body of the error response depends on the API that returns it.
    //
    // UI API read operations, such as the getRecord wire adapter, return error.body as an array of objects.
    // UI API write operations, such as the createRecord wire adapter, return error.body as an object, often with object-level and field-level errors.
    // Apex read and write operations return error.body as an object.
    // Network errors, such as an offline error, return error.body as an object.
    //

    privateBody;
    @api
    get body() {
        let newBody = "";
        if ( this.error ) {
            if ( this.error.body ) {
                if ( Array.isArray( this.error.body ) ) {
                    newBody = this.error.body.map( (e) => e.message ).join( ", ");
                } else if ( typeof this.error.body.message === "string" ) {
                    newBody = this.error.body.message;
                } else {
                    newBody = JSON.stringify( this.error.body );
                }
            } else {
                newBody = JSON.stringify( this.error );
            }
        }
        this.privateBody = newBody;
        return this.privateBody;
    }
    set body( value ) {
        this.privateBody = value;
    }

}
//