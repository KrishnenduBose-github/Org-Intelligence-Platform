import { LightningElement, wire, track } from 'lwc';
import getReleaseChecklist from '@salesforce/apex/OIP_ReleaseChecklist.getReleaseChecklist';

export default class OipReleaseChecklist extends LightningElement {
    @track items = [];
    @track allPassed = true;

    @wire(getReleaseChecklist)
    wiredChecklist({ error, data }) {
        if (data) {
            this.items = data;
            this.allPassed = data.every(item => item.status === 'Pass');
        }
    }

    get passedCount() { return this.items.filter(i => i.status === 'Pass').length; }
    get totalCount() { return this.items.length; }
}
