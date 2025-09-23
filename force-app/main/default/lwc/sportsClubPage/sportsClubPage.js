import { LightningElement } from 'lwc';

export default class SportsClubPage extends LightningElement {

    // Handle add-to-cart from scanner
    handleAddToCart(event) {
        const cart = this.template.querySelector('c-sports-item-list');
        if (cart) {
            cart.addItem(event.detail);
        }
    }
}