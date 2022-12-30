public class UserTriggerHandler {
    public static void setUserForumGroupOnInsert(List<User> triggeredUsers){
        List<CollaborationGroupMember> groupMembers = new List<CollaborationGroupMember>(); 
        
        //INITIAL SET UP OF COLLABORATION GROUP MAP
        Map<String,CollaborationGroup> collaborationGroupByName = new Map<String,CollaborationGroup>();
        List<String> chatterGroupNames = new List<String>{'ANZ Announcements','ANZ Guidance','UK Announcements','UK Guidance','CAN Announcements','CAN Guidance'};
            
        //QUERY RELEVANT GROUP AND CREATE MAP
        List<CollaborationGroup> collaborationGroups = new List<CollaborationGroup>([SELECT ID, Name FROM collaborationGroup WHERE NAME IN: chatterGroupNames]);
        for(CollaborationGroup collabGroup : collaborationGroups){
            collaborationGroupByName.put(collabGroup.Name,collabGroup);
        }
            
        //CHECK ON FORUM GROUPS ENABLEMENT
        for(User userRecord : triggeredUsers){
            Boolean hasForum = false;
            if(userRecord.ANZ_Announcement__c){
                groupMembers.add(createGroupMember(collaborationGroupByName.get('ANZ Announcements').Id,userRecord.Id));
            }
            if(userRecord.ANZ_Guidance__c){
                groupMembers.add(createGroupMember(collaborationGroupByName.get('ANZ Guidance').Id,userRecord.Id));
            }
            if(userRecord.CAN_Announcement__c){
                groupMembers.add(createGroupMember(collaborationGroupByName.get('CAN Announcements').Id,userRecord.Id));
            }
            if(userRecord.CAN_Guidance__c){
                groupMembers.add(createGroupMember(collaborationGroupByName.get('CAN Guidance').Id,userRecord.Id));
            }
            if(userRecord.UK_Announcement__c){
                groupMembers.add(createGroupMember(collaborationGroupByName.get('UK Announcements').Id,userRecord.Id));
            }
            if(userRecord.UK_Guidance__c){
                groupMembers.add(createGroupMember(collaborationGroupByName.get('UK Guidance').Id,userRecord.Id));
            }
        }

        if(!groupMembers.isEmpty()){
			INSERT groupMembers;            
        }        
    }
    public static void setUserForumGroupOnUpdate(List<User> triggeredUsers, Map<Id,User> triggeredOldUserMap){
        List<CollaborationGroupMember> groupMembersForInsert = new List<CollaborationGroupMember>(); 
        List<CollaborationGroupMember> groupMembersForDelete = new List<CollaborationGroupMember>(); 
        
        Map<String,CollaborationGroup> collaborationGroupByName = new Map<String,CollaborationGroup>();
        Map<String,CollaborationGroupMember> collaborationGroupMemberByConcatString = new Map<String,CollaborationGroupMember>();
        
        List<String> chatterGroupNames = new List<String>{'ANZ Announcements','ANZ Guidance','UK Announcements','UK Guidance','CAN Announcements','CAN Guidance'};
            
        //QUERY RELEVANT GROUP AND CREATE MAP
        List<CollaborationGroup> collaborationGroups = new List<CollaborationGroup>([SELECT ID, Name FROM collaborationGroup WHERE NAME IN: chatterGroupNames]);
        for(CollaborationGroup collabGroup : collaborationGroups){
            collaborationGroupByName.put(collabGroup.Name,collabGroup);
        }
        
        //QUERY RELEVANT GROUP MEMBER RECORDS
        List<CollaborationGroupMember> collabGroupMembers = new List<CollaborationGroupMember>([SELECT Id, collaborationGroupId, MemberId FROM CollaborationGroupMember WHERE MemberId IN: triggeredUsers]);
        for(CollaborationGroupMember collabGroupMember : collabGroupMembers){
            collaborationGroupMemberByConcatString.put(collabGroupMember.MemberId+''+collabGroupMember.collaborationGroupId,collabGroupMember);
        }
        
        List<CollaborationGroupMember> groupMembers = new List<CollaborationGroupMember>([SELECT Id, CollaborationGroup.Name, MemberId FROM CollaborationGroupMember WHERE MemberId IN: triggeredUsers]);
        Map<Id,List<String>> userIdByCollabGroupName = new Map<Id,List<String>>();
        for(CollaborationGroupMember collabGroupMember : groupMembers){
            if(userIdByCollabGroupName.containsKey(collabGroupMember.MemberId)){
                userIdByCollabGroupName.get(collabGroupMember.MemberId).add(collabGroupMember.CollaborationGroup.Name);
            }else{
                userIdByCollabGroupName.put(collabGroupMember.MemberId, new List<String>{collabGroupMember.CollaborationGroup.Name});
            }
        }
        
        //CHECK ON FORUM GROUPS ENABLEMENT
        for(User userRecord : triggeredUsers){
            Boolean hasForum = false;
            if(userRecord.ANZ_Announcement__c != triggeredOldUserMap.get(userRecord.Id).ANZ_Announcement__c){
                if(userRecord.ANZ_Announcement__c && (!userIdByCollabGroupName.containsKey(userRecord.Id) || (userIdByCollabGroupName.containsKey(userRecord.Id) && !userIdByCollabGroupName.get(userRecord.Id).contains('ANZ Announcements'))) ){
                    groupMembersForInsert.add(createGroupMember(collaborationGroupByName.get('ANZ Announcements').Id,userRecord.Id));
                }else if(!userRecord.ANZ_Announcement__c){
                    if(collaborationGroupMemberByConcatString.containsKey(userRecord.Id+''+collaborationGroupByName.get('ANZ Announcements').Id)){
                        groupMembersForDelete.add(collaborationGroupMemberByConcatString.get(userRecord.Id+''+collaborationGroupByName.get('ANZ Announcements').Id));
                    }
                }
            }

            if(userRecord.ANZ_Guidance__c != triggeredOldUserMap.get(userRecord.Id).ANZ_Guidance__c){
                if(userRecord.ANZ_Guidance__c && (!userIdByCollabGroupName.containsKey(userRecord.Id) || (userIdByCollabGroupName.containsKey(userRecord.Id) && !userIdByCollabGroupName.get(userRecord.Id).contains('ANZ Guidance')))){
                    groupMembersForInsert.add(createGroupMember(collaborationGroupByName.get('ANZ Guidance').Id,userRecord.Id));
                }else if(!userRecord.ANZ_Guidance__c){
                    if(collaborationGroupMemberByConcatString.containsKey(userRecord.Id+''+collaborationGroupByName.get('ANZ Guidance').Id)){
                        groupMembersForDelete.add(collaborationGroupMemberByConcatString.get(userRecord.Id+''+collaborationGroupByName.get('ANZ Guidance').Id));
                    }
                }
            }
            if(userRecord.CAN_Announcement__c != triggeredOldUserMap.get(userRecord.Id).CAN_Announcement__c){
                if(userRecord.CAN_Announcement__c && (!userIdByCollabGroupName.containsKey(userRecord.Id) || (userIdByCollabGroupName.containsKey(userRecord.Id) && !userIdByCollabGroupName.get(userRecord.Id).contains('CAN Announcements')))){
                    groupMembersForInsert.add(createGroupMember(collaborationGroupByName.get('CAN Announcements').Id,userRecord.Id));
                }else if(!userRecord.CAN_Announcement__c){
                    if(collaborationGroupMemberByConcatString.containsKey(userRecord.Id+''+collaborationGroupByName.get('CAN Announcements').Id)){
                        groupMembersForDelete.add(collaborationGroupMemberByConcatString.get(userRecord.Id+''+collaborationGroupByName.get('CAN Announcements').Id));
                    }
                }
            }
            if(userRecord.CAN_Guidance__c != triggeredOldUserMap.get(userRecord.Id).CAN_Guidance__c){
                if(userRecord.CAN_Guidance__c && (!userIdByCollabGroupName.containsKey(userRecord.Id) || (userIdByCollabGroupName.containsKey(userRecord.Id) && !userIdByCollabGroupName.get(userRecord.Id).contains('CAN Guidance')))){
                    groupMembersForInsert.add(createGroupMember(collaborationGroupByName.get('CAN Guidance').Id,userRecord.Id));
                }else if(!userRecord.CAN_Guidance__c){
                    if(collaborationGroupMemberByConcatString.containsKey(userRecord.Id+''+collaborationGroupByName.get('CAN Guidance').Id)){
                        groupMembersForDelete.add(collaborationGroupMemberByConcatString.get(userRecord.Id+''+collaborationGroupByName.get('CAN Guidance').Id));
                    }
                }
            }
            if(userRecord.UK_Announcement__c != triggeredOldUserMap.get(userRecord.Id).UK_Announcement__c){
                if(userRecord.UK_Announcement__c && (!userIdByCollabGroupName.containsKey(userRecord.Id) || (userIdByCollabGroupName.containsKey(userRecord.Id) && !userIdByCollabGroupName.get(userRecord.Id).contains('UK Announcements')))){
                    groupMembersForInsert.add(createGroupMember(collaborationGroupByName.get('UK Announcements').Id,userRecord.Id));
                }else if(!userRecord.UK_Announcement__c){
                    if(collaborationGroupMemberByConcatString.containsKey(userRecord.Id+''+collaborationGroupByName.get('UK Announcements').Id)){
                        groupMembersForDelete.add(collaborationGroupMemberByConcatString.get(userRecord.Id+''+collaborationGroupByName.get('UK Announcements').Id));
                    }
                }
            }
            if(userRecord.UK_Guidance__c != triggeredOldUserMap.get(userRecord.Id).UK_Guidance__c){
                if(userRecord.UK_Guidance__c && (!userIdByCollabGroupName.containsKey(userRecord.Id) || (userIdByCollabGroupName.containsKey(userRecord.Id) && !userIdByCollabGroupName.get(userRecord.Id).contains('UK Guidance')))){
                    groupMembersForInsert.add(createGroupMember(collaborationGroupByName.get('UK Guidance').Id,userRecord.Id));
                }else if(!userRecord.UK_Guidance__c){
                    if(collaborationGroupMemberByConcatString.containsKey(userRecord.Id+''+collaborationGroupByName.get('UK Guidance').Id)){
                        groupMembersForDelete.add(collaborationGroupMemberByConcatString.get(userRecord.Id+''+collaborationGroupByName.get('UK Guidance').Id));
                    }
                }
            }
        }
        if(!groupMembersForDelete.isEmpty()){
            DELETE groupMembersForDelete;
        }
        if(!groupMembersForInsert.isEmpty()){
            INSERT groupMembersForInsert;            
        }        
    }
    
    private static CollaborationGroupMember createGroupMember(Id collaborationGroupId, Id userId){
        CollaborationGroupMember member = new CollaborationGroupMember();
        member.MemberId = userId ;
        member.CollaborationGroupId = collaborationGroupId;
        member.NotificationFrequency = 'P';
        return member;
    }
}