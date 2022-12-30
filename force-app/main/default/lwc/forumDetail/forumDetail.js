import { LightningElement, api, track, wire } from 'lwc';
import loadChatterFeeds from '@salesforce/apex/KnowledgeCustomCmpController.loadChatterFeeds';
import replyCommentonChatter from '@salesforce/apex/KnowledgeCustomCmpController.replyCommentonChatter';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID from '@salesforce/user/Id';
import UserNameFld from '@salesforce/schema/User.Name';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import getParentFeedItemId from '@salesforce/apex/KnowledgeCustomCmpController.getParentFeedItemId';

export default class ForumDetail extends LightningElement {

    @api recordId;
    @api feedItemId;
    @track feedItemDetail;
    @track CollaborationGroupId;
    @track feedItemAttachments=[];
    @track descriptionValue;
    @track ticketLastModifyDate;
    @track ticketCreatedDate;
    @track caseComment;
    @track feedItemComments;
    @track currentUserName;
    @track runningUserName;
    @track filesData = [];
    @track loaded = false;
    @track loggedInUserTimeZone;
    @track collabGroupName;
    formats = [

        'bold',
        'italic',
        'underline',
        'strike',
        'list',
        'clean'
    ];
    @wire(getRecord, { recordId: USER_ID, fields: [UserNameFld] })
    userDetails({error, data}) {
        if (data) {
            this.runningUserName = data.fields.Name.value;
        } else if (error) {
            this.error = error ;
        }
    }
    
    connectedCallback() {
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);

        if (urlParams.has('feedId')) {
            this.feedItemId = urlParams.get('feedId');
            this.loadFeedItemDetail(this.feedItemId);
        } else{//ACCESSED USING EMAILV VIEW BUTTON
            const fullURL = window.location.href;
            console.log('URL ' , fullURL);


            const array = fullURL.split('feed/'); 
            console.log(array[1]);
            var feedDetail = array[1].slice(0,15);
            console.log(feedDetail);

            var startsWithID = feedDetail.slice(0,3);
            console.log(startsWithID);
            if(startsWithID == '0D5'){//FEED ITEM
                this.feedItemId = feedDetail;
                this.loadFeedItemDetail(this.feedItemId);
            }else if(startsWithID == '0D7'){//FEED COMMENT
                getParentFeedItemId({ 'feedCommentId': feedDetail})
                .then(result => {
                    console.log('results found here');
                    console.log(result);
                    this.feedItemId = result;
                    this.loadFeedItemDetail(this.feedItemId);
                })
                .catch(error => {
                    console.log('has errors');
                    console.log(error);
                    this.error = error;
                    this.loaded = false;
                    console.log(error.body.message);
                    if (error && error.body && error.body.message) {
                        this.showToast('Error', error.body.message, 'error');
                    } else {
                        this.showToast('error', error, 'error');
                    }
                });


                
            }
            

            
        }


        //console.log('feedItemId' + this.feedItemId);
        //this.loadFeedItemDetail(this.feedItemId);
    }

    @api
    loadFeedItemDetail(feedItemId) {
        loadChatterFeeds({ 'chatterFeedId': feedItemId })
            .then(result => {
                console.log('articleDetails ' + JSON.stringify(result));
                this.feedItemDetail = result.feedItemDetail;
                this.CollaborationGroupId = this.feedItemDetail.ParentId;
                this.feedItemAttachments = result.feedItemAttachments
                this.feedItemComments = result.feedCommentList;
                this.currentUserName = this.feedItemDetail.CreatedBy.Name;
                this.descriptionValue = this.feedItemDetail.Body;
                this.ticketLastModifyDate = this.feedItemDetail.LastModifiedDate;
                this.loggedInUserTimeZone = result.currentUserTimeZone;
                this.collabGroupName = this.feedItemDetail.Parent.Name;
                this.ticketCreatedDate = this.feedItemDetail.CreatedDate;
            })
            .catch(error => {
                this.showToast('error', error, 'error');
            });
            console.log(JSON.parse(JSON.stringify(this.feedItemAttachments)));
    }

    SavecaseFeedComment(event) {
        this.caseFeedComment = event.target.value;
    }

    putCaseComment(event) {
        let feedComment = {};
        feedComment.CommentBody = this.caseFeedComment;
        feedComment.ParentId = this.CollaborationGroupId;
        feedComment.FeedItemId = this.feedItemId;
        console.log('Feed Item ID: ' + this.feedItemId);
        this.loaded = true;
        let file = this.filesData.length > 0 ? this.filesData : null;
        replyCommentonChatter({ 'comment': feedComment, 'filedata': JSON.stringify(file) })
            .then(result => {
                console.log('putCaseComment ' + result)
                this.loadFeedItemDetail(this.feedItemId);
                this.caseFeedComment = '';
                this.filesData = [];
                this.template.querySelector('form').reset();
                this.loaded = false;
                this.showToast('Success', result, 'success');
            })
            .catch(error => {
                this.error = error;
                this.loaded = false;
                console.log(error.body.message);
                if (error && error.body && error.body.message) {
                    this.showToast('Error', error.body.message, 'error');
                } else {
                    this.showToast('error', error, 'error');
                }
            });
    }

    showToast(title, messgae, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: messgae,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    handleFileUploaded(event) {
        if (event.target.files.length > 0) {
            for (var i = 0; i < event.target.files.length; i++) {
                if (event.target.files[i].size > 20000000) //Checking if file size is more than 20 MB
                {
                    let message = "File size should not be more than 20 MB";
                    const msg = new ShowToastEvent({ title: message, message: '', variant: "error", mode: "dismissable" });
                    this.dispatchEvent(msg);
                    return;
                }
                let file = event.target.files[i];
                let reader = new FileReader();
                reader.onload = e => {
                    var fileContents = reader.result.split(',')[1]
                    this.filesData.push({ 'fileName': file.name, 'fileContent': fileContents });
                };
                reader.readAsDataURL(file);
            }
        }
    }
}