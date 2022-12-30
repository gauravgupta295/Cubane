import { LightningElement,wire,api,track } from 'lwc';

export default class KnowledgeRightBar extends LightningElement {  

    @api contentDetail;   
    @api contentType;
    @track displayDetail;
    @track displayList;
    @track displayCategory;

    @api
    setUpScreen(screenType, params)
    {
        console.log('Ray got in 1!');
        console.log(screenType);
        this.contentType = screenType;
        this.contentDetail = params;
        console.log('contedtType'+this.contentType);
        console.log('contentDetail'+this.contentDetail);
        console.log('Ray got in 2!');
        if(this.contentType === 'Detail')
        {
            this.displayDetail = true;
            this.displayList = false
            this.displayCategory = false;
            if(this.template.querySelector('c-knowledge-article-detail'))
                this.template.querySelector('c-knowledge-article-detail').showArticle(this.contentDetail);        
        }    
        else if(this.contentType === 'List')
        {
            this.displayDetail = false;
            this.displayList = true
            this.displayCategory = false;
            if(this.template.querySelector('c-knowledge-article-list'))
                this.template.querySelector('c-knowledge-article-list').displayArticleList(this.contentDetail);     
        }
        else
        {
            this.displayDetail = false;
            this.displayList = false
            this.displayCategory = true;
        }
    }

    onItemSelected(event)
    {
       // event.preventDefault();
        console.log('event.detail'+event.detail);
        this.rightBarScreenType = 'Detail';       
        this.articleDetail = event.detail;   
        this.setUpScreen('Detail',this.articleDetail);        
    }

    ItemSelected(event)
    {
        event.preventDefault();
       // console.log('event.detail'+event.detail);
        this.rightBarScreenType = 'Detail';       
        //this.articleDetail = event.detail;   
        this.setUpScreen('Detail',event.target.dataset.id);        
    }
}