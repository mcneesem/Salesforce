public without sharing class LoadFullAccessPermSetsSchedulable implements ISelfSchedulable , Schedulable {
    // test w/ LoadFullAccessPermSetsSchedulableTest (100%)

    private static String READ_PS = 'All_objects_All_fields_Read_access';
    private static String EDIT_PS = 'All_objects_All_fields_Edit_access';
    private static String READ_PS_NLO = 'All_objects_All_fields_Read_access_Non_Licensed';
    private static String EDIT_PS_NLO = 'All_objects_All_fields_Edit_access_Non_Licensed';
    private static List<String> filterNamespaces = new List<String>();

    public void execute( SchedulableContext ctx ) {
        if ( !Test.isRunningTest() ) {
            filterNamespaces.addAll( OrgSettings__c.getInstance().NLO_Namespaces__c.Split( ',' ) );
        }
        LoadFullAccessPermSets.runLoadFullAccessPermSets( READ_PS , EDIT_PS , null , null );
        LoadFullAccessPermSets.runLoadFullAccessPermSets( READ_PS_NLO , EDIT_PS_NLO , null , filterNamespaces );
    }

    // runs every friday at 2am central...
    // ~ process needs to be completed after release and post-steps are completed (Thursday nights)...
    // ~ process needs to be completed before DEV*** sandbox refresh cycle begins (Friday mornings)...
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'LoadFullAccessPermSetsSchedulable ~ Every Friday, 2AM' + suffix ,
            '0 0 2 ? * FRI *' ,
            new LoadFullAccessPermSetsSchedulable()
        );
    }

}
//