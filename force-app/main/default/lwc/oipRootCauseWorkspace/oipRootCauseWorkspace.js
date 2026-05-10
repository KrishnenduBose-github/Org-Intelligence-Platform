import { LightningElement, track, wire } from 'lwc';
import analyzeFailure from '@salesforce/apex/OIP_RootCauseAnalyzerService.analyzeFailure';
import generateChecklist from '@salesforce/apex/OIP_RootCauseAnalyzerService.generateChecklist';
import checkOIPUserPermission from '@salesforce/apex/OIP_DashboardController.checkOIPUserPermission';

export default class OipRootCauseWorkspace extends LightningElement {
    @track queryText = '';
    @track analysis = null;
    @track checklist = [];
    @track isLoading = false;
    @track hasNoPermission = false;
    @track errorMessage = '';

    @wire(checkOIPUserPermission)
    wiredPermission({ error, data }) {
        if (data !== undefined) this.hasNoPermission = !data;
    }

    handleQueryChange(event) {
        this.queryText = event.target.value;
    }

    handleKeyUp(event) {
        if (event.key === 'Enter') this.handleAnalyze();
    }

    handleAnalyze() {
        if (!this.queryText || this.queryText.trim().length === 0) return;
        this.isLoading = true;
        this.analysis = null;
        this.errorMessage = '';
        analyzeFailure({ componentFullName: this.queryText.trim() })
            .then(data => {
                this.analysis = data;
                this.isLoading = false;
            })
            .catch(error => {
                this.errorMessage = 'Analysis failed: ' + (error.body ? error.body.message : error.message);
                this.isLoading = false;
            });
    }

    handleHypothesisSelect(event) {
        const cause = event.detail.causeDescription;
        generateChecklist({ rootCauseDescription: cause })
            .then(data => { this.checklist = data; })
            .catch(() => { this.checklist = []; });
    }
}
