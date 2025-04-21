import { createElement } from 'lwc';
import Prepsandbox from 'c/prepsandbox';
import { ShowToastEventName } from 'lightning/platformShowToastEvent';
import runManualSteps from '@salesforce/apex/NSP_PrepSandbox.runManualSteps';
import runUserImport from '@salesforce/apex/NSP_PrepSandbox.runUserImport';
import runManualSteps2 from '@salesforce/apex/NSP_PrepSandbox.runManualSteps2';
import runE2CAddresses from '@salesforce/apex/NSP_PrepSandbox.runE2CAddresses';

// Mock the Apex methods
jest.mock('@salesforce/apex/NSP_PrepSandbox.runManualSteps', () => ({
    default: jest.fn()
}), { virtual: true });

jest.mock('@salesforce/apex/NSP_PrepSandbox.runUserImport', () => ({
    default: jest.fn()
}), { virtual: true });

jest.mock('@salesforce/apex/NSP_PrepSandbox.runManualSteps2', () => ({
    default: jest.fn()
}), { virtual: true });

jest.mock('@salesforce/apex/NSP_PrepSandbox.runE2CAddresses', () => ({
    default: jest.fn()
}), { virtual: true });

describe('c-prepsandbox', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('should invoke the correct Apex method for post-refresh steps', async () => {
        // Arrange
        const element = createElement('c-prepsandbox', {
            is: Prepsandbox
        });

        document.body.appendChild(element);

        // Act
        const button = element.shadowRoot.querySelector('lightning-button[label="Post-Refresh Steps"]');
        button.click();

        // Assert
        expect(runManualSteps).toHaveBeenCalled();
    });

    it('should invoke the correct Apex method for importing org users', async () => {
        // Arrange
        const element = createElement('c-prepsandbox', {
            is: Prepsandbox
        });

        document.body.appendChild(element);

        // Act
        const button = element.shadowRoot.querySelector('lightning-button[label="Import Org Users"]');
        button.click();

        // Assert
        expect(runUserImport).toHaveBeenCalled();
    });

    it('should invoke the correct Apex method for post-import steps', async () => {
        // Arrange
        const element = createElement('c-prepsandbox', {
            is: Prepsandbox
        });

        document.body.appendChild(element);

        // Act
        const button = element.shadowRoot.querySelector('lightning-button[label="Post-Import Steps"]');
        button.click();

        // Assert
        expect(runManualSteps2).toHaveBeenCalled();
    });

    it('should invoke the correct Apex method for E2C addresses', async () => {
        // Arrange
        const element = createElement('c-prepsandbox', {
            is: Prepsandbox
        });

        document.body.appendChild(element);

        // Act
        const button = element.shadowRoot.querySelector('lightning-button[label="E2C Addresses"]');
        button.click();

        // Assert
        expect(runE2CAddresses).toHaveBeenCalled();
    });

    it('should display a success toast notification upon successful completion', async () => {
        // Arrange
        const element = createElement('c-prepsandbox', {
            is: Prepsandbox
        });

        document.body.appendChild(element);

        // Act & Assert
        const button1 = element.shadowRoot.querySelector('lightning-button[label="Post-Refresh Steps"]');
        button1.click();
        await expect(runManualSteps).resolves.toBe('Success');
        expect(element.dispatchEvent).toHaveBeenCalledWith(new CustomEvent(ShowToastEventName, {
            detail: {
                message: 'Post-refresh steps completed successfully.',
                title: 'Success',
                variant: 'success'
            }
        }));

        const button2 = element.shadowRoot.querySelector('lightning-button[label="Import Org Users"]');
        button2.click();
        await expect(runUserImport).resolves.toBe('Success');
        expect(element.dispatchEvent).toHaveBeenCalledWith(new CustomEvent(ShowToastEventName, {
            detail: {
                message: 'Users imported successfully.',
                title: 'Success',
                variant: 'success'
            }
        }));

        const button3 = element.shadowRoot.querySelector('lightning-button[label="Post-Import Steps"]');
        button3.click();
        await expect(runManualSteps2).resolves.toBe('Success');
        expect(element.dispatchEvent).toHaveBeenCalledWith(new CustomEvent(ShowToastEventName, {
            detail: {
                message: 'Post-import steps completed successfully.',
                title: 'Success',
                variant: 'success'
            }
        }));

        const button4 = element.shadowRoot.querySelector('lightning-button[label="E2C Addresses"]');
        button4.click();
        await expect(runE2CAddresses).resolves.toBe('Success');
        expect(element.dispatchEvent).toHaveBeenCalledWith(new CustomEvent(ShowToastEventName, {
            detail: {
                message: 'E2C addresses updated successfully.',
                title: 'Success',
                variant: 'success'
            }
        }));
    });

    it('should display an error toast notification upon failure', async () => {
        // Arrange
        const element = createElement('c-prepsandbox', {
            is: Prepsandbox
        });

        document.body.appendChild(element);

        // Act & Assert
        const button1 = element.shadowRoot.querySelector('lightning-button[label="Post-Refresh Steps"]');
        button1.click();
        await expect(runManualSteps).rejects.toBe('Error');
        expect(element.dispatchEvent).toHaveBeenCalledWith(new CustomEvent(ShowToastEventName, {
            detail: {
                message: 'Failed to complete post-refresh steps.',
                title: 'Error',
                variant: 'error'
            }
        }));

        const button2 = element.shadowRoot.querySelector('lightning-button[label="Import Org Users"]');
        button2.click();
        await expect(runUserImport).rejects.toBe('Error');
        expect(element.dispatchEvent).toHaveBeenCalledWith(new CustomEvent(ShowToastEventName, {
            detail: {
                message: 'Failed to import users.',
                title: 'Error',
                variant: 'error'
            }
        }));

        const button3 = element.shadowRoot.querySelector('lightning-button[label="Post-Import Steps"]');
        button3.click();
        await expect(runManualSteps2).rejects.toBe('Error');
        expect(element.dispatchEvent).toHaveBeenCalledWith(new CustomEvent(ShowToastEventName, {
            detail: {
                message: 'Failed to complete post-import steps.',
                title: 'Error',
                variant: 'error'
            }
        }));

        const button4 = element.shadowRoot.querySelector('lightning-button[label="E2C Addresses"]');
        button4.click();
        await expect(runE2CAddresses).rejects.toBe('Error');
        expect(element.dispatchEvent).toHaveBeenCalledWith(new CustomEvent(ShowToastEventName, {
            detail: {
                message: 'Failed to update E2C addresses.',
                title: 'Error',
                variant: 'error'
            }
        }));
    });

    it('should disable the loading spinner upon starting the operation', async () => {
        // Arrange
        const element = createElement('c-prepsandbox', {
            is: Prepsandbox
        });

        document.body.appendChild(element);

        // Act
        const button1 = element.shadowRoot.querySelector('lightning-button[label="Post-Refresh Steps"]');
        button1.click();

        // Assert
        const spinner1 = element.shadowRoot.querySelector('lightning-spinner');
        expect(spinner1).not.toBeNull();
        expect(spinner1.alternativeText).toBe('Loading');

        // Act
        const button2 = element.shadowRoot.querySelector('lightning-button[label="Import Org Users"]');
        button2.click();

        // Assert
        const spinner2 = element.shadowRoot.querySelector('lightning-spinner');
        expect(spinner2).not.toBeNull();
        expect(spinner2.alternativeText).toBe('Loading');

        // Act
        const button3 = element.shadowRoot.querySelector('lightning-button[label="Post-Import Steps"]');
        button3.click();

        // Assert
        const spinner3 = element.shadowRoot.querySelector('lightning-spinner');
        expect(spinner3).not.toBeNull();
        expect(spinner3.alternativeText).toBe('Loading');

        // Act
        const button4 = element.shadowRoot.querySelector('lightning-button[label="E2C Addresses"]');
        button4.click();

        // Assert
        const spinner4 = element.shadowRoot.querySelector('lightning-spinner');
        expect(spinner4).not.toBeNull();
        expect(spinner4.alternativeText).toBe('Loading');
    });

    it('should re-enable the loading spinner upon completion of the operation', async () => {
        // Arrange
        const element = createElement('c-prepsandbox', {
            is: Prepsandbox
        });

        document.body.appendChild(element);

        // Act
        const button1 = element.shadowRoot.querySelector('lightning-button[label="Post-Refresh Steps"]');
        button1.click();
        await expect(runManualSteps).resolves.toBe('Success');

        // Assert
        const spinner1 = element.shadowRoot.querySelector('lightning-spinner');
        expect(spinner1).toBeNull();

        // Act
        const button2 = element.shadowRoot.querySelector('lightning-button[label="Import Org Users"]');
        button2.click();
        await expect(runUserImport).resolves.toBe('Success');

        // Assert
        const spinner2 = element.shadowRoot.querySelector('lightning-spinner');
        expect(spinner2).toBeNull();

        // Act
        const button3 = element.shadowRoot.querySelector('lightning-button[label="Post-Import Steps"]');
        button3.click();
        await expect(runManualSteps2).resolves.toBe('Success');

        // Assert
        const spinner3 = element.shadowRoot.querySelector('lightning-spinner');
        expect(spinner3).toBeNull();

        // Act
        const button4 = element.shadowRoot.querySelector('lightning-button[label="E2C Addresses"]');
        button4.click();
        await expect(runE2CAddresses).resolves.toBe('Success');

        // Assert
        const spinner4 = element.shadowRoot.querySelector('lightning-spinner');
        expect(spinner4).toBeNull();
    });
});