import { LightningElement, wire, api } from "lwc";
import getOpportunityMembers from "@salesforce/apex/UserOpportunityTeamService.getTeamMembersByOwner";
import getDefaultOppPageSize from "@salesforce/apex/UserOpportunityTeamService.getPageSize";

const COLUMNS = Object.freeze([
    { label: "User", fieldName: "userName", type: "text", sortable: true },
    { label: "Team Role", fieldName: "teamMemberRole", type: "text", sortable: true },
    { label: "Opportunity Access", fieldName: "opportunityAccessLevel", type: "text", sortable: true }
]);

export default class UserDefaultOpportunityTeam extends LightningElement {
    @api recordId;
    errorMessage;

    // expose columns for base
    columns = COLUMNS;
    pageSize;

    // load page size once and push to base
    @wire(getDefaultOppPageSize)
    wiredOppPageSize({ data, error }) {
        if (data) {
            this.pageSize = data;
        }
        else if (error) {
            this.pageSize = undefined;
        }
    }

    // wire data and push to base
    @wire(getOpportunityMembers, { ownerId: "$recordId" })
    wiredOppTeam({ data, error }) {
        const base = this.template.querySelector('c-user-default-team');
        if (Array.isArray(data) && base) {
            const teamRows = data.map((member) => ({
                id: member.id,
                ownerId: member.ownerId,
                userId: member.userId,
                userName: member.userName || "",
                teamMemberRole: member.teamMemberRole || "",
                opportunityAccessLevel: member.opportunityAccessLevel || ""
            }));
            base.setData(teamRows);
        } else if (error && base) {
            const errorText = Array.isArray(error?.body)
                ? error.body.map((e) => e.message).join(", ")
                : error?.body?.message || error?.message || "Unknown error";
            this.errorMessage = errorText;
        }
    }
}