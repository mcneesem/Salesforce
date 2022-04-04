/**
 * Represents the Enrollment Fee Payment trigger.
 */
trigger EnrollmentFeePaymentTrigger on NSP_Enrollment_Fee_Payment__c (after insert, after update, after delete, after undelete) {
    if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate || trigger.isUndelete)){
        RollUpEnrollmentFeePayment.sumofEnrollmentFee(trigger.new);
    }  else if(trigger.isAfter && trigger.isDelete){
        RollUpEnrollmentFeePayment.sumofEnrollmentFee(trigger.old);
    }

}