public with sharing class GetCaseData {
    // @AuraEnabled(cacheable=true)
    // public static List<Case> getCaseList() {
    //     //List<CaseRelatedIssue> cases = new List<CaseRelatedIssue>();
    //     //cases = [Select CaseId,Name from CaseRelatedIssue];
    //     return [Select CaseNumber, createdBy.Name,Subject,Status,CreatedDate,Priority FROM Case ];
    // }

    //static Id communityContactId;

    // GetCaseData()
    // {
    //     User userRecord = [select id, contactId, profile.name from User where Id=: UserInfo.getUserId() limit 1];
    //     communityContactId = userRecord.ContactId;
    // }

    @AuraEnabled//Get Cases Records
    public static String getCaseList(Integer pageSize, Integer pageNumber){
        String jsonDT = '';
        User userRecord = [select id, contactId, profile.name from User where Id=: UserInfo.getUserId() limit 1];
        Id communityContactId = userRecord.ContactId;
        //Offset for SOQL
        Integer offset = (pageNumber - 1) * pageSize;
         
        //Total Records
        Integer totalRecords = [SELECT COUNT() FROM Case where ContactId = :communityContactId];
        Integer recordEnd = pageSize * pageNumber;
         
        CaseDTWrapper objDT =  new CaseDTWrapper();  
        objDT.pageSize = pageSize;
        objDT.pageNumber = pageNumber;
        objDT.recordStart = offset + 1;
        objDT.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
        objDT.totalRecords = totalRecords;

      
       
        objDT.cases = [Select CaseNumber, createdBy.Name,Subject,Status,CreatedDate,Priority,LastModifiedDate, Priority_Number__c  
                        FROM Case where ContactId = : communityContactId order by LastModifiedDate Desc LIMIT :pageSize OFFSET :offset];
        jsonDT = JSON.serialize(objDT);
        return jsonDT;
    }

    @AuraEnabled//Get Filterred Cases Records
    public static string filterCases(String Status, String Priority, Integer pageSize, Integer pageNumber){
        try {
            User userRecord = [select id, contactId, profile.name from User where Id=: UserInfo.getUserId() limit 1];
            Id communityContactId = userRecord.ContactId;
            String jsonDT = '';
             
            //Offset for SOQL
            Integer offset = (pageNumber - 1) * pageSize;
             
             
            CaseDTWrapper objDT =  new CaseDTWrapper();  
            objDT.pageSize = pageSize;
            objDT.pageNumber = pageNumber;
            objDT.recordStart = offset + 1;
            if(string.isBlank(Status) && string.isBlank(Priority))
            {
                objDT.cases = [Select CaseNumber, createdBy.Name,Subject,Status,CreatedDate,Priority,LastModifiedDate, Priority_Number__c FROM Case where ContactId = : communityContactId order by LastModifiedDate Desc  LIMIT :pageSize OFFSET :offset];
                
                //Total Records
                Integer totalRecords = [SELECT COUNT() FROM Case where ContactId = : communityContactId];
                Integer recordEnd = pageSize * pageNumber;
                objDT.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
                objDT.totalRecords = totalRecords;
                jsonDT = JSON.serialize(objDT);
                return jsonDT;
            }
            else if(string.isBlank(Status))
            {
                string likePriority = '%'+Priority+'%';
                objDT.cases = [Select CaseNumber, createdBy.Name,Subject,Status,CreatedDate,Priority,LastModifiedDate, Priority_Number__c FROM Case where Priority like :likePriority and ContactId = : communityContactId order by LastModifiedDate Desc  LIMIT :pageSize OFFSET :offset];
                                
                //Total Records
                Integer totalRecords = [SELECT COUNT() FROM Case where Priority like :likePriority and ContactId = : communityContactId];
                Integer recordEnd = pageSize * pageNumber;
                objDT.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
                objDT.totalRecords = totalRecords;
                jsonDT = JSON.serialize(objDT);
                return jsonDT;
            }
            else if(string.isBlank(Priority))
            {
                string likeStatus = '%'+Status+'%';
                objDT.cases = [Select CaseNumber, createdBy.Name,Subject,Status,CreatedDate,Priority,LastModifiedDate, Priority_Number__c FROM Case where Status like :likeStatus and ContactId = : communityContactId order by LastModifiedDate Desc  LIMIT :pageSize OFFSET :offset];
                                
                //Total Records
                Integer totalRecords = [SELECT COUNT() FROM Case where Status like :likeStatus and ContactId = : communityContactId];
                Integer recordEnd = pageSize * pageNumber;
                objDT.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
                objDT.totalRecords = totalRecords;
                System.debug('Total records are '+ totalRecords);
                jsonDT = JSON.serialize(objDT);
                return jsonDT;
            }
            else 
            {
                string likePriority = '%'+Priority+'%';
                string likeStatus = '%'+Status+'%';
                objDT.cases = [Select CaseNumber, createdBy.Name,Subject,Status,CreatedDate,Priority,LastModifiedDate, Priority_Number__c FROM Case where Status like :likeStatus and Priority like :likePriority and ContactId = : communityContactId order by LastModifiedDate Desc  LIMIT :pageSize OFFSET :offset];
                                
                //Total Records
                Integer totalRecords = [SELECT COUNT() FROM Case where Status like :likeStatus and Priority like :likePriority and ContactId = : communityContactId];
                Integer recordEnd = pageSize * pageNumber;
                objDT.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
                objDT.totalRecords = totalRecords;
                jsonDT = JSON.serialize(objDT);
                return jsonDT;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<string> getStatusValues(){
        try {
            // List<sObject> dropdownValues = new List<sObject>();
            // dropdownValues = [Select Status FROM Case group by Status];
            // return dropdownValues;
            List<string> options = new List<string>();
		    Schema.DescribeFieldResult fieldResult = Case.Status.getDescribe();
		    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		    for( Schema.PicklistEntry f : ple){
                options.add(f.getValue());
		    }     
		    return options;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static  List<string> getPriorityValues(){
        try {
            // List<sObject> dropdownValues = new List<sObject>();
            // dropdownValues = [Select Priority FROM Case group by Priority];
            // return dropdownValues;            
            List<string> options = new List<string>{'Low','Medium','High','Urgent'};
            /*    
		    Schema.DescribeFieldResult fieldResult = Case.Priority.getDescribe();
		    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		    for( Schema.PicklistEntry f : ple){
                options.add(f.getValue());
		    }     */
		    return options;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
     
    public class CaseDTWrapper {
        public Integer pageSize {get;set;}
        public Integer pageNumber {get;set;}
        public Integer totalRecords {get;set;}
        public Integer recordStart {get;set;}
        public Integer recordEnd {get;set;}
        public List<Case> cases {get;set;}
    }
}