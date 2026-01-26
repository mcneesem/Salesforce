import { LightningElement, wire } from 'lwc';
import businessDays from '@salesforce/apex/UserAvailabilityService.getBusinessDates';
import getCountsMatrix from '@salesforce/apex/UserAvailabilityService.getCountsMatrix';
import USER_ID from '@salesforce/user/Id';

export default class Scheduler extends LightningElement {
    userId = USER_ID;
    error;
    columns = [];

    // Use @track for proper reactivity
    tableData = [
        { id: '1', name: '8:00-9:00', status: 'Pending', counts: [] },
        { id: '2', name: '8:30 - 9:30', counts: [] },
        { id: '3', name: '9:00 - 10:00', counts: [] },
        { id: '4', name: '9:30 - 10:30', counts: [] },
        { id: '5', name: '10:00 - 11:00', counts: [] },
        { id: '6', name: '11:30 - 12:30', counts: [] }
    ];

    /**
     * Computed property to help with template rendering
     * Returns a copy of tableData with explicit count values for template
     */
    get processedTableData() {
        // Return a shallow copy to ensure reactivity
        return this.tableData.map(row => ({...row}));
    }

    // Columns are now server-driven via Business Hours using Apex businessDays()
    @wire(businessDays, {businessHoursId: '01m4x000001119T', daysLimit:7})
    wiredDays({ data, error }) {
        if (data) {
            // data is now List<Date> serialized as 'YYYY-MM-DD'
            this.columns = data.map((yyyyMmDd, idx) => {
                let d;
                if (typeof yyyyMmDd === 'string') {
                    const parts = yyyyMmDd.split('-'); // [YYYY, MM, DD]
                    if (parts.length === 3) {
                        const y = parseInt(parts[0], 10);
                        const m = parseInt(parts[1], 10) - 1; // 0-based month
                        const day = parseInt(parts[2], 10);
                        d = new Date(y, m, day); // construct as local date to avoid TZ shift
                    } else {
                        d = new Date(yyyyMmDd);
                    }
                } else {
                    d = new Date(yyyyMmDd);
                }
                return {
                    key: idx,
                    label: d.toLocaleDateString(undefined, { weekday: 'short' }),
                    dateValue: d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
                };
            });
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.columns = [];
        }
    }

    // Matrix data for the 6 time slots × 7 business days
    @wire(getCountsMatrix, {
        userId: '$userId',
        bufferMinutes: 0,
        stepMinutes: 30
    })
    wiredMatrix({ data, error }) {
        if (data) {
            // data is List<List<Integer>> - 6 rows × 7 columns
            // Populate each row's counts array with the corresponding row from the matrix

            // Create a new array to ensure proper reactivity
            const updatedTableData = this.tableData.map((row, rowIndex) => {
                if (rowIndex < data.length) {
                    // Make sure we have a proper array and handle potential undefined values
                    const countsArray = Array.isArray(data[rowIndex]) ? data[rowIndex] : [];
                    return {
                        ...row,
                        counts: [...countsArray]
                    };
                }
                return row;
            });

            // Update the tracked property
            this.tableData = updatedTableData;
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
    }

    /**
     * Refresh the component data
     * Useful when data has changed in the org and needs to be reloaded
     */
    refreshData() {
        // This will trigger the wire adapters to reload data
        // We can force a refresh by resetting the columns (which will trigger the business days reload)
        this.columns = [];
        this.tableData = this.tableData.map(row => ({
            ...row,
            counts: []
        }));
    }

    get isLoading() {
        return !this.isReady();
    }
    get isReady() {
        return ( this.columns && ( this.columns.length > 0 ) );
    }
}