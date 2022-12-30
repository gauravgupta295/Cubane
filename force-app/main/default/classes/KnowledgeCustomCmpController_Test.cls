@isTest
public class KnowledgeCustomCmpController_Test {
    
    
    @testSetup 
    private static void setup() 
    {
        Case newCase = new Case();
        newCase.Priority = 'High';
        newCase.Subject = 'Test Subject';
        newCase.Description = 'Test Description';
        newCase.CC__c = 'Test@test.com';
        insert newCase;   
        feeditem comment = new feeditem();
        comment.Body = '<p>test comment</p>';
        comment.ParentId = newCase.Id;
        insert comment;
        ContentVersion testContentInsert = new ContentVersion(); 
        testContentInsert.VersionData = EncodingUtil.base64Decode('Unit Test Attachment Body');
        testContentInsert.PathOnClient = 'test';
        testContentInsert.Title ='Google.com';			
        insert testContentInsert; 
        ContentDocumentLink conDocLink = New ContentDocumentLink();
        for(ContentVersion cv : [SELECT Title,ContentDocumentId FROM ContentVersion WHERE Id =: testContentInsert.Id]) {
            
            conDocLink.LinkedEntityId = newCase.Id;
            conDocLink.ContentDocumentId = cv.ContentDocumentId;
            conDocLink.Visibility = 'AllUsers';
            conDocLink.shareType = 'V'; // V = Viewer, C = Collaborator, I = Inferred
            
            
        }
        Insert conDocLink;
        FeedAttachment feedAttachment = new FeedAttachment();
        for(ContentVersion cv : [SELECT Title,ContentDocumentId FROM ContentVersion WHERE Id =: testContentInsert.Id]) {
            
            feedAttachment.FeedEntityId = comment.Id;
            feedAttachment.RecordId = cv.Id; 
            feedAttachment.Title = cv.Title;   
            feedAttachment.Type = 'CONTENT';                  
            
            
        }
        
        Insert feedAttachment; 
        
        //INSERT KNOWLEDGE ARTICLE
        Knowledge__kav k= new Knowledge__kav();
        k.IsVisibleInCsp=true;
        k.UrlName='UTF-8';
        k.Title='title';
        k.IsVisibleInPkb=true;
        insert k;
        
        //INSERT DATA CATEGORY SELECTIONS
        Knowledge__DataCategorySelection kn= new Knowledge__DataCategorySelection();
        kn.ParentId=k.id;
        kn.DataCategoryGroupName='Region';
        kn.DataCategoryName='Only_ANZ';
        insert kn;
        
        Knowledge__DataCategorySelection kn1= new Knowledge__DataCategorySelection();
        kn1.ParentId=k.id;
        kn1.DataCategoryGroupName='Role';
        kn1.DataCategoryName='Program_Manager';
        insert kn1;

        Profile prof = [select id from profile where name = 'System Administrator'];
        
        User u = new User(Alias = 'sd', Email='test@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = prof.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='ser@testorg.com', Region__c = 'ANZ');
        insert u;
        
        //PUBLISHING ARTICLE
        string obj1 = [SELECT KnowledgeArticleId FROM Knowledge__kav WHERE Id =: k.Id].KnowledgeArticleId;            
        KbManagement.PublishingService.publishArticle(obj1, true);
    
    }
    
    @isTest
    private static void searchArticleTest()
    {
        User u = [SELECT Id FROM User WHERE Email = 'test@testorg.com'];
        
        test.startTest();
        System.runAs(u){
          KnowledgeCustomCmpController.searchArticle('title');  
        }
        
        test.stopTest();
    }
    
    @isTest
    private static void getTicketDetailTest()
    {
        Case c= [select id from Case limit 1];
        KnowledgeCustomCmpController.getTicketDetail(c.id);
    }
    
    @isTest
    private static void updateTicketDetailTest()
    {
        Case c= [select id from Case limit 1];
        KnowledgeCustomCmpController.updateTicketDetail(c);
    }
    
    @isTest
    private static void replyCommentonFeedTest()
    {
        List<KnowledgeCustomCmpController.FileDataWP> files = new List<KnowledgeCustomCmpController.FileDataWP>();
        KnowledgeCustomCmpController.FileDataWP data = new KnowledgeCustomCmpController.FileDataWP();
        data.fileName = 'test';
        data.fileContent = 'Unit Test Attachment Body';
        files.add(data);
        Case c= [select id from Case limit 1];
        feeditem comment = new feeditem();
        comment.Body = '<strong>test</strong> <em>test</em> <strike>strike</strike> <span>span</span> <p>ptag</p>';
        comment.ParentId = c.Id;
        
        test.startTest();
        KnowledgeCustomCmpController.replyCommentonFeed(comment,JSON.serialize(files));
        KnowledgeCustomCmpController.loadChatterFeeds(comment.Id);
        test.stopTest();
    }
    
    @isTest
    private static void loadCaseFeedItemTest()
    {
        Case c= [select id from Case limit 1];        
        EmailMessage emailMessage = new EmailMessage();
        emailMessage.parentId = c.Id;
        emailMessage.TextBody = 'Text';
        emailMessage.MessageDate = date.today();
        insert emailMessage;

        KnowledgeCustomCmpController.loadCaseFeedItem(c.Id);
    }
    
    @isTest
    private static void CreateCasesTest()
    {             
        CreateCases.CreateCases('test','test','test','test@test.com');
    }
    
    @isTest
    private static void uploadFilesTest()
    {         
        List<KnowledgeCustomCmpController.FileDataWP> files = new List<KnowledgeCustomCmpController.FileDataWP>();
        KnowledgeCustomCmpController.FileDataWP data = new KnowledgeCustomCmpController.FileDataWP();
        data.fileName = 'test';
        data.fileContent = 'Unit Test Attachment Body';
        files.add(data);
        Case c= [select id from Case limit 1];
        UploadMultipleFiles.uploadFiles(c.Id,JSON.serialize(files));
    }
    
    /*Author: Ray Hormillada*/
    @isTest
    private static void createArticle(){
        Knowledge__kav currentArticleDetail = [
            SELECT ArticleCreatedDate, ArticleNumber
            FROM Knowledge__kav limit 1
        ];
        
        KnowledgeArticle knowledgeArticle = [
            SELECT Id
            FROM KnowledgeArticle
            WHERE ArticleNumber = :currentArticleDetail.get('ArticleNumber').toString()
        ];
        
        //KbManagement.PublishingService.publishArticle(knowledgeArticle.Id, true);
        
        test.startTest();
        Knowledge__kav knowledgeRec = KnowledgeCustomCmpController.getData(currentArticleDetail.Id);
        test.stopTest();
        
        System.assertEquals(currentArticleDetail.Id,knowledgeRec.Id);
    }
    
    /*Author: Ray Hormillada*/
    @isTest
    private static void replyCommentonChatterTest()
    {
        
        List<KnowledgeCustomCmpController.FileDataWP> files = new List<KnowledgeCustomCmpController.FileDataWP>();
        KnowledgeCustomCmpController.FileDataWP data = new KnowledgeCustomCmpController.FileDataWP();
        data.fileName = 'test';
        data.fileContent = 'Unit Test Attachment Body';
        files.add(data);
        Case c= [select id from Case limit 1];
        feeditem comment = new feeditem();
        comment.Body = '<strong>test</strong> <em>test</em> <strike>strike</strike> <span>span</span> <p>ptag</p>';
        comment.ParentId = c.Id;
        insert comment;
        
        CollaborationGroup groupe = new CollaborationGroup(Name = 'Test1', CollaborationType = 'Public');
        insert groupe;
        
        
        User u = [SELECT Id FROM User WHERE Email = 'test@testorg.com'];
        
        
        collaborationgroupmember cgm = new collaborationgroupmember();
        cgm.CollaborationGroupId = groupe.Id;
        cgm.MemberId = u.Id;
        cgm.CollaborationRole = 'Standard';
        cgm.NotificationFrequency='P';
        insert cgm;
        
        FeedComment feedComment = new FeedComment();
        feedComment.CommentBody = '<strong>test</strong> <em>test</em> <strike>strike</strike> <span>span</span> <p>ptag</p>';
        feedComment.FeedItemId = comment.Id;
        
        test.startTest();
        System.runAs(u){
            KnowledgeCustomCmpController.replyCommentonChatter(feedComment,JSON.serialize(files));
            KnowledgeCustomCmpController.loadChatterFeeds(comment.Id);
        }
        test.stopTest();
    }
    
    /*Author: Ray Hormillada*/
    @isTest
    private static void loadChatterFeedsTest()
    {
        
        List<KnowledgeCustomCmpController.FileDataWP> files = new List<KnowledgeCustomCmpController.FileDataWP>();
        KnowledgeCustomCmpController.FileDataWP data = new KnowledgeCustomCmpController.FileDataWP();
        data.fileName = 'test';
        data.fileContent = 'Unit Test Attachment Body';
        files.add(data);
        Case c= [select id from Case limit 1];
        feeditem comment = new feeditem();
        comment.Body = '<strong>test</strong> <em>test</em> <strike>strike</strike> <span>span</span> <p>ptag</p>';
        comment.ParentId = c.Id;
        insert comment;
        
        KnowledgeCustomCmpController.loadChatterFeeds(comment.Id);
    }
    
    
}