trigger SportsSaleTrigger on Sports_Sale__c (before insert, before update) {
    // Query Store Business Hours once
    BusinessHours storeHours = [
        SELECT Id 
        FROM BusinessHours 
        WHERE Name = 'Store Hours' 
        LIMIT 1
    ];

    for (Sports_Sale__c sale : Trigger.new) {
        // Skip if no sale date provided
        if (sale.Sale_Date__c == null) continue;

        // Check if inside Store business hours
        Boolean isValid = BusinessHours.isWithin(
            storeHours.Id, 
            sale.Sale_Date__c
        );

        if (!isValid) {
            sale.Sale_Date__c.addError(
                'Store purchase not allowed outside Store timings (10 AM – 7 PM, Mon–Sat, excluding Sundays/holidays).'
            );
        }
    }
}