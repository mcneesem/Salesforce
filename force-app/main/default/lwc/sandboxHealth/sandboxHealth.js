import { LightningElement, wire } from 'lwc';
import getHealth from '@salesforce/apex/SandboxHealthController.getHealth';
import verifyWFACcEmails from '@salesforce/apex/SandboxHealthController.verifyWorkflowAlertCcEmails';
import verifyE2CAddresses from '@salesforce/apex/SandboxHealthController.verifyE2CAddresses';
import { refreshApex } from '@salesforce/apex';

export default class SandboxHealth extends LightningElement {
    activeSections = [];
    activeChildSections = [];
    sections = [];
    context = { sandboxName: '', instance: '' };
    evaluatedAtDisplay = '';
    error = '';
    loading = true;

    // Guard flag to prevent infinite re-render loops
    workflowSectionLoaded = false;
    e2cSectionLoaded = false;

    // Track wired result for refresh
    _wiredResult;

    // ----------------------------
    // Wire: cacheable Apex method
    // ----------------------------
    @wire(getHealth)
    wiredHealth(value) {
        this._wiredResult = value;
        const { error, data } = value;

        if (data) {
            this.applyData(data);
        } else if (error) {
            this.error = this.normalizeError(error);
        }
        this.loading = false;
    }

    // ----------------------------
    // Apply cached health data
    // ----------------------------
    applyData(data) {
        this.setContext(data);
        this.setTimestamp(data);

        const raw = this.toArray(data?.sections);
        const decorated = raw.map((s) => this.decorateSection(s));
        const buckets = this.bucketSections(decorated);
        const grouped = this.buildGroupedSections(buckets);

        // Reset sections from cached data
        this.sections = grouped;
        this.initChildActivesIfEmpty();
        this.initTopActivesIfEmpty();

        // Load Tooling API sections exactly once per refresh
        if ( !this.workflowSectionLoaded ) {
            this.workflowSectionLoaded = true;
            this.loadWorkflowAlertSection();
        }
        if ( !this.e2cSectionLoaded ) {
            this.e2cSectionLoaded = true;
            this.loadE2CSection();
        }
    }

    // ----------------------------
    // Imperative Tooling API call
    // ----------------------------
    async loadWorkflowAlertSection() {
        try {
            const section = await verifyWFACcEmails();
            if (!section) {
                return;
            }
            const decorated = this.decorateSection(section);

            // Append without mutating existing array
            this.sections = [...this.sections, decorated];
        } catch (err) {
            // Do not break the page for verification failures
            // Optional: surface as WARN UI element later
            console.warn('Workflow Alert CC Email verification failed', err);
        }
    }

    async loadE2CSection() {
        try {
            const section = await verifyE2CAddresses();
            if (!section) {
                return;
            }
            const decorated = this.decorateSection(section);

            // Append without mutating existing array
            this.sections = [...this.sections, decorated];
        } catch (err) {
            console.warn('E2C verification failed', err);
        }
    }

    // ----------------------------
    // Refresh handler
    // ----------------------------
    handleRefresh() {
        this.loading = true;
        this.error = '';
        this.workflowSectionLoaded = false;
        this.e2cSectionLoaded = false;

        if (this._wiredResult) {
            refreshApex(this._wiredResult)
                .then(() => {
                    const { data, error } = this._wiredResult;
                    if (data) {
                        this.applyData(data);
                    } else if (error) {
                        this.error = this.normalizeError(error);
                    }
                })
                .catch((err) => {
                    this.error = this.normalizeError(err);
                })
                .finally(() => {
                    this.loading = false;
                });
        } else {
            getHealth()
                .then((data) => {
                    this.applyData(data);
                })
                .catch((err) => {
                    this.error = this.normalizeError(err);
                })
                .finally(() => {
                    this.loading = false;
                });
        }
    }

    // ----------------------------
    // UI helpers
    // ----------------------------
    handleToggle(event) {
        this.activeSections = event?.detail?.openSections;
    }

    handleToggleAll() {
        if (this.hasAnyTopOpen()) {
            this.collapseAll();
        } else {
            this.expandAll();
        }
    }

    hasAnyTopOpen() {
        return Array.isArray(this.activeSections) && this.activeSections.length > 0;
    }

    collapseAll() {
        this.activeSections = [];
        this.activeChildSections = [];
    }

    expandAll() {
        const top = Array.isArray(this.sections) ? this.sections : [];
        this.activeSections = top.map((s) => s.key);
        this.activeChildSections = this.collectAllChildNames(top);
    }

    get toggleIcon() {
        return (!this.activeSections || this.activeSections.length === 0)
            ? 'utility:add'
            : 'utility:dash';
    }

    // ----------------------------
    // Section decoration
    // ----------------------------
    decorateSection(sec) {
        const checks = (sec?.checks || []).map((c) => ({
            ...c,
            isPass: c.status === 'PASS',
            isFail: c.status === 'FAIL',
            isWarn: c.status === 'WARN'
        }));
        return {
            ...sec,
            checks,
            isSectionPass: sec?.status === 'PASS',
            isSectionFail: sec?.status === 'FAIL',
            isSectionWarn: sec?.status === 'WARN'
        };
    }

    // ----------------------------
    // Bucketing & grouping
    // ----------------------------
    isCustomSettings(sec) {
        return (sec?.category || '').toLowerCase() === 'custom_settings';
    }

    isCustomMetadata(sec) {
        return (sec?.category || '').toLowerCase() === 'custom_metadata';
    }

    isCustomLabels(sec) {
        return (sec?.category || '').toLowerCase() === 'labels';
    }

    bucketSections(sections) {
        const buckets = {
            others: [],
            customSettings: [],
            customMetadata: [],
            customLabels: []
        };

        for (const s of sections) {
            if (this.isCustomSettings(s)) {
                buckets.customSettings.push(s);
            } else if (this.isCustomMetadata(s)) {
                buckets.customMetadata.push(s);
            } else if (this.isCustomLabels(s)) {
                buckets.customLabels.push(s);
            } else {
                buckets.others.push(s);
            }
        }
        return buckets;
    }

    deriveStatus(children) {
        let status = 'PASS';
        const statuses = children.map((s) => s.status);
        if (statuses.includes('FAIL')) status = 'FAIL';
        else if (statuses.includes('WARN')) status = 'WARN';
        return status;
    }

    makeParent(key, label, kids, prefix) {
        const parent = this.decorateSection({
            key,
            label,
            status: this.deriveStatus(kids),
            checks: []
        });
        parent.children = kids.map((c) => ({
            ...c,
            name: `${prefix}-${c.key || c.label}`
        }));
        return parent;
    }

    buildGroupedSections({ others, customSettings, customMetadata, customLabels }) {
        const out = [...others];
        if (customSettings.length) {
            out.unshift(this.makeParent('CUSTOM_SETTINGS', 'Custom Settings', customSettings, 'CS'));
        }
        if (customMetadata.length) {
            out.unshift(this.makeParent('CUSTOM_METADATA', 'Custom Metadata', customMetadata, 'CM'));
        }
        if (customLabels.length) {
            out.unshift(this.makeParent('CUSTOM_LABELS', 'Custom Labels', customLabels, 'CL'));
        }
        return out;
    }

    collectAllChildNames(sections) {
        const names = [];
        for (const s of sections) {
            if (Array.isArray(s.children)) {
                for (const c of s.children) {
                    if (c?.name) names.push(c.name);
                }
            }
        }
        return names;
    }

    initChildActivesIfEmpty() {
        if (!Array.isArray(this.activeChildSections)) {
            this.activeChildSections = [];
        }
    }

    initTopActivesIfEmpty() {
        if (!Array.isArray(this.activeSections)) {
            this.activeSections = [];
        }
    }

    // ----------------------------
    // Context helpers
    // ----------------------------
    toArray(x) {
        return Array.isArray(x) ? x : [];
    }

    setContext(data) {
        this.context = {
            sandboxName: data?.sandboxName || '',
            instance: data?.instance || ''
        };
    }

    setTimestamp(data) {
        try {
            const dt = data?.evaluatedAt ? new Date(data.evaluatedAt) : new Date();
            this.evaluatedAtDisplay = dt.toLocaleString();
        } catch {
            this.evaluatedAtDisplay = '';
        }
    }

    // ----------------------------
    // Error normalization
    // ----------------------------
    normalizeError(err) {
        if (!err) return 'Unexpected error';

        if (Array.isArray(err.body)) {
            return err.body.map((e) => e.message).join(', ');
        }
        if (err.body?.message) {
            return err.body.message;
        }
        if (err.message) {
            return err.message;
        }
        try {
            return JSON.stringify(err);
        } catch {
            return 'Unexpected error';
        }
    }
}