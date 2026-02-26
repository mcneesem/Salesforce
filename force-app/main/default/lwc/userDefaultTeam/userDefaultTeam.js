import { LightningElement, api } from "lwc";

const DEFAULT_PAGE_SIZE = 5;

export default class UserDefaultTeam extends LightningElement {
    // Public API
    @api titlePrefix = "Team";
    @api columns = [];

    // Internal state
    rows = [];
    errorMessage;
    totalRecords = 0;

    // sorting (read-only table; no selection or row actions)
    sortedBy = "userName";
    sortedDirection = "asc";

    // derived, initial render size
    pageSize = DEFAULT_PAGE_SIZE;
    showAll = false;

    // Title getter
    get title() {
        return `${this.titlePrefix} (${this.totalRecords})`;
    }

    // rows to render (either limited by pageSize or all)
    get pagedRows() {
        let result = [];
        if (this.showAll) {
            result = this.rows;
        } else {
            result = this.rows?.slice(0, this.pageSize);
        }
        return result;
    }

    // "View All" link state
    get isViewAllDisabled() {
        return this.totalRecords === 0 || this.showAll === true;
    }

    // Public API methods for children to drive data/pageSize/errors
    _pageSize = DEFAULT_PAGE_SIZE;
    @api
    get pageSize() {
        return this._pageSize;
    }
    set pageSize(value) {
        let parsed = DEFAULT_PAGE_SIZE;
        if (value) {
            parsed = Number(value);
        }
        if (!parsed || !Number.isFinite(parsed) || (parsed < 1)) {
            parsed = DEFAULT_PAGE_SIZE;
        }

        this._pageSize = parsed;
    }

    /**
     * @param {Array<object>} rows
     */
    @api
    setData(rows) {
        try {
            const valid = Array.isArray(rows);
            if (!valid || rows.length === 0) {
                this.resetState();
                this.errorMessage = undefined;
                return;
            }
            // Ensure objects and defensive defaults
            const sanitized = rows.map((dataRow) => ({ ...dataRow }));
            this.totalRecords = sanitized.length;
            this.rows = this.sortData(sanitized, this.sortedBy, this.sortedDirection);
            this.errorMessage = undefined;
            this.showAll = false;
        } catch (ex) {
            this.setError(ex?.message || "Unknown error");
        }
    }

    @api
    get error() {
        return this.errorMessage;
    }
    set error(message) {
        let msg = "UNKNOWN ERROR";
        if (typeof message === 'string' && message.length > 0) {
            msg = message;
        }
        this.errorMessage = msg;
        this.resetState();
    }

    // Handlers

    handleViewAll() {
        if (!this.isViewAllDisabled) {
            this.showAll = true;
        }
    }

    handleSort(event) {
        const detail = event?.detail || null;
        const sortField = typeof detail?.fieldName === "string" ? detail.fieldName : undefined;
        const sortDirection = typeof detail?.sortDirection === "string" ? detail.sortDirection : undefined;

        let changed = false;
        if (
            sortField &&
            sortDirection &&
            (sortField !== this.sortedBy || sortDirection !== this.sortedDirection)
        ) {
            this.sortedBy = sortField;
            this.sortedDirection = sortDirection;
            this.rows = this.sortData(this.rows, sortField, sortDirection);
            this.showAll = false;
            changed = true;
        }
        return changed;
    }

    // Helpers

    resetState() {
        this.rows = [];
        this.totalRecords = 0;
        this.showAll = false;
    }

    sortData(rowsToSort, sortField, sortDirection) {
        let result = rowsToSort;

        if (sortField) {
            const directionMultiplier = sortDirection === "desc" ? -1 : 1;
            result = [...rowsToSort].sort((rowA, rowB) => {
                const valueA = (rowA?.[sortField]?.toString() || "").toLowerCase();
                const valueB = (rowB?.[sortField]?.toString() || "").toLowerCase();

                let returnValue = 0;
                if (valueA > valueB) {
                    returnValue = directionMultiplier;
                } else if (valueA < valueB) {
                    returnValue = -directionMultiplier;
                }

                return returnValue;
            });
        }

        return result;
    }
}