public without sharing class CreateCases {
    @AuraEnabled
    public static string CreateCases(string Priority, string Subject, string Description, string CCValue){
        try {
            AssignmentRule AR = new AssignmentRule(); 
			Database.DMLOptions dmlOpts = new Database.DMLOptions();
            if(!Test.isRunningTest())
            {
            	//Assignment Rule Query
            	AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
            	//Creating DML Options
            	
            	dmlOpts.assignmentRuleHeader.assignmentRuleID = AR.ID; 
            }
            dmlOpts.EmailHeader.TriggerUserEmail = true;
            dmlOpts.EmailHeader.triggerAutoResponseEmail = true;

            Case newCase = new Case();
            newCase.Priority = Priority;
            newCase.Subject = Subject;
            newCase.Description = Description;
            newCase.CC__c = CCValue;
            newCase.setOptions(dmlOpts);
            insert newCase;
            return newCase.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}