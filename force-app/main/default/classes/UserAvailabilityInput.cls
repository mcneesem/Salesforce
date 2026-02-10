public class UserAvailabilityInput {
	@InvocableVariable(required=true)
    public Datetime startDT;
    
    @InvocableVariable(required=true)
    public Datetime endDT;
    
    @InvocableVariable
    public String skill;
    
    @InvocableVariable
    public Integer stepMinutes;
}