import { LightningElement, api, track } from 'lwc';
import getSearchRecords from '@salesforce/apex/DynamicSearchRecords.DynamicSearchRecords';
import getMetadataAndData from '@salesforce/apex/DynamicSearchRecords.getMetadataAndData';
import ReturnSearchRecords from '@salesforce/apex/DynamicSearchRecords.ReturnSearchRecords';

export default class DynamicSearchAndSelect extends LightningElement {
    @api minSearchTxtLen = 0;
    @api flowErrorMsg = 'Please Select a value'
    @api objectName;
    @api placeholder = '';
    @api autocomplete = 'off';
    @api searchFieldNames = '';
    searchFieldNameList;
    @api queryFieldNames = '';
    queryFieldNameList;
    @api selectionCriteria = '';
    @api whereClause = '';
    @api Label;
    @api iconName;
    @api recordsExcluded = '';
    @api dropdownOptionFields = '';
    dropdownFieldNames = [];
    @api selectedRecordRepresentation = '';
    @api limit = 10;
    @api orderBy = 'Id';
    @api textLengthRestrictionMsg = ''; //'Enter 2 or more characters to search';
    @api noResultMsg = 'No result found.';
    @api error = '';
    @api noSelectionError = '';
    @track hasRecId = false;
    @track searchRecords = [];
    fetchedRecords = [];
    @track selectedRecords = [];
    dispatchRecords = [];
    @track recordId = '';
    isDropdownHovered = false;
    @api disabled = false;
    @api hasEncryptedFieldSearch;
    @api returnUniqueValueFor;
    @api groupBy; //deprecated
    @api havingCond; //deprecated
    enteredText = '';
    records=[]
    //
    recordsList = []
    @track searchText = '';
    @track searchResults = [];
    @track showDropdown = false;
    @track isModalOpen = false;
    showMoreDataOption = false;
    showMoreDataFlag=true;
    isLoading = false;
    placeHolderText = ''
    showSortBy=false;
    noOfRecords='';
    displayText = ''; 
    sortByOptions=[]
    selectedOption='';
    copyBeforeSorting=[]
    selectedRow
    columnData=[]
    headerLabel=''
    searchBoxPlaceHolder=''
    replaceFieldsJson
    validatedFields
    selectedRecordId
    staticRecords=[]
    dynamicRecordsCopy
    // Dynamic dropdown options
   
    @api
    get finalSelId() {
        return this.recordId;
    }
    set finalSelId(value) {
        try {
            if (value != null && value != '') {
                if (value.length > 0) {
                    if (this.recordId === '' || this.recordId !== value) {
                        value = value.replaceAll(' ', '').replaceAll(',', ' ').trim().replaceAll(' ', ',');
                        let valueList = value.split(',');
                        let tempWhereClause = this.whereClause != null && this.whereClause != '' ? '(' + this.whereClause + ') AND' : '';
                        let autoPopulationWhereClause = tempWhereClause + " ID IN ('" + value.replaceAll(",", "','") + "')";
                        getSearchRecords({ ObjectName: this.objectName, SearchFieldNameList: this.searchFieldNameList, FieldsToFetch: this.queryFieldNames, str: '', selectedRecId: [], additionalCond: autoPopulationWhereClause, numOfRecs: valueList.length })
                            .then(result => {
                                this.reset();
                                this.fetchedRecords = result;
                                result.forEach(row => {
                                    let e = { currentTarget: { dataset: { id: row.Id } } };
                                    this.setSelectedRecord(e);
                                });
                            })
                            .catch(error => {
                                console.log('-------error-------------' + error);
                                console.log(error);
                            });
                    }
                } else {
                    this.reset();
                }
            }
        }
        catch (Exc) { console.log('Exc--' + Exc); }
    }
    @api
    get finalSelIdList() {
        return this.recordId.split(',');
    }

    @api required = false;
    labelVariant = 'label-hidden';//"standard";
    // iconClass = 'slds-icon_container slds-icon-standard-account slds-combobox__input-entity-icon slds-m-top_small';
    // btnClass = 'sicon_container slds-button slds-button_icon slds-input__icon slds-input__icon_right slds-input_height slds-p-top_x-small slds-button_icon-border';
    iconClass = 'slds-icon_container slds-icon-standard-account slds-combobox__input-entity-icon';
    btnClass = 'sicon_container slds-button slds-button_icon slds-input__icon slds-input__icon_right';

    @api LoadingText = false;
    @track txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    @track messageFlag = false;

    connectedCallback() { 
        this.setParentFields();
        if (this.objectName) {
            // this.fetchMetadataAndData(this.objectName);
        } else {
            console.error('Object name is not defined.');
        }
    }
    // 
    @api setParentFields() {
        try {
        this.searchFieldNameList = this.searchFieldNames.replaceAll(' ', '').split(',');
        let queryFNset = new Set(this.queryFieldNames.replaceAll(' ', '').split(','));
        if (queryFNset.has('ID') || queryFNset.has('Id') || queryFNset.has('iD') || queryFNset.has('id')) {
            queryFNset.delete('ID'); queryFNset.delete('Id'); queryFNset.delete('iD'); queryFNset.delete('id');
        }
        this.queryFieldNameList = [...queryFNset];
        this.queryFieldNameList.unshift('Id');
        this.queryFieldNames = this.queryFieldNameList.join();
        let dropdownFieldIndexArray = this.dropdownOptionFields.replaceAll(' ', '').split(',');
        this.dropdownFieldNames = [];
        dropdownFieldIndexArray.forEach(item => {
            this.dropdownFieldNames.push(this.queryFieldNameList[item]);
        });

        this.selectedRecordRepresentation = this.selectedRecordRepresentation.trim();
        this.selectionCriteria = this.selectionCriteria.trim().toLowerCase();
        if (this.whereClause)
            this.whereClause = this.whereClause.trim();
        if (this.selectionCriteria != 's' && this.selectionCriteria != 'm') {
            this.selectionCriteria = 's';
        }
        // Important Note: If value of required is coming as string, this will set it to appropriate boolean value for required
        if (this.required == true || this.required == 'true') {
            this.required = true;
        } else {
            this.required = false;
        }
              
    } catch (error) {
        console.log('error--' + error);
    }
    }

    _flatten = (nodeValue, flattenedRow, nodeName) => {
        let rowKeys = Object.keys(nodeValue);
        rowKeys.forEach((key) => {
            let finalKey = nodeName + '.' + key;
            flattenedRow[finalKey] = nodeValue[key];
        })
    }
    searchField(event) {
        try {
        var currentText = event.target.value;
        this.enteredText = event.target.value;
        this.noSelectionError = '';
        this.showMoreDataOption = this.enteredText.length > 1 && this.showMoreDataFlag;
        const selectedEvent = new CustomEvent('change', { detail: this.enteredText });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
        if (this.disabled) {
            // this.isDropdownHovered = false;
            this.LoadingText = false;
            this.txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        }
        else {
            this.isDropdownHovered = false;
            var selectRecId = [];
            if (this.recordsExcluded.length > 0) {
                selectRecId = this.recordsExcluded.replaceAll(' ', '').split(',');
            }
            for (let i = 0; i < this.selectedRecords.length; i++) {
                selectRecId.push(this.selectedRecords[i].recId);
            }
            this.selectedRecordId = selectRecId;
            if (currentText.length >= this.minSearchTxtLen && ((this.hasEncryptedFieldSearch && currentText.length > 1) || !this.hasEncryptedFieldSearch)) {
                this.LoadingText = true;
                this.messageFlag = false;
                this.fetchMetadataAndData(this.objectName);
                console.log('object---->'+ this.objectName+ 'where condition--->:', this.whereClause);
                getSearchRecords({ ObjectName: this.objectName, SearchFieldNameList: this.searchFieldNameList, FieldsToFetch: this.queryFieldNames, str: currentText, selectedRecId: selectRecId, additionalCond: this.whereClause, orderBy: this.orderBy, numOfRecs: this.limit, hasEncryptedFieldSearch: this.hasEncryptedFieldSearch, returnUniqueValueFor: this.returnUniqueValueFor })
                    .then(result => {
                        console.log('this.fetchedRecords:', JSON.stringify(result));
                        let noOfDropdownFields = this.dropdownFieldNames.length;
                        this.fetchedRecords = []; //result;
                        for (let row of result) {
                            // this const stroes a single flattened row. 
                            const flattenedRow = {}
                            // get keys of a single row — Name, Phone, LeadSource and etc
                            let rowKeys = Object.keys(row);
                            //iterate 
                            rowKeys.forEach((rowKey) => {
                                //get the value of each key of a single row. John, 999-999-999, Web and etc
                                const singleNodeValue = row[rowKey];
                                //check if the value is a node(object) or a string
                                if (singleNodeValue.constructor === Object) {
                                    //if it's an object flatten it
                                    this._flatten(singleNodeValue, flattenedRow, rowKey);
                                } else {
                                    //if it’s a normal string push it to the flattenedRow array
                                    flattenedRow[rowKey] = singleNodeValue;
                                }
                            });
                            this.fetchedRecords.push(flattenedRow);
                        }
                        let result1 = [];
                        for (let row of this.fetchedRecords) {
                            let newRow = {};
                            newRow.Id = row.Id;
                            newRow.optHeading = row[this.dropdownFieldNames[0]] ? row[this.dropdownFieldNames[0]] : '';
                            newRow.optMetaText = '';
                            for (let i = 1; i < noOfDropdownFields; i++) {
                                if (row[this.dropdownFieldNames[i]]) {
                                    if (newRow.optMetaText == '') {
                                        newRow.optMetaText = row[this.dropdownFieldNames[i]];
                                    } else {
                                        newRow.optMetaText += ' | ' + row[this.dropdownFieldNames[i]];
                                    }
                                }
                            }
                            result1.push(newRow);
                        }
                        this.searchRecords = result1;
                        this.LoadingText = false;

                        this.txtclassname = result1.length > 0 ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
                        if (result1.length == 0) {
                            this.messageFlag = true;
                        }
                        else {
                            this.messageFlag = false;
                        }
                    })
                    .catch(error => {
                        console.log('-------error-------------' + error);
                        console.log(error);
                    });
            } else {
                this.searchRecords = null;
                this.txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
            }
        }
              
    } catch (error) {
        console.log('error--' + error);
    }
    }
    @api
    resetSearchErrorAndText() {
        this.noSelectionError = '';
        this.enteredText = '';
    }
    setSelectedRecord(event) {
        let recId = event.currentTarget.dataset.id;
        let tempObject;
        let selRec_Representation = this.selectedRecordRepresentation;
        this.fetchedRecords.forEach(rec => {
            if (rec.Id == recId) {
                tempObject = rec;
            }
        });
        this.dispatchRecords.push(tempObject);
        for (var i = this.queryFieldNameList.length - 1; i >= 0; i--) {
            let key = 'field' + i;
            selRec_Representation = selRec_Representation.replace(i, key);
        }
        for (var i = this.queryFieldNameList.length - 1; i >= 0; i--) {
            let key = 'field' + i;
            let value = tempObject[this.queryFieldNameList[i]] ? tempObject[this.queryFieldNameList[i]] : '';
            selRec_Representation = selRec_Representation.replace(key, value);
        }

        let selRecLabel = selRec_Representation;
        let newsObject = { 'recId': recId, 'recLabel': selRecLabel };
        if (this.selectionCriteria == 's') {
            this.selectedRecords = [];
        }
        this.selectedRecords.push(newsObject);

        if (this.selectionCriteria == 's') {
            this.recordId = recId;
            this.hasRecId = true;
            this.txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
            this.enteredText = '';
        } else {
            if (this.recordId == '') {
                this.recordId = recId;
            } else {
                this.recordId += ',' + recId;
            }
            this.template.querySelector('.searchBox').focus();
        }
        this.template.querySelectorAll('lightning-input').forEach(each => {
            each.value = '';
        });
        const selectedEvent = new CustomEvent('selected', { detail: this.dispatchRecords });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }
    enterkeyevent(event) {
        if (event.keyCode === 13) {
            event.preventDefault();
        }
    }
    removeRecord(event) {
        console.log('event.target.type'); console.log(event.target.type);
        console.log('dynamic remove record ' + this.Label);
        try {
            let selectRecId = [];
            let tempRecordId = '';
            let tempDispatchRecords = [];
            for (let i = 0; i < this.selectedRecords.length; i++) {
                if (event.currentTarget.name !== this.selectedRecords[i].recId) {
                    selectRecId.push(this.selectedRecords[i]);
                    tempDispatchRecords.push(this.dispatchRecords[i]);
                    if (tempRecordId == '') {
                        tempRecordId = this.selectedRecords[i].recId;
                    } else {
                        tempRecordId += ',' + this.selectedRecords[i].recId;
                    }
                }
            }
            this.selectedRecords = [...selectRecId];
            this.dispatchRecords = tempDispatchRecords;
            if (this.selectionCriteria == 'm') {
                this.recordId = tempRecordId;
                this.template.querySelector('.searchBox').focus();
            }
            if (!this.selectedRecords.length) {
                this.recordId = '';
                this.hasRecId = false;
            }
            const selectedEvent = new CustomEvent('selected', { detail: this.dispatchRecords });
            // Dispatches the event.
            this.dispatchEvent(selectedEvent);
        }
        catch (Exception) {
            console.log('remove rec exception--' + Exception);
        }
    }
    // this method runs when search input box loses focus
    handleBlur(event) {
        if (!this.isDropdownHovered) {
            this.txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
            this.messageFlag = false; this.LoadingText = false;
            if (this.template.querySelector('.searchBox').value != '' && !this.selectedRecords.length)
                this.noSelectionError = 'Select an option from the lookup or remove the search term';
        }
    }
    handleDropdownHoverOut() {
        this.isDropdownHovered = false;
    }
    handleDropdownHoverIn() {
        this.isDropdownHovered = true;
    }
    @api reset() {
        this.searchRecords = [];
        this.txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        this.dispatchRecords = [];
        this.selectedRecords = [];
        this.recordId = '';
        this.hasRecId = false;
        this.noSelectionError = '';
        this.enteredText = '';
    }
    @api
    validate() {
        if (this.required) {
            if (this.recordId) {
                return { isValid: true };
            }
            else {
                // If the component is invalid, return the isValid parameter 
                // as false and return an error message. 
                return {
                    isValid: false,
                    errorMessage: this.flowErrorMsg
                };
            }
        }
    }



// Deeper search Implementation - Start
    fetchMetadataAndData(objectName) {
         this.isLoading = true;
        try {
        console.log('inside fetch method--->' + objectName)
        console.log('where clause before calling the method--->'+ objectName +'----'+ this.whereClause);
        getMetadataAndData({ objectName: objectName, whereClause: this.whereClause, queryFields:this.queryFieldNames})
            .then((result) => {
                console.log('getMetadataAndData--->', result.status)    
                if (result.status && result.columnData && result.data) {
                    this.recordsList = result.data;
                    this.replaceFieldsJson=result.fieldMappingJson
                    this.validatedFields=result.validatedFields
                    this.recordsList = this.recordsList.map(row => {
                        return {
                            ...row,
                            recordLink: '/'+ row.Id,
                            Global_Record_Number__c: row.Global_Record_Number__c
                        };
                    });
                    this.headerLabel = 'Select ' + (this.Label ? this.Label : '');
                    this.searchBoxPlaceHolder = 'Search ' + (this.Label ? this.Label : ''); 
                    this.searchResults=[... this.recordsList];
                    this.staticRecords=[... this.recordsList];
                    this.copyBeforeSorting=[...result.data];
                    this.columnData=JSON.parse(result.columnData)
                    this.options=JSON.parse(result.sortByFields)
                     this.isLoading = false;
                } 
                else {
                    console.log('No data or columns found in the response');
                    this.showMoreDataFlag = false;
                }
            })
            .catch((error) => {
                 this.isLoading = false;
                console.error('Error fetching metadata and data:', error);
            })
                 
        } catch (error) {
             this.isLoading = false;
            console.error('Error fetching data:', error);
        }
    }

    showMoreData() {
        this.searchText=this.enteredText;
        this.searchResults= []
        this.getDynamicData();
    }

    closeModal(event) {
        event.stopPropagation();
        this.reset();
        this.isModalOpen = false;
    }

    handleSearch(event) 
    {
        // entering
        let searchTerm = event.target.value;
        this.searchText = searchTerm;
        if(this.searchText.length==0)
            {
                this.fetchNoOfRecords();
            }
            else
            {
                this.getDynamicData();
                this.fetchNoOfRecords();
            }  
  
    }

    handleSearchInput(event) 
    {
        // clearing
        let searchText = event.target.value;
        this.searchText = searchText;
        if( this.searchText.length==0)
        {
            this.searchResults = this.staticRecords;
            this.fetchNoOfRecords();
        }
        if(this.searchText.length>0)
        {
            this.getDynamicData();
        
        }
    }
    
    fetchNoOfRecords()
    { 
        if (this.searchResults.length === 0) {
            this.noOfRecords = '0 Results';
            this.showSortBy =false;
        } else if (this.searchResults.length === 1) {
            this.noOfRecords = '1 Result';
            this.showSortBy =false;
        } else if (this.searchResults.length > 1) {
            this.noOfRecords = `${this.searchResults.length} Results • Sorted by`;
            this.showSortBy =true;
        }
    }

    handleFocus(event) {
        event.preventDefault();
    }

    handleSelection(event) {
        event.preventDefault();
        this.selectedOption = event.target.value;
        this.sortData(this.selectedOption);
    }
    
    sortData(fieldName) {
        try {
           
            if (fieldName === 'Relevance'){
                if(this.searchText.length>0)
                {
                    this.searchResults = [...this.dynamicRecordsCopy];
                }
                else
                {
                    this.searchResults = [...this.staticRecords];
                }
            }
            else{
                this.isLoading = true;
                const sortedResults = [...this.searchResults].sort((a, b) => {
                    const fieldA = a[fieldName] ? a[fieldName].toString().toLowerCase() : '';
                    const fieldB = b[fieldName] ? b[fieldName].toString().toLowerCase() : '';
                    if (fieldA < fieldB) {
                        return -1;
                    } else if (fieldA > fieldB) {
                        return 1;
                    }
                    return 0;
                });
                
                this.searchResults = sortedResults; 
                this.isLoading = false;     
            }
        } 
        catch (error) {
            this.isLoading = false;
            console.error('Error from sortData function:', error);
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        console.log('roe dataa---->'+JSON.stringify(row));
        try{
            if (actionName === 'select_row') {
                this.selectedRow = row; 
                console.log('selected row Id---->'+this.selectedRow.Id);
                this.processSelectedRecord(this.selectedRow.Id) 
            }
        }
        catch(exception){
            console.log('exception from selected record--'+exception);
        }
    }
       

    processSelectedRecord(recId) {
        let tempObject;
        let selRec_Representation = this.selectedRecordRepresentation;
        try {
            this.searchResults.forEach(rec => {
                if (rec.Id === recId) {
                    tempObject = rec;
                }
            });
    
            if (!tempObject) {
                console.error(`Record with Id ${recId} not found in fetchedRecords.`);
                return; 
            }
            console.log('Matched Record:', JSON.stringify(tempObject));
            this.dispatchRecords.push(tempObject);
    
            for (let i = this.queryFieldNameList.length - 1; i >= 0; i--) {
                let key = 'field' + i;
                selRec_Representation = selRec_Representation.replace(i, key);
            }
            for (let i = this.queryFieldNameList.length - 1; i >= 0; i--) {
                let key = 'field' + i;
                let value = tempObject[this.queryFieldNameList[i]] ? tempObject[this.queryFieldNameList[i]] : '';
                selRec_Representation = selRec_Representation.replace(key, value);
            }
    
            let selRecLabel = selRec_Representation;
            let newsObject = { recId: recId, recLabel: selRecLabel };
    
            if (this.selectionCriteria === 's') {
                this.selectedRecords = [];
            }
            this.selectedRecords.push(newsObject);
    
            if (this.selectionCriteria === 's') {
                this.recordId = recId;
                this.hasRecId = true;
                this.txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
                this.enteredText = '';
            } else {
                if (this.recordId === '') {
                    this.recordId = recId;
                } else {
                    this.recordId += ',' + recId;
                }
                this.template.querySelector('.searchBox').focus();
            }
    
            this.template.querySelectorAll('lightning-input').forEach(each => {
                each.value = '';
            });
    
            const selectedEvent = new CustomEvent('selected', { detail: this.dispatchRecords });
            this.dispatchEvent(selectedEvent);
            this.isModalOpen = false;
        } 
        catch (Exception) {
            console.error('Exception in processSelectedRecord:', Exception, 'Stack:', Exception.stack);
        }
    }
    
    handleKeyDown(event) {
        if (event.key === 'Enter') 
        {
            event.preventDefault();
        }
    }
    getDynamicData() {
        ReturnSearchRecords({
            ObjectName: this.objectName,
            SearchFieldNameList: this.searchFieldNameList,
            FieldsToFetch:this.validatedFields,
            str: this.searchText,
            selectedRecId: this.selectedRecordId,
            additionalCond: this.whereClause,
            orderBy: this.orderBy,
            numOfRecs: this.limit,
            hasEncryptedFieldSearch: this.hasEncryptedFieldSearch,
            returnUniqueValueFor: this.returnUniqueValueFor,
            fieldMappingJson:this.replaceFieldsJson
            }).then((result) => {
            if (result) {
                this.recordsList = result
                this.recordsList = this.recordsList.map(row => {
                    return {
                        ...row,
                        recordLink: '/'+ row.Id,
                        Global_Record_Number__c: row.Global_Record_Number__c
                    };
                });
                this.searchResults = this.recordsList;
                this.dynamicRecordsCopy=[...this.searchResults]
                this.sortData(this.selectedOption);
                this.fetchNoOfRecords();
                this.isModalOpen = true;
            }
        }).catch((error) => {
            console.error('Error fetching more data:', error);
        })
    }
}
