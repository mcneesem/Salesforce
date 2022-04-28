/**
 * Represents the Enrollment Fee Payment trigger.
 */
trigger EnrollmentFeePaymentTrigger on NSP_Enrollment_Fee_Payment__c (after insert, after update, after delete, after undelete) {
    if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate || trigger.isUndelete)){
        NSP_EnrollmentFeePaymentTriggerClass.sumofEnrollmentFee(trigger.new);
    }  else if(trigger.isAfter && trigger.isDelete){
        NSP_EnrollmentFeePaymentTriggerClass.sumofEnrollmentFee(trigger.old);
    }

}