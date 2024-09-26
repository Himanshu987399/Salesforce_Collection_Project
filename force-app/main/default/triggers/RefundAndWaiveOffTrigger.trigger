/**
* @author       TechMatrix Team
* @description Trigger for Refund_and_Waive_off_Request__c object.
* This trigger ensures that comments are mandatory when approving or rejecting
* Refund and Waive-off Requests.
*/
trigger RefundAndWaiveOffTrigger on Refund_and_Waive_off_Request__c (before update) {
    RefundAndWaiveOffHandler.OnBeforeUpdate(trigger.New ,trigger.Old,Trigger.NewMap,Trigger.OldMap);   
}