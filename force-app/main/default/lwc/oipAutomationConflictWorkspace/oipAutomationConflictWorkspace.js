import { LightningElement, track, wire } from 'lwc';
import detectAllConflictsForObject from '@salesforce/apex/OIP_AutomationConflictDetector.detectAllConflictsForObject';
import checkOIPUserPermission from '@salesforce/apex/OIP_DashboardController.checkOIPUserPermission';

export default class OipAutomationConflictWorkspace extends LightningElement {
    @track objectName = 'Account';
    @track report = null;
    @track isLoading = false;
    @track hasNoPermission = false;

    objectOptions = [
        { label: 'Account', value: 'Account' },
        { label: 'Contact', value: 'Contact' },
        { label: 'Opportunity', value: 'Opportunity' },
        { label: 'Lead', value: 'Lead' },
        { label: 'Case', value: 'Case' },
        { label: 'Custom', value: '' }
    ];

    @wire(checkOIPUserPermission)
    wiredPermission({ error, data }) {
        if (data !== undefined) this.hasNoPermission = !data;
    }

    handleObjectChange(event) {
        this.objectName = event.detail.value;
        this.detectConflicts();
    }

    detectConflicts() {
        if (!this.objectName) return;
        this.isLoading = true;
        detectAllConflictsForObject({ objectApiName: this.objectName })
            .then(data => { this.report = data; this.isLoading = false; })
            .catch(() => { this.isLoading = false; });
    }

    connectedCallback() { this.detectConflicts(); }

    get reportTitle() {
        return this.report ? 'Conflicts for ' + this.report.objectName : 'Conflicts';
    }
}
