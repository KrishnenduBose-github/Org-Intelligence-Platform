import { LightningElement, api, track, wire } from 'lwc';
import getNode from '@salesforce/apex/OIP_DependencyGraphEngine.getNode';
import getOutgoingEdges from '@salesforce/apex/OIP_DependencyGraphEngine.getOutgoingEdges';
import getIncomingEdges from '@salesforce/apex/OIP_DependencyGraphEngine.getIncomingEdges';
import traverseBFS from '@salesforce/apex/OIP_DependencyGraphEngine.traverseBFS';

export default class OipDependencyGraph extends LightningElement {
    @api startNodeId;
    @api depth = 3;
    @track nodes = [];
    @track edges = [];
    @track selectedNode;
    @track isLoading = true;

    nodeColors = {
        ApexClass: '#00A1E0',
        Flow: '#F3836F',
        LWC: '#7DBD57',
        ApexTrigger: '#A094DC',
        Aura: '#F7A654',
        CustomField: '#5EB0EF',
        CustomObject: '#1C93BD',
        ValidationRule: '#E86B6B',
        PermissionSet: '#6C9AD3',
        Profile: '#9489CC'
    };

    severityColors = {
        None: '#939393',
        Low: '#4BC076',
        Medium: '#FFB75D',
        High: '#FF9B45',
        Critical: '#EA001E'
    };

    get isEmptyGraph() {
        return !this.isLoading && (!this.nodes || this.nodes.length === 0);
    }

    @wire(getOutgoingEdges, { sourceNodeId: '$startNodeId' })
    wiredEdges({ error, data }) {
        if (data) {
            this.edges = data;
        }
    }

    @wire(traverseBFS, { startNodeId: '$startNodeId', maxDepth: '$depth' })
    wiredNodes({ error, data }) {
        if (data) {
            this.nodes = data;
            this.isLoading = false;
        } else if (error) {
            this.isLoading = false;
        }
    }

    handleNodeClick(event) {
        const nodeId = event.target.dataset.nodeId;
        this.selectedNode = this.nodes.find(n => n.nodeId === nodeId);
        this.dispatchEvent(new CustomEvent('nodeselect', {
            detail: this.selectedNode
        }));
    }

    get severityColor() {
        if (this.selectedNode) {
            return this.severityColors[this.selectedNode.severityRating] || '#939393';
        }
        return '#939393';
    }
}
