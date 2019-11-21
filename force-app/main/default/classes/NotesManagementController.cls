public class NotesManagementController {

    private String sortOrder = 'Effective_Date__c';
    public List<My_Notes__c> notes {get; set;}
    public String searchText {get; set;}
    public boolean searchByTitle {get; set;}
    public boolean searchByKeyword {get; set;}
    public Date startDate {get; set;}
    public Date endDate {get; set;}
    public boolean searchInActive {get; set;}
    
    public Integer pageSize {get; set;}
    public Integer currentPage {get; set;}
    public Integer offset {get; set;}
    public Integer countRecords {get; set;}
    public Integer lastPage {get; set;}

    public NotesManagementController() {
        this.pageSize = 5;
        this.currentPage = 1;
        this.searchInActive = false;
        this.searchText = '';
        this.searchByTitle = false;
        this.searchByKeyword = false;
        this.startDate = null;
        this.endDate = null;
        this.countRecords = 0;
        this.lastPage = 0;
        calculateOffset();
        initialize();
    }

    private void calculateOffset() {
        this.offset = (this.currentPage-1)*this.pageSize;
    }

    private void calculateLastPage() {
        this.lastPage = this.countRecords/this.pageSize + 1;
    }

    public void initialize() {
        Integer count = Database.countQuery('SELECT COUNT() FROM My_Notes__c');
        this.countRecords = count;
        calculateLastPage();
        this.notes = Database.query(
            'SELECT Id, Title__c, Keywords__c, Effective_Date__c, Active__c ' +
            'FROM My_Notes__c ' +
            'ORDER BY ' + this.sortOrder + ' ASC ' +
            'LIMIT ' + this.pageSize +
            'OFFSET ' + this.offset
        );
    }

    public void search() {
        String filters = generateSoqlFilters();
        String whereStmt = filters == '' ? '' : 'WHERE ' + filters + ' '; 
        Integer count = Database.countQuery(
            'SELECT COUNT() FROM My_Notes__c ' + whereStmt
        );
        this.countRecords = count;
        calculateLastPage();
        this.notes = Database.query(
            'SELECT Id, Title__c, Keywords__c, Effective_Date__c, Active__c ' +
            'FROM My_Notes__c ' +
            whereStmt + 
            'ORDER BY ' + this.sortOrder + ' ASC ' +
            'LIMIT ' + this.pageSize +
            'OFFSET ' + this.offset
        );
        ApexPages.getMessages().clear();
    }

    public void firstPage() {
        this.currentPage = 1;
        calculateOffset();
        search();
    }

    public void prevPage() {
        if (this.currentPage > 1) {
            this.currentPage -= 1;
            calculateOffset();
            search();
        }
    }

    public void nextPage() {
        this.currentPage += 1;
        calculateOffset();
        search();
    }

    public void lastPage() {
        this.currentPage = this.lastPage;
        calculateOffset();
        search();
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
        if (result.contains('OR')) {
            result = '(' + result + ')';
        }
        if (startDate != null) {
            result += result=='' ? '' : ' AND ';
            result += 'Effective_Date__c > ' + createDateString(startDate) +'T00:00:00Z';
        }
        if (endDate != null) {
            result += result=='' ? '' : ' AND ';
            result += 'Effective_Date__c < ' + createDateString(endDate) +'T00:00:00Z';
        }
        if (searchInActive) {
            result += result=='' ? '' : ' AND ';
            result += 'Active__c = TRUE';
        }
        
        return result;
    }

    public String createDateString(Date theDate) {
        String dateString = theDate.year() + '-';
        dateString += theDate.month() < 10 ? '0' : '';
        dateString += String.valueOf(theDate.month());
        dateString += '-';
        dateString += theDate.day() < 10 ? '0' : '';
        dateString += String.valueOf(theDate.day());
        return dateString;
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
