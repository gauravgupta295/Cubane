@isTest
public class GetCaseData_Test {
	
    @isTest
    private static void getCaseListTest()
    {
        GetCaseData.getCaseList(10,1);
    }
    
    @isTest
    private static void filterCasesTest()
    {
        GetCaseData.filterCases('Open','High',10,1);
    }
    
    @isTest
    private static void filterCasesTest1()
    {
        GetCaseData.filterCases('Open','',10,1);
    }
    
    @isTest
    private static void filterCasesTest2()
    {
        GetCaseData.filterCases('','High',10,1);
    }
    
    @isTest
    private static void filterCasesTest3()
    {
        GetCaseData.filterCases('','',10,1);
    }
    
     @isTest
    private static void getStatusValuesTest()
    {
        GetCaseData.getStatusValues();
    }
    
     @isTest
    private static void getPriorityValuesTest()
    {
        GetCaseData.getPriorityValues();
    }
}