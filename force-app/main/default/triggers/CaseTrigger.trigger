/**
* @author       TechMatrix Team
* @description Trigger for the Case object handling before update events.
* This trigger ensures that comments are mandatory for specific approval processes.
*/
trigger CaseTrigger on Case (before update) {
    CaseTriggerHandler.onBeforeUpdate(trigger.New ,trigger.Old,Trigger.NewMap,Trigger.OldMap); 
    
    // Call the future method
    
}