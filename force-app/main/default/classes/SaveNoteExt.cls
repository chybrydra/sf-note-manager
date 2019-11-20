public class SaveNoteExt {

    public My_Notes__c myNote {get; set;}

    public SaveNoteExt(ApexPages.StandardController controller) {
        this.myNote = (My_Notes__c) controller.getRecord();
    }

    public PageReference saveNote() {
        try {
            insert myNote;
            String message = 'New note: "' + myNote.Title__c + '" was created successfully';
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,message));
        } catch (DmlException e) {
            String message = 'Could not create a note.';
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, message));
        }
        myNote.id = null;
        return null;
 
    }    
}
