public class NSP_UpdateAsset {
    // test w/ NSP_AssetUpdateTest (100%)

    // @MethodName: updateAssets
    // @Description: This method is invoked from flow to update assets after 60sec of insert operation
    // @param :List<Asset> records
    // @return void
    @InvocableMethod(label='Update Assets' description='Updates asset with Unique Parent Id' category= 'Asset')
    public static void updateAssets(List<Asset> records) {
        list<asset> asstList = new list<asset>();
        Id WXWAAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset','NSP_Asset_Product');
        Date currDate = System.Date.today();
        Date monthStartDate = System.Date.today().toStartOfMonth();
        Date monthEndDate = monthStartDate.addMonths(1);
        Integer month = currDate.month();
        Integer year = currDate.year();
        Integer lastUniqueNumber = 0;
        List<Asset> lastWXWAAsset = [
            SELECT Id , NSP_WX_WA_Parent_ID__c , NSP_WX_WA_ParentId_Store_Internal__c , CreatedDate
            FROM Asset
            WHERE (
                NSP_WX_WA_ParentId_Store_Internal__c != null
                AND RecordTypeId = :WXWAAssetRecordTypeId
                AND CreatedDate >= :monthStartDate
                AND CreatedDate < :monthEndDate
            )
            ORDER BY NSP_WX_WA_ParentId_Store_Internal__c DESC
            LIMIT 1
        ];
        if(lastWXWAAsset.size()>0) {
            lastUniqueNumber = (Integer)lastWXWAAsset[0].NSP_WX_WA_ParentId_Store_Internal__c;
        }
        // STY-02728 code ends
        for(Asset assetObj : records) {
            // Added for STY-02728 
            if(assetObj.recordTypeId == WXWAAssetRecordTypeId ) {
                lastUniqueNumber += 1;
                String yearstr = String.valueOf(year);
                yearstr = yearstr.substring(2, 4);
                String monthstr = String.valueOf(month).leftPad(2, '0');
                String lpUniqNumber = String.valueOf(lastUniqueNumber).leftPad(3, '0');
                String finalIdString = yearstr+monthstr+lpUniqNumber;
                // assigning value to fields
                assetObj.NSP_WX_WA_ParentId_Store_Internal__c = lastUniqueNumber;
                assetObj.NSP_WX_WA_Parent_ID__c = finalIdString;
                asstList.add(new Asset(Id=assetObj.Id ,NSP_WX_WA_ParentId_Store_Internal__c=lastUniqueNumber,NSP_WX_WA_Parent_ID__c=finalIdString));
            }
            // STY-02728 code ends
        }
        update asstList;
    }

}
//