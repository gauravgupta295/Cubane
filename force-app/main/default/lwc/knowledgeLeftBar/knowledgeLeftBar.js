import { LightningElement, wire ,api } from 'lwc';
import getSidebarData from '@salesforce/apex/DataCategories.getSidebarData';

export default class KnowledgeLeftBar extends LightningElement {

    @api items;

    // @wire(getSidebarData)
    // wiredContacts({ error, data }) {
    //     if (data) {
    //        console.log('data'+data);
    //        this.items = JSON.parse(data);
    //     } else if (error) {
    //         console.log('error'+error);
    //     }
    // }
    //  selectedItemValue;

    handleOnselect(event) {
          // Creates the event with the contact ID data.
          if(event.detail.name.startsWith('ka'))
          {
          const selectedEvent = new CustomEvent('selected', { detail: event.detail.name });

          // Dispatches the event.
          this.dispatchEvent(selectedEvent);
          }
    }
   

}