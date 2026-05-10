import { LightningElement, api, track } from 'lwc';

export default class OipDebugSessionPanel extends LightningElement {
    @api sessionId;
    @api sessionName;
    @api sessionType;
    @api sessionStatus;
    @api confidenceScore;
    @track showNotes = false;

    handleToggleNotes() {
        this.showNotes = !this.showNotes;
    }

    handleExportCSV() {
        this.dispatchEvent(new CustomEvent('exportcsv', { detail: { sessionId: this.sessionId } }));
    }

    handleExportPDF() {
        this.dispatchEvent(new CustomEvent('exportpdf', { detail: { sessionId: this.sessionId } }));
    }
}
