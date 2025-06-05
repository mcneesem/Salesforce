global class NSP_ChatterPostSeparationAgreement {
    // test w/ NSP_ChatterPostSeperationAgreementTest (100%)
    // test w/ NSP_ChatterPostSeparationAgreementTest (100%)

    @InvocableMethod(label='Separation Agreement')
    global static void sendSperationAgreementPost( List<Case> caseList ) {
        String separationAgreementGroupName = System.Label.NSP_SeparationAgreementGroupName;
        Id separationAgreementGroupNameId = null;
        if ( String.isNotBlank( separationAgreementGroupName ) ) {
            List<CollaborationGroup> separationAgreementGroups = [
                SELECT Id , Name
                FROM CollaborationGroup
                WHERE Name = :separationAgreementGroupName
                LIMIT 1
            ];
            if ( ( separationAgreementGroups != null ) && !separationAgreementGroups.isEmpty() ) {
                separationAgreementGroupNameId = separationAgreementGroups[0].Id;
            }
        }
        if ( separationAgreementGroupNameId != null ) {
            NSP_ChatterPostFromProcessBuilder.postChatterFeed(
                caseList ,
                separationAgreementGroupNameId ,
                'New HR Separation Agreement Request Case created and assigned to team'
            );
        }
    }

}
//