/**
 * @description       : 
 * @author            : Sandeep Talari
 * @group             : 
 * @last modified on  : 03-02-2025
 * @last modified by  : Sandeep Talari
**/

public with sharing class CommonUtility {


    public static void collateChildFieldsOnParent(
        List<SObject> triggerNewRecords,
        List<SObject> triggerOldRecords,
        String parentObjectName,
        String childObjectName,
        String parentLookupField,
        String collatFieldNameOnParent,
        List<String> directFieldsToCollatOfChild, 
        List<String> relatedFieldsToCollatOfChild,
        String fieldDelimiter,
        String recordDelimiter,
        Boolean withLabel,
        Boolean blankFieldConsideredInOutput
    ) {
        String strAuditTrailLogText = '';
        Boolean status;
        try 
        {
            strAuditTrailLogText += 'triggerNewRecords: ' + triggerNewRecords + '\n'; 
            strAuditTrailLogText += 'triggerOldRecords: ' + triggerOldRecords + '\n'; 
            strAuditTrailLogText += 'parentObjectName: ' + parentObjectName + '\n'; 
            strAuditTrailLogText += 'childObjectName: ' + childObjectName + '\n'; 
            strAuditTrailLogText += 'parentLookupField: ' + parentLookupField + '\n'; 
            strAuditTrailLogText += 'collatFieldNameOnParent: ' + collatFieldNameOnParent + '\n'; 
            strAuditTrailLogText += 'directFieldsToCollatOfChild: ' + directFieldsToCollatOfChild + '\n'; 
            strAuditTrailLogText += 'relatedFieldsToCollatOfChild: ' + relatedFieldsToCollatOfChild + '\n'; 
            strAuditTrailLogText += 'fieldDelimiter: ' + fieldDelimiter + '\n'; 
            strAuditTrailLogText += 'recordDelimiter: ' + recordDelimiter + '\n'; 
            strAuditTrailLogText += 'withLabel: ' + withLabel + '\n'; 
            strAuditTrailLogText += 'blankFieldConsideredInOutput: ' + blankFieldConsideredInOutput + '\n';

            // Get parent IDs from both new and old records
            Set<Id> parentIds = new Set<Id>();
            
            // Handle new records (insert/update)
            if(triggerNewRecords != null) {
                for(SObject childRecord : triggerNewRecords) 
                {
                    Id parentId = (Id)childRecord.get(parentLookupField);
                    if(parentId != null) {
                        parentIds.add(parentId);
                    }
                }
            }
            strAuditTrailLogText += 'parentIds: ' + parentIds + '\n'; 
            // Handle old records (delete/update)
            if(triggerOldRecords != null) {
                for(SObject childRecord : triggerOldRecords) {
                    Id parentId = (Id)childRecord.get(parentLookupField);
                    if(parentId != null) {
                        parentIds.add(parentId);
                    }
                    
                }
            } 
            // If no parents found, exit
            if(parentIds.isEmpty()) return;
            
            // Get field labels using schema describe
            Map<String, String> directFieldToLabelMap = new Map<String, String>();
            Map<String, String> relatedFieldToLabelMap = new Map<String, String>();

            strAuditTrailLogText += 'directFieldsToCollatOfChild: ' + directFieldsToCollatOfChild + '\n';
            strAuditTrailLogText += 'relatedFieldsToCollatOfChild: ' + relatedFieldsToCollatOfChild + '\n';

            Schema.DescribeSObjectResult describeResult = 
                Schema.getGlobalDescribe().get(childObjectName).getDescribe();
            if (directFieldsToCollatOfChild != null) {
                for (String fieldName : directFieldsToCollatOfChild) {
                    Schema.SObjectField field = describeResult.fields.getMap().get(fieldName);
                    strAuditTrailLogText += 'field: ' + field + '\n';
                    if (field != null && withLabel) {
                        directFieldToLabelMap.put(fieldName, field.getDescribe().getLabel());
                        strAuditTrailLogText += 'directFieldToLabelMap: ' + directFieldToLabelMap + '\n';
                    }
                }
            }
            if(relatedFieldsToCollatOfChild!=null)
            {
                for(String fieldName : relatedFieldsToCollatOfChild) {
                    strAuditTrailLogText += 'fieldName: ' + fieldName + '\n';
                    String outputField = fieldName.replaceAll('__r\\..*', '__c');
                    strAuditTrailLogText += 'outputField: ' + outputField + '\n';
                    Schema.SObjectField field = describeResult.fields.getMap().get(outputField);
                    strAuditTrailLogText += 'field: ' + field + '\n';
                    strAuditTrailLogText += 'field.getDescribe().getLabel(): ' + field.getDescribe().getLabel() + '\n';
                    if(fieldName != null && withLabel) {
                        relatedFieldToLabelMap.put(fieldName, field.getDescribe().getLabel());
                        //relatedFieldToLabelMap.put(fieldName, outputField);
                        strAuditTrailLogText += 'relatedFieldToLabelMap: ' + relatedFieldToLabelMap + '\n';
                    }
                }  
            }
            strAuditTrailLogText += 'directFieldToLabelMap : ' + directFieldToLabelMap + '\n'; 
            strAuditTrailLogText += 'relatedFieldToLabelMap : ' + relatedFieldToLabelMap + '\n'; 

            // Prepare the dynamic query for child records

            // Initialize query string
            String childQuery = 'SELECT Id';

            // Add direct fields if not null
            if (directFieldsToCollatOfChild != null && !directFieldsToCollatOfChild.isEmpty()) {
                childQuery += ', ' + String.join(directFieldsToCollatOfChild, ',');
            }

            // Add related fields if not null
            if (relatedFieldsToCollatOfChild != null && !relatedFieldsToCollatOfChild.isEmpty()) {
                childQuery += ', ' + String.join(relatedFieldsToCollatOfChild, ',');
            }

            // Add parent lookup field and the rest of the query
            childQuery += ', ' + parentLookupField + 
                ' FROM ' + childObjectName + 
                ' WHERE ' + parentLookupField + 
                ' IN :parentIds ORDER BY CreatedDate ASC';
            strAuditTrailLogText += 'childQuery : ' + childQuery + '\n'; 
            
            // Query child records
            List<SObject> childRecords = Database.query(childQuery);
            System.debug('childRecords'+childRecords);
            
            strAuditTrailLogText += 'childRecords : ' + childRecords + '\n'; 
            // Map to store parent ID to collated string
            Map<Id, String> parentToCollatedString = new Map<Id, String>();
            
            // Process child records
            for(SObject childRecord : childRecords) {
                Id parentId = (Id)childRecord.get(parentLookupField);
                strAuditTrailLogText += 'parentId : ' + parentId + '\n';
                // Build collated string for this child record
                List<String> fieldValues = new List<String>();
                Boolean hasValidValue = false;

                // Process direct fields
                strAuditTrailLogText += 'directFieldsToCollatOfChild : ' + directFieldsToCollatOfChild + '\n';
                if(directFieldsToCollatOfChild!=null)
                {
                    for(String field : directFieldsToCollatOfChild) {
                        Object fieldValue = childRecord.get(field);
                        String strValue;
                        //String strValue = (fieldValue != null) ? String.valueOf(fieldValue) : '';
                        if(fieldValue!=null)
                        {
                            if (fieldValue instanceof Date) {
                                // Format Date field to MM/dd/yyyy
                                Date dateValue = (Date) fieldValue;
                                strValue = (dateValue.day() < 10 ? '0' : '') + dateValue.day() + '/' + 
                                                (dateValue.month() < 10 ? '0' : '') + dateValue.month() + '/' + 
                                                dateValue.year();
                            } else {
                                // Default handling for non-date fields
                                strValue = String.valueOf(fieldValue);
                            }
                        }
                        else
                            strValue ='';
                        strAuditTrailLogText += 'fieldValue : ' + fieldValue + '\n';
                        strAuditTrailLogText += 'strValue : ' + strValue + '\n';
                        
                        if(!String.isBlank(strValue) || blankFieldConsideredInOutput) {
                            String formattedValue;
                            if (directFieldToLabelMap != null && directFieldToLabelMap.containsKey(field))
                                formattedValue = directFieldToLabelMap.get(field) + ' = ' + strValue;
                            else
                                formattedValue = strValue;
                            fieldValues.add(formattedValue);
                            System.debug('formattedValue'+formattedValue);
                            strAuditTrailLogText += 'formattedValue : ' + formattedValue + '\n';
                            if(!String.isBlank(strValue)) hasValidValue = true;
                        }
                    }
                }
                if(relatedFieldsToCollatOfChild!=null)
                {
                    // Process related fields
                    for(String relatedField : relatedFieldsToCollatOfChild) { 
                        strAuditTrailLogText += 'relatedField : ' + relatedField + '\n';
                        strAuditTrailLogText += 'childRecord : ' + childRecord + '\n';
                        //Object relatedValue = childRecord.getSObject(relatedField);
                        Object relatedValue = getFieldFromRelatedObject(childRecord, relatedField);
                        String strValue = (relatedValue != null) ? String.valueOf(relatedValue) : '';
                        strAuditTrailLogText += 'relatedValue : ' + relatedValue + '\n';
                        strAuditTrailLogText += 'related - strValue : ' + strValue + '\n';
                        
                        if(!String.isBlank(strValue) || blankFieldConsideredInOutput) {
                            String formattedValue;
                            if(relatedFieldToLabelMap != null && relatedFieldToLabelMap.containsKey(relatedField))
                                formattedValue = relatedFieldToLabelMap.get(relatedField) + ' = ' + strValue;
                            else
                                formattedValue = strValue;
                            fieldValues.add(formattedValue);
                            strAuditTrailLogText += 'formattedValue - related: ' + formattedValue + '\n';
                            System.debug('formattedValue1'+formattedValue);
                            if(!String.isBlank(strValue)) hasValidValue = true;
                        }
                    }
                }
                strAuditTrailLogText += 'hasValidValue: ' + hasValidValue + '\n';
                strAuditTrailLogText += 'fieldValues: ' + fieldValues + '\n';
                // Only process if we have valid values or blank fields are allowed
                if(hasValidValue || blankFieldConsideredInOutput) {
                    String collatedValue = String.join(fieldValues, fieldDelimiter);
                    strAuditTrailLogText += 'collatedValue: ' + collatedValue + '\n';
                    strAuditTrailLogText += 'parentToCollatedString: ' + parentToCollatedString + '\n';
                    if(parentToCollatedString.containsKey(parentId)) {
                        parentToCollatedString.put(
                            parentId,
                            parentToCollatedString.get(parentId) + recordDelimiter + collatedValue
                        );
                        strAuditTrailLogText += 'parentToCollatedString ---: ' + parentToCollatedString + '\n';
                    } else {
                        parentToCollatedString.put(parentId, collatedValue);
                    }

                    strAuditTrailLogText += '====parentToCollatedString ====: ' + parentToCollatedString + '\n';
                }
            }
            
            // Update parent records - include all affected parents even if they have no children
            List<SObject> parentsToUpdate = new List<SObject>();
            for(Id parentId : parentIds) {
                SObject parentRecord = (SObject)Type.forName(parentObjectName).newInstance();
                parentRecord.put('Id', parentId);
                parentRecord.put(collatFieldNameOnParent, 
                            parentToCollatedString.containsKey(parentId) ? 
                            parentToCollatedString.get(parentId) : '');
                parentsToUpdate.add(parentRecord);
            }
            strAuditTrailLogText += '====parentsToUpdate ====: ' + parentsToUpdate + '\n';
            if(!parentsToUpdate.isEmpty()) {
                try {
                    //Publishes a list of platform events to the EventBus
                    List<General_Utility__e> eventList = new List<General_Utility__e>();
                    
                    for(Sobject obj:parentsToUpdate)
                    {
                        Map<String, String> jsonMap_params = new Map<String, String>();

                        jsonMap_params.put(collatFieldNameOnParent, String.valueOf(obj.get(collatFieldNameOnParent)));
                        jsonMap_params.put('sObjectName', String.valueOf(obj.getSObjectType()));

                        General_Utility__e event = new General_Utility__e(
                            Operation_Type__c = 'Collation',
                            Record_ID__c = String.valueOf(obj.Id),
                            JSON_Params__c = JSON.serialize(jsonMap_params)
                        );
                        eventList.add(event);   
                    }
                                 
                    if (!eventList.isEmpty()) {
                        // Publish to the platform event
                        try {
                            system.debug('eventList-'+eventList);
                            Database.saveResult[] sr = EventBus.publish(eventList);
                            for(Database.saveResult s:sr){
                            if(s.isSuccess()){
                                system.debug('successfully published event');
                            }
                            else{
                                for(Database.Error er: s.getErrors()){
                                    system.debug('error--'+er.getStatusCode()+'--'+er.getMessage());
                                }
                            }}
                        } catch (Exception e) {
                            System.debug('Error publishing platform event: ' + e.getMessage());
                        }
                    }
                    status = true;
                    strAuditTrailLogText += 'Successful Collation Utility - > updateCollatedFields.' + '\n';
                } catch (DmlException e) {
                    status = false;
                    strAuditTrailLogText += 'Error updating records: ' + e.getMessage();
                }
                status = true;
                strAuditTrailLogText += 'Successful collate child fields on parent done.' + '\n';
            } 
        } 
        catch (Exception e) {
            status = false;
            strAuditTrailLogText += 'Error in collating fields: ' + e.getMessage() + '\n';
            strAuditTrailLogText += 'Error: ' + e.getMessage() + e.getStackTraceString() + '\n';
        } finally {
            HelperAudit.updateAudit('collateChildFieldsOnParent', strAuditTrailLogText, status);
        }
    }


    @AuraEnabled
    public static Map<String, Object> getKeywordColorMap() {
        String strAuditTrailLogText = '\nStarted--->';
        Boolean status = false;
        
        Map<String, Object> resultMap = new Map<String, Object>();
        Map<String, List<String>> includeMap = new Map<String, List<String>>();
        List<String> excludeKeywordsList = new List<String>();
        Map<String, DateTime> keywordCreationMap = new Map<String, DateTime>(); 
    
        try {
    
            List<Keyword_Color_Map__mdt> keywordColorMapList = [
                SELECT Id, Color__c, Active__c, Type__c, Created_Date__c, Keywords__c
                FROM Keyword_Color_Map__mdt
                WHERE Active__c = true ORDER BY Created_Date__c ASC
            ];
    
            strAuditTrailLogText += '\n list of records--->' + keywordColorMapList;
    
           
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType customMetadataType = schemaMap.get('Keyword_Color_Map__mdt');
            Map<String, Schema.SObjectField> fieldMap = customMetadataType.getDescribe().fields.getMap();
            List<Schema.PicklistEntry> picklistEntries = fieldMap.get('Color__c').getDescribe().getPicklistValues();
    
            for (Keyword_Color_Map__mdt record : keywordColorMapList) {
                if (record.Keywords__c != null) {
                    List<String> keywords = record.Keywords__c.contains('|') 
                        ? new List<String>(record.Keywords__c.split('\\|'))
                        : new List<String>{record.Keywords__c};
                    
                    for (Integer i = 0; i < keywords.size(); i++) {
                        keywords[i] = keywords[i].trim();
                    }
    
                    if (record.Type__c == 'Include' && record.Color__c != null) {
                        List<String> updatedKeywords = includeMap.containsKey(record.Color__c) 
                            ? includeMap.get(record.Color__c) 
                            : new List<String>();
    
                        for (String keyword : keywords) {
                            if (!keywordCreationMap.containsKey(keyword) || 
                                keywordCreationMap.get(keyword) > record.Created_Date__c) {
                                keywordCreationMap.put(keyword, record.Created_Date__c); 
                                
                                if (!updatedKeywords.contains(keyword)) {
                                    updatedKeywords.add(keyword);
                                }
                            }
                        }
                        
                        includeMap.put(record.Color__c, updatedKeywords);
                    } else if (record.Type__c == 'Exclude') {
                        excludeKeywordsList.addAll(keywords);
                    }
                }
            }
    
            for (String excludeKeyword : excludeKeywordsList) {
                for (String color : includeMap.keySet()) {
                    List<String> colorKeywords = includeMap.get(color);
                    
                    Integer index = colorKeywords.indexOf(excludeKeyword);
                    if (index != -1) { 
                        colorKeywords.remove(index);
                    }
                    
    
                    includeMap.put(color, colorKeywords);
                }
            }
    
            resultMap.put('includeMap', includeMap);
            resultMap.put('excludeKeywordsList', excludeKeywordsList);
            
            if (!keywordColorMapList.isEmpty()) {
                status = true;
                strAuditTrailLogText += '\n Keyword_Color_Map__mdt records processed successfully--->' + resultMap;
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        } finally {
            HelperAudit.updateAudit('get keyword-color map', strAuditTrailLogText, status);
        }
        return resultMap;
    }

  
  
}
