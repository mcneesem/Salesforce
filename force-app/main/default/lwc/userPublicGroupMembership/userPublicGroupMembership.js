import { LightningElement, wire, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getPublicGroupMembershipsByUser from "@salesforce/apex/UserPublicGroupMembershipService.getPublicGroupMembershipsByUser";

const DEFAULT_PAGE_SIZE = 5;

const COLUMNS = Object.freeze([
    {
        label: "Label",
        fieldName: "groupDeveloperName",
        type: "button",
        typeAttributes: {
            label: { fieldName: "groupDeveloperName" },
            name: "openQueue",
            variant: "base"
        },
        sortable: true
    },
    {
        label: "Group Name",
        fieldName: "groupName",
        type: "button",
        typeAttributes: {
            label: { fieldName: "groupName" },
            name: "openQueue",
           variant: "base"
        },
        sortable: true
    },
    {
        label: "Reason For Membership",
        fieldName: "reasonForMembership",
        type: "text",
        sortable: false
    }
]);

export default class UserPublicGroupMembership extends LightningElement {
    @api recordId;

    rows = [];
    errorMessage;
    totalRecords = 0;

    // sorting
    sortedBy = "groupName";
    sortedDirection = "asc";

    // paging pattern aligned to userDefaultAccountTeam
    pageSize = DEFAULT_PAGE_SIZE;
    showAll = false;

    // dynamic title aligned to pattern
    get title() {
        return "Public Group Membership (" + this.totalRecords + ")";
    }

    // rows to render (either limited by pageSize or all)
    get pagedRows() {
        return this.showAll ? this.rows : (this.rows?.slice(0, this.pageSize) || []);
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

    // datatable bindings   mmvb
    columns = COLUMNS;
    
    // wire Apex
    @wire(getPublicGroupMembershipsByUser, { recordId: "$recordId" })
    wiredMemberships({ data, error }) {
        if (Array.isArray(data)) {
            this.processMembershipData(data);
        } else if (error) {
            this.handleError(error);
        } else {
            this.resetState();
        }
    }

    processMembershipData(data) {
        try {
            const isEmpty = !Array.isArray(data) || data.length === 0;
            if (isEmpty) {
                this.resetState();
                this.errorMessage = undefined;
            } else {
                const mapped = data.map((m) => ({
                    id: m.id,
                    groupId: m.groupId,
                    groupDeveloperName: m.groupDeveloperName || "",
                    groupName: m.groupName || "",
                    reasonForMembership: m.reasonForMembership || "—"
                }));
                this.totalRecords = mapped.length;
                this.rows = this.sortData(mapped, this.sortedBy, this.sortedDirection);
                this.errorMessage = undefined;
                this.showAll = false;
            }
        } catch (e) {
            this.handleError(e);
        }
    }

    handleError(error) {
        const errorText = Array.isArray(error?.body)
            ? error.body.map((e) => e.message).join(", ")
            : error?.body?.message || error?.message || "Unknown error";
        this.errorMessage = errorText;
        this.resetState();
    }

    resetState() {
        this.rows = [];
        this.totalRecords = 0;
        this.showAll = false;
    }

    // sorting
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
            // reset to initial limited view on sort
            this.showAll = false;
            changed = true;
        }
        return changed;
    }

    sortData(rowsToSort, sortField, sortDirection) {
        let result = rowsToSort;
        if (sortField) {
            const dir = sortDirection === "desc" ? -1 : 1;
            result = [...rowsToSort].sort((a, b) => {
                const va = (a?.[sortField]?.toString() || "").toLowerCase();
                const vb = (b?.[sortField]?.toString() || "").toLowerCase();
                if (va > vb) return dir;
                if (va < vb) return -dir;
                return 0;
            });
        }
        return result;
    }

    // handle row action for clickable label/name
    handleRowAction(event) {
        const actionName = event?.detail?.action?.name;
        const row = event?.detail?.row;
        if (actionName === "openQueue" && row?.groupId) {
            this.navigateToGroupRecord(row.groupId);
        }
    }

    navigateToGroupRecord(groupId) {
        // Construct URL with the specific domain format the user requires
        const currentOrigin = window.location.origin;
        // Replace force.com with setup.com to match user's expected format
        const setupOrigin = currentOrigin.replace('.lightning.force.com', '.my.salesforce-setup.com');
        const encodedId = encodeURIComponent(`p/own/Queue/d?id=${groupId}`);
        const url = `${setupOrigin}/lightning/setup/Queues/page?address=%2F${encodedId}`;
        
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        }, false);
    }
}