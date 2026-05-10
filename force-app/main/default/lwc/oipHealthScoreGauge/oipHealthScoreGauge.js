import { LightningElement, api, track } from 'lwc';

export default class OipHealthScoreGauge extends LightningElement {
    @api score = 0;
    @api trendData;

    get label() {
        if (this.score >= 91) return 'Healthy';
        if (this.score >= 71) return 'Good';
        if (this.score >= 51) return 'At Risk';
        if (this.score >= 31) return 'Warning';
        return 'Critical';
    }

    get gaugeClass() {
        return 'slds-badge slds-badge_large ' + this.colorClass;
    }

    get colorClass() {
        if (this.score >= 91) return 'oip-health-green-dark';
        if (this.score >= 71) return 'oip-health-green';
        if (this.score >= 51) return 'oip-health-yellow';
        if (this.score >= 31) return 'oip-health-orange';
        return 'oip-health-red';
    }

    get gaugeStyle() {
        return 'width: 120px; height: 120px; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center; font-weight: bold;';
    }

    get trendSummary() {
        if (!this.trendData || this.trendData.length < 2) return '';
        const latest = this.trendData[this.trendData.length - 1].score;
        const previous = this.trendData[this.trendData.length - 2].score;
        const diff = latest - previous;
        if (diff > 0) return `+${diff} from previous check`;
        if (diff < 0) return `${diff} from previous check`;
        return 'No change from previous check';
    }
}
