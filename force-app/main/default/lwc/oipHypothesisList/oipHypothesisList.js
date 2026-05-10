import { LightningElement, api } from 'lwc';

export default class OipHypothesisList extends LightningElement {
    @api hypotheses = [];

    handleSelect(event) {
        const index = event.currentTarget.dataset.index;
        this.dispatchEvent(new CustomEvent('hypothesisselect', {
            detail: this.hypotheses[index]
        }));
    }

    get severityIcon() {
        return {
            Low: 'utility:success',
            Medium: 'utility:warning',
            High: 'utility:error'
        };
    }
}
