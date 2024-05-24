public with sharing class SchemaController {
    // test w/ SchemaControllerTest (91%)
    private static final String CLASS_NAME = ' ~ SchemaController';

    // schema-safe Text value...
    // ~ returns a String within the maximum length described Text field...
    // ~ prevents... System.DmlException: STRING_TOO_LONG, {describedField}: data value too large: {value} (max length={maximum}): [{describedField}]
    // ~ can operate on any field with a DataType that can be cast into a String...
    //   ~ https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_enum_Schema_DisplayType.htm
    //   ~ Schema.DisplayType.STRING
    //   ~ Schema.DisplayType.EMAIL
    //   ~ Schema.DisplayType.PHONE
    //   ~ Schema.DisplayType.PICKLIST
    //   ~ Schema.DisplayType.TEXTAREA
    public static String safeText( String value , Schema.DescribeFieldResult describedField ) {
        if ( String.isNotBlank( value ) && ( describedField != null ) ) {
            // compute the maximum length for the described field...
            Integer maxLength = describedField.getLength();
            if ( ( maxLength != null ) && ( maxLength >= 0 ) ) {
                if ( describedField.isHtmlFormatted() && ( value.escapeHtml4().length() > maxLength ) ) {
                    // special consideration for the html entities in "Rich Text Area" fields...
                    value = value.escapeHtml4().substring( 0 , maxLength ).unescapeHtml4();
                } else if ( value.length() > maxLength ) {
                    // truncate normal text fields to the maximum length...
                    value = value.substring( 0 , maxLength );
                }
            }
        }
        return value;
    }

    // schema-safe Integer value...
    // ~ returns a Integer less than or equal to the maximum allowed by the described Text field...
    public static Integer safeInteger( Decimal value , Schema.DescribeFieldResult describedField ) {
        return Integer.valueOf(
            SchemaController.safeNumber(
                value ,
                describedField
            )
        );
    }

    // schema-safe Number value...
    // ~ returns a truncated and ceilinged value within the scale and precision of the described Number field...
    // ~ returns value as Object because Number fields can be either Decimal (i.e. Precision>0) OR Ingeger (i.e. Precision=0)...
    // ~ prevents... System.DmlException: NUMBER_OUTSIDE_VALID_RANGE, {describedField}: value outside of valid range on numeric field: {value}: [{describedField}]
    private static Object safeNumber( Decimal value , Schema.DescribeFieldResult describedField ) {
        if ( value == null ) {
            value = 0;
        }
        if ( ( value != null ) && ( describedField != null ) ) {
            // scale first...  then precision...
            Integer scale = describedField.Scale;
            if ( value.scale() != scale ) {
                // truncate extra decimal places...
                value = value.setScale( scale );
            }
            Integer precision = describedField.Precision;
            if ( value.precision() > precision ) {
                // use max field value when precision is too high...
                // ~ max=((10^precision)-1)/(10^scale)
                value = ( ( Decimal.valueOf( 10 ).pow( precision ) - 1 ) / ( Decimal.valueOf( 10 ).pow( scale ) ) );
            }
        }
        return value;
    }

}
//