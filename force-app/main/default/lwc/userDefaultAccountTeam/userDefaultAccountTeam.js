import { LightningElement, wire, api } from "lwc";
import getTeamMembersByOwner from "@salesforce/apex/UserAccountTeamService.getTeamMembersByOwner";
import getPageSize from "@salesforce/apex/UserAccountTeamService.getPageSize";

const COLUMNS = Object.freeze([
    { label: "User", fieldName: "userName", type: "text", sortable: true },
    { label: "Team Role", fieldName: "teamMemberRole", type: "text", sortable: true },
    { label: "Account Access", fieldName: "accountAccessLevel", type: "text", sortable: true },
    { label: "Opportunity Access", fieldName: "opportunityAccessLevel", type: "text", sortable: true },
    { label: "Case Access", fieldName: "caseAccessLevel", type: "text", sortable: true }
]);

export default class UserDefaultAccountTeam extends LightningElement {
    @api recordId;

    errorMessage;
    // expose columns for base
    columns = COLUMNS;
    pageSize;
    // wire page size and push to base
    @wire(getPageSize)
    wiredPageSize({ data, error }) {
        if (data) {
            this.pageSize = data;
        }
        else if (error) {
            this.pageSize = undefined;
        }

    }

    // wire data and set rows...
    rows;
    @wire(getTeamMembersByOwner, { ownerId: "$recordId" })
    wiredTeam({ data, error }) {
        if (Array.isArray(data)) {
            this.rows = data.map((member) => ({
                id: member.id,
                ownerId: member.ownerId,
                userId: member.userId,
                userName: member.userName || "",
                teamMemberRole: member.teamMemberRole || "",
                accountAccessLevel: member.accountAccessLevel || "",
                opportunityAccessLevel: member.opportunityAccessLevel || "",
                caseAccessLevel: member.caseAccessLevel || "",
                contactAccessLevel: member.contactAccessLevel || ""
            }));
        } else if (error) {
            const errorText = Array.isArray(error?.body)
                ? error.body.map((e) => e.message).join(", ")
                : error?.body?.message || error?.message || "Unknown error";
            this.errorMessage = errorText;
        }
    }
}