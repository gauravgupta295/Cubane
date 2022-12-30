import { LightningElement, api, track, wire } from 'lwc';
import getChatterGroups from '@salesforce/apex/Forums.GetForumsDataBasedOnCategory';
import getForumsDetails from '@salesforce/apex/Forums.getForumsDetails';
import getFilteredForumDetails from '@salesforce/apex/Forums.getFilteredForumDetails';
import postChatterFeed from '@salesforce/apex/Forums.postChatterFeed';
import getChatterEmailSetting from '@salesforce/apex/Forums.getChatterEmailSetting';
import setChatterEmailSetting from '@salesforce/apex/Forums.setChatterEmailSetting';
import { loadStyle } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CubaneForums extends LightningElement {
    showCreateTopicModal = false;
    formats = [
        'bold',
        'italic',
        'underline',
        'strike',
        'list',
        'clean'
    ];
    @track optOutEmail;//USED FOR EMAIL OPT OUT CHECKBOX
    @track forumIdList = [];//USED IF SELECTED FILTER IS ANY
    @track filesData = [];
    @track showSpinner = false;
    @track forums = [];
    @track value = [];
    @track newTopicForumGroup;
    @track recordsListInPage;
    @track empty = true;
    @track optionsCategory = [{ label: 'Any', value: 'Any' }];
    @track columns = [
        {
            label: 'Category',
            fieldName: 'Category',
            type: 'text',
            sortable: true,
            cellAttributes:{
                class:{fieldName:'tableData'}
            },
        },
        {
            label: 'Topic',
            fieldName: 'GroupUrl',
            cellAttributes:{
                class:{fieldName:'caseNumColor'}
            },
            type: 'url',
            typeAttributes: { label: { fieldName: 'Topic' } },
            sortable: true
        },
        {
            label: 'Replies',
            fieldName: 'Replies',
            type: 'text',
            sortable: true,
            cellAttributes:{
                class:{fieldName:'tableData'}
            }
        },
        {
            label: 'Last Post',
            fieldName: 'CreatedDate',
            type: 'date',
            typeAttributes: {
                day: 'numeric', month: 'numeric', year: 'numeric',
                hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true
            },
            sortable: true,
            cellAttributes:{
                class:{fieldName:'tableData'}
            }
        }];

    categoryIdFilter = 'Any';
    categoryIdNewTopic;
    topicFilter;
    placeHolderValue = 'Subject: \n\nBody';

    connectedCallback() {
        getChatterEmailSetting().then(result => {
            console.log('This opt Out Email Result: ' + result);
            this.optOutEmail = result;
        }).catch(error => {
            console.log(error.message);
            this.showToast('Error', 'error', error.message);
        });

        getChatterGroups().then(result => {
            console.log('Result on Chatter Group Query');
            console.log(result);
            for (var key in result) {
                this.forums.push({ label: result[key].CollaborationGroup.Name, value: result[key].CollaborationGroupId });
                this.forums = JSON.parse(JSON.stringify(this.forums));

                this.optionsCategory.push({ label: result[key].CollaborationGroup.Name, value: result[key].CollaborationGroupId });
                this.optionsCategory = JSON.parse(JSON.stringify(this.optionsCategory));

                this.forumIdList.push(result[key].CollaborationGroupId);
            }
        }).catch(error => {
            console.log(error.message);
            this.showToast('Error', 'error', error.message);
        }).finally(() => this.handleSearchFilter() );

        
    }

    renderedCallback() {
        let style = document.createElement('style');
        //style.innerText = '.slds-table .datatable-caseNum-color a{color: #488cdd;font-size:14px; !important;} [title="Topic"]{color: #488cdd;} .tableData{font-size:14px; !important}';
        style.innerText = '.slds-table .datatable-caseNum-color a{color: #488cdd;font-size:14px; !important;} .tableData{font-size:14px; !important}';
        this.template.querySelector('lightning-datatable').appendChild(style);
    }

    handleChangeChatterEmailSetting(event){
        if (event.target.checked) {
            this.optOutEmail = true;
        }else{
            this.optOutEmail = false;
        }
        console.log(this.optOutEmail);
        setChatterEmailSetting({ emailOptOut: this.optOutEmail }).then(result => {
        }).catch(error => {
            console.log(error.message);
            this.showToast('Error', 'error', error.message);
        });
    }

    showToast(title, variant, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                variant: variant,
                message: message,
            })
        );
    }

    /*
    handleListInputChange(event) {
        if (event.target.checked) {
            console.log('checked');
            this.value.push(event.target.dataset.id);
        }
        else {
            console.log('unchecked');
            this.value.forEach(function (item, index, object) {
                if (item === event.target.dataset.id) {
                    object.splice(index, 1);
                }
            });
        }
        // if(this.value.length)
        // {
        getForumsDetails({ forumIds: this.value })
            .then(result => {
                if (result) {
                    var resultData = JSON.parse(result);
                    console.log('Results');
                    console.log(resultData);
                    var data = resultData;
                    let parentArray = [];
                    for (let i = 0; i < data.length; i++) {
                        var newData = {
                            //TicketURL: '/s/group/' +data[i].Id,
                            GroupUrl: '/s/feed-item-page?feedId=' + data[i].forumRecord.Id,
                            Category: data[i].forumRecord.Parent.Name,
                            Topic: data[i].strippedHTMLBody,
                            caseNumColor: "datatable-caseNum-color",
                            Replies: data[i].forumRecord.CommentCount,
                            CreatedDate: data[i].forumRecord.FeedComments === null || data[i].forumRecord.FeedComments === undefined ? null : data[i].forumRecord.FeedComments.records[0].CreatedDate,
                            ForumRecordId: data[i].forumRecord.ParentId
                        };
                        parentArray.push(newData);
                        console.log(parentArray);
                    }
                    this.recordsListInPage = parentArray;
                    this.empty = false;
                    if (parentArray.length == 0) {
                        this.empty = true;
                    }
                }
                else {
                    this.empty = true;
                }
            })
            .catch(error => {
                this.empty = true;
                console.log('error' + error.message);
                //this.loader = false;
                //this.error = error;
            });
        console.log('Check what is clicked' + this.value);
        // }
    }*/



    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.recordsListInPage));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1 : -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.recordsListInPage = parseData;
    }

    handleFilterButtonClick(event) {
        this.categoryIdFilter = event.detail.value;
        console.log(this.categoryIdFilter);

        this.handleSearchFilter();
    }

    handleTopicFilter(event) {
        this.topicFilter = event.detail.value;
    }

    handleSearchFilter(event) {
        var categoryIdFilterForUse = [];
        if (this.categoryIdFilter === 'Any') {
            categoryIdFilterForUse = this.forumIdList;
        } else {
            var selectedForumIds = [];
            selectedForumIds.push(this.categoryIdFilter);
            categoryIdFilterForUse = selectedForumIds;
        }

        console.log(JSON.stringify(categoryIdFilterForUse));

        this.showSpinner = true;
        getFilteredForumDetails({ forumIds: categoryIdFilterForUse, filteredTopic: this.topicFilter })
            .then(result => {
                if (result) {
                    var resultData = JSON.parse(result);
                    console.log('Results');
                    console.log(resultData);
                    var data = resultData;
                    let parentArray = [];
                    for (let i = 0; i < data.length; i++) {
                        var newData = {
                            //TicketURL: '/s/group/' +data[i].Id,
                            GroupUrl: '/s/feed-item-page?feedId=' + data[i].forumRecord.Id,
                            Category: data[i].forumRecord.Parent.Name,
                            Topic: data[i].strippedHTMLBody,
                            caseNumColor: "datatable-caseNum-color",
                            tableData: "tableData",
                            Replies: data[i].forumRecord.CommentCount,
                            CreatedDate: data[i].forumRecord.FeedComments === null || data[i].forumRecord.FeedComments === undefined ? data[i].forumRecord.CreatedDate : data[i].forumRecord.FeedComments.records[0].CreatedDate,
                            ForumRecordId: data[i].forumRecord.ParentId
                        };
                        parentArray.push(newData);
                        console.log(parentArray);
                    }
                    this.recordsListInPage = parentArray;
                    this.empty = false;
                    if (parentArray.length == 0) {
                        this.empty = true;
                    }
                }
                else {
                    this.empty = true;
                }
            })
            .catch(error => {
                this.empty = true;
                console.log(JSON.stringify(error));
                console.log('error' + error.message);
                //this.loader = false;
                //this.error = error;
            }).finally(() => this.showSpinner = false );
    }

    handleCreateTopicButton() {
        this.richtext = null
        this.showCreateTopicModal = true;
    }

    handleCloseCreateTopicModal() {
        // to close modal set isModalOpen tarck value as false
        this.showCreateTopicModal = false;
    }

    handleChangeRTF(e) {
        this.richtext = e.detail.value;
        console.log(this.richtext);
    }

    handleSubmitTopic() {
        console.log(this.categoryIdNewTopic);
        console.log(this.richtext);
        if (!this.categoryIdNewTopic || !this.richtext) {
            this.showToast('Error', 'error', 'Please select a forum group and enter the details of the post');
        } else {
            this.showSpinner = true;
            let file = this.filesData.length > 0 ? this.filesData : null;
            postChatterFeed({
                chatterFeedGroupId: this.categoryIdNewTopic,
                richTextBody: this.richtext,//JSON.stringify(this.categoryIdNewTopic)
                filedata: JSON.stringify(file) 
            }).then(result => {
                console.log(result);
                //if (result && result == 'success') {
                this.filesData = [];
                this.filesSignedPrivacyForm = [];
                this.showToast('Success', 'success', 'Topic created successfully');
                this.showCreateTopicModal = false;


                //} else {
                //this.showToast('Error', 'error', result);
                //}
                this.handleSearchFilter();
            }).catch(error => {
                if (error && error.body && error.body.message) {
                    this.showToast('Error', 'error', error.body.message);
                }
            }).finally(() => this.showSpinner = false );
        }
        
    }

    handleChangeNewTopicForumGroup(event) {
        this.categoryIdNewTopic = event.detail.value;
        console.log(this.categoryIdNewTopic);
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