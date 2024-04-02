global class LoadFullAccessPermSetsSchedulable implements Schedulable {
	// test w/ LoadFullAccessPermSetsSchedulableTest (100%)

    private static String READ_PS = 'All_objects_All_fields_Read_access';
    private static String EDIT_PS = 'All_objects_All_fields_Edit_access';
    private static String READ_PS_NLO = 'All_objects_All_fields_Read_access_Non_Licensed';
    private static String EDIT_PS_NLO = 'All_objects_All_fields_Edit_access_Non_Licensed';
	public static List<String> filterNamespaces = new List<String>();

	global void execute(SchedulableContext ctx) {
        if (!Test.isRunningTest()) filterNamespaces.addAll(OrgSettings__c.getInstance().NLO_Namespaces__c.Split(','));
		LoadFullAccessPermSets.runLoadFullAccessPermSets(READ_PS, EDIT_PS, null, null);
		LoadFullAccessPermSets.runLoadFullAccessPermSets(READ_PS_NLO, EDIT_PS_NLO, null, filterNamespaces);
	}
}