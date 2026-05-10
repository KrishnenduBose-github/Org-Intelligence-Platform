import { LightningElement, api } from 'lwc';

export default class OipPhiWarningBanner extends LightningElement {
    @api phiTrace;

    get showWarning() { return this.phiTrace && this.phiTrace.isPHIField; }
    get bannerClass() {
        const risk = this.phiTrace?.complianceRisk;
        if (risk === 'High') return 'slds-theme_error';
        if (risk === 'Medium') return 'slds-theme_warning';
        return 'slds-theme_info';
    }
}
