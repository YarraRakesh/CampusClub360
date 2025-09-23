public with sharing class SportsSaleController {

    // Wrapper to map cart items coming from LWC
    public class CartItemWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public Decimal price;
        @AuraEnabled public String barcode;
        @AuraEnabled public Integer quantity;
    }

    @AuraEnabled
    public static Id finalizeSale(String itemsJson, Decimal totalAmount) {
        if (String.isBlank(itemsJson)) {
            throw new AuraHandledException('Cart is empty. Cannot finalize sale.');
        }

        // Deserialize JSON to wrapper list
        List<CartItemWrapper> items =
            (List<CartItemWrapper>) JSON.deserialize(itemsJson, List<CartItemWrapper>.class);

        if (items.isEmpty()) {
            throw new AuraHandledException('Cart is empty. Cannot finalize sale.');
        }

        // Build summary for Sale record
        String summary = '';
        for (CartItemWrapper item : items) {
            summary += item.name + ' (x' + item.quantity + ') - ₹' +
                       String.valueOf(item.price * item.quantity) + '\n';
        }

        // Create Sale record
        Sports_Sale__c sale = new Sports_Sale__c();
        sale.Name = 'Sale - ' + DateTime.now().format('yyyy-MM-dd HH:mm');
        sale.Sale_Date__c = System.now();
        sale.Total_Amount__c = totalAmount;
        sale.Items_Summary__c = summary;
        insert sale;

        // Reduce stock
        List<Sports_Item__c> updates = new List<Sports_Item__c>();
        for (CartItemWrapper item : items) {
            Sports_Item__c dbItem = [
                SELECT Id, Stock_Quantity__c
                FROM Sports_Item__c
                WHERE Id = :item.id
                LIMIT 1
            ];
            if (dbItem.Stock_Quantity__c >= item.quantity) {
                dbItem.Stock_Quantity__c -= item.quantity;
                updates.add(dbItem);
            } else {
                throw new AuraHandledException(
                    'Not enough stock for item: ' + item.name
                );
            }
        }
        if (!updates.isEmpty()) {
            update updates;
        }

        return sale.Id;
    }
}