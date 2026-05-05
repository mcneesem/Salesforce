import { LightningElement , api , wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class PortalPayPeriodCarousel extends LightningElement {
    @api recordId;

    error;
    records;
    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId' ,
        relatedListId: 'Portal_Pay_Periods__r' ,
        fields: [
            'Portal_Pay_Period__c.Id' ,
            'Portal_Pay_Period__c.Name' ,
            'Portal_Pay_Period__c.First_Pay_Period_Start__c' ,
            'Portal_Pay_Period__c.First_Pay_Period_End__c' ,
            'Portal_Pay_Period__c.First_Pay_Date__c' ,
            'Portal_Pay_Period__c.Pay_Frequency__c' ,
        ] ,
        sortBy: [ 'Portal_Pay_Period__c.Id' ]
    })
    listInfo({ error, data }) {
        if ( data ) {
            this.records = data.records;
            if ( this.records ) {
                this.indicators = this.rebuildIndicators( this.records[0]?.fields?.Id?.value );
            }
            this.isPaused = false;
            this.error = undefined;
        } else if ( error ) {
            this.error = error;
            this.records = undefined;
        }
    }

    intervalId;
    handleAnimationInterval() {
        if ( this.hasCarouselData && !this.intervalId ) {
            this.intervalId = setInterval(
                function() {
                    if ( this.isPaused || !this.hasCarouselData ) {
                        // stop the animations...
                        if ( this.intervalId ) {
                            clearInterval( this.intervalId );
                        }
                        this.intervalId = undefined;
                    } else if ( this.records ) {
                        // show next panel...
                        let nextIndex = 0;
                        if ( this.records.length > ( this.activePanelIndex + 1 ) ) {
                            nextIndex = ( this.activePanelIndex + 1 );
                        }
                        this.indicators = this.rebuildIndicators( this.records[nextIndex]?.fields?.Id?.value );
                    }
                }.bind( this ) ,
                ( 5 * 1000 ) // refresh once per 5 seconds ( 1 minute == 60 seconds == 60000 milliseconds )
            );
        }
    }

    get hasCarouselData() {
        return ( this.records && ( this.records.length > 1 ) );
    }

    //
    // play / pause
    //

    privateIsPaused;
    get isPaused() {
        return this.privateIsPaused;
    }
    set isPaused( value ) {
        this.privateIsPaused = value;
        if ( value === false ) {
            this.handleAnimationInterval();
        }
    }

    get iconPlayPause() {
        return ( this.isPaused ? "utility:play" : "utility:pause" );
    }

    get titlePlayPause() {
        return ( this.isPaused ? "Start auto-play" : "Stop auto-play" );
    }

    handleClickPlayPause( event ) {
        this.isPaused = !this.isPaused;
    }

    //
    // panels
    //

    get activePanelIndex() {
        const index = this.indicators.findIndex( indicator => indicator.id === this.activePanelDatasetId );
        return ( ( index < 0 ) ? 0 : index );
    }

    get panelCssStyle() {
        return "transform:translateX(-" + ( this.activePanelIndex * 100 ) + "%)";
    }

    //
    // indicators
    //

    privateIndicators;
    get indicators() {
        return this.privateIndicators;
    }
    set indicators( value ) {
        this.privateIndicators = value;
    }
    rebuildIndicators( recordId ) {
        this.activePanelDatasetId = recordId;
        let response = null;
        if ( this.hasCarouselData ) {
            response = this.records.map(
                function( record ) {
                    let cssClass = "slds-carousel__indicator-action";
                    let tabIndex = "-1";
                    if ( record?.fields?.Id?.value == this.activePanelDatasetId ) {
                        cssClass = "slds-carousel__indicator-action slds-is-active";
                        tabIndex = "0";
                    }
                    return {
                        id : record?.fields?.Id?.value ,
                        title : record?.fields?.Id?.value ,
                        cssClass : cssClass ,
                        tabIndex : tabIndex ,
                    };
                }.bind( this )
            );
        }
        return response;
    }

    handleClickIndicator( event ) {
        event.stopPropagation();
        this.isPaused = true;
        if ( event?.target?.dataset?.id ) {
            this.indicators = this.rebuildIndicators( event.target.dataset.id );
        }
    }

    handleKeyDown( event ) {
        // only created to appease sonar...
    }

}
//