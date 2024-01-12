import { LightningElement,api } from 'lwc';

export default class Nsp_pagination extends LightningElement {
    currentPage =1
    totalRecords;
    @api recordSize;
    totalPage = 0
    visibleRecords;

    startRecord;
    endRecord;
    end;
    totalRecordCounts;

    get records(){
        return this.visibleRecords
    }

    @api 
    set records(data){
        this.recordSize = this.recordSize > 100 ?this.recordSize :100;
        if(data){ 
            this.totalRecords = data;
            this.recordSize = Number(this.recordSize);
            this.totalRecordCounts = data.length;
            this.totalPage = Math.ceil(data.length/this.recordSize);
            this.preparePaginationList()

        }
    }

handleClick(event) {
    let label = event.target.label;
    if (label === "First") {
        this.handleFirst();
    } else if (label === "Previous") {
        this.handlePrevious();
    } else if (label === "Next") {
        this.handleNext();
    } else if (label === "Last") {
        this.handleLast();
    }
}

get disablePrevious(){ 
    return this.currentPage<=1
}
get disableNext(){ 
    return this.currentPage>=this.totalPage
}


handleNext() {
    this.currentPage += 1;
    this.preparePaginationList();
}

handlePrevious() {
    this.currentPage -= 1;
    this.preparePaginationList();
}

handleFirst() {
    this.currentPage = 1;
    this.preparePaginationList();
}

handleLast() {
    this.currentPage = this.totalPage;
    this.preparePaginationList();
}

preparePaginationList() {
    //this.isLoading = true;
    let begin = (this.currentPage - 1) * parseInt(this.recordSize);
    let end = parseInt(begin) + parseInt(this.recordSize);

    if(this.totalRecords!=null){
    this.visibleRecords = this.totalRecords.slice(begin, end);

    this.startRecord = this.totalRecordCounts >0 ? (begin + parseInt(1)): 0;
    this.endRecord = end > this.totalRecordCounts ? this.totalRecordCounts : end;
    this.end = end > this.totalRecordCounts ? true : false;


    this.dispatchEvent(new CustomEvent('pagination',{ 
        detail:{ 
            records:this.visibleRecords
        }
    }))
}

}

}