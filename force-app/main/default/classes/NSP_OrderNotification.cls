/**
* @description  : controller class for Order Notification visualforce component to display order products
* @author Raksha
* @date 21/09/2021
* Name : NSP_OrderNotification
*/

public class NSP_OrderNotification {

    public String orderIdstr{get;set;}

    public NSP_OrderNotification() {
       
    }

/**
* Method Name : getProductBundleList 
* Description : Method to query order bundle products records which will be displayed on order creation notification
* @return List  
*/ 

    public list<String> getProductBundleList() {
        list<String> quotelinelist =  new list<String>();
        for(OrderItem eachLine : [Select Id,Product2.Name
                                                        from OrderItem WHERE OrderId =:orderIdstr AND NSP_Is_Bundle__c = true ]) {
             quotelinelist.add(eachLine.Product2.Name);
           } 
          
        return quotelinelist;
    }

}