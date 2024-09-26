trigger FinancialAccountFeeTrigger on FinancialAccountFee (after insert, after update, after delete, after undelete) {
    FinancialAccountFeeHandler.handleTrigger(Trigger.new, Trigger.old, Trigger.oldMap, Trigger.operationType);
}