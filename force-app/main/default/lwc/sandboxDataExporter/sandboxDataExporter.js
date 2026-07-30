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
    selectedDeveloperNames = new Set();

    _wiredDefinitionsResult;
    _pendingTimeouts = [];
    _exportQueue = [];

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
            this.selectedDeveloperNames = new Set(data.map(d => d.developerName));
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
        const total = this._exportQueue.length || 0;
        const current = Math.min(done + 1, total);
        return `Running export ${current} of ${total}…`;
    }

    get selectableDefinitions() {
        return this.definitions.map(d => ({
            ...d,
            isSelected: this.selectedDeveloperNames.has(d.developerName)
        }));
    }

    get selectedDefinitions() {
        return this.definitions.filter(d => this.selectedDeveloperNames.has(d.developerName));
    }

    get selectedCount() {
        return this.selectedDeveloperNames.size;
    }

    get selectedCountSuffix() {
        return this.selectedCount === 1 ? '' : 's';
    }

    get isAllSelected() {
        return this.definitions.length > 0 && this.selectedCount === this.definitions.length;
    }

    get isNoneSelected() {
        return this.selectedCount === 0;
    }

    // ── Button state getters ──────────────────────────────────────

    get isExportAllDisabled() {
        return this.isGateLocked || this.isExporting || !this.hasDefinitions || this.isNoneSelected;
    }

    get exportButtonLabel() {
        return this.isExporting ? 'Exporting…' : 'Export';
    }

    get exportButtonTitle() {
        let title;
        if (this.isGateLocked) {
            title = 'ExternalId Objects health check must PASS before exporting';
        } else if (this.isNoneSelected) {
            title = 'Select at least one export to run';
        } else if (this.isExporting) {
            title = 'Export in progress…';
        } else {
            title = 'Download selected exports as CSV files';
        }
        return title;
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
            let order = 0;
            if (a.isFail !== b.isFail) {
                order = a.isFail ? -1 : 1;
            }
            return order;
        });
    }

    // ── Event handlers ────────────────────────────────────────────

    handleExport() {
        if (!this.isExportAllDisabled) {
            this._exportQueue = [...this.selectedDefinitions];
            this.isExporting = true;
            this.exportCompletedCount = 0;
            this.exportResults = [];
            this.runNextExport(0);
        }
    }

    handleSelectAll() {
        this.selectedDeveloperNames = new Set(this.definitions.map(d => d.developerName));
    }

    handleDeselectAll() {
        this.selectedDeveloperNames = new Set();
    }

    handleDefinitionToggle(event) {
        const developerName = event.target.dataset.developerName;
        const next = new Set(this.selectedDeveloperNames);
        if (event.target.checked) {
            next.add(developerName);
        } else {
            next.delete(developerName);
        }
        this.selectedDeveloperNames = next;
    }

    handleRefreshDefinitions() {
        this.defsLoading = true;
        this.exportResults = [];
        refreshApex(this._wiredDefinitionsResult).finally(() => {
            this.defsLoading = false;
        });
    }

    // ── Private helpers ───────────────────────────────────────────

    runNextExport(index) {
        if (index >= this._exportQueue.length) {
            this.finishExport();
        } else {
            const def = this._exportQueue[index];
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
        let message;
        if (!error) {
            message = 'Unknown error';
        } else if (typeof error.body?.message === 'string') {
            message = error.body.message;
        } else if (Array.isArray(error.body) && error.body.length > 0) {
            message = error.body.map((e) => e.message).join(', ');
        } else if (typeof error.message === 'string') {
            message = error.message;
        } else {
            try {
                message = JSON.stringify(error);
            } catch (stringifyError) {
                console.error('Error stringifying the error object:', stringifyError);
                message = 'Unknown error';
            }
        }
        return message;
    }
}
