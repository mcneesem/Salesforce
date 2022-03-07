//
// This code is provided as an example only, no warranty is expressed or implied. If you choose to use 
// any or all of this sample code, you agree to assume all risk and liability associated with that use.
//

public with sharing class CLMDocumentTransfer {

    public CLMDocumentTransfer() {

        //
        // Setup CLM.DS authentication - will need to modified for CLM.CM
        //
        DSAPIUserAuthenticator auth = new DSAPIUserAuthenticator(dsAccountId,iss,aud,sub,pkey,dataCenter,version);
        
        this.authenticator = auth;
        this.svc = new SpringCMService(authenticator);
    }

    //
    // Authentication variables for CLM.DS - will need to be modified for CLM.CM
    //
    //String dsAccountId = '951f9e95-35fd-4856-90e3-645d99a0026e';   //App Account API Id
    String dsAccountId = 'e22ffda7-6a07-476c-89df-175b2404dd77';   //App Account API Id [QA]
    //String dsAccountId = '07bae8e0-f4aa-4b36-8886-efa661e3e9b0';   //App Account API Id [Dev]
    String iss = 'e68d1b70-c724-41ec-b907-4e3592da6ad8';    // Integration Key
    // String aud = 'account.docusign.com'; // prod
    //String aud = 'demo.docusign.net'; // demo / uat
    String aud = 'account-d.docusign.com'; // demo / uat
    String sub = '10b401b6-e048-4b46-8dc9-439c6e24bebe';    // User ID
    String pkey = 'MIIEowIBAAKCAQEA2yOU2xdQenrWJh34eZE3aQYtNytgFlVi4teh40qufwPoFSgY0UZbNoy4ID3V3qUWV8tDfJVQdwfSipGkzl6E857a9hXqicXwY/8FuKqN4ittNBGU0lqszDHFhSX/3DMBrOs1qSXlDaaIqK8yFJtH+0Er6oQq0oWmqnyc+ZOynXBe6cKUHAFhg0SLbRhZNMG2qF6pZHaqM7N03PESo8lXJfUCVdp70PGgNCdCuRzCcEIdUXwt3riBrQdgpFZeAF/EU/rxGZiXZE44KjqVgiMuMmo8JR7nFrzNOJuAS9CgUvg8JDtKhAJJoyZuRFkUdjECeQHEKgu7AIdtU9WdLPFL+QIDAQABAoIBABSJHZJ4eVi4+SeCSH4v7xbe9s7EOFFveABU/706iuapOY79/nFiG/sdLcYLtWaTZugcSrs6jNtStta4dk7GicQAv3kvLZbynyfnxqP7C6fFtQqbmSwrRiUuhtmG6Za7iu0m75Tl0bS5RfY00McglBrGDTUBZLfswWUZn2Y+Ao+BQ11uML9s1eSkyv71y32jC5dOOSUnjUdZ4jDwFz7FXjA6f755f5EizBrTnzjvq5z17ctXcLvlq39IOfU8mFjK655HNLv/kqBoLVYdVOL28idS2BcsoJAfo7b2cY7ZRJDybAbgw3tmuLnYUzdZWhQIorF3k5W3qX8oUytEvcLXoGcCgYEA9vnI2EihtM0OtxpjkP1Y4+llRuKK5fq9rXr6vt5J5q2Ew4rcX0JRzd3bAR6Y7Il2TRhYS6K55UDH16hXOYD3Hfrw9Lffg4d9eoT/1H+m+jGdWU3CorZf7XhhLpMK2qsgxIWH1RiMkJrTtXP6NI01A8w225xqFo1rBz7qqw+MjLMCgYEA4yVpYDiZVKftBeqBfhBptb2LN47AVb58n6UPpHS10Twn946FOjBHcTrcUBYR2YBwtANRG3kF/lGftcZjqL5hsT1jpZaAofvWEPAgw5+ZBb5wqiaXiAS71gjK2zlPr5iWARR8oTOYZfRKwf94Y1flRI2kyVyUkM2nu8eD1w8EcqMCgYBEMstsNfo5Q9qJY0cVNXBDVyK5RTtXsDqKWgg9hoJfqZCcso6R221dbKLaF0nhH0BEn7FaCXBNxuqoOXsEjQEwDShWWyPkXRigKXO/iRRhyCuMCnXxmmy41WH4i3AW2+Rrf/f3NxUxpR9K3uC7fDaketK3J+T/n0Nrt8rzO5LzEwKBgAKKX5RY7bYZrrf7OHmNe3Ex7oWvjg0ndUNf2D3xpDrz3kqRiIHvGk106BPpO0fgfOI2i0iwYNXIWe3xixnPD06pLh0jAstNAsbruKIXfeGnkKEGj3lQ/DzXmlU7Xd3L6hmW/hHbft/dDJ0A23rY99J9dxNderfn5PFfuOTF4TnbAoGBAMZyiHTC9dgSksgJx2JyZrJ1CO1+j1+hVHXqmUVFy+w7uWE7xE1btXDil1VrNWEV/bQSsUCYnpAIvx0/C+J5RZKUCRXiCex+c49SgWoU47WrDrnW+Xu/mfxF+bgpOfi9y5/YnDmR1avwBMI4YfYn5gKq2hSg8OMeWJZNTJW1R8+O';  // Secret key
    // String dataCenter = 'na11';
    // String dataCenter = 'na21';
    // String dataCenter = 'us11';
    // String dataCenter = 'us211';
    String dataCenter = 'uatna11';
    String version = 'v2';

    //
    // Authentication and Service variables
    //
    SpringCMIAuthenticator authenticator;
    SpringCMService svc;

    public void downloadDocumentById(String clmDocId, String sfdcLinkedEntityId){

        //
        // Need the filename, so get the document information
        //
        //CLMDocument docInfo = new CLMDocument();
        CLMDocument docInfo = svc.GetDocumentById(clmDocId).getDocument();
        System.assert(docInfo != null);
        
        //
        // Download the document contents into a Blob
        //
        Blob docBlob = svc.GetDocumentById(clmDocId).downloadDocument('');
        System.assert(docBlob != null);
        
        //
        // Create a ContentVersion record with the filename and the document contents (Blob)
        //
        ContentVersion cv = new ContentVersion();
        cv.VersionData = docBlob;
        cv.Title = docInfo.Name;
        cv.PathOnClient = docInfo.Name;

        insert cv;

        //
        // Get the ContentDocumentId
        //
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];


        //
        // Create a ContentDocumentLink record to relate the document to the target record
        //
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = sfdcLinkedEntityId;
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.shareType = 'I';

        insert cdl;
    }

    @future (callout=true)
    public static void downloadDocument(String clmDocId, String sfdcLinkedEntityId) {
        CLMDocumentTransfer cdt = new CLMDocumentTransfer();
        cdt.downloadDocumentById(clmDocId, sfdcLinkedEntityId);
    }
}