import { LightningElement, api, track , wire} from 'lwc';
import getTicketDetail from '@salesforce/apex/KnowledgeCustomCmpController.getTicketDetail'; 
import getPriorityValues from '@salesforce/apex/GetCaseData.getPriorityValues';
import updateTicketDetail from '@salesforce/apex/KnowledgeCustomCmpController.updateTicketDetail';
import replyCommentonFeed from '@salesforce/apex/KnowledgeCustomCmpController.replyCommentonFeed'; 
import loadCaseFeedItem from '@salesforce/apex/KnowledgeCustomCmpController.loadCaseFeedItem';  
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class TicketDetail extends LightningElement {

    @api recordId;
    @api ticketId = '5005j00000Gx3LzAAJ';
    @track PriorityOptions;
    @track ticketDetail;
    @track descriptionValue;
    @track caseAttachments = [];
    @track Priorityvalue;
    @track ticketStatus;
    @track ccValue;
    @track ticketLastModifyDate;
    @track ticketSubject;
    @track IsValid = true;
    @track caseComment;
    @track caseFeeds;
    @track currentUserName;
    @track filesData = [];
    @track CaseNumber;
    @track loaded = false;
    @track loggedUserTimeZone;
    formats = [
       
        'bold',
        'italic',
        'underline',
        'strike',
        'list',
        'clean'
    ];
    @wire(getPriorityValues, {})
    WiredObjects_Priority({ error, data }) {
 
        if (data) {
            try {
                let Priority = [];
                for (var key in data) {
                    // Here key will have index of list of records starting from 0,1,2,....
                    Priority.push({label: data[key], value: data[key]});
                    // Here Name and Id are fields from sObject list.
                }
                this.PriorityOptions = Priority;
                 
            } catch (error) {
                console.error('check error here', error);
                this.showToast('error', error, 'error');
            }
        } else if (error) {
            console.error('check error here', error);
            this.showToast('error', error, 'error');
        }
 
    }

    connectedCallback()
    {       
       // alert('af');
        console.log('recordId'+this.recordId);
       
           // this.ticketId  = this.recordId;
           console.log('s'+window.location.href.split('/')[5]);
            this.ticketId = window.location.href.split('/')[5];
            this.loadArticleDetail(this.ticketId);
       
        
    }

    @api
    loadArticleDetail(ticketId)
    {
        getTicketDetail({'ticketId' :ticketId})
        .then(result => {
            console.log('articleDetails '+JSON.stringify( result));
            this.ticketDetail = result.CaseDetails;   
            this.caseFeeds = result.caseFeedList;
            this.currentUserName = result.currentUserName;
            this.ccValue  = this.ticketDetail.CC__c; 
            this.Priorityvalue = this.ticketDetail.Priority; 
            this.descriptionValue = this.ticketDetail.Description;
            this.caseAttachments = result.caseAttachments;
            console.log(result.caseAttachments);
            this.ticketStatus = this.ticketDetail.Status;
            this.ticketSubject = this.ticketDetail.Subject;
            this.ticketLastModifyDate = this.ticketDetail.LastModifiedDate;

            this.loggedUserTimeZone = result.currentUserTimeZone;
            // let targetTime = new Date(this.ticketDetail.LastModifiedDate);
            // let timeZoneFromDB = +10.00; //time zone value from database
            // //get the timezone offset from local time in minutes
            // let tzDifference = timeZoneFromDB * 60 + targetTime.getTimezoneOffset();
            // //convert the offset to milliseconds, add to targetTime, and make a new Date
            // console.log(new Date(targetTime.getTime() + tzDifference * 60 * 1000));
            // this.ticketLastModifyDate = new Date(targetTime.getTime() + tzDifference * 60 * 1000)
            this.CaseNumber = this.ticketDetail.CaseNumber;
        })
        .catch(error => {
            this.showToast('error', error, 'error');
        });
    }

    handlePriorityChange(event)
    {
        this.Priorityvalue = event.target.value;
        this.IsValid = false;
    }

    handleCCChange(event)
    {
        this.ccValue = event.target.value;
        this.IsValid = false;
    }

    updateTicketDetail(event)
    {
        var pattern = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}$/;
        var checker = true;

        console.log(this.ccValue);

        if(this.ccValue){
            for(let i=0; i<this.ccValue.split(';').length; i++){
                var splitVal = this.ccValue.split(';')[i];
                if(splitVal){
                    var trimmedSplitVal = splitVal.trim();
                    console.log('Trimmed SplitVal: ' + trimmedSplitVal);
                    if(!pattern.test(trimmedSplitVal)){
                        checker = false;
                    }
                }
            }
        }
        console.log('Final Checker: ' + checker);
        
        if(checker){
        this.loaded = true;
        let ticketDetail = {};
        ticketDetail.Description = this.descriptionValue;
        ticketDetail.CC__c = this.ccValue;
        ticketDetail.Id = this.ticketId;
        ticketDetail.Priority=this.Priorityvalue;
        updateTicketDetail({'ticketDetail' :ticketDetail})
        .then(result => {
            console.log('articleDetails '+result);       
            this.loaded = false;     
            this.showToast('Success', result, 'success');
        })
        .catch(error => {
            this.loaded = false;  
            this.error = error;
            this.showToast('error', error, 'error');
        });
        }else{
            this.showToast('Error', 'Please enter correct email addresses separated by semicolon','error');
        }
        
    }

    SavecaseFeedComment(event)
    {
        console.log(event.target.value);
        this.caseFeedComment = event.target.value;
    }

    putCaseComment(event)
    {
        if(this.caseFeedComment)
        {
            let comment = this.template.querySelector('lightning-input-rich-text').value;
        let ticketFeed = {};
        ticketFeed.Body = this.caseFeedComment;
        ticketFeed.ParentId = this.ticketId;
        this.loaded = true;
        let file = this.filesData.length > 0 ? this.filesData : null;
        replyCommentonFeed({'feed' :ticketFeed, 'filedata' : JSON.stringify(file)})
        .then(result => {
            console.log('putCaseComment '+result)
            this.getAllCaseFeedItem();
            this.caseFeedComment = '';
            this.filesData = [];
            this.template.querySelector('form').reset();
            this.loaded = false;  
            this.showToast('Success', result, 'success');
        })
        .catch(error => {
            this.error = error;
            this.loaded = false;  
            this.showToast('error', error, 'error');
        });
    }
    else{
        this.showToast('error', 'Please Enter Comment', 'error');
    }
    }

    getAllCaseFeedItem()
    {
        
        loadCaseFeedItem({'ticketId' :this.ticketId})
        .then(result => {
            console.log('putCaseComment '+result)
            this.caseFeeds = result; 
            //this.showToast('Success', result, 'success');
        })
        .catch(error => {
            this.error = error;
            this.showToast('error', error, 'error');
        });
    }
    

    showToast(title, messgae,variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: messgae,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    handleFileUploaded(event) {
        console.log('got in for file upload method');
        if (event.target.files.length > 0) {
            for(var i=0; i< event.target.files.length; i++){
                console.log('got in with files');
                if (event.target.files[i].size > 20000000) //Checking if file size is more than 20 MB
                {
                    console.log('got in file big');
                    let message = "File size should not be more than 20 MB";
                    const msg = new ShowToastEvent({title:message, message:'',variant:"error",mode:"dismissable"});
                    this.dispatchEvent(msg);
                    return;
                }
                let file = event.target.files[i];
                let reader = new FileReader();
                reader.onload = e => {
                    var fileContents = reader.result.split(',')[1]
                    this.filesData.push({'fileName':file.name, 'fileContent':fileContents});
                };
                reader.readAsDataURL(file);
            }
        }
    }

}