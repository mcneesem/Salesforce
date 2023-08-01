public with sharing class NSP_LookupOption {
    @AuraEnabled public String label;
    @AuraEnabled public String info;
    @AuraEnabled public String value;
    @AuraEnabled public String iconName;
    @AuraEnabled public Boolean disabled;

    public NSP_LookupOption(String label, String value, String info, String iconName, Boolean disabled){
        this.label = label;
        this.value = value;
        this.info = info;
        this.iconName = iconName;
        this.disabled = disabled;
    }

    public Boolean equals(Object obj) {
        if (obj === this){
            return true;
        }

        if (obj == null){ return false; }
        if (!(obj instanceof NSP_LookupOption)){ return false; }

        NSP_LookupOption other = (NSP_LookupOption) obj;

        return other.label == this.label && other.value == this.value && other.info == this.info 
                && other.iconName == this.iconName && other.disabled == this.disabled;
    }

    public Integer hashCode() {
        return (Integer) label.hashCode() * value.hashCode() * info.hashCode() * iconName.hashCode();
    }
}