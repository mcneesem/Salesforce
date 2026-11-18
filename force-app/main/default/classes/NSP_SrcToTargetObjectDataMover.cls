/* **************************************************************************************************   
Component Name :  NSP_SrcToTargetObjectDataMover class
Version              :  1.0                                                                          
Created Date         :  October 10, 2021                                                             
Function             :  This class is used as for Src to Target Data Mover 	
Story                :                                                                             
Modification Log     :                                                                               
*	Utpal           October 10, 2021          First Iteration
*
***************************************************************************************************
*/
public class NSP_SrcToTargetObjectDataMover {
    // test w/ NSP_SrcToTargetObjectDataMoverTest (83%)

    public static List<NSP_SourceToTargetObject__mdt> mdtMappingList;
    public static List<SObject> sobjectSourceList;
     //Constructor
     public NSP_SrcToTargetObjectDataMover(List<SObject> sobjectSrcList ,String customMDTLogicalGrp){
       
       sobjectSourceList=sobjectSrcList;
       List<NSP_SourceToTargetObject__mdt> mappings=[SELECT Id,SourceField__r.QualifiedApiName,SourceObject__r.QualifiedApiName,
                                        TargetField__r.QualifiedApiName,TargetObject__r.QualifiedApiName FROM NSP_SourceToTargetObject__mdt WHERE  LogicalGroup__c = :customMDTLogicalGrp ];//
       mdtMappingList = mappings;
      
     }
        
     
     /**
        * It will fetch Opportunity Data.
        * @param  Opportunity Quote Mapping,Opportunity record
        * @return      Quote
        * @Author Utpal Utkalit
        * @Since Nov 18, 2020
        */
       public static List<SObject> getSourceDatainTarget( List<SObject> sobjectSourceList){       
        
        List<SObject> returnObjectList=new List<SObject>();
       
        for(SObject srcobj:sobjectSourceList ){
        	sObject genericObject = Schema.getGlobalDescribe().get(mdtMappingList[0].TargetObject__r.QualifiedApiName).newSObject();
            for(NSP_SourceToTargetObject__mdt mdtMapping : mdtMappingList){
                if(String.isNotBlank(mdtMapping.TargetObject__r.QualifiedApiName) 
                   && String.isNotBlank(mdtMapping.SourceObject__r.QualifiedApiName)){
                       genericObject.put(mdtMapping.TargetField__r.QualifiedApiName, srcobj.get(mdtMapping.SourceField__r.QualifiedApiName)); 
                   }
            }
            returnObjectList.add(genericObject);
        }
		return returnObjectList;
    }
    
          
            /**
        * It will construct Quote Query.
        * @param  Quote Contract Mapping,quote record id
        * @return      String
        * @Author Utpal Utkalit
        * @Since Nov 18, 2020
        */
        public static String constructSourceQuery(List<String> fieldsToQueryList, Map<String,String> filterMap){       
            Set<String> fieldsToQuerySet = new Set<String>();
            for(NSP_SourceToTargetObject__mdt mdtMapping : mdtMappingList){
                if(String.isNotBlank(mdtMapping.SourceField__r.QualifiedApiName)){
                    fieldsToQuerySet.add(mdtMapping.SourceField__r.QualifiedApiName);    
                }
            }
            if(fieldsToQueryList == null){
                fieldsToQueryList = new List<String>(fieldsToQuerySet);
            }
            // fields need to set the default value and record type on quote
                    String objectToQuery = '';
            for(NSP_SourceToTargetObject__mdt mdtMapping: mdtMappingList){
                if(mdtMapping.SourceObject__c != null){
                    objectToQuery = mdtMapping.SourceObject__r.QualifiedApiName;
                    break;
                }
            }
           //Map<String, String> filterMap = new Map<String,String>{ idConatiningField => recordId};
                String query = getQuery(fieldsToQueryList,objectToQuery,filterMap,null);
            return query;
        }
        
        public static String sanitize(String value){
        return String.isBlank(value) ? 'null' :
            '\'' + String.escapeSingleQuotes(value) + '\'';
    }
       
        /**
        * It will form the query.
        * @param  fieldsToQueryList,objectToQuery,filterMap,range
        * @return      String
        * @Author Pallavi Joshi
        * @Since Nov 18, 2020
        */
         public static String getQuery(List<String> fieldsToQueryList, String objectToQuery, Map<String, String> filterMap, Integer range){
            //query construction
            String fieldsToQuery = String.join(fieldsToQueryList, ',');
            String query = 'SELECT '+fieldsToQuery+' FROM '+ objectToQuery;
            String filter = '';
            if(!filterMap.isEmpty()){
                Integer size=filterMap.keySet().size();
                for(String key : filterMap.keySet()){
                    String mapValue=filterMap.get(key);
                    if(mapValue.contains(',')){
                        List<String> values= mapValue.split(',');
                        mapValue='';
                        Integer vsize=values.size();
                        for(String str:values){
                            mapValue += '\'' + String.escapeSingleQuotes(str) + '\'';
                             if(vsize >1){
                               mapValue += ' , ' ;
                                vsize--;
                            }
                        }
                       filter += String.escapeSingleQuotes(key) + ' IN ( ' +mapValue + ')';  
                    } else{
                        //Boolean b = Boolean.valueOf('true');
                        String value=String.escapeSingleQuotes(filterMap.get(key));
                        String filtervalue =  Boolean.valueOf(value) ? ' = ' +Boolean.valueOf(value) : ' =\'' +value + '\' ';
                            filter += String.escapeSingleQuotes(key) + filtervalue; 
                    }
                    if(size >1){
                       filter += ' AND ' ;
                        size--;
                    }
                    
                }
            }
            
            if(String.isNotBlank(filter)){
                query += ' WHERE ' + filter;
            }
            if(range != null){
                query += ' LIMIT ' + range;
            }
            return query;
        } 
}