trigger UserTrigger on User (after insert, after update) {
    if(trigger.isAfter){
        if(trigger.isInsert){
            UserTriggerHandler.setUserForumGroupOnInsert(trigger.new);
        }else if(trigger.isUpdate){
            UserTriggerHandler.setUserForumGroupOnUpdate(trigger.new,trigger.oldMap);
        }
    }
}