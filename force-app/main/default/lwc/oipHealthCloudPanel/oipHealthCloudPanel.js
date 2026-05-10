import { LightningElement, track, wire } from 'lwc';
import getPHIFields from '@salesforce/apex/OIP_HealthCloudService.getPHIFields';
import getCarePlanDependencies from '@salesforce/apex/OIP_HealthCloudService.getCarePlanDependencies';
import getConsentDependencies from '@salesforce/apex/OIP_HealthCloudService.getConsentDependencies';
import getEHRDependencies from '@salesforce/apex/OIP_HealthCloudService.getEHRDependencies';
import isPHIModeEnabled from '@salesforce/apex/OIP_FeatureFlagService.isPHIModeEnabled';
import checkOIPUserPermission from '@salesforce/apex/OIP_DashboardController.checkOIPUserPermission';

export default class OipHealthCloudPanel extends LightningElement {
    @track phiFields = [];
    @track carePlanDeps = [];
    @track consentDeps = [];
    @track ehrDeps = [];
    @track isPHIMode = false;
    @track isLoading = false;
    @track hasNoPermission = false;

    @wire(checkOIPUserPermission)
    wiredPermission({ error, data }) {
        if (data !== undefined) this.hasNoPermission = !data;
    }

    @wire(isPHIModeEnabled)
    wiredPHIMode({ error, data }) {
        if (data !== undefined) this.isPHIMode = data;
    }

    handleRefresh() {
        this.isLoading = true;
        Promise.all([
            getPHIFields(),
            getCarePlanDependencies(),
            getConsentDependencies(),
            getEHRDependencies()
        ]).then(results => {
            this.phiFields = results[0];
            this.carePlanDeps = results[1];
            this.consentDeps = results[2];
            this.ehrDeps = results[3];
            this.isLoading = false;
        }).catch(() => { this.isLoading = false; });
    }

    connectedCallback() {
        if (this.isPHIMode) this.handleRefresh();
    }
}
