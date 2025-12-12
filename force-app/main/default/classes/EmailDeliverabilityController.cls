public with sharing class EmailDeliverabilityController {
    private static Email_Deliverability_Settings__c settings {
        private get {
            if ( settings == null ) {
                settings = Email_Deliverability_Settings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    public static Boolean isEnabledOutbound {
        public get {
            if ( isEnabledOutbound == null ) {
                isEnabledOutbound = true;
                if ( EmailDeliverabilityController.settings != null ) {
                    isEnabledOutbound = EmailDeliverabilityController.settings.IsEnabledOutbound__c;
                }
            }
            return isEnabledOutbound;
        }
        private set;
    }
}