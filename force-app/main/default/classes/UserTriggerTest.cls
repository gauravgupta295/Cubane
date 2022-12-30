@isTest
public class UserTriggerTest {
    @testSetup
    static void testDataSetup(){
        List<String> chatterGroupNames = new List<String>{'ANZ Announcements','ANZ Guidance','UK Announcements','UK Guidance','CAN Announcements','CAN Guidance'};
        List<CollaborationGroup> groups = new List<CollaborationGroup>();
        for(String groupName : chatterGroupNames){
            CollaborationGroup myGroup = new CollaborationGroup();
            myGroup.Name=groupName;
            myGroup.CollaborationType='Private'; //can be 'Public' or 'Private'  
            groups.add(myGroup);
        }
               
        insert groups;
    }
    
	@isTest
    static void createAndUpdateANZPMCommunityUser(){
        User u = new User(Alias = 'sd', Email='test@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].get(0).Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='ser@testorg.com', Region__c = 'ANZ', ANZ_Announcement__c = true, ANZ_Guidance__c = true);
        test.startTest();
        insert u;
        List<CollaborationGroupMember> collabGroupMembers = new List<CollaborationGroupMember>([SELECT Id FROM CollaborationGroupMember WHERE memberId =: u.Id]);
        System.assertEquals(2, collabGroupMembers.size());

        
        u.ANZ_Announcement__c = false;
        update u;
        List<CollaborationGroupMember> collabGroupMembers1 = new List<CollaborationGroupMember>([SELECT Id FROM CollaborationGroupMember WHERE memberId =: u.Id]);
        System.assertEquals(1, collabGroupMembers1.size());
        
        u.ANZ_Guidance__c = false;
        update u;
        List<CollaborationGroupMember> collabGroupMembers2 = new List<CollaborationGroupMember>([SELECT Id FROM CollaborationGroupMember WHERE memberId =: u.Id]);
        System.assertEquals(0, collabGroupMembers2.size());
        
        u.ANZ_Announcement__c = true;
        update u;
        List<CollaborationGroupMember> collabGroupMembers3 = new List<CollaborationGroupMember>([SELECT Id FROM CollaborationGroupMember WHERE memberId =: u.Id]);
        System.assertEquals(1, collabGroupMembers3.size());
        
        u.ANZ_Guidance__c = true;
        update u;
        List<CollaborationGroupMember> collabGroupMembers4 = new List<CollaborationGroupMember>([SELECT Id FROM CollaborationGroupMember WHERE memberId =: u.Id]);
        System.assertEquals(2, collabGroupMembers4.size());
        test.stopTest();

        

    }
    
	@isTest
    static void createAndUpdateCANPMCommunityUser(){
        User u = new User(Alias = 'sd', Email='test@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].get(0).Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='ser@testorg.com', Region__c = 'CAN', CAN_Announcement__c = true, CAN_Guidance__c = true);
        test.startTest();
        insert u;
        List<CollaborationGroupMember> collabGroupMembers = new List<CollaborationGroupMember>([SELECT Id FROM CollaborationGroupMember WHERE memberId =: u.Id]);
        System.assertEquals(2, collabGroupMembers.size());

        
        u.CAN_Announcement__c = false;
        update u;
        List<CollaborationGroupMember> collabGroupMembers1 = new List<CollaborationGroupMember>([SELECT Id FROM CollaborationGroupMember WHERE memberId =: u.Id]);
        System.assertEquals(1, collabGroupMembers1.size());
        
        u.CAN_Guidance__c = false;
        update u;
        List<CollaborationGroupMember> collabGroupMembers2 = new List<CollaborationGroupMember>([SELECT Id FROM CollaborationGroupMember WHERE memberId =: u.Id]);
        System.assertEquals(0, collabGroupMembers2.size());
        
        u.CAN_Announcement__c = true;
        update u;
        List<CollaborationGroupMember> collabGroupMembers3 = new List<CollaborationGroupMember>([SELECT Id FROM CollaborationGroupMember WHERE memberId =: u.Id]);
        System.assertEquals(1, collabGroupMembers3.size());
        
        u.CAN_Guidance__c = true;
        update u;
        List<CollaborationGroupMember> collabGroupMembers4 = new List<CollaborationGroupMember>([SELECT Id FROM CollaborationGroupMember WHERE memberId =: u.Id]);
        System.assertEquals(2, collabGroupMembers4.size());
        test.stopTest();

    }
    
	@isTest
    static void createAndUpdateUKPMCommunityUser(){
        User u = new User(Alias = 'sd', Email='test@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].get(0).Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='ser@testorg.com', Region__c = 'UK', UK_Announcement__c = true, UK_Guidance__c = true);

        test.startTest();
        insert u;
        List<CollaborationGroupMember> collabGroupMembers = new List<CollaborationGroupMember>([SELECT Id FROM CollaborationGroupMember WHERE memberId =: u.Id]);
        System.assertEquals(2, collabGroupMembers.size());

        
        u.UK_Announcement__c = false;
        update u;
        List<CollaborationGroupMember> collabGroupMembers1 = new List<CollaborationGroupMember>([SELECT Id FROM CollaborationGroupMember WHERE memberId =: u.Id]);
        System.assertEquals(1, collabGroupMembers1.size());
        
        u.UK_Guidance__c = false;
        update u;
        List<CollaborationGroupMember> collabGroupMembers2 = new List<CollaborationGroupMember>([SELECT Id FROM CollaborationGroupMember WHERE memberId =: u.Id]);
        System.assertEquals(0, collabGroupMembers2.size());
        
        u.UK_Announcement__c = true;
        update u;
        List<CollaborationGroupMember> collabGroupMembers3 = new List<CollaborationGroupMember>([SELECT Id FROM CollaborationGroupMember WHERE memberId =: u.Id]);
        System.assertEquals(1, collabGroupMembers3.size());
        
        u.UK_Guidance__c = true;
        update u;
        List<CollaborationGroupMember> collabGroupMembers4 = new List<CollaborationGroupMember>([SELECT Id FROM CollaborationGroupMember WHERE memberId =: u.Id]);
        System.assertEquals(2, collabGroupMembers4.size());
        test.stopTest();
    }
}