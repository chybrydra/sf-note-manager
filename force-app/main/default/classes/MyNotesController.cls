public with sharing class MyNotesController {

    public My_Notes__c newNote {get; set;}

    public MyNotesController() {
        initialize();
    }

    private void initialize() {
        this.newNote = new My_Notes__c();
    }

    public void saveNote() {
        try {
            insert this.newNote;
            String message = 'New note: "' + newNote.Title__c + '" was created successfully';
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,message));
        } catch (DmlException e) {
            String message = 'Could not create a note.';
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, message));
        }
        initialize();
    }

}
