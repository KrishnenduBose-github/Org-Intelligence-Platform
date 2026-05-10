import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import searchComponents from '@salesforce/apex/OIP_DependencyGraphEngine.searchNodes';
import checkOIPUserPermission from '@salesforce/apex/OIP_DashboardController.checkOIPUserPermission';

export default class OipSearchWorkspace extends LightningElement {
    @track results = [];
    @track isLoading = false;
    @track hasNoPermission = false;

    componentTypes = ['ApexClass', 'Flow', 'LWC', 'ApexTrigger', 'CustomField', 'CustomObject', 'ValidationRule', 'PermissionSet', 'Profile'];

    @wire(CurrentPageReference) pageRef;
    @wire(checkOIPUserPermission)
    wiredPermission({ error, data }) {
        if (data !== undefined) {
            this.hasNoPermission = !data;
        }
    }

    handleSearchSubmit(event) {
        const { query, type } = event.detail;
        if (!query || query.trim().length === 0) {
            return;
        }
        this.isLoading = true;
        searchComponents({ searchTerm: query })
            .then(data => {
                this.results = data.map(record => ({
                    id: record.Id,
                    fullName: record.OIP_FullName__c,
                    componentType: record.OIP_ComponentType__c,
                    severityRating: record.OIP_SeverityRating__c
                }));
                this.isLoading = false;
            })
            .catch(error => {
                this.results = [];
                this.isLoading = false;
            });
    }

    handleResultSelect(event) {
        console.log('Selected:', JSON.stringify(event.detail));
    }
}
