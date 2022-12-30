@isTest(SeeAlldata =false)
public class Forums_Test {
    @testSetup
    static void testData(){
        Profile prof = [select id from profile where name = 'System Administrator'];
        
        User u = new User(Alias = 'sd', Email='test@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = prof.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='ser@testorg.com', Region__c = 'ANZ');
        
        insert u;
                
        System.runAs(u){
            CollaborationGroup groupe = new CollaborationGroup(Name = 'Test1', CollaborationType = 'Public');
            insert groupe;
            
            //COLLABORATION GROUP MEMBER CREATION
            /*
            collaborationgroupmember cgm = new collaborationgroupmember();
            cgm.CollaborationGroupId = groupe.Id;
            cgm.MemberId = u.Id;
            cgm.CollaborationRole = 'Standard';
            cgm.NotificationFrequency='P';
            insert cgm;*/
            
            List<KnowledgeCustomCmpController.FileDataWP> files = new List<KnowledgeCustomCmpController.FileDataWP>();
            KnowledgeCustomCmpController.FileDataWP data = new KnowledgeCustomCmpController.FileDataWP();
            data.fileName = 'test';
            data.fileContent = 'Unit Test Attachment Body';
            files.add(data);
            
            //FEED ITEM
            feeditem comment = new feeditem();
            comment.Body = '<strong>test</strong> <em>test</em> <strike>strike</strike> <span>span</span> <p>ptag</p>';
            comment.ParentId = groupe.Id;
            KnowledgeCustomCmpController.replyCommentonFeed(comment,JSON.serialize(files));
            
            //FEED COMMENT
            FeedComment feedComment = new FeedComment();
            feedComment.CommentBody = '<strong>test</strong> <em>test</em> <strike>strike</strike> <span>span</span> <p>ptag</p>';
            feedComment.FeedItemId = comment.Id;
            KnowledgeCustomCmpController.replyCommentonChatter(feedComment,JSON.serialize(files));
        }
        
    }
    
    @isTest
    private static void GetForumsDataBasedOnCategoryTest()
    {
        User u = [SELECT Id FROM User WHERE Email = 'test@testorg.com'];
        Forums.GetForumsDataBasedOnCategory();
    }
    
    @isTest
    private static void getForumsDetailsTest()
    {
        User u = [SELECT Id FROM User WHERE Email = 'test@testorg.com'];
        
        List<string> ids = new List<string>();
        for(CollaborationGroup groupp : [Select Id,Name from CollaborationGroup])
        {
            ids.add(groupp.Id);
        }
        Forums.getForumsDetails(ids);
    }
    
    @isTest
    private static void getFilteredForumDetailsTest(){
        User u = [SELECT Id FROM User WHERE Email = 'test@testorg.com'];
       
        
        test.startTest();
        System.runAs(u){
            CollaborationGroupMember groupMember = [select CollaborationGroupId, CollaborationRole, CollaborationGroup.Name from CollaborationGroupMember where MemberId =: u.Id LIMIT 1];
            List<Id> collaborationGroupIds = new List<Id>{groupMember.CollaborationGroupId};
            Forums.getFilteredForumDetails(collaborationGroupIds,'test');
        }
        test.stopTest();
    }
    
    @isTest
    private static void postChatterFeedTest(){
        User u = [SELECT Id FROM User WHERE Email = 'test@testorg.com'];
         System.debug(u.Id);
        
        test.startTest();
        System.runAs(u){
            CollaborationGroupMember groupMember = [select CollaborationGroupId, CollaborationRole, CollaborationGroup.Name from CollaborationGroupMember where MemberId =: u.Id LIMIT 1];
            //List<Id> collaborationGroupIds = new List<Id>{groupMember.CollaborationGroupId};
            
            List<KnowledgeCustomCmpController.FileDataWP> files = new List<KnowledgeCustomCmpController.FileDataWP>();
            KnowledgeCustomCmpController.FileDataWP data = new KnowledgeCustomCmpController.FileDataWP();
            data.fileName = 'test';
            data.fileContent = 'Unit Test Attachment Body';
            files.add(data);
            Forums.postChatterFeed(groupMember.CollaborationGroupId,'<strong>test</strong> <em>test</em> <strike>strike</strike> <span>span</span> <p>ptag</p>',JSON.serialize(files));
        }
        test.stopTest();
    }
    
    @isTest
    private static void getChatterEmailSettingTest(){
        User u = [SELECT Id FROM User WHERE Email = 'test@testorg.com'];
        
        
        System.runAs(u){
            test.startTest();
            Boolean chatterSetting = Forums.getChatterEmailSetting();
            test.stopTest();
            System.assertEquals(false,chatterSetting);
        }
        
        
    }
    
    @isTest
    private static void setChatterEmailSettingTest(){
        User u = [SELECT Id FROM User WHERE Email = 'test@testorg.com'];
        
        System.runAs(u){
            test.startTest();
            Forums.setChatterEmailSetting(true);
            test.stopTest();
            Boolean chatterSetting = Forums.getChatterEmailSetting();
            System.assertEquals(true,chatterSetting);
        }

    }
}