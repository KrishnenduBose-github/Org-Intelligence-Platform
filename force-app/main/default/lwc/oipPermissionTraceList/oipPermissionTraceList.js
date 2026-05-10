import { LightningElement, api } from 'lwc';

export default class OipPermissionTraceList extends LightningElement {
    @api trace;

    get hasSources() { return this.trace && this.trace.sources && this.trace.sources.length > 0; }

    get accessColor() {
        const level = this.trace?.accessLevel;
        if (level === 'Edit') return 'slds-theme_error';
        if (level === 'Read') return 'slds-theme_success';
        return 'slds-theme_inverse';
    }
}
