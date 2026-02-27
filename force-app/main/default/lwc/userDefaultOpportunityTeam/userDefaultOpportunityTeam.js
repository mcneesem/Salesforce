import { LightningElement , wire , api } from "lwc";
import getOpportunityPageSize from "@salesforce/apex/UserOpportunityTeamService.getPageSize";
import getOpportunityTeamMembers from "@salesforce/apex/UserOpportunityTeamService.getTeamMembersByOwner";

const COLUMNS = Object.freeze([
    { label: "User", fieldName: "userName", type: "text", sortable: true },
    { label: "Team Role", fieldName: "teamMemberRole", type: "text", sortable: true },
    { label: "Opportunity Access", fieldName: "opportunityAccessLevel", type: "text", sortable: true }
]);

export default class UserDefaultOpportunityTeam extends LightningElement {
    @api recordId;

    // expose columns...
    columns = COLUMNS;

    // wire page size...
    pageSize;
    @wire( getOpportunityPageSize )
    wiredOpportunityPageSize( { data , error } ) {
        if ( data ) {
            this.pageSize = data;
        } else if ( error ) {
            this.pageSize = undefined;
        }
    }

    // wire data and set rows...
    rows;
    errorMessage;
    @wire( getOpportunityTeamMembers , { ownerId: "$recordId" } )
    wiredOpportunityTeamMembers( { data , error } ) {
        if ( Array.isArray( data ) ) {
            this.rows = data.map((member) => ({
                id: member.id,
                ownerId: member.ownerId,
                userId: member.userId,
                userName: member.userName || "",
                teamMemberRole: member.teamMemberRole || "",
                opportunityAccessLevel: member.opportunityAccessLevel || ""
            }));
        } else if ( error ) {
            const errorText = Array.isArray(error?.body)
                ? error.body.map((e) => e.message).join(", ")
                : error?.body?.message || error?.message || "Unknown error";
            this.errorMessage = errorText;
        }
    }

}
//