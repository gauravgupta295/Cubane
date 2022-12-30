import { LightningElement } from 'lwc';

export default class KnowledgeTopBar extends LightningElement {

    searchText;
    searchTextValue(event)
    {
        this.searchText = event.target.value;
    }
    handleSearchArtcile(event)
    {

        // Creates the event with the contact ID data.
         const selectedEvent = new CustomEvent('search', { detail: this.searchText });

         // Dispatches the event.
         this.dispatchEvent(selectedEvent);
    }
}