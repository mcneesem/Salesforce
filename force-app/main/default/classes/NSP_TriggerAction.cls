public abstract class NSP_TriggerAction {

	/*	
		Version: 1.0
		Date: 03/29/2022
		Abstract class for implementing a recursion control on trigger
		Provides functionality for determining trigger context and tracking if trigger action has run before.
	*/
		private static Map < String, Integer > execMap = new Map < String, Integer > ();
		protected NSP_TriggerAction() {}
	
		/* Helper methods for tracking if a subclass has been run before */
	
		// Kludge for getting class name in apex
		public String getClassName() {
			return String.valueOf(this).substring(0, String.valueOf(this).indexOf(':'));
		}
	
		// Marks that a child class has been run;
		// leverages the execMap static map for tracking
		public void markRun() {
			String clsNm = this.getClassName();
			if (NSP_TriggerAction.execMap.containsKey(clsNm)) {
				NSP_TriggerAction.execMap.put(clsNm, NSP_TriggerAction.execMap.get(clsNm) + 1);
			} else {
				NSP_TriggerAction.execMap.put(clsNm, 1);
			}
		}
	
	
		// Return the number of times a class has been run;
		// leverages the execMap static map for tracking
		public Integer timesRun() {
			String clsNm = this.getClassName();
			if (NSP_TriggerAction.execMap.containsKey(clsNm)) {
				return NSP_TriggerAction.execMap.get(clsNm);
			} else {
				return 0;
			}
		}
		// Return if class has run before;
		// leverages timesRun() instance method
		public Boolean hasRun() {
			return this.timesRun() > 0;
		}
		// Reset hasRun count for this class
		public void resetHasRun() {
			NSP_TriggerAction.execMap.put(this.getClassName(), 0);
		}
		// Reset hasRun counts for all trigger action classes
		public static void resetAllHasRun() {
			NSP_TriggerAction.execMap.clear();
		}
	
	}