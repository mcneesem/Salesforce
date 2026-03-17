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
        // If any top-level sections are open, collapse everything (top-level and children)
        if (this.activeSections && this.activeSections.length > 0) {
            this.activeSections = []; // Collapse all top-level
            this.activeChildSections = []; // Collapse all nested children
        } else {
        // Otherwise, expand all top-level sections and all nested child sections (if any)
            const topLevel = Array.isArray(this.sections) ? this.sections : [];
            this.activeSections = topLevel.map((s) => s.key);

            // Collect all child section names from grouped sections (e.g., Custom Settings)
            const childNames = [];
            for (const s of topLevel) {
                if (s && Array.isArray(s.children) && s.children.length > 0) {
                    for (const c of s.children) {
                        if (c && c.name) {
                            childNames.push(c.name);
                        }
                    }
                }
            }
            this.activeChildSections = childNames;
        }
    }

    get toggleIcon() {
        return (!this.activeSections || this.activeSections.length === 0) ? 'utility:add' : 'utility:dash';
    }

    // Derive a set for quick lookup during render if needed
    get activeSectionsSet() {
        return new Set(this.activeSections || []);
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

    applyData(data) {
        // Context
        this.context = {
            sandboxName: data?.sandboxName || '',
            instance: data?.instance || ''
        };
        // Timestamp
        try {
            const dt = data?.evaluatedAt ? new Date(data.evaluatedAt) : new Date();
            this.evaluatedAtDisplay = dt.toLocaleString();
        } catch (e) {
            this.evaluatedAtDisplay = '';
        }

        // Helper to decorate a section/check with computed flags
        const decorateSection = (sec) => {
            const checks = (sec.checks || []).map((c) => ({
                ...c,
                isPass: c.status === 'PASS',
                isFail: c.status === 'FAIL',
                isWarn: c.status === 'WARN'
            }));
            const isSectionPass = sec.status === 'PASS';
            const isSectionFail = sec.status === 'FAIL';
            const isSectionWarn = sec.status === 'WARN';
            return { ...sec, checks, isSectionPass, isSectionFail, isSectionWarn };
        };

        // Predicate to identify Custom Settings sections
        const isCustomSettingsSection = (sec) => {
            const key = (sec?.key || '').toLowerCase();
            const label = (sec?.label || '').toLowerCase();
            const category = (sec?.category || '').toString().toLowerCase();
            // Prefer explicit category/type if supplied by Apex
            if (category === 'custom_settings' || category === 'custom_setting' || category === 'customsetting') {
                return true;
            }
            // Fallback heuristics on key/label
            return key.includes('custom setting') || key.includes('custom_settings') || label.includes('custom setting') || label.includes('custom settings');
        };

        const rawSections = Array.isArray(data?.sections) ? data.sections : [];

        const customChildren = [];
        const others = [];

        for (const sec of rawSections) {
            if (isCustomSettingsSection(sec)) {
                customChildren.push(decorateSection(sec));
            } else {
                others.push(decorateSection(sec));
            }
        }

        // If we have any custom settings sections, wrap them under a parent section
        if (customChildren.length > 0) {
            // Derive parent status: FAIL > WARN > PASS
            const statuses = customChildren.map((s) => s.status);
            let parentStatus = 'PASS';
            if (statuses.includes('FAIL')) {
                parentStatus = 'FAIL';
            } else if (statuses.includes('WARN')) {
                parentStatus = 'WARN';
            }

            const parent = decorateSection({
                key: 'CUSTOM_SETTINGS',
                label: 'Custom Settings',
                status: parentStatus,
                // parent will render nested accordion; keep checks empty to avoid duplicate rendering
                checks: []
            });

            // attach children and generate unique child names for nested accordion
            parent.children = customChildren.map((c) => ({
                ...c,
                // Ensure nested unique names; preserve original key for display
                name: `CS-${c.key || c.label}` // used only in nested accordion active names
            }));

            this.sections = [...others, parent];

            // Maintain expand/collapse expectations:
            // When top-level expand-all is requested, also ensure nested children are opened.
            // We won't auto-open here, but reset child actives if necessary.
            if (!this.activeChildSections || this.activeChildSections.length === 0) {
                this.activeChildSections = parent.children.map((c) => c.name);
            }
        } else {
            // No custom settings grouping needed
            this.sections = others;
            this.activeChildSections = [];
        }

        // Default all sections to collapsed initially if currently empty
        if (!this.activeSections || this.activeSections.length === 0) {
            this.activeChildSections = [];
            this.activeSections = []; // Collapse all
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
