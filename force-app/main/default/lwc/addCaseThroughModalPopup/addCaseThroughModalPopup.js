import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import UploadMultipleFiles from '@salesforce/apex/UploadMultipleFiles.uploadFiles';
import CreateCases from '@salesforce/apex/CreateCases.CreateCases';

export default class AddCaseThroughModalPopup extends LightningElement {

    isrendered = false;
    @api isModalOpen;
    @api recordId;
    @api isNew;
    @api priorityOptions;
    @track priorityValue = 'Medium';
    @track descriptionValue;
    @track subjectValue;
    @track ccValue;
    @track showSpinner = false;
    @track recordId;
    @track filesData = [];
    @track dataLoaded = true;

    renderedCallback() {

        if (!this.isrendered) {
            this.isrendered = true;
            const styleTag = document.createElement('style');
            styleTag.innerText = "textarea { min-height: 100px; }";
            if (this.template.querySelector('lightning-textarea')) {
                this.template.querySelector('lightning-textarea').forEach((element) => {
                    element.appendChild(styleTag);
                })
            }
            //this.template.querySelector('lightning-textarea').appendChild(styleTag);
        }

    }

    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
    }
    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
        this.closePopup();
    }
    closePopup() {
        const closePopup = new CustomEvent("popupclosed", {
            detail: this.isModalOpen
        });
        this.dispatchEvent(closePopup);
    }

    clearId() {
        this.priorityValue = '';
        this.subjectValue = '';
        this.descriptionValue = '';
        this.ccValue = '';
    }

    handlePriorityChange(event) {
        this.priorityValue = event.target.value;
    }

    handleSubjectChanged(event) {
        this.subjectValue = event.target.value;
    }

    handleDescriptionChanged(event) {
        this.descriptionValue = event.target.value;
    }

    handleCcChanged(event) {
        this.ccValue = event.target.value;
    }

    isInputValid() {
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField => {
            if (!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
            //this.contact[inputField.name] = inputField.value;
        });
        return isValid;
    }

    submitDetails(event) {


        //FOR VALIDATE CC BOX
        var pattern = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}$/;
        var checker = true;

        console.log(this.ccValue);

        if (this.ccValue) {
            for (let i = 0; i < this.ccValue.split(';').length; i++) {
                var splitVal = this.ccValue.split(';')[i];
                console.log(splitVal);

                if (splitVal) {
                    var trimmedSplitVal = splitVal.trim();
                    console.log('Trimmed SplitVal: ' + trimmedSplitVal);
                    if (!pattern.test(trimmedSplitVal)) {
                        checker = false;
                    }
                }
            }
        }

        console.log('Final Checker: ' + checker);

        if (checker) {
            if (this.isInputValid()) {
                console.log('Valid');
            }
            if ((this.subjectValue != null && this.subjectValue!='') && (this.descriptionValue != null && this.descriptionValue != '')) {
                this.dataLoaded = false;
                if (this.subjectValue && this.descriptionValue && this.priorityValue) {
                    CreateCases({
                        Priority: this.priorityValue,
                        Subject: this.subjectValue,
                        Description: this.descriptionValue,
                        CCValue: this.ccValue
                    }).then(result => {
                        console.log('Result' + result);
                        if (this.filesData.length > 0) {
                            this.UploadMultipleFiles(result);
                        }
                        else {
                            let message = "Record created successfully";
                            const msg = new ShowToastEvent({ title: "Success", message: message, variant: "success", mode: "dismissable" });
                            this.dispatchEvent(msg);
                            const newRecordCreated = new CustomEvent("newrecordcreated", {
                                detail: 'result'
                            });
                            this.dispatchEvent(newRecordCreated);
                            this.isModalOpen = false;
                            this.closePopup();
                            this.clearId();
                            this.dataLoaded = true;
                        }
                    }).catch(error => {
                        if (error && error.body && error.body.message) {
                            const msg = new ShowToastEvent({ title: error.body.message, message: '', variant: "error", mode: "dismissable" });
                            this.dispatchEvent(msg);
                            this.isModalOpen = false;
                            this.closePopup();
                            this.clearId();
                            this.dataLoaded = true;
                        }
                    })
                }
            }
        } else {
            const msg = new ShowToastEvent({ title: 'Error', message: 'Please enter correct email addresses separated by semicolon', variant: "error", mode: "dismissable" });
            this.dispatchEvent(msg);
        }
    }


    handleFileUploaded(event) {
        if (event.target.files.length > 0) {
            for (var i = 0; i < event.target.files.length; i++) {
                if (event.target.files[i].size > 2000000) //Checking if file size is more than 20 MB
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

    UploadMultipleFiles(recordId) {
        if (this.filesData == [] || this.filesData.length == 0) {
            let message = "Please select files first";
            const msg = new ShowToastEvent({ title: message, message: '', variant: "error", mode: "dismissable" });
            this.dispatchEvent(msg);
            return;
        }
        this.showSpinner = true;
        UploadMultipleFiles({
            recordId: recordId,
            filedata: JSON.stringify(this.filesData)
        })
            .then(result => {
                console.log(result);
                if (result && result == 'success') {
                    this.dataLoaded = true;
                    this.filesData = [];
                    let message = "Record created successfully";
                    const msg = new ShowToastEvent({ title: "Success", message: message, variant: "success", mode: "dismissable" });
                    this.dispatchEvent(msg);
                    const newRecordCreated = new CustomEvent("newrecordcreated", {
                        detail: 'result'
                    });
                    this.dispatchEvent(newRecordCreated);
                    this.isModalOpen = false;
                    this.closePopup();
                    this.clearId();
                } else {
                    this.isModalOpen = false;
                    this.closePopup();
                    this.clearId();
                    const msg = new ShowToastEvent({ title: error.body.message, message: '', variant: "error", mode: "dismissable" });
                    this.dispatchEvent(msg);
                    this.dataLoaded = true;
                }
            }).catch(error => {
                if (error && error.body && error.body.message) {
                    this.isModalOpen = false;
                    this.closePopup();
                    this.clearId();
                    const msg = new ShowToastEvent({ title: error.body.message, message: '', variant: "error", mode: "dismissable" });
                    this.dispatchEvent(msg);
                    this.dataLoaded = true;
                }
            }).finally(() => this.showSpinner = false);
    }

    removeReceiptImage(event) {
        var index = event.currentTarget.dataset.id;
        this.filesData.splice(index, 1);
    }
}