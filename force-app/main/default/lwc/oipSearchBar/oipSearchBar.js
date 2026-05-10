import { LightningElement, api, track } from 'lwc';

export default class OipSearchBar extends LightningElement {
    @api placeholder = 'Search metadata components...';
    @api componentTypes;
    @track queryText = '';
    @track selectedType = 'All';

    get typeOptions() {
        let options = [{ label: 'All', value: 'All' }];
        if (this.componentTypes) {
            for (let ct of this.componentTypes) {
                options.push({ label: ct, value: ct });
            }
        }
        return options;
    }

    handleQueryChange(event) {
        this.queryText = event.target.value;
    }

    handleTypeChange(event) {
        this.selectedType = event.detail.value;
    }

    handleSearch() {
        this.dispatchEvent(new CustomEvent('searchsubmit', {
            detail: { query: this.queryText, type: this.selectedType }
        }));
    }

    handleKeyUp(event) {
        if (event.key === 'Enter') {
            this.handleSearch();
        }
    }
}
