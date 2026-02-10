import { LightningElement , api , wire } from 'lwc';
import { RefreshEvent } from 'lightning/refresh';
import getSCCHRCount from '@salesforce/apex/PdsContactController.getSCCHRCount';
import getSCCPCCount from '@salesforce/apex/PdsContactController.getSCCPCCount';

// Base LWC to Apex wire result. Accepts two inputs:
// - flowApiName: Flow API name to render
// - apexMethodApiName: use to select Apex count method from getSCCHRCount or getSCCPCCount
// - recordId: the recordId of the context record
export default class PdsBaseContact extends LightningElement {
    // Public API
    @api flowApiName;
    @api apexMethodApiName;

    // Record context provided by the page
    @api recordId;

    showFlow = false;
    loading = false;

    // standard flow input variables (recordId only)
    get flowInputs() {
        return [
            {
                name : 'recordId' ,
                type : 'String' ,
                value : this.recordId
            }
        ];
    }

    // Wire to SCCHR count; only act when this.apexMethodApiName selects it
    @wire( getSCCHRCount , { recordId : '$recordId' } )
    wiredGetSCCHR( result ) {
        if ( this.apexMethodApiName === 'getSCCHRCount' ) {
           this.applyCountWireResult( result );
        }
    }

    // Wire to SCCPC count; only act when this.apexMethodApiName selects it
    @wire( getSCCPCCount , { recordId : '$recordId' } )
    wiredGetSCCPC( result ) {
        if ( this.apexMethodApiName === 'getSCCPCCount' ) {
            this.applyCountWireResult( result );
        }
    }

    // helper to normalize wire responses for count wires
    applyCountWireResult( { data , error } ) {
        this.loading = true;
        if ( ( data !== undefined ) && ( data !== null ) ) {
            this.showFlow = ( (data) > 1 );
            this.loading = false;
        } else if ( error ) {
            this.showFlow = false;
            this.loading = false;
        }
    }

    handleFlowStatusChange( event ) {
        const status = event?.detail?.status;
        if ( ( status === 'FINISHED' )
            || ( status === 'FINISHED_SCREEN' )
            || ( status === 'FINISHED_SUCCESS' )
            || ( status === 'ERROR' )
            )
        {
            this.dispatchEvent( new RefreshEvent() );
        }
    }

}
//