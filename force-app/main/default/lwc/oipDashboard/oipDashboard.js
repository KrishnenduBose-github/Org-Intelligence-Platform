import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getHealthScore from '@salesforce/apex/OIP_DashboardController.getHealthScore';
import getRecentSessions from '@salesforce/apex/OIP_DashboardController.getRecentSessions';
import checkOIPUserPermission from '@salesforce/apex/OIP_DashboardController.checkOIPUserPermission';

export default class OipDashboard extends NavigationMixin(LightningElement) {
    @track healthScore = 0;
    @track scoreTrend = [];
    @track recentSessions = [];
    @track hasNoPermission = false;

    workspaceCards = [
        { id: '1', title: 'Search', description: 'Search across all org metadata by name, type, or natural language query.', icon: 'standard:search', url: '/oip/search' },
        { id: '2', title: 'Impact Analysis', description: 'Trace dependency chains and understand what breaks when a component changes.', icon: 'standard:record_create', url: '/oip/impact' },
        { id: '3', title: 'Root Cause', description: 'Debug failures with AI-ranked root cause hypotheses and confidence scores.', icon: 'standard:junction_list', url: '/oip/root-cause' },
        { id: '4', title: 'Security Debugging', description: 'Trace permission chains and identify FLS, OLS, and sharing rule issues.', icon: 'standard:lock', url: '/oip/security' },
        { id: '5', title: 'Deployment Debugging', description: 'Compare orgs and surface deployment blockers and missing dependencies.', icon: 'standard:launch', url: '/oip/deployment' },
        { id: '6', title: 'Automation Conflicts', description: 'Detect overlapping triggers, flows, and validation rules on the same object.', icon: 'standard:flow', url: '/oip/conflicts' }
    ];

    @wire(getHealthScore)
    wiredHealthScore({ error, data }) {
        if (data) {
            this.healthScore = data.score;
            this.scoreTrend = data.trend;
        } else if (error) {
            this.healthScore = 0;
        }
    }

    @wire(getRecentSessions)
    wiredRecentSessions({ error, data }) {
        if (data) {
            this.recentSessions = data;
        } else if (error) {
            this.recentSessions = [];
        }
    }

    @wire(checkOIPUserPermission)
    wiredPermission({ error, data }) {
        if (data !== undefined) {
            this.hasNoPermission = !data;
        } else if (error) {
            this.hasNoPermission = true;
        }
    }
}
