// Scheduler class
global class DailyMeetingCleanupScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        DailyMeetingCleanupBatch batch = new DailyMeetingCleanupBatch();
        Database.executeBatch(batch, 50);  // batch size 50
    }
}