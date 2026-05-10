import { LightningElement, track, wire } from 'lwc';
import resolveFieldAccess from '@salesforce/apex/OIP_PermissionResolverService.resolveFieldAccess';
import tracePHIAccess from '@salesforce/apex/OIP_PermissionResolverService.tracePHIAccess';
import checkOIPUserPermission from '@salesforce/apex/OIP_DashboardController.checkOIPUserPermission';

export default class OipSecurityDebugWorkspace extends LightningElement {
    @track userId = '';
    @track objectName = 'Account';
    @track fieldName = 'Name';
    @track trace = null;
    @track phiTrace = null;
    @track isLoading = false;
    @track hasNoPermission = false;
    @track errorMessage = '';

    objectOptions = [
        { label: 'Account', value: 'Account' },
        { label: 'Contact', value: 'Contact' },
        { label: 'Opportunity', value: 'Opportunity' },
        { label: 'Lead', value: 'Lead' },
        { label: 'Case', value: 'Case' }
    ];

    @wire(checkOIPUserPermission)
    wiredPermission({ error, data }) {
        if (data !== undefined) this.hasNoPermission = !data;
    }

    handleObjectChange(event) { this.objectName = event.detail.value; }
    handleFieldChange(event) { this.fieldName = event.target.value; }
    handleUserIdChange(event) { this.userId = event.target.value; }

    handleTrace() {
        if (!this.objectName || !this.fieldName) return;
        this.isLoading = true;
        this.errorMessage = '';
        resolveFieldAccess({ userId: this.userId || UserInfo.getUserId(), objectApiName: this.objectName, fieldApiName: this.fieldName })
            .then(data => { this.trace = data; this.isLoading = false; })
            .catch(err => { this.errorMessage = err.body?.message || err.message; this.isLoading = false; });
    }

    handleCheckPHI() {
        tracePHIAccess({ objectApiName: this.objectName })
            .then(data => { this.phiTrace = data; })
            .catch(() => { this.phiTrace = null; });
    }

    connectedCallback() {
        this.handleCheckPHI();
    }
}
