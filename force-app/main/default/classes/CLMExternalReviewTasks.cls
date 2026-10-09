global with sharing class CLMExternalReviewTasks {
    // test w/ SpringCMTests (??%)

    global CLMUser Sender { get; set; }

    global CLMDocumentItems Documents { get; set; }

    global Recipient Recipient { get; set; }

    global AlsoNotify[] AlsoNotify { get; set; }

    global String Status { get; set; }

    global String DueDate { get; set; }

    global String EmailSubject { get; set; }

    global String EmailMessage { get; set; }

    global String Comment { get; set; }

    global Boolean AddSignature { get; set; }

    global String Href { get; set; }

    global class Recipient {
        global String Name { get; set; }

        global String Email { get; set; }
    }

    global class AlsoNotify {
        global String Name { get; set; }

        global String Email { get; set; }
    }

}
//