import { LightningElement, api, wire,track} from 'lwc';
import searchArticle from '@salesforce/apex/KnowledgeCustomCmpController.searchArticle';

export default class KnowledgeArticleList extends LightningElement {

    @api contentDetail;
    @track articleList;

    connectedCallback()
    {
        console.log('searchText '+this.contentDetail) ;
        this.displayArticleList(this.contentDetail);
    }

    @api
    displayArticleList(contextText)
    {
        searchArticle({'searchText' :contextText})
        .then(result => {
           if(result && result.length > 0)
           {
            console.log('articleDetails '+result)
               this.articleList = result;   
           }
           else
           {
               this.articleList = undefined;
           }   
       })
       .catch(error => {
           this.error = error;
       });
    }
    LoadArticleDetail(event)
    {
        event.preventDefault();
        //alert(event.target.dataset.id);
         // Creates the event with the contact ID data.
         const selectedEvent = new CustomEvent('selected', { detail: event.target.dataset.id });

         // Dispatches the event.
         this.dispatchEvent(selectedEvent);
    }
}