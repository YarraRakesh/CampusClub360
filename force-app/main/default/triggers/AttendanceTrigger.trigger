trigger AttendanceTrigger on Attendance__c (before insert, before update) {
    // Query Club Business Hours once
    BusinessHours clubHours = [
        SELECT Id 
        FROM BusinessHours 
        WHERE Name = 'Club Hours' 
        LIMIT 1
    ];

    for (Attendance__c att : Trigger.new) {
        // Skip if no check-in time provided
        if (att.Check_In_Time__c == null) continue;

        // Check if inside Club business hours
        Boolean isValid = BusinessHours.isWithin(
            clubHours.Id, 
            att.Check_In_Time__c
        );

        if (!isValid) {
            att.Check_In_Time__c.addError(
                'Attendance not allowed outside Club timings (10 AM – 3 PM, Mon–Sat, excluding holidays).'
            );
        }
    }
}