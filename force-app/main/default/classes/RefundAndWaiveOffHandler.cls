/**
 * @author       TechMatrix Team
 * @description Refund And Waive Off Handler.
 */
public with Sharing class RefundAndWaiveOffHandler {
     /**
     * @description Ensure Comment mendatory for Approval proccess.
     * 
     * @param newRefundWaiveOff List of refund and waive off new 
     * @param oldRefundWaiveOff List of refund and waive off old
     * @param newMapRefundWaiveOff Map of refund and waive off new
     * @param oldMapRefundWaiveOff Map of refund and waive off old
     */
	public static void onBeforeUpdate( List<Refund_and_Waive_off_Request__c> newRefundWaiveOff, List<Refund_and_Waive_off_Request__c> oldRefundWaiveOff, Map<ID, Refund_and_Waive_off_Request__c> newMapRefundWaiveOff , Map<ID, Refund_and_Waive_off_Request__c> oldMapRefundWaiveOff )
    {
        ApprovalProcessComment.ensureCommentOnApprovalChange(
            newRefundWaiveOff,
            oldMapRefundWaiveOff,
            'Approval_Status__c',
            'Approved',
            'Rejected',
            newMapRefundWaiveOff
        );
    }
}