import { LightningElement, wire, api } from "lwc";
import getTeamMembersByOwner from "@salesforce/apex/UserOpportunityTeamService.getTeamMembersByOwner";
import getPageSize from "@salesforce/apex/UserOpportunityTeamService.getPageSize";

const COLUMNS = Object.freeze([
    { label: "User", fieldName: "userName", type: "text", sortable: true },
    { label: "Team Role", fieldName: "teamMemberRole", type: "text", sortable: true },
    { label: "Opportunity Access", fieldName: "opportunityAccessLevel", type: "text", sortable: true }
]);

export default class UserDefaultOpportunityTeam extends LightningElement {
    @api recordId;

    // expose columns for base
    columns = COLUMNS;

    // load page size once and push to base
    @wire(getPageSize)
    wiredPageSize({ data, error }) {
        const base = this.template.querySelector('c-user-default-team-member-base');
        if (data != null && base) {
            const n = Number(data);
            base.setPageSize(Number.isFinite(n) && n > 0 ? n : undefined);
        } else if (error && base) {
            base.setPageSize(undefined);
        }
    }

    // wire data and push to base
    @wire(getTeamMembersByOwner, { ownerId: "$recordId" })
    wiredTeam({ data, error }) {
        const base = this.template.querySelector('c-user-default-team-member-base');
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
            base.setError(errorText);
        }
    }
}