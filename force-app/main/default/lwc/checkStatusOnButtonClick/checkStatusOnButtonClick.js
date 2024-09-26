import { LightningElement, track, api } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
import Payment_Time_Out from '@salesforce/label/c.Payment_Time_Out';
import Limit_send_payment from '@salesforce/label/c.Limit_send_payment';
import Something_went_wrong_Case_ID_not_found from '@salesforce/label/c.Something_went_wrong_Case_ID_not_found';
import FetchDataTime from '@salesforce/label/c.FetchDataTime';
import checkPaymentStatus from '@salesforce/apex/PaymentGatewayIntegration.checkPaymentStatus';
import getAmountData from '@salesforce/apex/SendPaymentLinkListAction.getCaseAmountData';
import sendPaymentLink from '@salesforce/apex/SendPaymentLinkListAction.sendPaymentLinkFromLWC';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CheckStatusOnButtonClick extends OmniscriptBaseMixin(LightningElement) {
    // API property to receive data from OmniScript
    @api omniJsonData;

    // Track properties for reactive state management
    @track _paymentId;
    @track timeLeft = Payment_Time_Out; // Initialize the timer with the configured timeout value
    @track fetchDataTime = FetchDataTime * 1000; // Time interval for fetching data
    @track isRunning = false;
    @track amount = '';
    @track paymentOptionValue = '';
    @track showTimer = false;
    @track caseAmount = '';
    @track isLoading = true;
    @track showSecondScreen = false;
    defaultPaymentOption = '';
    isDisabledCombo = true;
    value = 'created';

    // Constants
    limitOfSendPaymentAmount = Limit_send_payment;

    // Properties for controlling UI elements
    isDisabledStatusButton = true;
    amountDisabled = true;
    sendPaymentButtonBypass = false;
    comoboxDisabled = false;
    showfirstScreen = false;

    // Timer and Interval IDs
    timerId;
    fetchDataInterval;
    amountDisabledOption  = false;
    paymentValue = '';

    // Getter to define the payment options available in the combobox
    get paymentOption() {
        return [
            { "label": "--None--", value: "" },
            { "label": "Pay the Entire Amount", value: "Pay the Entire Amount" },
            { "label": "Pay Partial Amount", value: "Pay Partial Amount" },
        ];
    }

    get amountOption(){
        return [
            {"label" : "Yes", value:"Yes" },
            {"label" : "No", value:"No" }
        ];
    }

    // Getter to define the payment status options available in the combobox
    get options() {
        return [
            { "label": "Payment Link Created", value: "created" },
            { "label": "Payment Partially Paid", value: "partially_paid" },
            { "label": "Payment Link Expired", value: "expired" },
            { "label": "Payment Cancelled", value: "cancelled" },
            { "label": "Payment Completed", value: "paid" }
        ];
    }

    // Computed property to disable or enable the send payment button based on conditions
    get sendPaymentButton() {
        return this.paymentOptionValue === '' || this.amount === 0 || this.amount === '' || this.sendPaymentButtonBypass;
    }

    get circleStyle() {
        const progress = (this.timeLeft / Payment_Time_Out) * 100;
        return `background : conic-gradient(#4CAF50 ${progress}%, #f3f3f3 ${progress}% 100%)`;
        
    }

    // Lifecycle hook executed when the component is inserted into the DOM
    connectedCallback() {
        this.initializeOmniScriptData();
        this.getAmountData();
    }

    

    // Initialize OmniScript data and set case record ID
    initializeOmniScriptData() {
        console.log('kkkk'+JSON.stringify(this.omniJsonData));
        if (this.omniJsonData.ContextId) {
            this.caseRecordId = this.omniJsonData.ContextId;
        } else {
            this.showMessage('Error', 'Error', Something_went_wrong_Case_ID_not_found);
        }
    }

    // Fetch the case amount data from the server
    getAmountData() {
        getAmountData({ caseId: this.caseRecordId })
            .then(result => {
                this.amount = result;
                this.caseAmount = result;
                this.isLoading = false;
            })
            .catch(error => {
                console.error(error);
            });
    }

    // Start a countdown timer
    startTimer() {
        if (!this.isRunning) {
            this.isRunning = true;
            this.timerId = setInterval(() => {
                this.timeLeft -= 1;
                if (this.timeLeft === 0) {
                    this.showTimer = false;
                    this.isDisabledStatusButton = false;
                    this.stopTimer();
                }
            }, 1000);
        }
    }

    // Stop the countdown timer
    stopTimer() {
        clearInterval(this.timerId);
        this.isRunning = false;
    }

    // Start fetching payment status at intervals
    startFetchDataInterval() {
        this.fetchDataInterval = setInterval(() => {
            this.fetchDataFromApi();
            if (this.timeLeft === 0) {
                this.stopFetchDataInterval();
            }
        }, this.fetchDataTime);
    }

    // Stop fetching payment status
    stopFetchDataInterval() {
        clearInterval(this.fetchDataInterval);
    }

    // Fetch payment status from the server
    fetchDataFromApi() {
        checkPaymentStatus({ paymentIds: null, singleRecordFound: true, singlePaymentId: this._paymentId })
            .then(result => {
                if (result.isSuccess) {
                    this.value = result.paymentStatus;
                    if (result.paymentStatus !== 'created') {
                        this.stopTimer();
                        this.stopFetchDataInterval();
                        this.isDisabledStatusButton = true;
                    }
                } else {
                    console.log(result.message);
                }
            })
            .catch(error => {
                console.error(error);
            });
    }

    // Handle form field changes
    handleChange(event) {
        
        if (event.target.label === 'Desired Payment Amount?') {
            let amountTemplate = this.template.querySelector(".inputData");
            amountTemplate.setCustomValidity("");
            amountTemplate.reportValidity();
            this.paymentOptionValue = event.target.value;
            if (this.paymentOptionValue === 'Pay the Entire Amount' || this.paymentOptionValue === '') {
                this.amount = this.caseAmount;
                this.amountDisabled = true;
            } else if (this.paymentOptionValue === 'Pay Partial Amount') {
                this.amountDisabled = false;
            }
            var data = {
                "How_much_do_you_want_to_pay" : this.paymentOptionValue
            }
            this.omniUpdateDataJson(data);
            this.omniApplyCallResp(data)
        }

        if (event.target.label === 'Amount to Paid?') {
            let amountTemplate = this.template.querySelector(".inputData");
            amountTemplate.setCustomValidity("");
            amountTemplate.reportValidity();
            this.amount = event.target.value;
            if (Number(this.amount) >= Number(this.limitOfSendPaymentAmount)) {
                let message = 'Send payment Amount Limit Exceeded';
                amountTemplate.setCustomValidity(message);
                amountTemplate.reportValidity();
            }
        }

        if(event.target.label === 'Can you pay the amount online now ?'){
            this.paymentValue = event.detail.value;
            if(this.paymentValue == 'Yes'){
                this.showfirstScreen = true;
            }else{
                this.showfirstScreen = false;
            }
            var data = {
                "Can_you_pay_the_amount_online_now" : this.paymentValue,
            }
            this.omniUpdateDataJson(data);
            this.omniApplyCallResp(data)
        }
    }

    // Handle the click event to send a payment link
    handleClick() {
        let isValidate = this.validateData();
        if (isValidate.isError) {
            this.showMessage('Error', 'Error', isValidate.isErrorMessage);
        } else {
            this.sendPaymentLink();
        }
    }

    // Validate the form data before submission
    validateData() {
        let returnData = { isError: false, isErrorMessage: "" };

        if (this.paymentOptionValue === 'Pay Partial Amount' && this.amount === this.caseAmount) {
            returnData.isError = true;
            returnData.isErrorMessage = 'Amount to Paid should be less than Outstanding Amount';
        } else if (Number(this.amountNumber) >= Number(this.limitOfSendPaymentAmount)) {
            returnData.isError = true;
            returnData.isErrorMessage = `Amount limit exceeded. Limit for sending payment amount is ${this.limitOfSendPaymentAmount}`;
        }else if(Number(this.amount) > Number(this.caseAmount)){
            returnData.isError = true;
            returnData.isErrorMessage = 'Amount to Paid should be less than Outstanding Amount';
        }

        return returnData;
    }

    // Send the payment link
    sendPaymentLink() {
        this.isLoading = true;
        sendPaymentLink({ caseId: this.caseRecordId, amount: this.amount, paymentOption: this.paymentOptionValue })
            .then(result => {
                if (result.isError) {
                    this.showMessage('Error', 'Error', result.message);
                } else {
                    this.showMessage('Success', 'Success', result.message);
                    if (result.paymentId) {
                        var data = {
                            "How_much_do_you_want_to_pay" : this.paymentOptionValue,
                            "Amount_to_Paid" : this.amount
                        }
                        this.omniUpdateDataJson(data);
                        this.comoboxDisabled = true;
                        this.amountDisabledOption = true;
                        this.sendPaymentButtonBypass = true;
                        this.showSecondScreen = true;
                        this.amountDisabled = true;
                        this._paymentId = result.paymentId;
                        this.showTimer = true;
                        this.startTimer();
                        this.startFetchDataInterval();
                    }
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.showMessage('Error', 'Error', error.body.message);
                this.isLoading = false;
            });
    }

    // Display a toast message
    showMessage(title, variant, message) {
        const event = new ShowToastEvent({
            title: title,
            variant: variant,
            mode: 'dismissable',
            message: message
        });
        this.dispatchEvent(event);
    }

    // Lifecycle hook executed when the component is removed from the DOM
    disconnectedCallback() {
        this.stopTimer();
        this.stopFetchDataInterval();
    }
}