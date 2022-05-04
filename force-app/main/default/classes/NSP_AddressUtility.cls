/* **************************************************************************************************   
Component Name :  NSP_AddressUtility class
Version              :  1.0                                                                          
Created Date         :  September 2021                                                             
Function             :  This class is used as a controller for Address Aura Component   	
Story                : address fields state and country need to be drop down                                                                            
Modification Log     :                                                                               
*	Tejas           September 2021          First Iteration
*
***************************************************************************************************
*/

public class NSP_AddressUtility {

	/**********************************************************************************************
	 * Method Name:getAuraDependentOptions
	 * Purpose: This aura method is used to get dependent picklist values
	 ***********************************************************************************************/

	@AuraEnabled
	public static Map < String, List < String >> getAuraDependentOptions(String pObjName, String pControllingFieldName, String pDependentFieldName) {
		Map < String, List < String >> depPicklist = new Map < String, List < String >> ();
		try {
			depPicklist = getDependentOptions(pObjName, pControllingFieldName, pDependentFieldName);
		} catch (Exception ex) {
			//handling exception in catch block
			throw new AuraHandledException(ex.getMessage());
		}
		return depPicklist;
	}



	/**********************************************************************************************
	 * Method Name:getDependentOptions
	 * Purpose: This method is used to get the dependent picklist values 
	 ***********************************************************************************************/

	public static Map < String, List < String >> getDependentOptions(String pObjName, String pControllingFieldName,
		String pDependentFieldName) {
		try {
			Map < String, List < String >> mapResults = new Map < String, List < String >> ();

			//verify/get object schema
			Schema.SObjectType pType = Schema.getGlobalDescribe().get(pObjName);
			if (pType == null) {
				return mapResults;
			}
			Map < String, Schema.SObjectField > objFieldMap = pType.getDescribe().fields.getMap();

			//verify field names
			if (!objFieldMap.containsKey(pControllingFieldName) || !objFieldMap.containsKey(pDependentFieldName)) {
				return mapResults;
			}

			//get the control & dependent values   
			List < Schema.PicklistEntry > ctrl_ple = objFieldMap.get(pControllingFieldName).
			getDescribe().getPicklistValues();
			List < Schema.PicklistEntry > dep_ple = objFieldMap.get(pDependentFieldName).
			getDescribe().getPicklistValues();

			//clear heap
			objFieldMap = null;

			//initialize results mapping
			for (Integer pControllingIndex = 0; pControllingIndex < ctrl_ple.size(); pControllingIndex++) {
				mapResults.put(ctrl_ple[pControllingIndex].getLabel(), new List < String > ());
			}
			//cater for null and empty
			mapResults.put('', new List < String > ());
			mapResults.put(null, new List < String > ());

			//serialize dep entries        
			List < NPS_TPicklistEntry > objDS_Entries = new List < NPS_TPicklistEntry > ();
			objDS_Entries = (List < NPS_TPicklistEntry > ) JSON.deserialize(JSON.serialize(dep_ple), List < NPS_TPicklistEntry > .class);

			List < Integer > validIndexes;
			for (NPS_TPicklistEntry objDepPLE: objDS_Entries) {

				validIndexes = convertBits(objDepPLE.validFor);

				for (Integer validIndex: validIndexes) {
					mapResults.get(ctrl_ple[validIndex - 1].getLabel()).add(objDepPLE.label);
				}
			}

			//clear heap
			objDS_Entries = null;
			return mapResults;
		} catch (exception ex) {
			//SME_GlobalExceptionHandlerCtrl.processException('SME_UtilityCtrl', 'getDependentOptions', ex);
			//return null;
			throw new AuraHandledException(ex.getMessage());
		}
	} //GetDependentOptions    




	/**********************************************************************************************
	 * Inner Class Name:TPicklistEntry
	 * Purpose: Inner wrapper class to get picklist values
	 ***********************************************************************************************/

	public class NPS_TPicklistEntry {
		//active 
		public string active {
			get;
			set;
		}
		//default value
		public string defaultValue {
			get;
			set;
		}
		//label
		public string label {
			get;
			set;
		}
		//value
		public string value {
			get;
			set;
		}
		//validfor
		public string validFor {
			get;
			set;
		}
		public NPS_TPicklistEntry() {}
	} //TPicklistEntry     

	/**********************************************************************************************
	 * Method Name:BlobToBytes
	 * Purpose: Aura method for Converts a base64 string into a list of integers indicating at which position the bits are on
	 ***********************************************************************************************/

	public static List < Integer > convertBits(String b64Str) {
		List < Integer > lst = new List < Integer > ();
		try {
			List < Integer > lstOut = new List < Integer > ();
			if (b64Str == null || b64Str == '') {
				return lstOut;
			}
			List < Integer > lstBytes = convertB64ToBytes(b64Str);
			Integer i, b, v;
			for (i = 0; i < lstBytes.size(); i++) {
				v = lstBytes[i];
				for (b = 1; b <= 8; b++) {
					if ((v & 128) == 128) {
						lstOut.add((i * 8) + b);
					}
					v <<= 1;
				}
			}

			return lstOut;
		} catch (exception ex) {
			// SME_GlobalExceptionHandlerCtrl.processException('SME_UtilityCtrl', 'cnvBits', ex);
			return lst;
		}
	}



	/**********************************************************************************************
	 * Method Name:convertB64ToBytes
	 * Purpose: Aura method for Base64 to Bytes decoding
	 ***********************************************************************************************/
	//this method is used to Base64 to Bytes decoding
	public static List < Integer > convertB64ToBytes(String sIn) {
		List < Integer > lst = new List < Integer > ();
		try {
			Map < Integer, Integer > base64 = new Map < Integer, Integer > {
				65 => 0,
				66 => 1,
				67 => 2,
				68 => 3,
				69 => 4,
				70 => 5,
				71 => 6,
				72 => 7,
				73 => 8,
				74 => 9,
				75 => 10,
				76 => 11,
				77 => 12,
				78 => 13,
				79 => 14,
				80 => 15,
				81 => 16,
				82 => 17,
				83 => 18,
				84 => 19,
				85 => 20,
				86 => 21,
				87 => 22,
				88 => 23,
				89 => 24,
				90 => 25,
				97 => 26,
				98 => 27,
				99 => 28,
				100 => 29,
				101 => 30,
				102 => 31,
				103 => 32,
				104 => 33,
				105 => 34,
				106 => 35,
				107 => 36,
				108 => 37,
				109 => 38,
				110 => 39,
				111 => 40,
				112 => 41,
				113 => 42,
				114 => 43,
				115 => 44,
				116 => 45,
				117 => 46,
				118 => 47,
				119 => 48,
				120 => 49,
				121 => 50,
				122 => 51,
				48 => 52,
				49 => 53,
				50 => 54,
				51 => 55,
				52 => 56,
				53 => 57,
				54 => 58,
				55 => 59,
				56 => 60,
				57 => 61,
				43 => 62,
				47 => 63
			};
			List < Integer > lstOut = new List < Integer > ();
			if (sIn == null || sIn == '') {
				return lstOut;
			}
			sIn += '='.repeat(4 - Math.mod(sIn.length(), 4));
			for (Integer idx = 0; idx < sIn.length(); idx += 4) {
				if (base64.get(sIn.charAt(idx + 1)) != null) {
					lstOut.add((base64.get(sIn.charAt(idx)) << 2) | (base64.get(sIn.charAt(idx + 1)) >>> 4));
				}
				if (base64.get(sIn.charAt(idx + 2)) != null) {
					lstOut.add(((base64.get(sIn.charAt(idx + 1)) & 15) << 4) | (base64.get(sIn.charAt(idx + 2)) >>> 2));
				}
				if (base64.get(sIn.charAt(idx + 3)) != null) {
					lstOut.add(((base64.get(sIn.charAt(idx + 2)) & 3) << 6) | base64.get(sIn.charAt(idx + 3)));
				}
			}
			return lstOut;
		} catch (Exception ex) {
			// SME_GlobalExceptionHandlerCtrl.processException('SME_UtilityCtrl', 'convertB64ToBytes', ex);
			return lst;
		}
	} //B64ToBytes

}