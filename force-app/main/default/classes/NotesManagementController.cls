public class NotesManagementController {

    private String sortOrder = 'Effective_Date__c';
    public List<My_Notes__c> notes {get; set;}
    public String searchText {get; set;}
    public boolean searchByTitle {get; set;}
    public boolean searchByKeyword {get; set;}

    public NotesManagementController() {
        initialize();
    }

    public void initialize() {
        this.notes = Database.query(
            'SELECT Id, Title__c, Keywords__c, Effective_Date__c, Active__c ' +
            'FROM My_Notes__c ' +
            'ORDER BY ' + sortOrder + ' ASC ' +
            'LIMIT 20'
        );
    }

    public void search() {
        String filters = generateSoqlFilters();
        String whereStmt = filters == '' ? '' : 'WHERE ' + filters + ' '; 
        this.notes = Database.query(
            'SELECT Id, Title__c, Keywords__c, Effective_Date__c, Active__c ' +
            'FROM My_Notes__c ' +
            whereStmt + 
            'ORDER BY ' + sortOrder + ' ASC ' +
            'LIMIT 20'
        );
    }

    private String generateSoqlFilters() {
        Map<String, Boolean> likeFilters = new Map<String, Boolean>();
        likeFilters.put('Title__c', searchByTitle);
        likeFilters.put('Keywords__c', searchByKeyword);
        String result = '';
        for (String key : likeFilters.keySet()) {
            if (likeFilters.get(key) == false) continue;
            if (result == '') {
                result += ' ' + key +' LIKE \'%' + searchText + '%\'';
            } else {
                result += ' OR ' + key + ' LIKE \'%' + searchText + '%\'';
            }
        }
        return result;
    }

    public void deleteNote() {
        Id noteId = ApexPages.currentpage().getParameters().get('NoteId');
        My_Notes__c noteToDelete = [SELECT Id FROM My_Notes__c WHERE Id=:noteId LIMIT 1];
        try {
            delete noteToDelete;
            for (My_Notes__c note : notes) {
                if (note.Id == noteId) {
                    Integer noteIndex = notes.indexOf(note);
                    String message = 'Note deleted successfully: ' + notes.get(noteIndex).Title__c;
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,message));
                    notes.remove(noteIndex);
                    break;
                }
            }
        } catch (DmlException e) {
            System.debug(e.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'The note could not be deleted'));            
        }
    }
}
