public Without Sharing class KnowledgeCustomCmpController {
    @AuraEnabled(cacheable=true)
    public static Knowledge__kav getdata(string recordId){
        try
        {
            list<Knowledge__kav> knowledgelist =[SELECT Id, Title, Content__c from Knowledge__kav where id =:recordId
                                                 and PublishStatus ='Online'];
            return knowledgelist[0];
        }
        catch(exception e)
        {
            throw new  AuraHandledException(e.getMessage());         
        }  
    }
    @AuraEnabled(cacheable=true)
    public static List<Knowledge__kav> searchArticle(string searchText){
        try
        {
            /*string searchT = '%'+searchText+'%';
            system.debug('searchT'+searchT);
            list<Knowledge__kav> knowledgelist =[SELECT Id, Title, Content__c from Knowledge__kav where Title like: searchT
                                                 and PublishStatus  = 'Online'];
            return knowledgelist;
           */
           return getArticleIdsBasedOnRegion(searchText);
        }
        catch(exception e)
        {
            throw new  AuraHandledException(e.getMessage());         
        }  
    }
    
    private static List<Knowledge__kav> getArticleIdsBasedOnRegion(string searchText)
    {
        User userRecord = [select id, Region__c, profile.name from User where Id=: UserInfo.getUserId() limit 1];
        string userRegion = userRecord.Region__c;
        List<Id> articleIds = new List<id>();
        List<Knowledge__kav> lstArticle = new List<Knowledge__kav>();
        string searchT = '%'+searchText+'%';
        for(Knowledge__DataCategorySelection cate: [SELECT DataCategoryGroupName, DataCategoryName, ParentId, Parent.title, Parent.Question__c, 
         Parent.Answer__c FROM Knowledge__DataCategorySelection where parent.PublishStatus ='Online'
                                                   and Parent.Title like: searchT  ])
     {        
         if(cate.DataCategoryGroupName == 'Region' && cate.DataCategoryName.contains(userRegion))
         {              
             articleIds.add(cate.ParentId);
         }        
     }
        
        for(Knowledge__DataCategorySelection cate: [SELECT DataCategoryGroupName, DataCategoryName, ParentId,Parent.Content__c, Parent.title, Parent.Question__c, 
                                                    Parent.Answer__c FROM Knowledge__DataCategorySelection where ParentId IN :articleIds])
        {
            if(cate.DataCategoryGroupName == 'Role')
            {
          		 Knowledge__kav articleOBj = new Knowledge__kav();
                 articleOBj.Id = cate.ParentId;
             	 articleOBj.Title = cate.Parent.title;
                 articleOBj.Content__c = cate.Parent.Content__c;
         		 lstArticle.add(articleOBj);
          }
     }  
        
        return lstArticle;
    }
    
    @AuraEnabled
    public static CaseDetailWrapper getTicketDetail(string ticketId){
        try
        {
            CaseDetailWrapper wrapper = new CaseDetailWrapper();
            wrapper.CaseDetails = [SELECT Id, CaseNumber,subject, description,CC__c,Priority,status,lastmodifiedDate from case where Id  =:ticketId];
            
            List<ContentDocumentLink> contentDocumentLinkRecords = new List<ContentDocumentLink>();
            contentDocumentLinkRecords = [select id, ContentDocumentId from ContentDocumentLink  where LinkedEntityId =: wrapper.CaseDetails.Id];
            
            Set<Id> contentDocumentIds = new Set<Id>();
            for(ContentDocumentLink contentDocumentLinkRecord : contentDocumentLinkRecords){
                contentDocumentIds.add(contentDocumentLinkRecord.ContentDocumentId);
            }
            
            List<ContentVersion> contentVersionRecords = new List<ContentVersion>();
            contentVersionRecords = [SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE ContentDocumentId IN: contentDocumentIds];
            
            List<CaseAttachments> caseAttachments = new List<CaseAttachments>();
            for(ContentVersion contentVersionRecord : contentVersionRecords){
                CaseAttachments caseAttachmentsWrap = new caseAttachments();
                string baseURL = URL.getSalesforceBaseUrl().toExternalForm() + '/sfc/servlet.shepherd/version/download/' + contentVersionRecord.ID + '?operationContext=S1';
                caseAttachmentsWrap.URL = baseURL;
                caseAttachmentsWrap.contentVersion = contentVersionRecord;
                caseAttachments.add(caseAttachmentsWrap);
            }
            
            wrapper.caseAttachments = caseAttachments;
            
            
            List<Id> attachementIds = new List<Id>();
            for(feeditem c : [SELECT Id,(select id,RecordId,type from FeedAttachments),Type, Body,InsertedBy.name,InsertedBy.firstname,InsertedBy.lastname,LastModifiedDate from feeditem 
                                where parentId =:ticketId and (Type ='TextPost' or Type = 'ContentPost')])
            {
                if(string.isNotBlank(c.Body))
                {
                    FeedCommentWrapper ticketComment = new FeedCommentWrapper();
                    ticketComment.Attachements = new List<CaseCommentAttachement>(); 
                    ticketComment.Id = c.Id;
                    ticketComment.Body = c.Body;
                    ticketComment.Name = c.InsertedBy.firstname + ' ' + c.InsertedBy.lastname;
                    ticketComment.LastModifiedDate = c.LastModifiedDate;
                    Map<string,FeedAttachment> mapAtt = new Map<string,FeedAttachment>();
                    if(c.Type == 'ContentPost')
                    {
                        List<string> urls = new List<string>();
                        for(FeedAttachment att : c.FeedAttachments)
                        {
                            string baseURL = URL.getSalesforceBaseUrl().toExternalForm();
                            urls.add(baseURL+'/sfc/servlet.shepherd/version/download/' + att.recordId);
                            attachementIds.add(att.recordId);
                            mapAtt.put(att.recordId,att);
                        }
                        ticketComment.linkURL = urls;   
                        ticketComment.mapAttachement = mapAtt;
                    }
                    
                    wrapper.caseFeedList.add(ticketComment);
                }
            }
            if(attachementIds.size() > 0)
            {
                for(ContentVersion cv : [select id, title from ContentVersion where IsDeleted =false and IsLatest = true and Id IN: attachementIds])
                {       
                    for(FeedCommentWrapper comment : wrapper.caseFeedList)
                    {    
                        
                        if(comment.mapAttachement !=null && comment.mapAttachement.size() > 0 && comment.mapAttachement.ContainsKey(cv.Id))
                        {
                            CaseCommentAttachement att = new CaseCommentAttachement();
                            string baseURL = URL.getSalesforceBaseUrl().toExternalForm();                        
                            att.Title = cv.Title.split('\\.')[0];
                            att.URL = baseURL+'/sfc/servlet.shepherd/version/download/' + cv.Id;
                            comment.Attachements.add(att);
                        }                        
                    }
                }                
            }
            for(EmailMessage c : [SELECT ID,TextBody,htmlBody, MessageDate,FromName FROM EmailMessage where parentId =:ticketId])
            {
                FeedCommentWrapper ticketComment = new FeedCommentWrapper();
                ticketComment.Id = c.Id;
                ticketComment.Body = c.htmlBody;
                ticketComment.Name = c.FromName;
                ticketComment.LastModifiedDate = c.MessageDate;
                wrapper.caseFeedList.add(ticketComment);
            }
            wrapper.caseFeedList.sort();
            wrapper.currentUserName = UserInfo.getName();
            TimeZone tz = UserInfo.getTimeZone();
            List<string> ls = tz.getDisplayName().remove('(').remove(')').split(' ');
            system.debug(ls[ls.size()-1]);
            wrapper.currentUserTimeZone = ls[ls.size()-1];
            return wrapper;
        }
        catch(exception e)
        {
            throw new  AuraHandledException(e.getMessage());         
        }      
    }
    
    @AuraEnabled
    public static string updateTicketDetail(Case ticketDetail){ 
        try
        {
            system.debug('ticketDetail'+ticketDetail);
            upsert ticketDetail;
            return 'Ticket Updated Successfully.';
        }
        catch(exception e)
        {
            throw new  AuraHandledException(e.getMessage());         
        }       
    }

    @AuraEnabled
    public static string replyCommentonFeed(feeditem feed, string filedata){ 
        try
        {           
            feed.IsRichText = true;
            if(feed.Body.Contains('strong'))
            {
                system.debug('body'+feed.Body.Contains('strong'));
                feed.Body = feed.Body.replace('strong','b');
                 system.debug('body'+feed.Body);
            }
            if(feed.Body.Contains('em'))
            {
                
               feed.Body = feed.Body.replace('em','i'); 
                system.debug('body'+feed.Body);
            }
            if(feed.Body.Contains('strike'))
            {
                
               feed.Body = feed.Body.replace('strike','s'); 
                system.debug('body'+feed.Body);
            }
            if(feed.Body.Contains('span'))
            {
                
               feed.Body = feed.Body.replace('span','p'); 
                system.debug('body'+feed.Body);
            }
            if(feed.Body.Contains('class="ql-cursor"'))
            {
                
               feed.Body = feed.Body.replace('class="ql-cursor"',''); 
                system.debug('body'+feed.Body);
            }
            if(feed.Body.Contains('<br>'))
            {
                feed.Body = feed.Body.replace('<br>','&nbsp;'); 
            }         
            
            insert feed;
            if(FileData != 'null') {
                UploadContentAttachement(feed.Id, feed.ParentId, filedata,null);
            }
            return 'Reply/Comment Posted Successfully.';
        }
        catch(exception e)
        {
            throw new  AuraHandledException(e.getMessage());         
        }       
    }

    @AuraEnabled
    public static string replyCommentonChatter(FeedComment comment, string filedata){ 
        try
        {           
            comment.IsRichText = true;
            
            if(comment.CommentBody.Contains('strong'))
            {
                system.debug('body'+comment.CommentBody.Contains('strong'));
                comment.CommentBody = comment.CommentBody.replace('strong','b');
                 system.debug('body'+comment.CommentBody);
            }
            if(comment.CommentBody.Contains('em'))
            {
                
                comment.CommentBody = comment.CommentBody.replace('em','i'); 
                system.debug('body'+comment.CommentBody);
            }
            if(comment.CommentBody.Contains('strike'))
            {
                
                comment.CommentBody = comment.CommentBody.replace('strike','s'); 
                system.debug('body'+comment.CommentBody);
            }
            if(comment.CommentBody.Contains('span'))
            {
                
                comment.CommentBody = comment.CommentBody.replace('span','p'); 
                system.debug('body'+comment.CommentBody);
            }
            if(comment.CommentBody.Contains('class="ql-cursor"'))
            {
                
                comment.CommentBody = comment.CommentBody.replace('class="ql-cursor"',''); 
                system.debug('body'+comment.CommentBody);
            }
            if(comment.CommentBody.Contains('<br>'))
            {
                comment.CommentBody = comment.CommentBody.replace('<br>','&nbsp;'); 
            }            
            comment.CommentBody = comment.CommentBody;
            insert comment;
            if(FileData != 'null') {
                System.debug(comment.Id);
                UploadContentAttachement(comment.FeedItemId,comment.ParentId, filedata, comment.Id);
            }
            return 'Reply/Comment Posted Successfully.';
        }
        catch(exception e)
        {
            throw new  AuraHandledException(e.getMessage());         
        }       
    }

    public static void UploadContentAttachement(string postId, string ParentId, string fileData, string feedAttachmentId)
    {
        try {
            if(String.isNotBlank(FileData)) {
                List<FileDataWP> files = (List<FileDataWP>) JSON.deserialize(filedata, List<FileDataWP>.class);
                System.debug(files);
 
                List<ContentVersion> cvList = new List<ContentVersion>();
                for(FileDataWP file : files) {
                    ContentVersion conVer = new ContentVersion();
                    conVer.ContentLocation = 'S'; // S = Salesforce, E = External Files
                    conVer.VersionData = EncodingUtil.base64Decode(file.fileContent);
                    conVer.Title = file.fileName;
                    conVer.PathOnClient = file.fileName;
                    if(feedAttachmentId != null){
                        conVer.Feed_Attachment_ID__c = feedAttachmentId;
                    }
                    cvList.add(conVer);
                }
                Insert cvList;
 
                List<ContentDocumentLink> cdList = new List<ContentDocumentLink>();
                List<FeedAttachment> feedAttachmentLIit = new List<FeedAttachment>();
                for(ContentVersion cv : [SELECT Title,ContentDocumentId FROM ContentVersion WHERE Id =: cvList]) {
                    ContentDocumentLink conDocLink = New ContentDocumentLink();
                    if(test.isRunningTest()){
                        conDocLink.LinkedEntityId = [SELECT Id, ParentId FROM FeedItem WHERE ID=: postId LIMIT 1].ParentId;
                    }else{
					    conDocLink.LinkedEntityId = ParentId;                    
                    }
                    
                    conDocLink.ContentDocumentId = cv.ContentDocumentId;
                    conDocLink.Visibility = 'AllUsers';
                    conDocLink.shareType = 'V'; // V = Viewer, C = Collaborator, I = Inferred
                    cdList.add(conDocLink);
                     
                 }
                 Insert cdList;
                 for(ContentVersion cv : [SELECT Title,ContentDocumentId FROM ContentVersion WHERE Id =: cvList]) {
                    System.debug(postId);
                    System.debug(cv.Id);
                    System.debug(cv.Title);

                    FeedAttachment feedAttachment = new FeedAttachment();
                    feedAttachment.FeedEntityId = postId;
                    feedAttachment.RecordId = cv.Id; 
                    feedAttachment.Title = cv.Title;   
                    feedAttachment.Type = 'CONTENT';                  
                    feedAttachmentLIit.add(feedAttachment);

                }
                 
                Insert feedAttachmentLIit;     
            }            
        } catch (Exception ex) {
            System.debug(ex.getMessage() + ' -> ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static List<FeedCommentWrapper> loadCaseFeedItem(string ticketId){ 
        try
        {    
            List<Id> attachementIds = new List<Id>();                   
            //return [SELECT Id, Body,InsertedBy.name,InsertedBy.firstname,InsertedBy.lastname,LastModifiedDate from feeditem where parentId =:ticketId and type = 'TextPost'];
            List<FeedCommentWrapper> caseFeedComment = new List<FeedCommentWrapper>();
            for(feeditem c : [SELECT Id, Type,(select id,RecordId,type from FeedAttachments),Body,InsertedBy.name,InsertedBy.firstname,InsertedBy.lastname,LastModifiedDate from feeditem 
                                where parentId =:ticketId and (Type ='TextPost' or Type = 'ContentPost')])
            {
                if(String.isNotBlank(c.Body))
                {
                    FeedCommentWrapper ticketComment = new FeedCommentWrapper();
                    ticketComment.Attachements = new List<CaseCommentAttachement>(); 
                    ticketComment.Id = c.Id;
                    ticketComment.Body = c.Body;
                    ticketComment.Name = c.InsertedBy.firstname + ' ' + c.InsertedBy.lastname;
                    ticketComment.LastModifiedDate = c.LastModifiedDate;
                    Map<string,FeedAttachment> mapAtt = new Map<string,FeedAttachment>();
                    if(c.Type == 'ContentPost')
                    {
                        List<string> urls = new List<string>();
                        for(FeedAttachment att : c.FeedAttachments)
                        {
                            string baseURL = URL.getSalesforceBaseUrl().toExternalForm();
                            urls.add(baseURL+'/sfc/servlet.shepherd/version/download/' + att.recordId);
                            attachementIds.add(att.recordId);
                            mapAtt.put(att.recordId,att);
                        }
                        ticketComment.linkURL = urls;   
                        ticketComment.mapAttachement = mapAtt;
                    }
                    caseFeedComment.add(ticketComment);
                }
            }
            if(attachementIds.size() > 0)
            {
                for(ContentVersion cv : [select id, title from ContentVersion where IsDeleted =false and IsLatest = true and Id IN: attachementIds])
                {       
                    for(FeedCommentWrapper comment : caseFeedComment)
                    {    
                        
                        if(comment.mapAttachement !=null && comment.mapAttachement.size() > 0 && comment.mapAttachement.ContainsKey(cv.Id))
                        {
                            CaseCommentAttachement att = new CaseCommentAttachement();
                            string baseURL = URL.getSalesforceBaseUrl().toExternalForm();                        
                            att.Title = cv.Title.split('\\.')[0];
                            att.URL = baseURL+'/sfc/servlet.shepherd/version/download/' + cv.Id;
                            comment.Attachements.add(att);
                        }                        
                    }
                }                
            }

            for(EmailMessage c : [SELECT ID,TextBody,htmlBody, MessageDate,FromName FROM EmailMessage where parentId =:ticketId])
            {
                FeedCommentWrapper ticketComment = new FeedCommentWrapper();
                ticketComment.Id = c.Id;
                ticketComment.Body = c.htmlBody;
                ticketComment.Name = c.FromName;
                ticketComment.LastModifiedDate = c.MessageDate;
                caseFeedComment.add(ticketComment);
            }
            caseFeedComment.sort();
            return caseFeedComment;
        }
        catch(exception e)
        {
            throw new  AuraHandledException(e.getMessage());         
        }       
    }

    @AuraEnabled
    public static ChatterFeed loadChatterFeeds(string chatterFeedId){ 
        try
        {    
           ChatterFeed feed = new ChatterFeed();                   
           FeedItem fItem = [Select ID, body, CreatedBy.Name, LastModifiedDate, ParentId, Parent.Name, CreatedDate FROM feeditem where  Id = :chatterFeedId];
           feed.feedItemDetail = fItem; 

           //FEED ATTACHMENT FOR FEED ITEM DETAIL LOGIC STARTS HERE
           List<FeedAttachment> feedAttachments = new List<FeedAttachment>([select id,RecordId,type,FeedEntityId from FeedAttachment WHERE FeedEntityId =: chatterFeedId]);
           Set<Id> feedItemAttachmentCVIds = new Set<Id>();
           for(FeedAttachment feedAttachmentRec: feedAttachments){
                feedItemAttachmentCVIds.add(feedAttachmentRec.RecordId);
            }

           Map<Id,FeedComment> feedCommentsMap = new Map<Id,FeedComment>([Select ID, CreatedBy.Name, CommentBody, ParentId, RelatedRecordId, ThreadParentId, FeedItemId, CreatedDate FROM FeedComment where FeedItemId =:fItem.Id order by createddate desc]);
           List<ContentVersion> contentVersion = new List<ContentVersion>([select id, Title, Feed_Attachment_ID__c, IsLatest from contentversion where (Feed_Attachment_ID__c IN: feedCommentsMap.keySet() OR Id IN: feedItemAttachmentCVIds)and IsLatest = true]);
           Map<Id,List<ContentVersion>> contentVersionRecordsByFeedAttachmentId = new Map<Id,List<ContentVersion>>();//USED FOR FEED COMMENT CVs
           Map<Id,ContentVersion> contentVersionRecordById = new Map<Id,ContentVersion>();//USED FOR FEED ITEM DETAIL CVs
           //SETTING CONTENT VERSION MAP BY FEED ATTACHMENT IDS
           if(!contentVersion.isEmpty()){
                for(ContentVersion contentVersionRec : contentVersion){
                    if(!String.isBlank(contentVersionRec.Feed_Attachment_ID__c)){//THIS CONTENT VERSION IS FOR FEED COMMENTS
                        if(contentVersionRecordsByFeedAttachmentId.containsKey(contentVersionRec.Feed_Attachment_ID__c)){
                            contentVersionRecordsByFeedAttachmentId.get(contentVersionRec.Feed_Attachment_ID__c).add(contentVersionRec);
                        }else{
                            contentVersionRecordsByFeedAttachmentId.put(contentVersionRec.Feed_Attachment_ID__c,new List<ContentVersion>{contentVersionRec});
                        }
                    }else{//THIS CONTENT VERSION IS FOR FEED ITEM DETAIL
                        contentVersionRecordById.put(contentVersionRec.Id,contentVersionRec);
                    }
                }
           }
           


           TimeZone tz = UserInfo.getTimeZone();
           List<string> ls = tz.getDisplayName().remove('(').remove(')').split(' ');
           system.debug(ls[ls.size()-1]);      
           feed.currentUserTimeZone = ls[ls.size()-1];

           //LOGIC FOR SETTING FEED ITEM DETAIL ATTACHMENTS
           List<ChatterPostAttachment> feedItemDetailAttachments = new List<ChatterPostAttachment>();
           for(FeedAttachment feedAttachmentRec: feedAttachments){
                if(contentVersionRecordById.containsKey(feedAttachmentRec.RecordId)){
                    ChatterPostAttachment chatterPostAttachmentRec = new ChatterPostAttachment();
                    chatterPostAttachmentRec.Title = contentVersionRecordById.get(feedAttachmentRec.RecordId).Title;
                    string baseURL = URL.getSalesforceBaseUrl().toExternalForm(); 
                    chatterPostAttachmentRec.URL = baseURL+'/sfc/servlet.shepherd/version/download/' + contentVersionRecordById.get(feedAttachmentRec.RecordId).Id;
                    feedItemDetailAttachments.add(chatterPostAttachmentRec);
                }
            }
            feed.feedItemAttachments = feedItemDetailAttachments;
           
           //LOGIC FOR SETTING FEED COMMENT POSTS AND ATTACHMENTS
           List<ChatterComment> chatterComments = new List<ChatterComment>();
           for(Id feedComentId : feedCommentsMap.keySet()){
                ChatterComment chatterCommentWrap = new ChatterComment();
                List<ChatterPostAttachment> attachmentRecords = new List<ChatterPostAttachment>();

                if(contentVersionRecordsByFeedAttachmentId.containsKey(feedComentId)){
                    for(ContentVersion contentVersionRec : contentVersionRecordsByFeedAttachmentId.get(feedComentId)){
                        ChatterPostAttachment attachmentRecord = new ChatterPostAttachment();
                        attachmentRecord.Title = contentVersionRec.Title;
                        string baseURL = URL.getSalesforceBaseUrl().toExternalForm(); 
                        attachmentRecord.URL = baseURL+'/sfc/servlet.shepherd/version/download/' + contentVersionRec.Id;
                        attachmentRecords.add(attachmentRecord);
                    }
                }

                chatterCommentWrap.feedComment = feedCommentsMap.get(feedComentId);
                chatterCommentWrap.feedAttachments = attachmentRecords;
                chatterComments.add(chatterCommentWrap);
           }

           feed.feedCommentList = chatterComments;

           return feed;
        }
        catch(exception e)
        {
            throw new  AuraHandledException(e.getMessage());         
        }       
    }
    
    @AuraEnabled
    public static String getParentFeedItemId(String feedCommentId){
        return [SELECT ID, FeedItemId FROM FeedComment WHERE Id =: feedCommentId].FeedItemId;
    }
    
    public class CaseDetailWrapper  {
        @AuraEnabled
        public Case CaseDetails;
        @AuraEnabled
        public List<caseAttachments> caseAttachments;
        @AuraEnabled
        public List<FeedCommentWrapper> caseFeedList;
        CaseDetailWrapper()
        {
            CaseDetails = new case();
            caseFeedList = new list<FeedCommentWrapper>();
        }
        @AuraEnabled
        public string currentUserName;
        @AuraEnabled
        public string currentUserTimeZone;                 
    }
    
    public class CaseAttachments{
        @AuraEnabled
        public string URL;
        
        @AuraEnabled
        public ContentVersion contentVersion;
    }

    public class FeedCommentWrapper implements Comparable
    {
        @AuraEnabled
        public string Id {get;set;}
        @AuraEnabled
        public string Body {get;set;}
        @AuraEnabled
        public string Name {get;set;}
        @AuraEnabled
        public DateTime LastModifiedDate {get;set;}    
        @AuraEnabled
        public List<string> linkURL {get;set;}

        public Map<string,FeedAttachment> mapAttachement {get;set;}
        @AuraEnabled
        public List<CaseCommentAttachement> Attachements{get;set;}
        public string sortBy = 'Date';
        
        public Integer  compareTo(Object objToCompare) {
			 FeedCommentWrapper compareToins = (FeedCommentWrapper)objToCompare;

        	// The return value of 0 indicates that both elements are equal.
        	Integer returnValue = 0;
        	if (LastModifiedDate > compareToins.LastModifiedDate) {
            	// Set return value to a positive value.
            	returnValue = -1;
        	} else if (LastModifiedDate < compareToins.LastModifiedDate) {
            	// Set return value to a negative value.
            	returnValue = 1;
        	}
        return returnValue;      
		}
    }

    public class FileDataWP {
        @AuraEnabled
        public String fileName;
        @AuraEnabled
        public String fileContent;
    }

    public class CaseCommentAttachement {
        @AuraEnabled
        public String Title;
        @AuraEnabled
        public String URL;
    }

    public class ChatterPostAttachment {
        @AuraEnabled
        public String Title;
        @AuraEnabled
        public String URL;
    }

    public class ChatterComment{
        @AuraEnabled
        public FeedComment feedComment;
        @AuraEnabled
        public List<ChatterPostAttachment> feedAttachments = new List<ChatterPostAttachment>();
    }

    public class ChatterFeed {
        @AuraEnabled
        public FeedItem feedItemDetail;
        @AuraEnabled
        public List<ChatterComment> feedCommentList;
        @AuraEnabled
        public List<ChatterPostAttachment> feedItemAttachments = new List<ChatterPostAttachment>();
        ChatterFeed()
        {
            feedItemDetail = new FeedItem();
        }
        @AuraEnabled
        public string currentUserName;
        @AuraEnabled
        public string currentUserTimeZone;
    }
}