// Batch class
global class DailyMeetingCleanupBatch 
    implements Database.Batchable<SObject>, Database.Stateful {

    // Maps to hold summaries and counts
    Map<Id, String> meetingSummaries = new Map<Id, String>();
    Map<Id, Integer> meetingCounts = new Map<Id, Integer>();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Query yesterday’s attendance
        return Database.getQueryLocator([
            SELECT Id, Name, Student__r.Name, Student_Email__c,
                   Club_Meeting__c, Club_Meeting__r.Name,
                   Club_Meeting__r.Meeting_Date__c,
                   Club_Meeting__r.Location__c,
                   Club_Meeting__r.CreatedBy.Name,
                   Club_Meeting__r.CreatedBy.Email
            FROM Attendance__c
            WHERE Club_Meeting__r.Meeting_Date__c = YESTERDAY
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Attendance__c> scope) {
        Map<Id, List<Attendance__c>> grouped = new Map<Id, List<Attendance__c>>();

        // Group Attendance by Meeting
        for (Attendance__c att : scope) {
            if (!grouped.containsKey(att.Club_Meeting__c)) {
                grouped.put(att.Club_Meeting__c, new List<Attendance__c>());
            }
            grouped.get(att.Club_Meeting__c).add(att);
        }

        // Build summaries
        for (Id meetingId : grouped.keySet()) {
            List<Attendance__c> attList = grouped.get(meetingId);

            if (!meetingSummaries.containsKey(meetingId)) {
                meetingSummaries.put(meetingId, '');
                meetingCounts.put(meetingId, 0);
            }

            String summary = meetingSummaries.get(meetingId);
            Integer count = meetingCounts.get(meetingId);

            for (Attendance__c att : attList) {
                count++;
                summary += '- ' + att.Student__r.Name;
                if (att.Student_Email__c != null) {
                    summary += ' (' + att.Student_Email__c + ')';
                }
                summary += '\n';
            }

            meetingSummaries.put(meetingId, summary);
            meetingCounts.put(meetingId, count);
        }

        // Delete Attendance in this batch scope
        delete scope;
    }

    global void finish(Database.BatchableContext bc) {
        // Query yesterday’s meetings
        List<Club_Meeting__c> meetings = [
            SELECT Id, Name, Meeting_Date__c, Location__c,
                   CreatedBy.Name, CreatedBy.Email
            FROM Club_Meeting__c
            WHERE Meeting_Date__c = YESTERDAY
        ];

        List<Club_Meeting__c> toDelete = new List<Club_Meeting__c>();
        List<Messaging.SingleEmailMessage> allEmails = new List<Messaging.SingleEmailMessage>();

        for (Club_Meeting__c meeting : meetings) {
            // Safe defaults
            Integer count = meetingCounts.containsKey(meeting.Id) ? meetingCounts.get(meeting.Id) : 0;
            String summary = meetingSummaries.containsKey(meeting.Id) ? meetingSummaries.get(meeting.Id) : 'No students attended.\n';

            String emailBody = 'Hello ' + meeting.CreatedBy.Name + ',\n\n' +
                               'Here is the attendance summary for your meeting:\n\n' +
                               'Meeting: ' + meeting.Name + '\n' +
                               'Date: ' + meeting.Meeting_Date__c + '\n' +
                               'Location: ' + meeting.Location__c + '\n\n' +
                               'Total Students Attended: ' + count + '\n' +
                               'Details:\n' + summary + '\n\n' +
                               'This meeting and attendance have now been archived and removed.\n\n' +
                               'Regards,\nCampus System';

            // Build email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { meeting.CreatedBy.Email });
            mail.setSubject('Club Meeting Attendance Summary – ' + meeting.Meeting_Date__c);
            mail.setPlainTextBody(emailBody);
            allEmails.add(mail);

            // Add meeting to delete list
            toDelete.add(meeting);
        }

        // Send all emails in one call (avoids governor limits)
        if (!allEmails.isEmpty()) {
            Messaging.sendEmail(allEmails);
        }

        // Delete yesterday’s meetings
        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }
}