public with sharing class SportsRegistrationController {
    @AuraEnabled
    public static void createRegistration(String sport, String teamName, Integer players, Decimal fee) {
        Sports_Registration__c reg = new Sports_Registration__c();
        reg.Name = teamName; // use standard Name
        reg.Sport__c = sport;
        reg.Number_of_Players__c = players;
        reg.Registration_Fee__c = fee;
        insert reg;
    }
}