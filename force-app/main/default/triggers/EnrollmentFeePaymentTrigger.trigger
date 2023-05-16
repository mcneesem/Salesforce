/**
 * Represents the Enrollment Fee Payment trigger.
 */
trigger EnrollmentFeePaymentTrigger on NSP_Enrollment_Fee_Payment__c (before insert, after insert, after update, after delete, after undelete) {
    if(trigger.isBefore && trigger.isInsert){
        NSP_EnrollmentFeePaymentTriggerClass.enrollmentFeeMidMarket(trigger.new);
    }
    else if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate || trigger.isUndelete)){
        NSP_EnrollmentFeePaymentTriggerClass.sumofEnrollmentFee(trigger.new);
        NSP_EnrollmentFeePaymentSharing.onEfpRecordInsert(trigger.new);
    }  else if(trigger.isAfter && trigger.isDelete){
        NSP_EnrollmentFeePaymentTriggerClass.sumofEnrollmentFee(trigger.old);
    }
     

}