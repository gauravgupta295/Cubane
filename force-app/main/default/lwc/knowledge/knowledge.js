import { LightningElement,wire,track } from 'lwc';
import getSidebarData from '@salesforce/apex/DataCategories.getSidebarData';

export default class Knowledge extends LightningElement {

    @track items;
    @track categories;
  //  @track menuItems;
    @track menuItems=[];
    @track articleDetail;
    @track rightBarScreenType;
    @wire(getSidebarData)
    wiredContacts({ error, data }) {
        if (data) {
           console.log('data'+data);
           this.items = JSON.parse(data); 
           for(let i=0;i<this.items.parentCount;i++)
           {
             this.menuItems.push(this.items.items[i].label);
           }
           
           
          // this.menuItems =  this.items.map(a => a.label);
           //this.menuItems =  data;
           console.log('menuItems'+this.menuItems);
           this.loadLeftBar(this.menuItems[0]);

        } else if (error) {
            console.log('error'+error);
        }
    }

    onItemSelected(event)
    {
        console.log('event.detail'+event.detail);
        this.rightBarScreenType = 'Detail';       
        this.articleDetail = event.detail;   
        this.template.querySelector('c-knowledge-right-bar').setUpScreen('Detail', event.detail);        
    }

    searchArticle(event)
    {
        console.log('event.detail'+event.detail) ;
        this.rightBarScreenType = 'List';       
        this.articleDetail = event.detail; 
        this.template.querySelector('c-knowledge-right-bar').setUpScreen('List', event.detail);        
    }
    loadLeftBar(category)
    {
        if(category)
        {
            this.categories = this.items.items.filter(obj => {
                return obj.label === category
              })[0].items;
        }
        else
        this.categories = this.items[0].items;
        this.LoadRightBar(category,'Category');
    }
    LoadRightBar(category,screenType)
    {
        this.rightBarScreenType = screenType;
        console.log('category'+category) ;
        category  = category.split(' ').join('_');
            let fistItem =category;
            this.articleDetail = this.items.items.filter(e=>e.name === category)[0].items;   
            //COMMENTED BY RAY - NEEDS TO HAVE A BIT OF DELAY FOR CHILD COMPONENT TO RE RENDER BEFOR CALLING CHILD METHOD - SOLUTION NEEDS TO BE FURTHER TESTED
           //this.template.querySelector('c-knowledge-right-bar').setUpScreen('Category', this.articleDetail);    
           setTimeout(() =>this.template.querySelector('c-knowledge-right-bar').setUpScreen('Category', this.articleDetail));       
    }

    isCategoryClicked = false;
    filterCategories(event)
    {        
        this.isCategoryClicked = true;
        this.loadLeftBar(event.target.dataset.category);   
        if(this.template.querySelectorAll('.selectd'))
        this.template.querySelectorAll(".selectd")[0].classList.remove("selectd")
        event.target.classList.add('selectd'); 
    }

    renderedCallback()
    {
        if(!this.isCategoryClicked)
        {
            setTimeout(() =>this.template.querySelectorAll('.custom-box')[0].classList.add('selectd')); 
        }
    }
}