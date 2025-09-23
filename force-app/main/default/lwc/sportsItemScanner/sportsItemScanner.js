import { LightningElement, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import ZXingLib from '@salesforce/resourceUrl/ZXing';
import getItemByBarcode from '@salesforce/apex/SportsItemController.getItemByBarcode';

export default class SportsItemScanner extends LightningElement {
    @track scannedItem;   // Store scanned item details
    @track errorMsg;
    scannerRunning = false;
    zxingLoaded = false;
    codeReader;

    renderedCallback() {
        if (this.zxingLoaded) return;

        loadScript(this, ZXingLib)
            .then(() => {
                this.zxingLoaded = true;
                this.codeReader = new window.ZXing.BrowserBarcodeReader();
                console.log('✅ ZXing loaded successfully');
            })
            .catch(error => {
                this.errorMsg = 'Failed to load ZXing: ' + error;
                console.error(this.errorMsg);
            });
    }

    async startScanner() {
        try {
            const video = this.template.querySelector('video');
            const result = await this.codeReader.decodeOnceFromVideoDevice(undefined, video);

            // Call Apex to get item details
            const item = await getItemByBarcode({ barcode: result.text });
            if (item) {
                this.scannedItem = item;
                this.errorMsg = null;
            } else {
                this.scannedItem = null;
                this.errorMsg = '⚠️ Item not found in system';
            }

            this.stopScanner();
        } catch (err) {
            this.errorMsg = '⚠️ Scan failed: ' + err.message;
            console.error(err);
        }
    }

    stopScanner() {
        if (this.codeReader) {
            this.codeReader.reset();
        }
        this.scannerRunning = false;
    }

    toggleScanner() {
        if (this.scannerRunning) {
            this.stopScanner();
        } else {
            this.startScanner();
            this.scannerRunning = true;
        }
    }

    get buttonLabel() {
        return this.scannerRunning ? 'Stop Scanner' : 'Start Scanner';
    }

    // Add item to cart
    // sportsItemScanner.js
    addToCart() {
    if (this.scannedItem) {
        this.dispatchEvent(new CustomEvent('addtocart', {
            detail: {
                id: this.scannedItem.Id,   // 👈 very important
                name: this.scannedItem.Name,
                price: Number(this.scannedItem.Price__c),
                barcode: this.scannedItem.Barcode__c,
                quantity: 1
            }
        }));
        this.scannedItem = null;
    }
    }

}