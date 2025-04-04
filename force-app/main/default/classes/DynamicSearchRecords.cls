/**
 * @description       : 
 * @author            : Sandeep Talari
 * @group             : 
 * @last modified on  : 02-25-2025
 * @last modified by  : Sandeep Talari
**/
public without sharing class DynamicSearchRecords {
    @AuraEnabled(cacheable=true)
    public static List<SObject> DynamicSearchRecords(String ObjectName, List<String> SearchFieldNameList, string FieldsToFetch, string str, List<String> selectedRecId, String additionalCond, String orderBy, Integer numOfRecs, Boolean hasEncryptedFieldSearch, String returnUniqueValueFor) {
       return getRecords(ObjectName,SearchFieldNameList,FieldsToFetch,str,selectedRecId,additionalCond,orderBy,numOfRecs, hasEncryptedFieldSearch, returnUniqueValueFor);
    }
     @AuraEnabled
    public static List<SObject> RetrieveSearchRecords(String ObjectName, List<String> SearchFieldNameList, string FieldsToFetch, string str, List<String> selectedRecId, String additionalCond, String orderBy, Integer numOfRecs, Boolean hasEncryptedFieldSearch, String returnUniqueValueFor) {
       return getRecords(ObjectName,SearchFieldNameList,FieldsToFetch,str,selectedRecId,additionalCond,orderBy,numOfRecs, hasEncryptedFieldSearch, returnUniqueValueFor);
    }
    @AuraEnabled(cacheable=true)
    public static List<SObject> DynamicQueryRecords(String query){
        System.debug('Js Query: '+query);
        List<SObject> recList = Database.Query(query);
        return recList;
    }
    @AuraEnabled
    public static List<SObject> RetrieveQueryRecords(String query){
        List<SObject> recList = Database.Query(query);
        return recList;
    }
    public static List<SObject> getRecords(String ObjectName, List<String> SearchFieldNameList, string FieldsToFetch, string str, List<String> selectedRecId, String additionalCond, String orderBy, Integer numOfRecs, Boolean hasEncryptedFieldSearch, String returnUniqueValueFor)
    {
        if (hasEncryptedFieldSearch == null) {
            hasEncryptedFieldSearch = false;
        }
        String searchStr = str.trim();
        List<SObject> recList = new List<SObject>();
        if(selectedRecId == null){
            selectedRecId = new List<String>();
        }
        if (String.isNotBlank(additionalCond)) {            
            additionalCond = '( ' + additionalCond  + ' ) and ';
        }else{
            additionalCond='';
        }
        System.debug(additionalCond);
        String whereCond = additionalCond +'ID NOT IN :selectedRecId';
        String orderByCond='',queryLimit='';
        if (String.isNotBlank(orderBy)) {
            orderByCond += ' ORDER BY ' + orderBy;
        }
        if (numOfRecs != null) {
            queryLimit += ' LIMIT :numOfRecs';
        }
        if (hasEncryptedFieldSearch) {
            if (searchStr.length() > 1) {
                String soslQuery = 'FIND \''+String.escapeSingleQuotes(searchStr)+'*\' RETURNING '+ObjectName+'('+FieldsToFetch +' WHERE '+ whereCond + orderByCond + queryLimit +')';
                System.debug('SOSL_Query: '+soslQuery);
                List<List<SObject>> soslRes = search.query(soslQuery);
                if (soslRes.size() > 0) {
                    recList = soslRes[0];
                }
            }
            /* else {
                String soqlQuery = 'Select '+ FieldsToFetch +' from '+ ObjectName +' where '+ whereCond;
                System.debug('SOQL_Query: '+soqlQuery);
                recList = Database.Query(soqlQuery);
            } */
        } else {
            String searchCond = '';
            if(String.isNotEmpty(searchStr)){
                for (String fName : SearchFieldNameList) {
                    if (searchCond == '') {
                        searchCond = fName + ' LIKE \'%' + String.escapeSingleQuotes(searchStr) + '%\' ';
                    } else {
                        searchCond += 'or ' + fName + ' LIKE \'%' + String.escapeSingleQuotes(searchStr) + '%\' ';
                    }
                }
                searchCond = '( '+ searchCond + ') and ';
            }
            String soqlQuery = 'Select '+ FieldsToFetch +' from '+ ObjectName +' where '+ searchCond + whereCond + orderByCond + queryLimit;
            System.debug('SOQL_Query: '+soqlQuery);
            recList = Database.Query(soqlQuery);
        }
        if (String.isNotBlank(returnUniqueValueFor)) {
            Map<String, SObject> returnMap = new Map<String, SObject>();
            for (SObject sobj : recList) {
                returnMap.put((String)sobj.get(returnUniqueValueFor), sobj);
            }
            recList = returnMap.values();
        }
        system.debug(recList);
        system.debug(recList.size());
        return recList;
    }
    
@AuraEnabled
public static DataWrapper getMetadataAndData(String objectName, String whereClause, String queryFields) {
    string strAuditTrialLog = 'Started-> \n Object API Name--->' + objectName;
    DataWrapper response = new DataWrapper();

    try {
        List<Dynamic_Search_Data__mdt> metadataRecords = [
            SELECT Column_Data__c,Query_Fields__c, Replace_Fields__c, Sort_By_Options__c, Object_Name__c 
            FROM Dynamic_Search_Data__mdt 
            WHERE Object_Name__c = :objectName
        ];

        if (metadataRecords.isEmpty()) {
            strAuditTrialLog += '\n No metadata found.';
            response.status = false;
            return response;
        }

        Dynamic_Search_Data__mdt metadata = metadataRecords[0];

        response.columnData = metadata.Column_Data__c;
        Object deserializedColumns = JSON.deserializeUntyped(response.columnData);
        response.columnData = JSON.serialize(deserializedColumns);

        Set<String> metadataFields = new Set<String>(metadata.Query_Fields__c.split(','));
        Set<String> passedFields = new Set<String>(queryFields.split(','));

        metadataFields.addAll(passedFields);
        String validatedFields = String.join(new List<String>(metadataFields), ',');
        strAuditTrialLog+= '\n Validated Fields--->' + validatedFields;

        String query = 'SELECT ' + validatedFields + ' FROM ' + objectName;
        if (String.isNotBlank(whereClause)) {
            query += ' WHERE ' + whereClause;
        }

        query += ' LIMIT 100';
        List<SObject> queriedRecords = Database.query(query);
        if(metadata.Replace_Fields__c != null && queriedRecords.size() > 0){
            queriedRecords= replaceFieldValues(queriedRecords, metadata.Replace_Fields__c);
            strAuditTrialLog += '\n Replaced Fields--->' + metadata.Replace_Fields__c;
        }
        response.data = queriedRecords;
        response.sortByFields = metadata.Sort_By_Options__c;
        response.status = true;
        response.validatedFields = validatedFields;
        response.fieldMappingJson = metadata.Replace_Fields__c;

        strAuditTrialLog += '\n Query Response--->' + response;
    } catch (Exception e) {
        strAuditTrialLog += '\n Exception--->' + e.getMessage() + '\n' + 
            e.getStackTraceString() + '\nline number' + e.getLineNumber();
        throw new AuraHandledException(e.getMessage());
    } finally {
        strAuditTrialLog += '\n End of method.';
        HelperAudit.updateAudit('Get Metadata', strAuditTrialLog, true);
    }

    return response;
}


public static List<SObject> replaceFieldValues(List<SObject> records, String fieldMappingJson) {
    if (records == null || records.isEmpty() || String.isBlank(fieldMappingJson)) {
        return records;
    }
    System.debug('records before replacing: ' + records);
    
    Map<String, Object> rawMapping = (Map<String, Object>) JSON.deserializeUntyped(fieldMappingJson);
    Map<String, String> fieldMapping = new Map<String, String>();
    
    for(String key : rawMapping.keySet()) {
        fieldMapping.put(key, String.valueOf(rawMapping.get(key)));
    }
    
    for (SObject record : records) {
        for (String sourceField : fieldMapping.keySet()) {
            String targetField = fieldMapping.get(sourceField);
            
            List<String> targetParts = targetField.split('\\.');
            
            Object targetValue = record;
            Boolean isFirst = true;
            
            for (String part : targetParts) {
                if (targetValue instanceof SObject) {
                    if (isFirst) {
                        targetValue = ((SObject)targetValue).getSObject(part);
                        isFirst = false;
                    } else {
                        targetValue = ((SObject)targetValue).get(part);
                    }
                }
            }
            if (targetValue != null) {
                try {
                    record.put(sourceField, targetValue);
                    System.debug('Updated field ' + sourceField + ' with value: ' + targetValue);
                } catch (Exception e) {
                    System.debug('Error updating field ' + sourceField + ': ' + e.getMessage());
                }
            }
        }
    }
    System.debug('records after replacing: ' + records);
    return records;
}

@AuraEnabled 
public static List<SObject> ReturnSearchRecords(String ObjectName,List<String> SearchFieldNameList,
                string FieldsToFetch, 
                string str, 
                List<String> selectedRecId, 
                String additionalCond, 
                String orderBy, 
                Integer numOfRecs, 
                Boolean hasEncryptedFieldSearch, 
                String returnUniqueValueFor, 
                String fieldMappingJson) {

                string auditTrailLog = 'Started-> \n Object API Name--->' + ObjectName;
                List<SObject> recordsList = new List<SObject>();

    try {
  
                auditTrailLog += '\n Search Fields--->' + SearchFieldNameList;
                auditTrailLog += '\n Fields To Fetch--->' + FieldsToFetch;
                auditTrailLog += '\n Search String--->' + str;
                auditTrailLog += '\n Selected Record Ids--->' + selectedRecId;
                auditTrailLog += '\n Additional Condition--->' + additionalCond;
                auditTrailLog += '\n Order By--->' + orderBy;
                auditTrailLog += '\n Number Of Records--->' + numOfRecs;
                auditTrailLog += '\n Has Encrypted Field Search--->' + hasEncryptedFieldSearch;
                auditTrailLog += '\n Return Unique Value For--->' + returnUniqueValueFor;
                auditTrailLog += '\n Field Mapping JSON--->' + fieldMappingJson;

            recordsList=getRecords(ObjectName,SearchFieldNameList,FieldsToFetch,str,selectedRecId,additionalCond,orderBy,numOfRecs, hasEncryptedFieldSearch, returnUniqueValueFor);
            auditTrailLog += '\n Records List--->' + recordsList.size() + ' records found.';
            if(recordsList.size() > 0 && fieldMappingJson != null)
            {
                recordsList= replaceFieldValues(recordsList, fieldMappingJson);
                auditTrailLog += '\n after replacing' + recordsList;

            }

} 
catch (Exception ex) {
    auditTrailLog += '\n ex--->' + ex.getMessage() + '\n' + 
        ex.getStackTraceString() + '\nline number' + ex.getLineNumber();
        
} finally {
    auditTrailLog += '\n End of method.';
    HelperAudit.updateAudit('Return Search Records', auditTrailLog, true);
}
    
    return recordsList;
}

public class DataWrapper {
    @AuraEnabled
    public String columnData { get; set; }

    @AuraEnabled
    public String sortByFields { get; set; }

    @AuraEnabled
    public Object data { get; set; }
    
    @AuraEnabled
    public Boolean status { get; set; }

    @AuraEnabled
    public String fieldMappingJson { get; set; }

    @AuraEnabled
    public String validatedFields { get; set; }
}

}
