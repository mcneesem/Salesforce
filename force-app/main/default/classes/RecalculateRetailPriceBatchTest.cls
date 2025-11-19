@isTest private class RecalculateRetailPriceBatchTest {

    @testSetup private static void createTestData(){
        RecalculateRetailPriceBatchSettings__c sett = new RecalculateRetailPriceBatchSettings__c();
        sett.isEnabled__c = true;
        sett.BatchSize__c = 100;
        sett.MonitorEmailAddresses__c = 'xyz@invalid.com';
        insert sett;
        
        Account objaccount = NSP_TestHelper.createAccount(true);
        
        Asset astObj = new Asset();
        astObj.Name = 'testAsset';
        astObj.AccountId = objAccount.id;
        insert astObj;
        
        List<Product2> prodList = new List<Product2>();
        
        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);
        objproduct.NSP_Is_Bundle__c = true;
        objproduct.ProductCode = 'xyz';
        prodList.add(objproduct);
        
        Product2 objproductChild = NSP_TestHelper.createProduct('Child Product',false);
        objproductChild.NSP_Is_Bundle__c = false;
        objproductChild.ProductCode = 'Child';
        objproductChild.Roll_Up_Bundle__c = 'xyz';
        prodList.add(objproductChild);
        
        Product2 objproductalone = NSP_TestHelper.createProduct('Alone Product',false);
        objproductalone.NSP_Is_Bundle__c = false;
        objproductalone.ProductCode = 'Alone';
        prodList.add(objproductalone);
        
        insert prodList;
        
        List<Purchased_Product__c> purList = new List<Purchased_PRoduct__c>();
        
        Purchased_Product__c prod = new Purchased_Product__c();
        prod.Asset__c = astObj.id;
        prod.Product__c = objproduct.id;
        prod.Component_Price__c = 10;
        prod.Purchase_Status__c = 'Purchased';
        purList.add(prod);

        Purchased_Product__c prodChild = new Purchased_Product__c();
        prodChild.Asset__c = astObj.id;
        prodChild.Product__c = objproductChild.id;
        prodChild.Component_Price__c = 1;
        prodChild.Purchase_Status__c = 'Purchased';
		purList.add(prodChild);
        
        Purchased_Product__c prodAlone = new Purchased_Product__c();
        prodAlone.Asset__c = astObj.id;
        prodAlone.Product__c = objproductalone.id;
        prodAlone.Component_Price__c = 5;
        prodAlone.Purchase_Status__c = 'Purchased';
		purList.add(prodAlone);
        
        insert(purList);
        
        Purchased_Product__History history = new Purchased_Product__History();
        history.ParentId = prod.id;
        history.Field = 'Component_Price__c';
        insert history;
    }
    
    @isTest private static void recalculateTest(){
        Test.startTest();
        RecalculateRetailPriceBatch.executeBatch();
        Test.stopTest();
        
        List<Purchased_Product__c> products = [SELECT Retail_Price__c FROM Purchased_Product__c WHERE Product__r.ProductCode = 'xyz'];
        system.assertEquals(products[0].Retail_Price__c,11);
    }
    
    @isTest private static void schedulableTest(){
        Test.startTest();
        RecalculateRetailPriceBatch.schedule();
        Test.stopTest();
    }
}