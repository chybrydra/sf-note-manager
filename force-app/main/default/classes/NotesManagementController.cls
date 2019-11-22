public with sharing class NotesManagementController {

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

    private String whereStmt {get; set;}

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
        this.whereStmt = '';
        calculateOffset();
        initialize();
    }

    private void initialize() {
        countRecords(whereStmt);
        calculateLastPage();
        queryRecords('');
    }

    private void generateWhereStmt() {
        String filters = generateSoqlFilters();
        this.whereStmt = filters == '' ? '' : 'WHERE ' + filters + ' '; 
    }

    public void search() {
        firstPage();
        generateWhereStmt();
        countRecords(this.whereStmt);
        calculateLastPage();
        queryRecords(this.whereStmt);        
        ApexPages.getMessages().clear();
    }    

    public void deleteNote() {
        Id noteId = ApexPages.currentpage().getParameters().get('NoteId');
        My_Notes__c noteToDelete;
        Integer noteIndex = getNoteIndexByNoteId(noteId, this.notes);
        try {
            noteToDelete = notes.get(noteIndex);
            String message = 'Note deleted successfully: ' + noteToDelete.Title__c;    
            delete(noteToDelete);            
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,message));
            queryRecords(whereStmt);
            search();
        } catch (DmlException e) {
            System.debug(e.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'The note could not be deleted'));            
        }
    }    

    public void firstPage() {
        this.currentPage = 1;
        calculateOffset();
        queryRecords(this.whereStmt);
    }

    public void prevPage() {
        if (this.currentPage > 1) {
            this.currentPage -= 1;
            calculateOffset();
            queryRecords(this.whereStmt);
        }
    }

    public void nextPage() {
        if (currentPage<lastPage) {
            this.currentPage += 1;
            calculateOffset();
            queryRecords(this.whereStmt);
        }
    }

    public void lastPage() {
        this.currentPage = this.lastPage;
        calculateOffset();
        queryRecords(this.whereStmt);
    }

    private void countRecords(String whereStmt) {
        Integer count = Database.countQuery(
            'SELECT COUNT() FROM My_Notes__c ' + whereStmt
        );
        this.countRecords = count;
    }

    private void queryRecords(String whereStmt) {
        this.notes = Database.query(
            'SELECT Id, Title__c, Keywords__c, Effective_Date__c, Active__c ' +
            'FROM My_Notes__c ' +
            whereStmt + 
            'ORDER BY ' + this.sortOrder + ' ASC ' +
            'LIMIT ' + this.pageSize +
            'OFFSET ' + this.offset
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

    private String createDateString(Date theDate) {
        String dateString = theDate.year() + '-';
        dateString += theDate.month() < 10 ? '0' : '';
        dateString += String.valueOf(theDate.month());
        dateString += '-';
        dateString += theDate.day() < 10 ? '0' : '';
        dateString += String.valueOf(theDate.day());
        return dateString;
    }

    private void calculateOffset() {
        this.offset = (this.currentPage-1)*this.pageSize;
    }

    private void calculateLastPage() {
        this.lastPage = this.countRecords/this.pageSize + 1;
    }

    private Integer getNoteIndexByNoteId(Id noteId, List<My_Notes__c> notes) {
        Integer result;
        for (My_Notes__c note : notes) {
            if (note.Id == noteId) {
                result = notes.indexOf(note);
            }
        }
        return result;
    }
}
