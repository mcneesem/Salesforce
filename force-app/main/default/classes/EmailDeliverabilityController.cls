public with sharing class EmailDeliverabilityController {
    // test w/ EmailDeliverabilityControllerTest (100%)

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
                Boolean local = false;
                if ( EmailDeliverabilityController.settings != null ) {
                    local = EmailDeliverabilityController.settings.IsEnabledOutbound__c;
                }
                isEnabledOutbound = local;
            }
            return isEnabledOutbound;
        }
        private set;
    }

}
//