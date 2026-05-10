import { LightningElement, api, track } from 'lwc';

export default class OipSearchResults extends LightningElement {
    @api results = [];
    @track _isLoading = false;

    @api
    get isLoading() {
        return this._isLoading;
    }
    set isLoading(value) {
        this._isLoading = value;
    }

    get hasResults() {
        return this.results && this.results.length > 0;
    }

    get isEmpty() {
        return !this._isLoading && (!this.results || this.results.length === 0);
    }

    handleResultClick(event) {
        const index = event.currentTarget.dataset.index;
        this.dispatchEvent(new CustomEvent('resultselect', {
            detail: this.results[index]
        }));
    }

    get severityBadgeClass() {
        return {
            None: 'slds-text-color_weak',
            Low: 'slds-theme_warning',
            Medium: 'slds-theme_warning',
            High: 'slds-theme_error',
            Critical: 'slds-theme_error'
        };
    }
}
