import { LightningElement, api } from 'lwc';

export default class OipConfidenceMeter extends LightningElement {
    @api confidence = 0;

    get meterStyle() {
        return 'width: ' + this.confidence + '%';
    }

    get meterColor() {
        if (this.confidence >= 80) return 'slds-theme_success';
        if (this.confidence >= 50) return 'slds-theme_warning';
        return 'slds-theme_error';
    }
}
