import { LightningElement, wire, api } from 'lwc';
import { OmniscriptBaseMixin } from "omnistudio/omniscriptBaseMixin";
import { IsConsoleNavigation, getFocusedTabInfo, closeTab, refreshTab } from 'lightning/platformWorkspaceApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation'
import previewFile from '@salesforce/apex/CollectionUtility.getContentDocumentId';

export default class RefreshScreen extends NavigationMixin(OmniscriptBaseMixin(LightningElement)) {
    // API property to receive data from OmniScript
    @api omniJsonData;
    isLoading = true;
    jobId;
    contentDocumentId;

    // Wire adapter to check if the component is running in console navigation
    @wire(IsConsoleNavigation) isConsoleNavigation;

    /**
     * Handles the click event to close the tab
     */
    handleClick() {
        try {
            this.closeTab();
        } catch (error) {
            console.error('Error in handleClick:', error);
        }
    }

    /**
     * Lifecycle hook that fires when a component is inserted into the DOM
     */
    connectedCallback() {
        try {
            setTimeout(() => {
                this.isLoading = false;
            }, 2000);
            this.initializeOmniScriptData();
            // const url = window.location.href;
            // const queryString = url.split('?')[1];
            // if (queryString) {
            //     const urlParams = new URLSearchParams(queryString);
            //     const tabLabel = urlParams.get('c__tabLabel');
            //     if (tabLabel == 'ReceiptDocumentGeneration') {
            //         this.showPreview = true;
            //         this.initializeOmniScriptData();
            //     }
            // }
        } catch (error) {
            console.error('Error in connectedCallback:', error);
        }
    }

    /**
     * Initializes OmniScript data and sets case record ID
     */
    initializeOmniScriptData() {
        try {
            if (this.omniJsonData && this.omniJsonData.jobId) {
                this.jobId = this.omniJsonData.jobId;
            }
        } catch (error) {
            console.error('Error in initializeOmniScriptData:', error);
        }
    }

    /**
     * Closes the current tab in console navigation
     */
    async closeTab() {
        try {
            if (!this.isConsoleNavigation) {
                return;
            }
            const { tabId } = await getFocusedTabInfo();
            const currentBaseTabId = tabId.split('_')[0];
            await refreshTab(currentBaseTabId, {
                includeAllSubtabs: true
            });
            await closeTab(tabId);
        } catch (error) {
            console.error('Error in closeTab:', error);
        }
    }

    /**
     * Previews the file associated with the current job
     */
    previewFile() {
        try {
            if (this.contentDocumentId) {
                this.navigationFile();
            } else {
                this.isLoading = true;
                previewFile({ jobId: this.jobId })
                    .then((result) => {
                        if (result) {
                            this.contentDocumentId = result;
                            this.navigationFile();
                        } else {
                            this.showMessage('Error', 'error', 'Content document id not found');
                        }
                    })
                    .catch((err) => {
                        this.showMessage('Error', 'error', err.body.message);
                    })
                    .finally(() => {
                        this.isLoading = false;
                    });
            }
        } catch (error) {
            console.error('Error in previewFile:', error);
            this.isLoading = false;
        }
    }

     /**
     * Navigate to file content
     */
    navigationFile() {
        try {
            this[NavigationMixin.Navigate]({
                type: 'standard__namedPage',
                attributes: {
                    pageName: 'filePreview'
                },
                state: {
                    selectedRecordId: this.contentDocumentId
                }
            });
        } catch (error) {
            console.error('Error in navigationFile: ', error);
        }
    }

    /**
     * Displays a toast message
     * @param {string} title - The title of the toast message
     * @param {string} variant - The variant of the toast (success, error, warning, info)
     * @param {string} message - The message to display in the toast
     */
    showMessage(title, variant, message) {
        try {
            const event = new ShowToastEvent({
                title: title,
                variant: variant,
                mode: 'dismissable',
                message: message
            });
            this.dispatchEvent(event);
        } catch (error) {
            console.error('Error in showMessage:', error);
        }
    }
}