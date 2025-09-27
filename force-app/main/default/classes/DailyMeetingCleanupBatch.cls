// Batch class
global class DailyMeetingCleanupBatch implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date yesterday = Date.today().addDays(-1);
        return Database.getQueryLocator([
            SELECT Id, Name, CreatedBy.Email, CreatedBy.Name
            FROM Club_Meeting__c
            WHERE Meeting_Date__c = :yesterday
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Club_Meeting__c> meetings) {
        for (Club_Meeting__c meeting : meetings) {
            
            // Get attendance for this meeting
            List<Attendance__c> attendanceList = [
                SELECT Id, Student__r.Name, Student_Email__c
                FROM Attendance__c
                WHERE Club_Meeting__c = :meeting.Id
            ];
            
            if (!attendanceList.isEmpty()) {
                
                // Build HTML table
                String htmlTable = '<table border="1" style="border-collapse:collapse;">' +
                                   '<tr><th>Student Name</th><th>Email</th></tr>';
                for (Attendance__c att : attendanceList) {
                    String studentName = (att.Student__r != null) ? att.Student__r.Name : 'Unknown';
                    String studentEmail = (att.Student_Email__c != null) ? att.Student_Email__c : 'N/A';
                    htmlTable += '<tr><td>' + studentName + '</td><td>' + studentEmail + '</td></tr>';
                }
                htmlTable += '</table>';
                
                // Send email to meeting creator
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { meeting.CreatedBy.Email });
                mail.setSubject('Attendance Report for ' + meeting.Name);
                mail.setHtmlBody('Dear ' + meeting.CreatedBy.Name + ',<br/><br/>' +
                                 'Here is the attendance for your meeting: ' + meeting.Name + '<br/><br/>' +
                                 htmlTable +
                                 '<br/><br/>Regards,<br/>System');
                
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                
                // Delete attendance
                delete attendanceList;
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optional logging
    }
}