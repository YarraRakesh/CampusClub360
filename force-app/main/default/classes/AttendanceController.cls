public with sharing class AttendanceController {
    // Wrapper to return attendance record + flag whether it was newly created
    public class AttendanceResult {
        @AuraEnabled public Attendance__c attendance;
        @AuraEnabled public Boolean isNew;
        public AttendanceResult(Attendance__c a, Boolean n) {
            this.attendance = a;
            this.isNew = n;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Club_Meeting__c> getMeetings() {
    return [
        SELECT Id, Name, Meeting_Date__c
        FROM Club_Meeting__c
        ORDER BY Meeting_Date__c ASC
     ];
     }

    
    @AuraEnabled(cacheable=true)
    public static Student__c findStudentByBarcode(String barcodeValue) {
        List<Student__c> s = [
            SELECT Id, Name, Student_ID__c, Barcode_Value__c
            FROM Student__c
            WHERE Barcode_Value__c = :barcodeValue
            LIMIT 1
        ];
        return s.isEmpty() ? null : s[0];
    }

    @AuraEnabled
    public static AttendanceResult createAttendance(Id studentId, Id meetingId) {
        // Attempt to find existing attendance
        List<Attendance__c> existing = [
            SELECT Id, Check_In_Time__c, Student__r.Name, Club_Meeting__r.Name
            FROM Attendance__c
            WHERE Student__c = :studentId AND Club_Meeting__c = :meetingId
            LIMIT 1
        ];
        if (!existing.isEmpty()) {
            return new AttendanceResult(existing[0], false);
        }

        // Create new Attendance (also populate UniqueKey__c if you created it)
        Attendance__c a = new Attendance__c(
            Student__c = studentId,
            Club_Meeting__c = meetingId,
            Check_In_Time__c = System.now()
        );

        // If you have a UniqueKey__c text unique field, set it here:
        // a.UniqueKey__c = studentId + '-' + meetingId;

        insert a;

        // Re-query to include relationship fields for the UI
        a = [
            SELECT Id, Check_In_Time__c, Student__r.Name, Club_Meeting__r.Name
            FROM Attendance__c
            WHERE Id = :a.Id
            LIMIT 1
        ];

        return new AttendanceResult(a, true);
    }
}