import { LightningElement, api, track } from 'lwc';
import exportSessionCSV from '@salesforce/apex/OIP_ExportService.exportSessionCSV';
import isExportCSVEnabled from '@salesforce/apex/OIP_FeatureFlagService.isExportCSVEnabled';

export default class OipExportPanel extends LightningElement {
    @api sessionId;
    @api componentName;
    @track csvData = '';
    @track showPreview = false;
    @track exportEnabled = true;

    connectedCallback() {
        isExportCSVEnabled().then(data => { this.exportEnabled = data; });
    }

    handleExportCSV() {
        if (this.sessionId) {
            exportSessionCSV({ sessionId: this.sessionId })
                .then(data => {
                    this.csvData = data;
                    this.downloadCSV('session-export.csv', data);
                });
        }
    }

    downloadCSV(filename, data) {
        const blob = new Blob([data], { type: 'text/csv' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        a.click();
        URL.revokeObjectURL(url);
    }
}
