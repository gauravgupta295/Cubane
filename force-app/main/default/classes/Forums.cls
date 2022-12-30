public without sharing class Forums {

    @AuraEnabled(cacheable=true)
    public static List<sObject> GetForumsDataBasedOnCategory(){
        try {
            List<sObject> collab = new List<sObject>();
            String userId = UserInfo.getUserId(); 
            User currentUser = [select id, Region__c from User where id=:userId limit 1];
            string userRegion = currentUser.Region__c;
            String searchString = '%' + userRegion + '%';
            /*collab = [Select Id,Name from CollaborationGroup where Name like :searchString and 
                                                                    IsArchived=false and
                                                                    Id in 
                                                                    ( select CollaborationGroupId 
                                                                     from CollaborationGroupMember 
                                                                     where MemberId =: userId)];*/
            collab = [select CollaborationGroupId, CollaborationRole, CollaborationGroup.Name from CollaborationGroupMember where MemberId =: userId AND CollaborationGroup.IsArchived=false];

            return collab;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getForumsDetails(List<String> forumIds){
        try {
            String jsonDT = '';
            List<ForumsDTWrapper> objDT =  new List<ForumsDTWrapper>();  
            List<CollaborationGroupFeed> forums = new List<CollaborationGroupFeed>();
            forums = [select id,Body,ParentId,Parent.name,Title,CommentCount,Type, (SELECT Id, ThreadLastUpdatedDate, CreatedDate FROM FeedComments Order by ThreadLastUpdatedDate desc limit 1) from CollaborationGroupFeed where ParentId in : forumIds ORDER BY LastModifiedDate DESC];
            
            if(!forums.isEmpty()){
                for(CollaborationGroupFeed forumRecord : forums){
                    ForumsDTWrapper objDTRec = new ForumsDTWrapper();
                    objDTRec.forumRecord = forumRecord;
                    objDTRec.strippedHTMLBody = forumRecord.Body.stripHtmlTags();
                    objDT.add(objDTRec);
                }
            }
            
            
            jsonDT = JSON.serialize(objDT);
            return jsonDT;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string getFilteredForumDetails(List<Id> forumIds, String filteredTopic){
        try {
            String jsonDT = '';
            List<ForumsDTWrapper> objDT =  new List<ForumsDTWrapper>();  
            List<CollaborationGroupFeed> forums = new List<CollaborationGroupFeed>();
            
            forums = [select id,Body,ParentId,Parent.name,Title,CommentCount,Type, CreatedDate, (SELECT Id, ThreadLastUpdatedDate, CreatedDate FROM FeedComments Order by ThreadLastUpdatedDate desc limit 1) from CollaborationGroupFeed where ParentId IN: forumIds ORDER BY LastModifiedDate DESC];
            
            
            if(!forums.isEmpty()){
                for(CollaborationGroupFeed forumRecord : forums){
                    
                    if(filteredTopic == null || forumRecord.Body.toLowerCase().contains(filteredTopic.toLowerCase())){
                        ForumsDTWrapper objDTRec = new ForumsDTWrapper();
                        objDTRec.forumRecord = forumRecord;
                        objDTRec.strippedHTMLBody = forumRecord.Body.stripHtmlTags();
                        objDT.add(objDTRec);
                    }
                }
            }
            
            
            jsonDT = JSON.serialize(objDT);
            return jsonDT;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void postChatterFeed(string chatterFeedGroupId, string richTextBody, string filedata){ 
        try
        {    
            FeedItem objFI = new FeedItem();
            objFI.IsRichText = true;
            
            if(richTextBody.Contains('strong'))
            {
                richTextBody = richTextBody.replace('strong','b');
            }
            if(richTextBody.Contains('em'))
            {
               richTextBody = richTextBody.replace('em','i'); 
            }
            if(richTextBody.Contains('strike'))
            {
               richTextBody = richTextBody.replace('strike','s'); 
            }
            if(richTextBody.Contains('span'))
            {
               richTextBody = richTextBody.replace('span','p'); 
            }
            if(richTextBody.Contains('<br>'))
            {
               richTextBody = richTextBody.replace('<br>','&nbsp;'); 
            }            
            
            objFI.Body  = richTextBody;
            objFI.ParentId = chatterFeedGroupId;
            if(test.isRunningTest()){
                objFI.NetworkScope = null;
            }else{
				objFI.NetworkScope = System.Label.Cubane_Consulting_Network_ID;                
            }
            
            insert objFI;

            if(FileData != 'null') {
                KnowledgeCustomCmpController.UploadContentAttachement(objFI.Id, chatterFeedGroupId, filedata,null);
            }
        }
        catch(exception e)
        {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());         
        }       
    }

    @AuraEnabled
    public static Boolean getChatterEmailSetting(){
        try {
            //String userId = UserInfo.getUserId(); 
            NetworkMember member = [SELECT id, PreferencesDisableAllFeedsEmail from NetworkMember WHERE MemberId =: UserInfo.getUserId() LIMIT 1];
            return member.PreferencesDisableAllFeedsEmail;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void setChatterEmailSetting(Boolean emailOptOut){
        try {
            //String userId = UserInfo.getUserId(); 
            NetworkMember member = [SELECT id, PreferencesDisableAllFeedsEmail from NetworkMember WHERE MemberId =: UserInfo.getUserId() LIMIT 1];
            member.PreferencesDisableAllFeedsEmail = emailOptOut;
            update member;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class ForumsDTWrapper {
        public CollaborationGroupFeed forumRecord {get;set;}
        public String strippedHTMLBody {get;set;}
        // public Integer pageSize {get;set;}
        // public Integer pageNumber {get;set;}
        // public Integer totalRecords {get;set;}
        // public Integer recordStart {get;set;}
        // public Integer recordEnd {get;set;}
        public List<CollaborationGroupFeed> forums {get;set;}
    }
}