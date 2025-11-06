import { LightningElement, wire, api } from 'lwc';
import getTeamMembersByOwner from "@salesforce/apex/UserOpportunityTeamService.getTeamMembersByOwner";
import getPageSize from "@salesforce/apex/UserOpportunityTeamService.getPageSize";

const DEFAULT_PAGE_SIZE = 5;

const COLUMNS = Object.freeze([
    { label: "User", fieldName: "userName", type: "text", sortable: true },
    { label: "Team Role", fieldName: "teamMemberRole", type: "text", sortable: true },
    { label: "Opportunity Access", fieldName: "opportunityAccessLevel", type: "text", sortable: true }
]);

export default class UserDefaultOpportunityTeam extends LightningElement {
    // recordId provided by record page context
    @api recordId;

    rows = [];
    errorMessage;
    totalRecords = 0;

    // sorting (read-only table; no selection or row actions)
    sortedBy = "userName";
    sortedDirection = "asc";

    // derived, initial render size from custom setting
    pageSize = DEFAULT_PAGE_SIZE;
    showAll = false;

    // use getter to get the title of the page
    get title() {
        return "Default Account Team (" + this.totalRecords + ")";
    }

    // rows to render (either limited by pageSize or all)
    get pagedRows() {
        let result = [];
        // Guard against undefined/invalid rows array
        if (this.showAll) {
            result = this.rows;
        } else {
            result = this.rows?.slice(0, this.pageSize);
        }
        return result;
    }

    // "View All" link state: disabled when there are no records or already showing all
    get isViewAllDisabled() {
        return this.totalRecords === 0 || this.showAll === true;
    }

    // Handler for "View All" click - render all rows within this component
    handleViewAll() {
        if (!this.isViewAllDisabled) {
            this.showAll = true;
        }
    }

    // Columns: read-only, no actions
    columns = COLUMNS;

    // load page size once
    @wire(getPageSize)
    wiredPageSize({ data, error }) {
        if (data != null) {
            const n = Number(data);
            this.pageSize = Number.isFinite(n) && n > 0 ? n : DEFAULT_PAGE_SIZE;
        } else if (error) {
            // ignore and use default
            this.pageSize = DEFAULT_PAGE_SIZE;
        }
    }

    @wire(getTeamMembersByOwner, { ownerId: "$recordId" })
    wiredTeam({ data, error }) {
        if (Array.isArray(data)) {
            this.processTeamData(data);
        } else if (error) {
            this.handleError(error);
        } else {
            this.resetState();
        }
    }

    handleError(error) {
        const errorText = Array.isArray(error?.body)
            ? error.body.map((e) => e.message).join(", ")
            : error?.body?.message || error?.message || "Unknown error";

        this.errorMessage = errorText;
        this.resetState();
    }

    processTeamData(data) {
        try {
            const isEmpty = !Array.isArray(data) || data.length === 0;
            if (isEmpty) {
                this.resetState();
                this.errorMessage = undefined;
            } else {
                const teamRows = data.map((member) => ({
                    id: member.id,
                    ownerId: member.ownerId,
                    userId: member.userId,
                    userName: member.userName || "",
                    teamMemberRole: member.teamMemberRole || "",
                    opportunityAccessLevel: member.opportunityAccessLevel || ""
                }));
                this.totalRecords = teamRows.length;
                this.rows = this.sortData(teamRows, this.sortedBy, this.sortedDirection);
                this.errorMessage = undefined;
                this.showAll = false;
            }
        } catch (parseError) {
            this.handleError(parseError);
        }
    }

    resetState() {
        this.rows = [];
        this.totalRecords = 0;
        this.showAll = false;
    }

    handleSort(event) {
        // Validate event and detail payload before using
        const detail = event?.detail || null;
        const sortField = typeof detail?.fieldName === "string" ? detail.fieldName : undefined;
        const sortDirection = typeof detail?.sortDirection === "string" ? detail.sortDirection : undefined;
        // single-return function: track whether we applied a change
        let changed = false;
        // Guard: require both field and direction
        // No-op if sort settings are unchanged
        if (
            sortField &&
            sortDirection &&
            (sortField !== this.sortedBy || sortDirection !== this.sortedDirection)
        ) {
            // Update state and re-sort
            this.sortedBy = sortField;
            this.sortedDirection = sortDirection;
            this.rows = this.sortData(this.rows, sortField, sortDirection);
            // reset to initial limited view on sort
            this.showAll = false;
            // handle response...
            changed = true;
        }
        // single exit
        return changed;
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
