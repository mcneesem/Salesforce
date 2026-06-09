import { LightningElement , api , wire } from 'lwc';
import getAggregateCountsMatrix from '@salesforce/apex/UserAvailabilityService.getAggregateCountsMatrix';
import getBusinessDates from '@salesforce/apex/UserAvailabilityService.getBusinessDates';
import getTimeBlocks from '@salesforce/apex/UserAvailabilityService.getTimeBlocks';
import isScheduleSellerAdmin from '@salesforce/apex/UserAvailabilityService.isScheduleSellerAdmin';
import { NavigationMixin } from 'lightning/navigation';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class ScheduleSeller extends NavigationMixin(LightningElement) {
    _skill;
    _timeZone;
    @api startDateTime;
    @api endDateTime;

    error;
    columns = [];
    timeBlocks = [];
    isAdmin = false;

    // Store raw matrix from Apex directly (M rows × N columns)
    matrix = [];

    @api get skill() { return this._skill; }
    set skill(v) { this._skill = v; this.loadMatrix(); }

    @api get timeZone() { return this._timeZone; }
    set timeZone(v) { this._timeZone = v; this.loadMatrix(); }

    connectedCallback() {
        this.loadMatrix();
    }

    // Computed property to help with template rendering
    // Returns a copy of tableData with explicit count values for template
    get processedTableData() {
        const cols = ( Array.isArray( this.columns ) ? this.columns : [] );
        const matrix = ( Array.isArray( this.matrix ) ? this.matrix : [] );

        // Compute cutoff for non-admins: now + 24h (rounded to minute)
        const cutoffUtc = new Date(Date.now() + 24 * 60 * 60 * 1000);
        cutoffUtc.setUTCSeconds(0, 0);

        const rowCount = this.timeBlocks.length;
        return Array.from(
            { length: rowCount } ,
            ( _v , rowIndex ) => {
                const counts = ( Array.isArray( matrix[rowIndex] ) ? matrix[rowIndex] : [] );
                const startTime = this.timeBlocks[rowIndex].StartDateTime;
                const endTime = this.timeBlocks[rowIndex].EndDateTime;
                const id = String( rowIndex + 1 );
                const cells = cols.map(
                    ( c , colIndex ) => {
                        // c.fullDate is already "YYYY-MM-DD"
                        const fullDate = new Date( `${c.fullDate}T00:00:00` );
                        //
                        const startDate = new Date( this.timeBlocks[rowIndex].StartDateTime );
                        const startUTCDate = new Date(
                            Date.UTC(
                                fullDate.getUTCFullYear() ,
                                fullDate.getUTCMonth() ,
                                fullDate.getUTCDate() ,
                                startDate.getUTCHours() ,
                                startDate.getUTCMinutes() ,
                                0
                            )
                        );
                        //
                        const endDate = new Date( this.timeBlocks[rowIndex].EndDateTime );
                        const endUTCDate = new Date(
                            Date.UTC(
                                fullDate.getUTCFullYear() ,
                                fullDate.getUTCMonth() ,
                                fullDate.getUTCDate() ,
                                endDate.getUTCHours() ,
                                endDate.getUTCMinutes() ,
                                0
                            )
                        );
                        //

                        const countVal = counts[colIndex];
                        // default Button disabled when zero availability
                        let isDisabled = ( countVal === 0 );
                        if ( !isDisabled && !this.isAdmin ) {
                            const startRounded = new Date(startUTCDate.getTime());
                            startRounded.setUTCSeconds(0, 0);
                            // Enforce 24-hour restriction for non-admins and disable when count is zero
                            isDisabled = ( startRounded < cutoffUtc );
                        }

                        return {
                            key: `${id}-${c.fullDate}` ,
                            value: ( countVal != null ? countVal : '' ),
                            start: startUTCDate.toISOString() , // "2026-01-28T14:00:00Z"
                            end: endUTCDate.toISOString() , // "2026-01-28T15:00:00Z"
                            disabled: isDisabled,
                            // Add disabled attribute to make it unclickable in template
                        }
                    }
                );
                return { id , startTime , endTime , counts , cells };
            }
        );
    }

    //
    //
    //

    // Refresh the component data
    // Useful when data has changed in the org and needs to be reloaded
    refreshData() {
        // This will trigger the wire adapters to reload data
        // We can force a refresh by resetting the columns (which will trigger the business days reload)
        this.columns = [];
        this.matrix = [];
        // processedTableData getter will regenerate rows/cells on next render
    }

    get isLoading() {
        return !this.isReady;
    }

    get isReady() {
        return ( this.columns && ( this.columns.length > 0 ) );
    }

    //
    //
    //

    // Columns are server-driven via Business Hours using Apex getBusinessDates()
    @wire(
        getBusinessDates ,
        { skill: '$skill' }
    )
    wiredDays( { data , error } )  {
        if ( data ) {
            this.columns = data.map( ( yyyyMmDd , idx ) => {
                // yyyyMmDd is already "YYYY-MM-DD"
                const d = new Date( `${yyyyMmDd}T00:00:00` );
                return {
                    key: idx ,
                    label: d.toLocaleDateString( undefined , { weekday: 'short' } ) ,
                    dateValue: d.toLocaleDateString( undefined , { month: 'short' , day: 'numeric' } ) ,
                    fullDate: yyyyMmDd ,
                };
            });
            this.error = undefined;
        } else if ( error ) {
            this.error = error;
            this.columns = [];
        }
    }

    @wire(
        getTimeBlocks ,
        { skill: '$skill' , timeZone: '$timeZone' }
    )
    wiredTimeBlocks( { data , error } ) {
        if ( data ) {
            this.timeBlocks = data;
            this.error = undefined;
        } else if ( error ) {
            this.error = error;
            this.timeBlocks = [];
        }
    }

    // Matrix data for the M time slots × N business days
    async loadMatrix() {
        if (this._skill && this._timeZone) {
            try {
                const data = await getAggregateCountsMatrix({ skill: this._skill, timeZone: this._timeZone });
                this.matrix = Array.isArray(data) ? data : [];
                this.error = undefined;
            } catch (e) {
                this.error = e;
                this.matrix = [];
            }
        }
    }
    // Admin flag
    @wire(isScheduleSellerAdmin)
    wiredIsAdmin({ data, error }) {
        if (data !== undefined) {
            this.isAdmin = Boolean(data);
        } else if (error) {
            // Fail-safe: treat as non-admin if error
            this.isAdmin = false;
            this.error = error;
        }
    }

    //
    //
    //

    handleCellClick( event ) {
        event.preventDefault();
        const dataStart = event.currentTarget.dataset.start;
        const dataEnd = event.currentTarget.dataset.end;
        const isDisabled = event.currentTarget.dataset.disabled === 'true';
        if ( !isDisabled && dataStart && dataEnd ) {
            this.startDateTime = dataStart;
            this.endDateTime = dataEnd;
            // Move Flow to next screen
            this.dispatchEvent( new FlowNavigationNextEvent() );
        }
    }

    // Build ISO 8601 strings anchored to GMT/UTC (Zulu) time
    buildGmtIso( dateStr , timeStr ) {
        const [ year , month , day ] = dateStr.split( '-' ).map( Number );
        const [ h , m ] = timeStr.split( ':' ).map( Number );
        // Construct the instant at that GMT wall time using Date.UTC (no local offset applied)
        const dt = new Date(
            year ,
            ( month - 1 ) ,
            day ,
            h ,
            m ,
            0 ,
            0
        );
        // Standardize milliseconds to .000Z
        return dt.toISOString();
    }

}
//