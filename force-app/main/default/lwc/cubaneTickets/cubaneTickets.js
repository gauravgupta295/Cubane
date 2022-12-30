import { LightningElement,wire,track } from 'lwc';
import getCaseList from '@salesforce/apex/GetCaseData.getCaseList';
import filterCases from '@salesforce/apex/GetCaseData.filterCases';
import getStatusValues from '@salesforce/apex/GetCaseData.getStatusValues';
import getPriorityValues from '@salesforce/apex/GetCaseData.getPriorityValues';
import strUserId from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import {getRecord} from 'lightning/uiRecordApi';

export default class CubaneTickets extends LightningElement {
    @track prfName;
    userId = strUserId;
    @track error;
    @track recordsListInPage ;    
    @track loader = false;
    @track error = null;
    @track pageSize = 50;
    @track pageNumber = 1;
    @track totalRecords = 0;
    @track totalPages = 0;
    @track recordEnd = 0;
    @track recordStart = 0;
    @track isPrev = true;
    @track isNext = true;
    @track sortBy;
    @track sortDirection;
    @track StatusOptions;
    @track PriorityOptions;
    @track Priorityvalue = '';
    @track value = ''
    @track dataFilterred = false;
    @track isChildModalOpen = false;
    @track isNewRecord = true;
    
    @wire(getRecord, {
        recordId: strUserId,
        fields: [PROFILE_NAME_FIELD]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
           this.error = error ; 
        } else if (data) {
            this.prfName =data.fields.Profile.value.fields.Name.value;        
        }
    }

    get showNewTicket() {
        if(this.prfName === 'Customer Community Login User (Collections)' || this.prfName === 'Customer Community Login User (UF Analytics)' )
           return false;
        
         return true;
          } 

    @track columns = [
    {
        label: 'Ticket Id',
        fieldName: 'TicketURL',
        cellAttributes:{
            class:{fieldName:'caseNumColor'}
        }, 
        type: 'url',
        typeAttributes: {label: { fieldName: 'CaseNumber' }},
        sortable: true,
        initialWidth: 100,
    },
    {
        label: 'Customer',
        fieldName: 'CreatedByName',
        type: 'text',
        sortable: true,
        initialWidth: 150,
        cellAttributes:{
            class:{fieldName:'tableData'}
        }
        //api:'CreatedBy.Name'
    },
    {
        label: 'Subject',
        fieldName: 'Subject',
        type: 'text',
        sortable: true,
        cellAttributes:{
            class:{fieldName:'tableData'}
        }
    },
    {
        label: 'Created',
        fieldName: 'CreatedDate',
        type: 'date',
        typeAttributes:{day:'numeric',month:'numeric',year:'numeric',
        hour:'2-digit',minute:'2-digit',second:'2-digit',hour12:true},
        sortable: true,
        initialWidth: 180,
        cellAttributes:{
            class:{fieldName:'tableData'}
        }
    },
    {
        label: 'Modified',
        fieldName: 'ModifiedDate',
        type: 'date',
        typeAttributes:{day:'numeric',month:'numeric',year:'numeric',
        hour:'2-digit',minute:'2-digit',second:'2-digit',hour12:true},
        sortable: true,
        initialWidth: 180,
        cellAttributes:{
            class:{fieldName:'tableData'}
        }
    },
    {
        label: 'Status',
        fieldName: 'Status',
        type: 'text',
        sortable: true,
        initialWidth: 180,
        cellAttributes:{
            class:{fieldName:'tableData'}
        }
    },
    {
        label: 'Priority',
        fieldName: 'Priority',
        type: 'text',
        sortable: true,
        initialWidth: 100,
        cellAttributes:{
            class:{fieldName:'tableData'}
        }
    }];

    
    //On load
    connectedCallback() {
        this.getCases();
    }

    renderedCallback() {
        let style = document.createElement('style');
        //style.innerText = '.slds-table .datatable-caseNum-color a{color: #488cdd;font-size:14px; !important;} [title="Ticket Id"]{color: #488cdd;} .tableData{font-size:14px; !important}';
        style.innerText = '.slds-table .datatable-caseNum-color a{color: #488cdd;font-size:14px; !important;} .tableData{font-size:14px; !important}';
        //style.innerText = '.slds-table .datatable-caseNum-color a{color: #488cdd;} [title="Ticket Id"]{color: #488cdd;}';
        this.template.querySelector('lightning-datatable').appendChild(style);
     
    }

 
    @wire(getStatusValues, {})
    WiredObjects_Status({ error, data }) {
 
        if (data) {
            try {
                // this.l_All_Types = data; 
                let Status = [];
                Status.push({label: '--Select--', value:''});
                for (var key in data) {
                    // Here key will have index of list of records starting from 0,1,2,....
                    Status.push({ label: data[key], value: data[key]  });
                    // Here Name and Id are fields from sObject list.
                }
                this.StatusOptions = Status;
                 
            } catch (error) {
                console.error('check error here', error);
            }
        } else if (error) {
            console.error('check error here', error);
        }
 
    }

 
    @wire(getPriorityValues, {})
    WiredObjects_Priority({ error, data }) {
 
        if (data) {
            try {
                let Priority = [];
                Priority.push({label: '--Select--', value:''});
                console.log('Data debug: ', data);
                for (var key in data) {
                    // Here key will have index of list of records starting from 0,1,2,....
                    Priority.push({label: data[key], value: data[key]});
                    // Here Name and Id are fields from sObject list.
                }
                this.PriorityOptions = Priority;
                 
            } catch (error) {
                console.error('check error here', error);
            }
        } else if (error) {
            console.error('check error here', error);
        }
 
    }

    doSorting(event) {
        /*
        if(event.detail.fieldName === 'Priority'){
            console.log('is priority');
            event.detail.fieldName = 'Priority_Number__c';
            this.sortBy = event.detail.fieldName;
        }else{
            this.sortBy = event.detail.fieldName;
        }*/
        if(event.detail.fieldName === 'Priority'){
            console.log('is priority');
            this.sortBy = event.detail.fieldName;
            this.sortDirection = event.detail.sortDirection;
            this.sortData('Priority_Number__c', this.sortDirection);
        }else{
            this.sortBy = event.detail.fieldName;
            this.sortDirection = event.detail.sortDirection;
            this.sortData(this.sortBy, this.sortDirection);
        }

    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.recordsListInPage));
        console.log(parseData);
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.recordsListInPage = parseData;
    }

    getCases(){
        this.loader = true;
        getCaseList({pageSize: this.pageSize, pageNumber : this.pageNumber})
        .then(result => {
            this.loader = false;
            if(result){
            var resultData = JSON.parse(result);
            var data = resultData.cases;
            let parentArray = [];
            for(let i=0;i<data.length;i++)
            {
                var onlyDate =  new Date(data[i].CreatedDate);
                var onlyModifiedDate = new Date(data[i].LastModifiedDate);
                var newData = {
                    TicketURL: '/s/ticket/' +data[i].Id,
                    CaseNumber: data[i].CaseNumber, 
                    caseNumColor: "datatable-caseNum-color",
                    tableData: "tableData",
                    CreatedByName: data[i].CreatedBy.Name,
                    Subject: data[i].Subject,
                    Status: data[i].Status,
                    Priority: data[i].Priority,
                    Id: data[i].Id,
                    //CreatedDate: onlyDate.getDate()+'/'+(onlyDate.getMonth()+1)+'/'+onlyDate.getFullYear(),
                    //ModifiedDate: onlyModifiedDate.getDate()+'/'+(onlyModifiedDate.getMonth()+1)+'/'+onlyModifiedDate.getFullYear()
                    CreatedDate: data[i].CreatedDate,
                    ModifiedDate: data[i].LastModifiedDate,
                    Priority_Number__c: data[i].Priority_Number__c//added by Ray
                };
                parentArray.push(newData);
                console.log(parentArray);
            }
            this.recordsListInPage = parentArray;
            this.pageNumber = resultData.pageNumber;
            this.totalRecords = resultData.totalRecords;
            this.recordStart = resultData.recordStart;
            this.recordEnd = resultData.recordEnd;
            this.totalPages = Math.ceil(resultData.totalRecords / this.pageSize);
            this.isNext = (this.pageNumber == this.totalPages || this.totalPages == 0);
            this.isPrev = (this.pageNumber == 1 || this.totalRecords < this.pageSize);
            }
        })
        .catch(error => {
            this.loader = false;
            this.error = error;
        });
    }
    
 
    //handle next
    handleNext(){
        this.pageNumber = this.pageNumber+1;
        if(this.value || this.Priorityvalue)
        {
            this.filterData();
        }
        else{
            this.getCases();
        }
    }
 
    //handle prev
    handlePrev(){
        this.pageNumber = this.pageNumber-1;
        if(this.value || this.Priorityvalue)
        {
            this.filterData();
        }
        else{
            this.getCases();
        }
    }
 
    handleStatusChange(event){
        this.value = event.target.value; 
        // Do Something.
    }

    handlePriorityChange(event)
    {
        this.Priorityvalue = event.target.value;
    }
    
    filterData(){
        console.log('In filter data');
        if(!this.dataFilterred)
        {
            this.pageSize = 50;
            this.pageNumber = 1;
            this.totalRecords = 0;
            this.totalPages = 0;
            this.recordEnd = 0;
            this.recordStart = 0;
        }
        filterCases({Status: this.value, Priority: this.Priorityvalue, pageSize: this.pageSize, pageNumber : this.pageNumber})
        .then(result=>{
            var resultData = JSON.parse(result);
            var data = resultData.cases;
            let parentArray = [];
            for(let i=0;i<data.length;i++)
            {
                var onlyDate =  new Date(data[i].CreatedDate);
                var onlyModifiedDate = new Date(data[i].LastModifiedDate);
                var newData = {
                    TicketURL: '/s/ticket/' +data[i].Id,
                    CaseNumber: data[i].CaseNumber, 
                    caseNumColor: "datatable-caseNum-color",
                    tableData: "tableData",
                    CreatedByName: data[i].CreatedBy.Name,
                    Subject: data[i].Subject,
                    Status: data[i].Status,
                    Priority: data[i].Priority,
                    Id: data[i].Id,
                    //CreatedDate: onlyDate.getDate()+'/'+(onlyDate.getMonth()+1)+'/'+onlyDate.getFullYear(),
                    //ModifiedDate: onlyModifiedDate.getDate()+'/'+(onlyModifiedDate.getMonth()+1)+'/'+onlyModifiedDate.getFullYear()
                    CreatedDate: data[i].CreatedDate,
                    ModifiedDate: data[i].LastModifiedDate,
                    Priority_Number__c: data[i].Priority_Number__c//added by Ray
                };
                parentArray.push(newData);
                console.log(parentArray);
            }
            this.recordsListInPage = parentArray;
            this.pageNumber = resultData.pageNumber;
            this.totalRecords = resultData.totalRecords;
            this.recordStart = resultData.recordStart;
            this.recordEnd = resultData.recordEnd;
            this.totalPages = Math.ceil(resultData.totalRecords / this.pageSize);
            this.isNext = (this.pageNumber == this.totalPages || this.totalPages == 0);
            this.isPrev = (this.pageNumber == 1 || this.totalRecords < this.pageSize);
            this.dataFilterred = true;
        })
        .catch(error=>{
            this.contactData=undefined;
        })
    }    

    handlePopUpClosed(event){
        this.isChildModalOpen = event.detail;
    }
    handleNewRecordCreated(event)
    {
        this.getCases();
    }
    openChildModal() {
        this.isChildModalOpen = true;
        this.isNewRecord = true;
    }

    resetFilter(){
        this.value = '';
        this.Priorityvalue = '';
        this.getCases();
 
    }   
}