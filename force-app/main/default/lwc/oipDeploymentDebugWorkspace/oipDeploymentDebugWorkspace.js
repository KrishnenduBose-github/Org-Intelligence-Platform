import { LightningElement, track, wire } from 'lwc';
import detectMissingDependencies from '@salesforce/apex/OIP_DeploymentDebuggerService.detectMissingDependencies';
import checkOIPUserPermission from '@salesforce/apex/OIP_DashboardController.checkOIPUserPermission';

export default class OipDeploymentDebugWorkspace extends LightningElement {
    @track components = '';
    @track targetOrgId = '';
    @track diff = null;
    @track isLoading = false;
    @track hasNoPermission = false;

    @wire(checkOIPUserPermission)
    wiredPermission({ error, data }) {
        if (data !== undefined) this.hasNoPermission = !data;
    }

    handleComponentsChange(event) { this.components = event.target.value; }
    handleOrgChange(event) { this.targetOrgId = event.target.value; }

    handleAnalyze() {
        if (!this.components.trim()) return;
        this.isLoading = true;
        const compList = this.components.split(',').map(c => c.trim()).filter(c => c);
        detectMissingDependencies({ componentFullNames: compList, targetOrgId: this.targetOrgId })
            .then(data => { this.diff = data; this.isLoading = false; })
            .catch(() => { this.isLoading = false; });
    }
}
