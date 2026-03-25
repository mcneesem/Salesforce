import { LightningElement, wire, track } from 'lwc';
import getHealth from '@salesforce/apex/SandboxHealthController.getHealth';
import { refreshApex } from '@salesforce/apex';

export default class SandboxHealth extends LightningElement {
    @track activeSections = [];
    @track sections = [];
    @track context = { sandboxName: '', instance: '' };
    @track evaluatedAtDisplay = '';
    @track error = '';
    @track loading = true;

    // Track child active sections for nested accordion (e.g., Custom Settings children)
    @track activeChildSections = [];

    // Wire to Apex (cacheable)
    // Capture wired result so we can refresh later if needed
    _wiredResult;

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

    handleToggle(event) {
        this.activeSections = event.detail.openSections;
    }

    handleToggleAll() {
        if ( this.hasAnyTopOpen() ) {
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
        this.activeSections = top.map(s => s.key);
        this.activeChildSections = this.collectAllChildNames(top);
    }

    get toggleIcon() {
        return (!this.activeSections || this.activeSections.length === 0) ? 'utility:add' : 'utility:dash';
    }

    handleRefresh() {
        // Prefer refreshApex on the wired result to bust LDS cache, fallback to imperative call
        this.loading = true;
        this.error = '';

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
            // Fallback: call Apex imperatively
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

    isCustomSettings(sec) {
        const cat = (sec?.category || '').toString().toLowerCase();
        return (cat === 'custom_settings' );
    }

    isCustomMetadata(sec) {
        const cat = (sec?.category || '').toString().toLowerCase();
        return ( cat === 'custom_metadata' );
    }

    isCustomLabels(sec) {
        const cat = (sec?.category || '').toString().toLowerCase();
        return ( cat === 'labels' );
    }

    bucketSections(sections) {
        const buckets = { others: [] , customSettings: [] , customMetadata: [] , customLabels: [] };
        for (const s of sections) {
            if (this.isCustomSettings(s)) buckets.customSettings.push(s);
            else if (this.isCustomMetadata(s)) buckets.customMetadata.push(s);
            else if (this.isCustomLabels(s)) buckets.customLabels.push(s);
            else buckets.others.push(s);
        }
        return buckets;
    }

    deriveStatus(children) {
        const st = children.map((s) => s.status);
        if (st.includes('FAIL')) return 'FAIL';
        if (st.includes('WARN')) return 'WARN';
        return 'PASS';
    }

    makeParent(key, label, kids, prefix) {
        const parent = this.decorateSection({
            key,
            label,
            status: this.deriveStatus(kids),
            checks: []
        });
        parent.children = kids.map((c) => ({ ...c, name: `${prefix}-${c.key || c.label}` }));
        return parent;
    }

    buildGroupedSections({ others , customSettings , customMetadata , customLabels }) {
        const out = [...others];
        if ( customSettings.length ) out.unshift( this.makeParent( 'CUSTOM_SETTINGS' , 'Custom Settings' , customSettings , 'CS' ) );
        if ( customMetadata.length ) out.unshift( this.makeParent( 'CUSTOM_METADATA' , 'Custom Metadata' , customMetadata , 'CM' ) );
        if ( customLabels.length ) out.unshift( this.makeParent( 'CUSTOM_LABELS' , 'Custom Labels' , customLabels , 'CL' ) );
        return out;
    }

    collectAllChildNames(sections) {
        const names = [];
        for (const s of sections) {
            if (s && Array.isArray(s.children)) {
                for (const c of s.children) if (c?.name) names.push(c.name);
            }
        }
        return names;
    }

    initChildActivesIfEmpty(grouped) {
        if (!this.activeChildSections || this.activeChildSections.length === 0) {
            this.activeChildSections = [];
        }
    }

    // Ensure top-level accordion starts collapsed if unset
    initTopActivesIfEmpty() {
        if (!this.activeSections || this.activeSections.length === 0) {
            this.activeSections = [];
        }
    }

    // --- Refactored to reduce cognitive complexity ---
    applyData(data) {
        this.setContext(data);
        this.setTimestamp(data);

        const raw = this.toArray(data?.sections);
        const decorated = raw.map((s) => this.decorateSection(s));
        const buckets = this.bucketSections(decorated); // { others, customSettings, customMetadata, customLabels }
        const grouped = this.buildGroupedSections(buckets); // adds parents when needed

        this.sections = grouped;
        this.initChildActivesIfEmpty(grouped);
        this.initTopActivesIfEmpty();
    }

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
        } catch (e) {
            this.evaluatedAtDisplay = '';
        }
    }

    normalizeError(err) {
        if (!err) return 'Unknown error';
        if (Array.isArray(err.body)) {
            return err.body.map((e) => e.message).join(', ');
        }
        if (err.body && typeof err.body.message === 'string') {
            return err.body.message;
        }
        if (typeof err.message === 'string') {
            return err.message;
        }
        try {
            return JSON.stringify(err);
        } catch (e) {
            return 'Unexpected error';
        }
    }
}
