// Scheduler class
global class DailyMeetingCleanupScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Run batch to handle yesterday’s meetings
        Database.executeBatch(new DailyMeetingCleanupBatch(), 200);
    }
}