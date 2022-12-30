import { LightningElement, api, wire, track} from 'lwc';
import getData from '@salesforce/apex/KnowledgeCustomCmpController.getdata';
export default class KnowledgeArticleDetail extends LightningElement {

    @api contentDetail;

    @track articleDetail;
    @track articleTitle;

    connectedCallback()
    { console.log('contentDetail '+this.contentDetail) ;
        this.showArticle(this.contentDetail);
    }

    @api
    showArticle(articleId)
    {
        console.log('contentDetail '+articleId) ;
     getData({'recordId' :articleId})
     .then(result => {
         console.log('articleDetails '+result)
        var updatedString = result.Content__c;
        updatedString = updatedString.replaceAll('<h1>','<h1 style=\"font-weight:normal;margin-bottom:20px;\">');
        updatedString = updatedString.replaceAll('<h2>','<h2 style=\"font-size:17px;margin-top:20px;margin-bottom:20px;font-weight:normal;border-top:solid;border-top-color:rgb(232,237,255);padding-top:33px\">');
        updatedString = updatedString.replaceAll('<h3>','<h3 style=\"font-weight:normal;\">');
        updatedString = updatedString.replaceAll('<li>','<li style=\"padding-left:8px;margin-bottom:8px;font-size:14px;\">');
        updatedString = updatedString.replaceAll('<p>','<p style=\"font-size:14px;\">');
        updatedString = updatedString.replaceAll('<th ','<th style=\"font-size:14px;padding:6px;background-color:rgb(80,95,106);color:white;\" ');
        updatedString = updatedString.replaceAll('<td ','<td style=\"font-size:14px;padding:6px;\" ');
        console.log(updatedString);
        this.articleDetail = updatedString;
        this.articleTitle = result.Title;
    })
    .catch(error => {
        this.error = error;
    });
    }
    renderedCallback() {
        // if(this.articleDetail){
        //     const container = this.template.querySelector('.container'); 
        //     container.innerHTML =  this.articleDetail.Content__c;
        // }
    }

    openPrintWindow()
    {
        window.print();
    }
}