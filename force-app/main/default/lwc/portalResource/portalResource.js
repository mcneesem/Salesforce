import { LightningElement , api , wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import isCommunityContext from "@salesforce/apex/PortalClientSelector.isCommunityContext";

export default class PortalResource extends NavigationMixin(LightningElement) {
    @api record; // is-a Portal_Resource__c

    isCommunity = false;
    @wire( isCommunityContext )
    wiredIsCommunityContext( { error , data } ) {
        if ( !error && data && ( typeof data === 'boolean' ) ) {
            this.isCommunity = data;
        }
    }

    //
    // Files
    //

    get parentRecordId() {
        return ( this.record ? this.record.fields?.Id?.value : undefined );
    }

    links;
    handleLoaded( event ) {
        if ( event ) {
            this.links = event?.detail;
        }
    }

    get contentDocumentLink() {
        return ( ( this.links && Array.isArray( this.links ) && ( this.links.length > 0 ) ) ? this.links[0] : undefined );
    }

    get isLoading() {
        return ( !this.links );
    }

    //
    //
    //

    get hasResource() {
        return ( !this.isLoading && this.title && ( this.linkUrl || this.contentDocumentId ) );
    }

    get title() {
        return ( this.record.fields?.Name?.value ? this.record.fields?.Name?.value : undefined );
    }

    get linkUrl() {
        return ( this.record.fields?.Link_URL__c?.value ? this.record.fields?.Link_URL__c?.value : undefined );
    }

    get contentDocumentId() {
        return ( this.contentDocumentLink ? this.contentDocumentLink?.fields?.ContentDocumentId?.value : undefined );
    }

    //
    //
    //

    handleClick( event ) {
        const dataset = event?.currentTarget?.dataset;
        let resourceUrl = dataset?.linkurl;
        if ( dataset?.contentdocumentid ) {
            resourceUrl = ( this.isCommunity ? './sfsites/c' : '' ) + '/sfc/servlet.shepherd/document/download/' + dataset?.contentdocumentid;
        }
        if ( resourceUrl ) {
            this[NavigationMixin.Navigate](
                {
                    type: 'standard__webPage' ,
                    attributes: {
                        url: resourceUrl ,
                    } ,
                }
            );
        }
    }

}
//