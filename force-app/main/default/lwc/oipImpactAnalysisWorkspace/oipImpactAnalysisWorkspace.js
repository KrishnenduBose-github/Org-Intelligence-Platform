import { LightningElement, track, wire } from 'lwc';
import checkOIPUserPermission from '@salesforce/apex/OIP_DashboardController.checkOIPUserPermission';

export default class OipImpactAnalysisWorkspace extends LightningElement {
    @track selectedComponent;
    @track startNodeId;
    @track hasNoPermission = false;

    @wire(checkOIPUserPermission)
    wiredPermission({ error, data }) {
        if (data !== undefined) {
            this.hasNoPermission = !data;
        }
    }

    handleNodeSelect(event) {
        this.selectedComponent = event.detail;
    }

    handleComponentSearch(event) {
        this.startNodeId = event.detail.nodeId;
        this.selectedComponent = event.detail;
    }
}
