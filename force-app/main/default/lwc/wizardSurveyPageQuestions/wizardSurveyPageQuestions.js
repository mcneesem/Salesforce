import { LightningElement, track, api } from 'lwc';

export default class wizardSurveyPageQuestions extends LightningElement {

    @track mergeObjectList = [];
    @track questionTypeFields = ['NSP_Custom_Question1_Type__c'];
    @api reReqId = 'a7Y1F000000Eoal';
    isOnloaded =true;
    NSP_TotalCustomQuestion_Added__c =1;
    isPrevClick=false;
    matrixOnLoaded =true;
    isSaveClick =false;

    get addButton(){
        if(this.NSP_TotalCustomQuestion_Added__c > 9){
            return true;
        }else{
            return false
        }
    }

    get deleteButton(){
        if(this.NSP_TotalCustomQuestion_Added__c < 2 ){
            return true;
        }else{
            return false
        }
    }

    NSP_ClientWantsToincludeCustomQuestion__c;
    fieldOjbect={ Question:'NSP_Custom_Question_1__c',QuestionLabel:'Custom Question 1', QuestionType:'NSP_Custom_Question1_Type__c',Matrix_SubCategory:'NSP_Question1_MatrixSubCategories__c',Matrix_Rating:'NSP_Question1_RatingValues__c' , matrixRequired: false , MatrixCategory:null, MatrixRating:null, IsNewQuestion:false};
    @track questionFields ;
    removeFieldOjbect = [];

    recordTypeId ='012000000000000AAA' ;
    pageNumber = 3;
    IsAddedNewQuestion =false;

    renderedCallback(){
        if(this.IsAddedNewQuestion){
            this.boldNewQuestion();
        }
    }

    get restValue(){       
        return null;
    }

    set restValue(event){
        
    }

    pickValueYesNo = [
        { "attributes": null, "label": "Yes", "value": "Yes"},
        { "attributes": null, "label": "No", "value": "No" }
      ];   

    boldNewQuestion(){
       // let index = this.questionFields.length - 1;
       // if(this.template.querySelector("lightning-input-field.NSP_Custom_Question_"+index+"__c") != null ){
       //     this.template.querySelector("lightning-input-field.NSP_Custom_Question_"+index+"__c").style.fontWeight='normal';
       // }
       //if(this.template.querySelector("lightning-input-field.NSP_Custom_Question_"+this.questionFields.length+"__c") != null){
       //    this.template.querySelector("lightning-input-field.NSP_Custom_Question_"+this.questionFields.length+"__c").style.fontWeight='bold';
       // }
        
    }

    addQuestion(event){
     if(event?.currentTarget?.localName == "lightning-button"){
        this.isOnloaded =false;
     }
       let index = this.questionFields.length + 1;
       let tempObj ={ ...this.fieldOjbect};
       tempObj.Question='NSP_Custom_Question_'+index+'__c';
       tempObj.QuestionType='NSP_Custom_Question'+index+'_Type__c';
       tempObj.QuestionLabel="Custom Question "+index;
       tempObj.matrixRequired= false ;
       if(!this.isOnloaded){
             this.clear(index)
             tempObj.MatrixCategory= ' ';
             tempObj.MatrixRating= ' ';
             tempObj.IsNewQuestion =true;
             this.IsAddedNewQuestion = true; 
        }else{
            tempObj.MatrixCategory= null;
            tempObj.MatrixRating= null;
            tempObj.IsNewQuestionm = null;
        }
       tempObj.Matrix_SubCategory='NSP_Question'+index+'_MatrixSubCategories__c';
       tempObj.Matrix_Rating='NSP_Question'+index+'_RatingValues__c';
        this.questionFields.push(tempObj);
        this.NSP_TotalCustomQuestion_Added__c = index;
        this.questionTypeFields.push('NSP_Custom_Question'+index+'_Type__c');
        if(this.removeFieldOjbect != null && this.removeFieldOjbect.length > 0 ){
           let findIndex = this.removeFieldOjbect.findIndex((obj =>  obj.Question == 'NSP_Custom_Question_'+index+'__c' ));
           if(findIndex != null){
               let tempObj = this.removeFieldOjbect[findIndex];  
               this.removeFieldOjbect.pop(tempObj); 
           }
        }
    }

    removeQuestion(event){
        let index = this.questionFields.length;
        let findIndex = this.questionFields.findIndex((obj =>  obj.Question == 'NSP_Custom_Question_'+index+'__c' ));
        if(findIndex != null){
            let tempObj = this.questionFields[findIndex];
            tempObj.QuestionLabel="Custom Question "+index;
            this.removeFieldOjbect.push(tempObj);
            this.questionFields.pop(tempObj);
            this.questionTypeFields.pop('NSP_Custom_Question'+index+'_Type__c');
            this.NSP_TotalCustomQuestion_Added__c = index-1;
            this.clear(index);
        }
    }


    clear(index){
        if(this.template.querySelector('lightning-input-field[data-fname="NSP_Custom_Question_'+index+'__c"]')!= null){
            this.template.querySelector('lightning-input-field[data-fname="NSP_Custom_Question_'+index+'__c"]').value ='';
        }
        if(this.template.querySelector('lightning-input-field[data-fname="NSP_Custom_Question'+index+'_Type__c"]')!= null){
            this.template.querySelector('lightning-input-field[data-fname="NSP_Custom_Question'+index+'_Type__c"]').value ='';
        }
        if(this.template.querySelector('lightning-input-field[data-fname="NSP_Question'+index+'_MatrixSubCategories__c"]')!= null){
            this.template.querySelector('lightning-input-field[data-fname="NSP_Question'+index+'_MatrixSubCategories__c"]').value ='';
        }
        if(this.template.querySelector('lightning-input-field[data-fname="NSP_Question'+index+'_RatingValues__c"]')!= null){
            this.template.querySelector('lightning-input-field[data-fname="NSP_Question'+index+'_RatingValues__c"]').value ='';
        }
        if(this.template.querySelector('lightning-input-field.NSP_Custom_Question'+index+'_Type__c') !=null){
            [...this.template.querySelectorAll('lightning-input-field.NSP_Custom_Question'+index+'_Type__c')].map(x =>{
           x.style.display='none';
           x.value='';
            });
        }
    }

    handleChange(event) {
        if(event.currentTarget !=null && event.currentTarget.fieldName !=null && event.currentTarget.value !=null){
        let key = event.currentTarget.fieldName;
        let value = event.currentTarget.value;
        if(this.template.querySelector('lightning-input-field.'+key) !=null){
             [...this.template.querySelectorAll('lightning-input-field.'+ key)].map(x =>{
            if(value != 'Matrix'){ x.value=''; }
        });

        if( this.template.querySelector('div.'+key) !=null){
            value == 'Matrix' ? this.template.querySelector('div.'+key).style.display='' : 
            this.template.querySelector('div.'+key).style.display ='none';
        }

        }
            this.questionFields = JSON.parse(JSON.stringify(this.questionFields));
            let findIndex = this.questionFields.findIndex((obj =>  obj.QuestionType == key ));
            this.questionFields = [... this.questionFields]
            value == 'Matrix'? this.questionFields [findIndex ].matrixRequired =true : this.questionFields [findIndex ].matrixRequired =false;
      }
    }

    handleRadioChange(event){

        if(event.currentTarget !=null && event.currentTarget.name !=null && event.currentTarget.value !=null){
            this[event.currentTarget.name] = event.currentTarget.value;           
            if(event.currentTarget.value=='Yes'){
                
                this.fieldOjbect ={ Question:'NSP_Custom_Question_1__c',QuestionLabel:'Custom Question 1',QuestionType:'NSP_Custom_Question1_Type__c',Matrix_SubCategory:'NSP_Question1_MatrixSubCategories__c',Matrix_Rating:'NSP_Question1_RatingValues__c' , matrixRequired: false , MatrixCategory:' ', MatrixRating:' ', IsNewQuestion:true};
                this.questionFields=[{...this.fieldOjbect}];
                this.clear(1);
                this.questionTypeFields = ['NSP_Custom_Question1_Type__c'];
                this.NSP_TotalCustomQuestion_Added__c = 1;
            }else{
                this.questionTypeFields = ['NSP_Custom_Question1_Type__c'];
                if(this.questionFields != null ){
                    for(let index ; index < this.questionFields.length ; index ++){
                        this.clear(index);
                    }
                }
                this.questionFields = null;
                this.NSP_TotalCustomQuestion_Added__c = 1;
            }
        }
    }


    handlePrev(event){
        this.isPrevClick=true;
        this.dispatchEvent(new CustomEvent('prev', {detail: this.reReqId}));
      }

      
      handleOnSubmit(event) {
        
        if((this.removeFieldOjbect != null && this.removeFieldOjbect.length >0) || this.NSP_ClientWantsToincludeCustomQuestion__c =='No'){
            event.preventDefault(); 
            let fields = event.detail.fields;
            if(this.NSP_ClientWantsToincludeCustomQuestion__c =='No'){
                for(let index = 1 ; index <= 10; index ++){
                    fields['NSP_Custom_Question_'+index+'__c']=null;
                    fields['NSP_Custom_Question'+index+'_Type__c']=null;
                    fields['NSP_Question'+index+'_MatrixSubCategories__c']=null;
                    fields['NSP_Question'+index+'_RatingValues__c']=null;
                }
            }else{
                this.removeFieldOjbect.forEach(eachObj=>{
                    Object.values(eachObj).forEach(eachValue=>{ 
                        if(eachValue != null &&  typeof eachValue == 'string' && eachValue.endsWith('__c')){ 
                            fields[eachValue] ='';
                          }
                    })   
                }
            )
            }
            this.template.querySelector('lightning-record-edit-form').submit(fields); // it will submit the form
        }

    }

    handleOnload(event){
        if((!this.IsAddedNewQuestion)){
        if(event.detail != null &&  event.detail.records != null){
               this.fieldsData =Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].fields;
               this.recordTypeId =  Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].recordTypeId;
               if(this.fieldsData != null &&  this.fieldsData != undefined && this.fieldsData !='' ){
                if(this.isOnloaded){
                    if(this.fieldsData.NSP_ClientWantsToincludeCustomQuestion__c != null  && this.fieldsData.NSP_ClientWantsToincludeCustomQuestion__c.value != null){
                        this.NSP_ClientWantsToincludeCustomQuestion__c = this.fieldsData.NSP_ClientWantsToincludeCustomQuestion__c.value;
                        if(this.NSP_ClientWantsToincludeCustomQuestion__c =='Yes' ){
                            this.questionFields=[{...this.fieldOjbect}];
                        }else{
                            this.questionFields = null;
                        }
                    }
                    if(this.fieldsData.NSP_TotalCustomQuestion_Added__c != null  && this.fieldsData.NSP_TotalCustomQuestion_Added__c.value != null){
                        let totalPage = this.fieldsData.NSP_TotalCustomQuestion_Added__c.value;
                        this.isOnloaded = true;
                        if(totalPage > 1){
                            for(let index=1; index < totalPage; index++ ){
                                this.addQuestion('');
                            }
                        }
                        this.isOnloaded =false;
                    }
                }
                if(this.questionTypeFields.length >0 && this.matrixOnLoaded){
                    let matrixElement=[] ;
                    let temp = JSON.parse(JSON.stringify(this.questionTypeFields))
                    temp.forEach(element => {
                        
                        if(this.fieldsData[element] != null && this.fieldsData[element].value == 'Matrix' ){
                           
                            if(this.template.querySelector('div.'+element) !=null){
                                this.template.querySelector('div.'+element).style.display='';
                                this.matrixOnLoaded = false;
                            }else{
                                matrixElement.push(element);
                            }
                        this.questionFields = JSON.parse(JSON.stringify(this.questionFields));
                        let findIndex = this.questionFields.findIndex((obj =>  obj.QuestionType == element ));
                        this.questionFields = [... this.questionFields]
                        this.questionFields [findIndex ].matrixRequired =true ;
                     }else{
                        matrixElement.push(element);
                     }
                    });
                    if(matrixElement.length >0){
                        this.matrixOnLoaded = true  ;
                    }
                    /**
                     this.questionFields = this.questionFields.map((obj)=> {
                        let temp = JSON.parse(JSON.stringify(obj));
                        if(this.fieldsData[obj.QuestionType] != null && this.fieldsData[obj.QuestionType].value == 'Matrix' ){
                          temp.MatrixCategory = this.fieldsData[obj.Matrix_SubCategory]
                          temp.MatrixRating = this.fieldsData[obj.Matrix_Rating];
                        }
                        return { ...temp}
                      });
                       */
                }
            }
        }
        }
        this.IsAddedNewQuestion =false;
    }

    handleSuccess(event) {
        if(!this.isSaveClick && !this.isPrevClick){
            this.reReqId = event.detail.id;
            //recordField.Id=event.detail.id;
            
            this.dispatchEvent(new CustomEvent('next', {detail: this.reReqId }));
          }else if(this.isSaveClick){
            const saveEvent = new CustomEvent('saveexit', { bubbles: true });
            this.dispatchEvent(saveEvent);
          }

    }

    connectedCallback(){
        if(this.recordObj!= null && this.recordObj.RecordTypeId != null){
            this.recordTypeId =this.recordObj.RecordTypeId ;
        }
    }

    handleSave(event) {
        this.isSaveClick=true;
        this.template.querySelector('lightning-record-edit-form').submit();
    }
}