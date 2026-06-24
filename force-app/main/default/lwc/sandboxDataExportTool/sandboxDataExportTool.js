import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getHealth from '@salesforce/apex/SandboxHealthController.getHealth';
import getExportDefinitions from '@salesforce/apex/SandboxDataExportController.getExportDefinitions';
import executeExport from '@salesforce/apex/SandboxDataExportController.executeExport';

const EXTERNAL_ID_SECTION_KEY = 'externalIdObjects';
const DOWNLOAD_DELAY_MS = 150;

export default class SandboxDataExportTool extends LightningElement {
    health = null;
    healthError = null;
    healthLoading = true;

    definitions = [];
    defsError = null;
    defsLoading = true;

    isExporting = false;
    exportCompletedCount = 0;
    exportResults = [];

    _wiredDefinitionsResult;
    _pendingTimeouts = [];

    @wire(getHealth)
    wiredHealth({ data, error }) {
        if (data) {
            this.health = data;
            this.healthError = null;
        } else if (error) {
            this.health = null;
            this.healthError = error;
        }
        this.healthLoading = false;
    }

    @wire(getExportDefinitions)
    wiredDefinitions(result) {
        this._wiredDefinitionsResult = result;
        const { data, error } = result;
        if (data) {
            this.definitions = data;
            this.defsError = null;
        } else if (error) {
            this.definitions = [];
            this.defsError = error;
        }
        this.defsLoading = false;
    }

    disconnectedCallback() {
        this._pendingTimeouts.forEach(clearTimeout);
        this._pendingTimeouts = [];
    }

    // ── Visibility getters ────────────────────────────────────────

    get isLoading() {
        return this.healthLoading || this.defsLoading;
    }

    get isSandbox() {
        return this.health?.isSandbox === true;
    }

    get isVisible() {
        return !this.healthLoading && !this.isSandbox;
    }

    get hasError() {
        return this.healthError || this.defsError;
    }

    get isContentVisible() {
        return this.isVisible && !this.isLoading && !this.hasError;
    }

    // ── Health-gate getters ───────────────────────────────────────

    get isExternalIdPass() {
        let pass = false;
        if (this.health && Array.isArray(this.health.sections)) {
            const section = this.health.sections.find(
                s => s?.key === EXTERNAL_ID_SECTION_KEY
            );
            pass = section?.status === 'PASS';
        }
        return pass;
    }

    get isGateLocked() {
        return !this.isExternalIdPass;
    }

    // ── Export definition getters ─────────────────────────────────

    get hasDefinitions() {
        return Array.isArray(this.definitions) && this.definitions.length > 0;
    }

    get definitionCountSuffix() {
        return this.definitions.length === 1 ? '' : 's';
    }

    get exportResultsCountSuffix() {
        return this.sortedExportResults.length === 1 ? '' : 's';
    }

    get exportStatusText() {
        const done = this.exportCompletedCount;
        const total = this.definitions.length || 0;
        const current = Math.min(done + 1, total);
        return `Running export ${current} of ${total}…`;
    }

// ── Button state getters ──────────────────────────────────────

    get isExportAllDisabled() {
        return this.isGateLocked || this.isExporting || !this.hasDefinitions;
    }

    get exportButtonLabel() {
        return this.isExporting ? 'Exporting…' : 'Export All';
    }

    get exportButtonTitle() {
        if (this.isGateLocked) {
            return 'ExternalId Objects health check must PASS before exporting';
        }
        if (this.isExporting) {
            return 'Export in progress…';
        }
        return 'Download all configured exports as CSV files';
    }

    get isPreExport() {
        return !this.isExporting && !this.hasResults;
    }

    get isAllExportsPass() {
        return !this.isExporting && this.hasResults && this.exportResults.every(r => r.isPass);
    }

    get hasExportFailures() {
        return !this.isExporting && this.exportResults.some(r => r.isFail);
    }

    get hasResults() {
        return Array.isArray(this.exportResults) && this.exportResults.length > 0;
    }

    get sortedExportResults() {
        return [...this.exportResults].sort((a, b) => {
            if (a.isFail === b.isFail) return 0;
            return a.isFail ? -1 : 1;
        });
    }

    // ── Event handlers ────────────────────────────────────────────

    handleExportAll() {
        if (this.isExportAllDisabled) {
            return;
        }
        this.isExporting = true;
        this.exportCompletedCount = 0;
        this.exportResults = [];

        this.runNextExport(0);
    }

    handleRefreshDefinitions() {
        this.defsLoading = true;
        refreshApex(this._wiredDefinitionsResult).finally(() => {
            this.defsLoading = false;
        });
    }

    // ── Private helpers ───────────────────────────────────────────

    runNextExport(index) {
        if (index >= this.definitions.length) {
            this.finishExport();
            return;
        }

        const def = this.definitions[index];
        this.currentExportStep = def.developerName;

        executeExport({ developerName: def.developerName })
            .then((csv) => {
                this.triggerCsvDownload(def.fileName + '.csv', csv || '');
                this.exportCompletedCount = index + 1;
                this.exportResults = [
                    ...this.exportResults,
                    { key: def.developerName, label: def.label || def.developerName, isPass: true, isFail: false, message: def.fileName + '.csv' }
                ];
            })
            .catch((err) => {
                this.exportCompletedCount = index + 1;
                this.exportResults = [
                    ...this.exportResults,
                    { key: def.developerName, label: def.label || def.developerName, isPass: false, isFail: true, message: this.extractErrorMessage(err) }
                ];
            })
            .finally(() => {
                const timeoutId = setTimeout(() => {
                    this.runNextExport(index + 1);
                }, DOWNLOAD_DELAY_MS);
                this._pendingTimeouts.push(timeoutId);
            });
    }

    finishExport() {
        this.isExporting = false;
        this.currentExportStep = null;
    }

    triggerCsvDownload(filename, csvContent) {
        const dataUri = 'data:text/plain;charset=utf-8,' + encodeURIComponent(csvContent);
        const anchor = document.createElement('a');
        anchor.href = dataUri;
        anchor.download = filename;
        anchor.style.display = 'none';

        const container = this.template.querySelector('[data-id="download-container"]');
        container.appendChild(anchor);
        anchor.click();

        const timeoutId = setTimeout(() => {
            anchor.remove();
        }, 1000);
        this._pendingTimeouts.push(timeoutId);
    }

    extractErrorMessage(error) {
        if (!error) {
            return 'Unknown error';
        }
        if (typeof error.body?.message === 'string') {
            return error.body.message;
        }
        if (Array.isArray(error.body) && error.body.length > 0) {
            return error.body.map((e) => e.message).join(', ');
        }
        if (typeof error.message === 'string') {
            return error.message;
        }
        try {
            return JSON.stringify(error);
        } catch (error) {
            console.error('Error stringifying error object:', error);
            return 'Unknown error';
        }
    }
}
