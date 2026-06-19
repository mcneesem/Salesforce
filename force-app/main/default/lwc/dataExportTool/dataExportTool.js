import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getHealth from '@salesforce/apex/SandboxHealthController.getHealth';
import getExportDefinitions from '@salesforce/apex/DataExportController.getExportDefinitions';
import executeExport from '@salesforce/apex/DataExportController.executeExport';

const EXTERNAL_ID_SECTION_KEY = 'externalIdObjects';
const DOWNLOAD_DELAY_MS = 150;

export default class DataExportTool extends LightningElement {
    health = null;
    healthError = null;
    healthLoading = true;

    definitions = [];
    defsError = null;
    defsLoading = true;

    isExporting = false;
    currentExportStep = null;
    exportCompletedCount = 0;
    exportErrors = [];
    showSuccessBanner = false;
    successMessage = '';

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
        return this.health != null && this.health.isSandbox === true;
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
                (s) => s != null && s.key === EXTERNAL_ID_SECTION_KEY
            );
            pass = section != null && section.status === 'PASS';
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

    get progressSteps() {
        return (this.definitions || []).map((d) => ({
            value: d.developerName,
            label: d.label || d.developerName
        }));
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

    get hasExportErrors() {
        return Array.isArray(this.exportErrors) && this.exportErrors.length > 0;
    }

    // ── Event handlers ────────────────────────────────────────────

    handleExportAll() {
        if (this.isExportAllDisabled) {
            return;
        }
        this.isExporting = true;
        this.exportCompletedCount = 0;
        this.exportErrors = [];
        this.showSuccessBanner = false;

        this.runNextExport(0);
    }

    handleDismissSuccess() {
        this.showSuccessBanner = false;
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
            })
            .catch((err) => {
                this.exportErrors = [
                    ...this.exportErrors,
                    {
                        developerName: def.developerName,
                        message:
                            (def.label || def.developerName) +
                            ': ' +
                            this.extractErrorMessage(err)
                    }
                ];
                this.exportCompletedCount = index + 1;
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
        const errorCount = this.exportErrors.length;
        const total = Array.isArray(this.definitions) ? this.definitions.length : 0;
        const successCount = total - errorCount;
        if (successCount > 0) {
            this.showSuccessBanner = true;
            this.successMessage =
                successCount === 1
                    ? '1 file downloaded successfully.'
                    : successCount + ' files downloaded successfully.' +
                      (errorCount > 0 ? ' ' + errorCount + ' failed.' : '');
        }
    }

    triggerCsvDownload(filename, csvContent) {
        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const objectUrl = URL.createObjectURL(blob);
        const anchor = document.createElement('a');
        anchor.href = objectUrl;
        anchor.download = filename;
        anchor.style.display = 'none';

        const container = this.template.querySelector('[data-id="download-container"]');
        container.appendChild(anchor);
        anchor.click();

        const timeoutId = setTimeout(() => {
            container.removeChild(anchor);
            URL.revokeObjectURL(objectUrl);
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
        } catch (_e) {
            return 'Unknown error';
        }
    }
}
