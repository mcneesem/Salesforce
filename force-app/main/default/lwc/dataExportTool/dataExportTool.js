import { LightningElement, wire } from 'lwc';
import getHealth from '@salesforce/apex/SandboxHealthController.getHealth';
import getExportDefinitions from '@salesforce/apex/DataExportController.getExportDefinitions';
import executeExport from '@salesforce/apex/DataExportController.executeExport';

/** Section key used by SandboxHealthController for the ExternalId Objects check. */
const EXTERNAL_ID_SECTION_KEY = 'externalIdObjects';

/**
 * Milliseconds to wait between triggering each file download.
 * Prevents browser pop-up blockers from suppressing successive downloads.
 */
const DOWNLOAD_DELAY_MS = 150;

export default class DataExportTool extends LightningElement {
    // ── Wire backing fields ────────────────────────────────────────
    health = null;
    healthError = null;
    healthLoading = true;

    definitions = [];
    defsLoading = true;

    // ── Export runtime state ───────────────────────────────────────
    isExporting = false;
    currentExportStep = null;
    exportCompletedCount = 0;
    exportErrors = [];
    showSuccessBanner = false;
    successMessage = '';

    // ── Wire: SandboxHealthController.getHealth ────────────────────

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

    // ── Wire: DataExportController.getExportDefinitions ───────────

    @wire(getExportDefinitions)
    wiredDefinitions({ data, error }) {
        if (data) {
            this.definitions = data;
        } else if (error) {
            this.definitions = [];
            this.healthError = this.healthError || error;
        }
        this.defsLoading = false;
    }

    // ── Visibility getters ────────────────────────────────────────

    get isLoading() {
        return this.healthLoading || this.defsLoading;
    }

    get isSandbox() {
        return this.health != null && this.health.isSandbox === true;
    }

    /**
     * Component renders only when health is loaded AND the org is not a sandbox.
     * The isSandbox gate prevents the card from appearing in production-like refresh orgs.
     */
    get isVisible() {
        return !this.healthLoading && !this.isSandbox;
    }

    get isContentVisible() {
        return this.isVisible && !this.isLoading && !this.healthError;
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

    /** Steps array consumed by c-progress-bar. */
    get progressSteps() {
        return (this.definitions || []).map((d) => ({
            value: d.developerName,
            label: d.label || d.developerName
        }));
    }

    get exportStatusText() {
        const done = this.exportCompletedCount;
        const total = Array.isArray(this.definitions) ? this.definitions.length : 0;
        return `Running export ${done + 1} of ${total}\u2026`;
    }

    // ── Button state getters ──────────────────────────────────────

    get isExportAllDisabled() {
        return this.isGateLocked || this.isExporting || !this.hasDefinitions;
    }

    get exportButtonLabel() {
        return this.isExporting ? 'Exporting\u2026' : 'Export All';
    }

    get exportButtonTitle() {
        let title = 'Download all configured exports as CSV files';
        if (this.isGateLocked) {
            title = 'ExternalId Objects health check must PASS before exporting';
        } else if (this.isExporting) {
            title = 'Export in progress\u2026';
        }
        return title;
    }

    get hasExportErrors() {
        return Array.isArray(this.exportErrors) && this.exportErrors.length > 0;
    }

    // ── Event handler ─────────────────────────────────────────────

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

    // ── Private helpers ───────────────────────────────────────────

    /**
     * Recursively processes each export definition in order.
     * Uses setTimeout between downloads to avoid browser pop-up blocking.
     *
     * @param {number} index - Current position in this.definitions
     */
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
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                setTimeout(() => {
                    this.runNextExport(index + 1);
                }, DOWNLOAD_DELAY_MS);
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

    /**
     * Triggers a browser file-download for the given CSV content.
     * Creates a temporary anchor element in the page body, clicks it,
     * then removes it after the browser has handled the download.
     *
     * @param {string} filename - Target filename including .csv extension
     * @param {string} csvContent - CSV string to write to the file
     */
    triggerCsvDownload(filename, csvContent) {
        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const objectUrl = URL.createObjectURL(blob);
        const anchor = document.createElement('a');
        anchor.href = objectUrl;
        anchor.download = filename;
        anchor.style.display = 'none';
        document.body.appendChild(anchor);
        anchor.click();
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            document.body.removeChild(anchor);
            URL.revokeObjectURL(objectUrl);
        }, 1000);
    }

    /**
     * Extracts a user-readable message from an Apex or network error object.
     *
     * @param {object} error - Error thrown by an @AuraEnabled Apex method
     * @returns {string} Human-readable error message
     */
    extractErrorMessage(error) {
        let msg = 'Unknown error';
        if (error) {
            if (typeof error.body?.message === 'string') {
                msg = error.body.message;
            } else if (Array.isArray(error.body) && error.body.length > 0) {
                msg = error.body.map((e) => e.message).join(', ');
            } else if (typeof error.message === 'string') {
                msg = error.message;
            } else {
                try {
                    msg = JSON.stringify(error);
                } catch (_e) {
                    msg = 'Unknown error';
                }
            }
        }
        return msg;
    }
}