public with sharing class SportsItemController {

    @AuraEnabled(cacheable=true)
    public static Sports_Item__c getItemByBarcode(String barcode) {
        try {
            List<Sports_Item__c> items = [
                SELECT Id, Name, Price__c, Barcode__c, Stock_Quantity__c
                FROM Sports_Item__c
                WHERE Barcode__c = :barcode
                LIMIT 1
            ];
            if (!items.isEmpty()) {
                return items[0];
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching item: ' + e.getMessage());
        }
    }

    // Helper inner class to receive cart data from LWC
    public class CartItem {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public Decimal price;
        @AuraEnabled public String barcode;
        @AuraEnabled public Integer quantity;
    }

    @AuraEnabled
    public static String finalizeSale(List<CartItem> items, Decimal totalAmount) {
        if (items == null || items.isEmpty()) {
            throw new AuraHandledException('Cart is empty. Nothing to finalize.');
        }

        try {
            // Create Sale record
            Sports_Sale__c sale = new Sports_Sale__c();
            sale.Name = 'Sale - ' + DateTime.now().format('yyyy-MM-dd HH:mm');
            sale.Sale_Date__c = System.now();
            sale.Total_Amount__c = totalAmount;
            insert sale;

            // Build item summary text
            String summary = '';
            List<Sports_Item__c> updates = new List<Sports_Item__c>();

            for (CartItem ci : items) {
                summary += ci.name + ' (x' + ci.quantity + ') - ₹' + (ci.price * ci.quantity) + '\n';

                if (ci.id != null) {
                    // Try to fetch by Id
                    List<Sports_Item__c> results = [
                        SELECT Id, Stock_Quantity__c
                        FROM Sports_Item__c
                        WHERE Id = :ci.id
                        LIMIT 1
                    ];
                    if (!results.isEmpty()) {
                        Sports_Item__c item = results[0];
                        Integer currentStock = item.Stock_Quantity__c == null ? 0 : Integer.valueOf(item.Stock_Quantity__c);
                        item.Stock_Quantity__c = Math.max(0, currentStock - ci.quantity);
                        updates.add(item);
                    }
                }
            }

            if (!updates.isEmpty()) {
                update updates;
            }

            // Update sale with summary
            sale.Items_Summary__c = summary;
            update sale;

            return 'Sale finalized successfully. Id: ' + sale.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to finalize sale: ' + e.getMessage());
        }
    }
}