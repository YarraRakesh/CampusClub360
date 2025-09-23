import { LightningElement, track, api } from 'lwc';
import finalizeSale from '@salesforce/apex/SportsSaleController.finalizeSale';

export default class SportsItemList extends LightningElement {
    @track cartItems = [];
    @track totalAmount = 0;

    // toast state
    @track toast = { visible: false, message: '', type: '' };

    showToast(message, type = 'info') {
        this.toast = { visible: true, message, type };

        // auto hide after 3 sec
        setTimeout(() => {
            this.toast.visible = false;
        }, 3000);
    }

    // Add item
    @api addItem(item) {
        let existing = this.cartItems.find(i => i.id === item.id);
        if (existing) {
            existing.quantity += 1;
            existing.lineTotal = existing.price * existing.quantity;
        } else {
            this.cartItems = [
                ...this.cartItems,
                { ...item, quantity: 1, lineTotal: item.price }
            ];
        }
        this.calculateTotal();
    }

    removeItem(event) {
        const id = event.currentTarget.dataset.id;
        let index = this.cartItems.findIndex(i => i.id === id);
        if (index > -1) {
            if (this.cartItems[index].quantity > 1) {
                this.cartItems[index].quantity -= 1;
                this.cartItems[index].lineTotal =
                    this.cartItems[index].price * this.cartItems[index].quantity;
            } else {
                this.cartItems.splice(index, 1);
            }
            this.cartItems = [...this.cartItems];
        }
        this.calculateTotal();
    }

    calculateTotal() {
        this.totalAmount = this.cartItems.reduce((sum, i) => sum + i.lineTotal, 0);
    }

    finalizeSale() {
        finalizeSale({
            itemsJson: JSON.stringify(this.cartItems),
            totalAmount: this.totalAmount
        })
            .then(() => {
                this.showToast('✅ Sale finalized successfully!', 'success');
                this.cartItems = [];
                this.totalAmount = 0;
            })
            .catch((err) => {
                let message = 'Unknown error';
                if (err && err.body && err.body.message) {
                    message = err.body.message;
                } else if (err && err.message) {
                    message = err.message;
                }
                this.showToast('❌ Failed to finalize sale: ' + message, 'error');
            });
    }
}