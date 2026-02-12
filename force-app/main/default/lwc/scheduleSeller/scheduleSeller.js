import { LightningElement, wire, api } from 'lwc';
import getBusinessDates from '@salesforce/apex/UserAvailabilityService.getBusinessDates';
import getTimeBlocks from '@salesforce/apex/UserAvailabilityService.getTimeBlocks';
import getAvailableUsersForWindow from '@salesforce/apex/UserAvailabilityService.getAvailableUsersForWindow';
import getAggregateCountsMatrix from '@salesforce/apex/UserAvailabilityService.getAggregateCountsMatrix';
import USER_ID from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';
import {FlowNavigationNextEvent} from 'lightning/flowSupport';

export default class ScheduleSeller extends NavigationMixin(LightningElement) {
    userId = USER_ID;
    error;
    columns = [];
    @api skill;
    @api timeZone;
    @api startDateTime;
    @api endDateTime;
    timeBlocks = [];
    isCreatingEvent = false;

    // Store raw matrix from Apex directly (6 rows × N columns)
    matrix = [];

    /**
     * Computed property to help with template rendering
     * Returns a copy of tableData with explicit count values for template
     */
    get processedTableData() {
        const cols = Array.isArray(this.columns) ? this.columns : [];
        const matrix = Array.isArray(this.matrix) ? this.matrix : [];

        // Ensure we always have 6 rows for display; pad with empty arrays if needed
        const rowCount = Math.max(6, matrix.length);

        return Array.from({ length: rowCount }, (_v, rowIndex) => {
            const counts = Array.isArray(matrix[rowIndex]) ? matrix[rowIndex] : [];
            const name = this.timeBlocks[rowIndex] || `Slot ${rowIndex + 1}`;
            const id = String(rowIndex + 1);

            const cells = cols.map((c, colIndex) => ({
                key: `${id}-${c.fullDate}`,
                value: counts[colIndex] != null ? counts[colIndex] : 0,
                timeBlock: name,          // "8:00 - 9:00"
                fullDate: c.fullDate      // "2026-01-28"
            }));

            return { id, name, counts, cells };
        });
    }


    // Columns are server-driven via Business Hours using Apex getBusinessDates()
    @wire(getBusinessDates, { businessHoursId: '01m4x000001119T', daysLimit: 7 })
    wiredDays({ data, error }) {
    if (data) {
        this.columns = data.map((yyyyMmDd, idx) => {
            // yyyyMmDd is already "YYYY-MM-DD"
            const d = new Date(`${yyyyMmDd}T00:00:00`);

            return {
                key: idx,
                label: d.toLocaleDateString(undefined, { weekday: 'short' }),
                dateValue: d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' }),

                fullDate: yyyyMmDd
            };
        });

            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.columns = [];
        }
    }

    @wire(getTimeBlocks, { timeZone: '$timeZone'})
        wiredTimeBlocks({ data, error }) {
        if (data) {
            this.timeBlocks = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.timeBlocks = [];
        }
    }

    // Matrix data for the 6 time slots × 7 business days
    @wire(getAggregateCountsMatrix, {
        skill: '$skill'
    })
    wiredMatrix({ data, error }) {
        if (data) {
            // Assign Apex matrix directly; no re-mapping
            this.matrix = Array.isArray(data) ? data : [];
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.matrix = [];
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
        this.matrix = [];
        // processedTableData getter will regenerate rows/cells on next render
    }

    get isLoading() {
        return !this.isReady;
    }
    get isReady() {
        return ( this.columns && ( this.columns.length > 0 ) );
    }

   async handleCellClick(event) {
        event.preventDefault();

        const timeBlock = event.currentTarget.dataset.timeblock;
        const date = event.currentTarget.dataset.date;

        if (!timeBlock || !date) return;

        const [rawStart, rawEnd] = timeBlock.split('-');
        const startTime = rawStart.trim();
        const endTime = rawEnd.trim();

        // Build ISO 8601 strings anchored to GMT/UTC (Zulu) time
        function buildGmtIso(dateStr, timeStr) {
            const [year, month, day] = dateStr.split('-').map(Number);
            const [h, m] = timeStr.split(':').map(Number);
            // Construct the instant at that GMT wall time using Date.UTC (no local offset applied)
            const dt = new Date(year, month - 1, day, h, m, 0, 0);
            // Standardize milliseconds to .000Z
            return dt.toISOString();
        }

        this.startDateTime = buildGmtIso(date, startTime);
        this.endDateTime = buildGmtIso(date, endTime);
        this.isCreatingEvent = true;
        try {
        const data = await getAvailableUsersForWindow({
            startDateTime: this.startDateTime,
            endDateTime: this.endDateTime,
            skill: this.skill
        });

        this.singleUserIds = data.join(','); // Store userIds in the exposed property
        this.error = undefined;

    } catch (error) {
        this.error = error;
    }
        // Move Flow to next screen
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

}