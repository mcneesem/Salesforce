public with sharing class NotificationDeliverabilityController {
    // test w/ NotificationDeliverabilityControllerTest (100%)

    private static Notification_Deliverability_Settings__c settings {
        private get {
            if ( settings == null ) {
                settings = Notification_Deliverability_Settings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    public static Boolean isEnabledOutbound {
        public get {
            if ( isEnabledOutbound == null ) {
                Boolean local = false;
                if ( NotificationDeliverabilityController.settings != null ) {
                    local = NotificationDeliverabilityController.settings.IsEnabledOutbound__c;
                }
                isEnabledOutbound = local;
            }
            return isEnabledOutbound;
        }
        private set;
    }

}
//