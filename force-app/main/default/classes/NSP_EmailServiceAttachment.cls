public class NSP_EmailServiceAttachment {
    
    /***********************************************************************************************
    * MethodName: getProjectAttachments
    * Description : This method retreive the completed attachments for project tasks
    * Params:      String recordId
    * ********************************************************************************************/
    public static  List<Messaging.EmailFileAttachment> getProjectTaskAttachments(String recordId){
    List<ContentDocumentLink> contentdocLinkList= [SELECT Id , ContentDocumentId FROM  
                                                   ContentDocumentLink WHERE LinkedEntityId=:recordId ORDER BY SystemModstamp ASC ];
    Set<Id> contentDocumentIds = new Set<Id>();
    //iterating through the files
    for(ContentDocumentLink cdl:contentdocLinkList){
        contentDocumentIds.add(cdl.ContentDocumentId);
    }
    //List of files based on the ID's fetched from above
    List<ContentVersion> contentversionList=[SELECT Id, Title, FileType,versiondata  FROM contentversion
                                             WHERE ContentDocumentId IN: contentDocumentIds ];
    //list of email attachments
    List<Messaging.EmailFileAttachment> emailattachments = new List<Messaging.EmailFileAttachment>();
    //setting file name and body
    if(!contentversionList.isEmpty()){
        for(ContentVersion contentversions:contentversionList){
               Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment(); 
               Blob Data = contentversions.VersionData;
               String fileType;
               if(contentversions.FileType=='EXCEL_X'){
                fileType ='xlsx';
                }else if(contentversions.FileType=='POWER_POINT_X'){
                    fileType ='pptx';
                }else if(contentversions.FileType=='WORD_X'){
                    fileType ='docx';
                }else{
                    fileType =contentversions.FileType;
                }
               String AttachmentFileName=contentversions.Title+'.'+fileType;
               efa.setFileName(AttachmentFileName);
               efa.setBody(Data);
               emailattachments.add(efa);  
        } 
    }
    
    return emailattachments;
    }
    
    /***********************************************************************************************
    * MethodName: getProjectAttachments
    * Description : This method retreive the completed attachments for project tasks
    * Params:      Set<Id>taskIdSet
    * ********************************************************************************************/
    public static  Map<Id,List<Messaging.EmailFileAttachment>> getProjectTaskAttachments(Set<Id>taskIdSet){
        Map<Id,List<Messaging.EmailFileAttachment>> mapTaskIdListAttachments = new  Map<Id,List<Messaging.EmailFileAttachment>>();
        Map<Id,Id> mapConDocIdTaskId = new  Map<Id,Id>(); 
        List<ContentDocumentLink> contentdocLinkList= [SELECT Id ,LinkedEntityId, ContentDocumentId FROM  
                                                       ContentDocumentLink WHERE LinkedEntityId IN:taskIdSet ORDER BY SystemModstamp ASC ];
        //mapping the files 
        for(ContentDocumentLink cdl:contentdocLinkList){
            mapConDocIdTaskId.put(cdl.ContentDocumentId,cdl.LinkedEntityId);
        }
        //fetching the list of files, from the ID's in the above map
        List<ContentVersion> contentversionList=[SELECT Id,ContentDocumentId, Title, FileType,versiondata  FROM contentversion
                                                 WHERE ContentDocumentId IN: mapConDocIdTaskId.KeySet() ];
        //adding the files to the map created
        if(!contentversionList.isEmpty()){
            for(ContentVersion contentversions:contentversionList){
                   Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment(); 
                   Blob Data = contentversions.VersionData;
                   String fileType;
                   if(contentversions.FileType=='EXCEL_X'){
                    fileType ='xlsx';
                    }else if(contentversions.FileType=='POWER_POINT_X'){
                        fileType ='pptx';
                    }else if(contentversions.FileType=='WORD_X'){
                        fileType ='docx';
                    }else{
                        fileType =contentversions.FileType;
                    }
                   String AttachmentFileName=contentversions.Title+'.'+fileType;
                   efa.setFileName(AttachmentFileName);
                   efa.setBody(Data);  
                if(!mapTaskIdListAttachments.containsKey(mapConDocIdTaskId.get(contentversions.ContentDocumentId))){
                    mapTaskIdListAttachments.put(mapConDocIdTaskId.get(contentversions.ContentDocumentId), new List<Messaging.EmailFileAttachment>() );
                }
                mapTaskIdListAttachments.get(mapConDocIdTaskId.get(contentversions.ContentDocumentId)).add(efa);
            } 
        }    
        return mapTaskIdListAttachments;
        }
}