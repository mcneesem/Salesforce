public with sharing class NSP_QueryBuilder {
    // test w/ NSP_QueryBuilderTest (??%)

    private static final String WHERE_IDENTIFIER = ' WHERE ';
    private static final String LIMIT_IDENTIFIER = ' LIMIT ';
    private static final String AND_IDENTIFIER = ' AND ';
    private static final List<String> DEFAULT_FIELDS = new List<String>{ 'Name' };
    private static final String FIELD_NAME_SEPARATOR = ', ';

    private String baseQuery;
    private List<String> filters;
    private Integer recSize;
    private String orderBy;
    private Boolean isSecurityEnforced = true;

    public NSP_QueryBuilder(String objectApiName) {
        setupBaseQuery(objectApiName, DEFAULT_FIELDS);
    }

    public NSP_QueryBuilder(String objectApiName, List<String> fields) {
        setupBaseQuery(objectApiName, fields);
    }

    // Methods to add in Future
    // public NSP_QueryBuilder setEnforceFLS(Boolean enforceFLS)
    // public NSP_QueryBuilder setOffset(Integer offsetCount)

    public NSP_QueryBuilder orderBy( String fieldName , String direction , Boolean nullsLast ) {
        return this.orderBy( fieldName , direction , ( nullsLast ? 'LAST' : '' ) );
    }

    public NSP_QueryBuilder orderBy( String fieldName , String directionOption , String nullsOption ) {
        if ( String.isNotBlank( fieldName ) ) {
            String directionSuffix = '';
            if ( ( directionOption == 'ASC' ) || ( directionOption == 'DESC' ) ) {
                directionSuffix = ' ' + directionOption;
            }
            String nullsSuffix = '';
            if ( ( nullsOption == 'FIRST' ) || ( nullsOption == 'LAST' ) ) {
                nullsSuffix = ' NULLS ' + nullsOption;
            }
            this.orderBy = ' ORDER BY ' + fieldName + directionSuffix + nullsSuffix;
        }
        return this;
    }

    public NSP_QueryBuilder addFilter(String fieldName, String fieldValue){
        addFilter(fieldName, fieldValue, null, true);

        return this;
    }

    public NSP_QueryBuilder addFilter(String fieldName, Id fieldValue){
        addFilter(fieldName, fieldValue, null, true);

        return this;
    }

    public NSP_QueryBuilder addFilter(String fieldName, Object fieldValue){
        addFilter(fieldName, fieldValue, null, false);

        return this;
    }

    public NSP_QueryBuilder addFilter(String fieldName, String fieldValue, Operator op){
        addFilter(fieldName, fieldValue, op, true);

        return this;
    }

    public NSP_QueryBuilder addFilter(String fieldName, Object fieldValue, Operator op){
        addFilter(fieldName, fieldValue, op, false);

        return this;
    }

    public NSP_QueryBuilder addFilter(String fieldName, List<String> fieldValues, Operator op){
        addFilter(fieldName, stringify(fieldValues), op, false);

        return this;
    }

    public NSP_QueryBuilder addContainsFilter(String fieldName, Object fieldValue){
        addFilter(fieldName, '%' + fieldValue + '%', Operator.LIKES, true);

        return this;
    }

    public NSP_QueryBuilder addStartsWithFilter(String fieldName, Object fieldValue){
        addFilter(fieldName, fieldValue + '%', Operator.LIKES, true);

        return this;
    }

    public NSP_QueryBuilder addEndsWithFilter(String fieldName, Object fieldValue){
        addFilter(fieldName, '%' + fieldValue, Operator.LIKES, true);

        return this;
    }

    public NSP_QueryBuilder addFilter(String fieldName, Object fieldValue, Operator op, Boolean doStringify){
        if(String.isNotBlank(fieldName)){
            String fieldValueStr = String.valueOf(fieldValue);
            String updatedFieldValue = doStringify == true ? stringify(fieldValueStr) : fieldValueStr;
            this.filters.add(getFilterString(fieldName, updatedFieldValue, op));
        }

        return this;
    }

    public NSP_QueryBuilder addLimit(Integer recSize){
        this.recSize = recSize;

        return this;
    }

    public NSP_QueryBuilder setSecurityEnforce(Boolean enforce){
        this.isSecurityEnforced = enforce;

        return this;
    }

    public String build(){
        String query = this.baseQuery;

        if(!this.filters.isEmpty()){
            query += WHERE_IDENTIFIER + String.join(filters, AND_IDENTIFIER);
        }

        if(this.isSecurityEnforced){
            query += ' WITH SECURITY_ENFORCED ';
        }

        if(this.orderBy != null){
            query += this.orderBy;
        }

        if(this.recSize != null){
            query += LIMIT_IDENTIFIER + String.valueOf(this.recSize);
        }

        return query;
    }

    private static String getFilterString(String fieldName, String fieldValue, Operator op){
        if(op == null || op == Operator.EQUALS){
            return fieldName + ' = ' + fieldValue;
        }

        if(op == Operator.GREATER_THAN_OR_EQUALS){
            return fieldName + ' >= ' + fieldValue;
        }

        if(op == Operator.LESS_THAN_OR_EQUALS){
            return fieldName + ' <= ' + fieldValue;
        }

        if(op == Operator.NOT_EQUALS){
            return fieldName + ' != ' + fieldValue;
        }

        if(op == Operator.LIKES){
            return fieldName + ' LIKE ' + fieldValue;
        }

        if(op == Operator.INCLUDES){
            return fieldName + ' IN (' + fieldValue + ')';
        }

        if(op == Operator.NOT_IN){
            return fieldName + ' NOT IN (' + fieldValue + ')';
        }

        return fieldName + ' = ' + fieldValue;
    }

    private void setupBaseQuery(String objectApiName, List<String> fields){
        if(String.isBlank(objectApiName)){
            throw new AuraHandledException('Object API Name cannot be blank.');
        }

        List<String> fieldList = fields == null || fields.isEmpty() ? DEFAULT_FIELDS : fields;
        this.baseQuery = 'SELECT ' + String.join(fieldList, FIELD_NAME_SEPARATOR) + ' FROM ' + objectApiName;
        filters = new List<String>();
    }

    private static String stringify(String value){
        return '\'' + value + '\'';
    }

    private static String stringify(List<String> values){
        return stringify(String.join(values , '\', \''));
    }

   public enum Operator { EQUALS, NOT_EQUALS, LIKES, INCLUDES, NOT_IN , GREATER_THAN_OR_EQUALS, LESS_THAN_OR_EQUALS}
   public class RequiredInfoMissingException extends Exception{}

}
//