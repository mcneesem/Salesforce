import { LightningElement, api } from 'lwc';

export default class CaseCatSubCatComponent extends LightningElement {    
    
    @api selectedRecTypeId='';
    isCQAChildCase;
    @api selectedCategory;
    @api selectedSubCategory;
    @api selectedDetail;
    @api selectedVersion;
    @api showConfidential;
    @api showAllCategory;
    @api showAllSubCategory;

    handleConfidentialField(event){
        this.showConfidential = event.detail;
    }
   
    handleSelectedValues(){
        this.selectedCategory = this.template.querySelector('c-case-cat-subcat-detail').selectedCategory;
        this.selectedSubCategory = this.template.querySelector('c-case-cat-subcat-detail').selectedSubCategory;
        this.selectedDetail = this.template.querySelector('c-case-cat-subcat-detail').selectedDetail;
        this.selectedVersion = this.template.querySelector('c-case-cat-subcat-detail').selectedVersion;
        this.showAllCategory = this.template.querySelector('c-case-cat-subcat-detail').showAllCategory;
        this.showAllSubCategory = this.template.querySelector('c-case-cat-subcat-detail').showAllSubCategory;               
    }
    
    
    @api 
    validate(event){
        if(
           (this.selectedCategory===undefined || this.selectedCategory===null || this.selectedCategory==='') ||
           (this.selectedSubCategory===undefined || this.selectedSubCategory===null || this.selectedSubCategory==='')
        ){
            return {
                isValid: false,
                errorMessage: "Category and Subcategory are mandatory."
            }
        }
        else{
            return {
                isValid: true,
               }       
        }
    }
}