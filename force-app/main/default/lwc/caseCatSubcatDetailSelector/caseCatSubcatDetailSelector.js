import { LightningElement , api } from 'lwc';

export default class CaseCatSubcatDetailSelector extends LightningElement {
    @api selectedRecTypeId='';
    isCQAChildCase;
    @api selectedCategory;
    @api selectedSubCategory;
    @api selectedDetail;
    @api selectedVersion;
    @api showConfidential;
    @api showAllCategory;
    @api showAllSubCategory;

    handleConfidentialField(event) {
        if (event && event.detail !== undefined) {
            this.showConfidential = event.detail;
        }
    }

    handleSelectedValues() {
        const categoryComponent = this.template.querySelector('c-case-cat-subcat-detail');
        if (categoryComponent) {
            this.selectedCategory = categoryComponent.selectedCategory;
            this.selectedSubCategory = categoryComponent.selectedSubCategory;
            this.selectedDetail = categoryComponent.selectedDetail;
            this.selectedVersion = categoryComponent.selectedVersion;
            this.showAllCategory = categoryComponent.showAllCategory;
            this.showAllSubCategory = categoryComponent.showAllSubCategory;
        }
    }

    @api
    validate() {
        let response = {
            isValid: true
        };
        if (!this.selectedCategory || !this.selectedSubCategory) {
            response.isValid = false;
            response.errorMessage = "Category and Subcategory are mandatory.";
            this.showAllSubCategory = true;
        }
        return response;
    }

}