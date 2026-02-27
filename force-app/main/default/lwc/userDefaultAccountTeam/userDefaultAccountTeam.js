import { LightningElement , wire , api } from "lwc";
import getAccountPageSize from "@salesforce/apex/UserAccountTeamService.getPageSize";
import getAccountTeamMembers from "@salesforce/apex/UserAccountTeamService.getTeamMembersByOwner";

const COLUMNS = Object.freeze([
    { label: "User", fieldName: "userName", type: "text", sortable: true },
    { label: "Team Role", fieldName: "teamMemberRole", type: "text", sortable: true },
    { label: "Account Access", fieldName: "accountAccessLevel", type: "text", sortable: true },
    { label: "Opportunity Access", fieldName: "opportunityAccessLevel", type: "text", sortable: true },
    { label: "Case Access", fieldName: "caseAccessLevel", type: "text", sortable: true }
]);

export default class UserDefaultAccountTeam extends LightningElement {
    @api recordId;

    // expose columns...
    columns = COLUMNS;

    // wire page size...
    pageSize;
    @wire( getAccountPageSize )
    wiredAccountPageSize( { data , error } ) {
        if ( data ) {
            this.pageSize = data;
        } else if ( error ) {
            this.pageSize = undefined;
        }

    }

    // wire data and set rows...
    rows;
    errorMessage;
    @wire( getAccountTeamMembers , { ownerId: "$recordId" } )
    wiredAccountTeamMembers( { data , error } ) {
        if ( Array.isArray( data ) ) {
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
        } else if ( error ) {
            const errorText = Array.isArray(error?.body)
                ? error.body.map((e) => e.message).join(", ")
                : error?.body?.message || error?.message || "Unknown error";
            this.errorMessage = errorText;
        }
    }

}
//