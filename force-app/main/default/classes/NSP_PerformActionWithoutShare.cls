public without sharing class NSP_PerformActionWithoutShare {
    private NSP_PerformActionWithoutShare(){
        //private constructor
    }
    public static List<Sobject> queryWithoutShare(String Query, Set<Id> sIds){
        String getQuery = String.escapeSingleQuotes(Query);
        return Database.query(getQuery);
    }
    public static void insertWithoutShare(List<Sobject> lSobjects){
        // Added Test.isRunningTest to by pass insertion of survey subject share records during insertion in test class
        if(!Test.isRunningTest()){
        insert lSobjects;
        }
    }
}
