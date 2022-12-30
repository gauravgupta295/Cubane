public with sharing class DataCategories {

static wrapper wrap = new wrapper();

	
static Map<string,List<articleList>> mapArticles = new Map<string,List<articleList>>();
    
     @AuraEnabled(cacheable=true)
	public static String getSidebarData(){
        
     User userRecord = [select id, Region__c, profile.name from User where Id=: UserInfo.getUserId() limit 1];
     string userRegion = userRecord.Region__c;
        
        system.debug('userRegion' + userRegion);
        List<Id> articleIds = new List<id>();
        for(Knowledge__DataCategorySelection cate: [SELECT DataCategoryGroupName, DataCategoryName, ParentId, Parent.title, Parent.Question__c, 
                                                    Parent.Answer__c FROM Knowledge__DataCategorySelection where parent.PublishStatus ='Online'])
        {
            system.debug('cate.DataCategoryGroupName' + cate.DataCategoryGroupName);
            system.debug('cate.DataCategoryName.contains(userRegion) ' + cate.DataCategoryName.contains(userRegion));
            if(cate.DataCategoryGroupName == 'Region' && cate.DataCategoryName.contains(userRegion))
            {
                system.debug('In the loop');
                articleIds.add(cate.ParentId);
            }        
        }
        
        system.debug('articleIds '+articleIds);
        
        for(Knowledge__DataCategorySelection cate: [SELECT DataCategoryGroupName, DataCategoryName, ParentId, Parent.title, Parent.Question__c, 
                                                    Parent.Answer__c FROM Knowledge__DataCategorySelection where ParentId IN :articleIds order by parent.Article_Order__c asc])
        {
            if(cate.DataCategoryGroupName == 'Role')
            {
                articleList articleOBj = new articleList();
                articleOBj.recordId = cate.ParentId;
                articleOBj.title = cate.Parent.title;
                if(!mapArticles.containsKey(cate.DataCategoryName))
                {                         
                    mapArticles.put(cate.DataCategoryName, new List<articleList>{articleOBj});
                }
                else
                {
                    mapArticles.get(cate.DataCategoryName).add(articleOBj);
                }
            }
     }
	 getDescribeDataCategoryGroupStructureResults();
	 
	 //extract value of 'All' i.e. first child
	 system.debug('JSON.serialize(wrap.items[0].items); '+JSON.serialize(wrap.items[0].items));
	 return JSON.serialize(wrap); 
	}

	public static List<DescribeDataCategoryGroupStructureResult> 
	getDescribeDataCategoryGroupStructureResults(){
	  List<DescribeDataCategoryGroupResult> describeCategoryResult;
	  List<DescribeDataCategoryGroupStructureResult> describeCategoryStructureResult;
	  try {
	     //Making the call to the describeDataCategoryGroups to
	     //get the list of category groups associated
	     List<String> objType = new List<String>();
	     objType.add('KnowledgeArticleVersion');
	     describeCategoryResult = Schema.describeDataCategoryGroups(objType);
	     
	     //Creating a list of pair objects to use as a parameter
	     //for the describe call
	     List<DataCategoryGroupSobjectTypePair> pairs = 
	        new List<DataCategoryGroupSobjectTypePair>();
	     
	     //Looping throught the first describe result to create
	     //the list of pairs for the second describe call
	     for(DescribeDataCategoryGroupResult singleResult : 
	     describeCategoryResult){
	        DataCategoryGroupSobjectTypePair p =
	           new DataCategoryGroupSobjectTypePair();
             system.debug('singleResult.getSobject()'+singleResult.getSobject());
              system.debug('singleResult.getName()'+singleResult.getName());
	        p.setSobject(singleResult.getSobject());
	        p.setDataCategoryGroupName(singleResult.getName());
	        pairs.add(p);
	     }
	     
	     //describeDataCategoryGroupStructures()
	     describeCategoryStructureResult = 
	        Schema.describeDataCategoryGroupStructures(pairs, false);

          integer count = 0;
	     //Getting data from the result
	     for(DescribeDataCategoryGroupStructureResult singleResult : describeCategoryStructureResult){                          
	        //Get name of the associated Sobject
	        singleResult.getSobject();
 //system.debug('singleResult.getSobject() Next'+singleResult.getSobject());
	        //Get the name of the data category group
	        singleResult.getName();
//system.debug('singleResult.getName() Next'+singleResult.getName());
	        //Get the name of the data category group
	        singleResult.getLabel();
system.debug('singleResult.getLabel() Next'+singleResult.getLabel());
	        //Get the description of the data category group
	        singleResult.getDescription();
			
             if(singleResult.getLabel() == 'Role')
             {
	        //Get the top level categories
	        DataCategory [] toplevelCategories = 
	           singleResult.getTopCategories();
	        system.debug('singleResult.getTopCategories() Next'+singleResult.getTopCategories());
             wrap.parentCount = singleResult.getTopCategories().size();
	        //Recursively get all the categories
	        List<DataCategory> allCategories = 
	           getAllCategories(toplevelCategories);
				
	        //take out 'All' category from allcategories for better processing
	        List<DataCategory> categoryToIterate = new List<DataCategory>();

	        for(DataCategory category: allCategories){
                categoryToIterate.add(category);
	         /* if(category.getName().equalsIgnoreCase('All')){
	              categoryToIterate.add(category);
	           }*/
	        }
	        
	        displayCategories(categoryToIterate, '', new Node());

             }
	     }
         
	  } catch (Exception e){
	  }
	  return describeCategoryStructureResult;
	}
 
	private static void displayCategories(List<DataCategory> allCategories, String parentName, Node node){
	 for(DataCategory category : allCategories) {
         if(!category.getName().equalsIgnoreCase('All')){
	   	System.debug('No Child' + category.getName() +' - '+ parentName); 
	   Node nd = new Node();
	   nd.label = category.getLabel();
       nd.Name =  category.getName();
	   if(node.label != null){
	     node.items.add(nd);
	   }else{
           nd.recordId = 'parent';
	     wrap.items.add(nd);
	   }

	  // System.debug(category.getName() +' - '+ parentName);
	  
	   DataCategory[] childs = category.getChildCategories();
	   if(!childs.isEmpty()){
	     displayCategories(childs, category.getName(), nd);
	   }
         else
         {
				System.debug('No Child' + category.getName() +' - '+ parentName); 
             if(mapArticles.containsKey(category.getName()))
             {                                            
	     			for(articleList art : mapArticles.get(category.getName()))
                    {
                        Node nd1 = new Node();
	   					nd1.label = art.title;  
                        nd1.name = art.recordId;
                        nd.items.add(nd1);
                    }                                                   
             }
         }
	   
	 }
     }
	}

	private static DataCategory[] getAllCategories(DataCategory [] categories){
	  if(categories.isEmpty()){
	     return new DataCategory[]{};
	  } else {
	     DataCategory [] categoriesClone = categories.clone();
	     DataCategory category = categoriesClone[0];
	     DataCategory[] allCategories = new DataCategory[]{category};
	     categoriesClone.remove(0);
	     categoriesClone.addAll(category.getChildCategories());
	     allCategories.addAll(getAllCategories(categoriesClone));
	     return allCategories;
	  }
	}


	/************************************************************************************
	********************************* WRAPPERS *********************************************
	***************************************************************************************/
 
	public class wrapper{
        List<node> items;
        integer parentCount;
        public wrapper(){
          items = new List<node>();
      }
    }
    
  
    public class node{
        String label;
        String recordId;
        String name;
        List<node> items;
        public node(){
          items = new List<node>();
        }
    }
    
    
    public class articleList{
       public string title;
       public string recordId;
       public string label;
    }
}