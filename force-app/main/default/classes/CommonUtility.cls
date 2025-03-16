/**
 * @description       : 
 * @author            : Sandeep Talari
 * @group             : 
 * @last modified on  : 03-16-2025
 * @last modified by  : Sandeep Talari
**/

public with sharing class CommonUtility {


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


@AuraEnabled(cacheable=true)
public static List<SObject> DynamicSearchRecords(String ObjectName, List<String> SearchFieldNameList, string FieldsToFetch, string str, List<String> selectedRecId, String additionalCond, String orderBy, Integer numOfRecs, Boolean hasEncryptedFieldSearch, String returnUniqueValueFor) {
    return getRecords(ObjectName,SearchFieldNameList,FieldsToFetch,str,selectedRecId,additionalCond,orderBy,numOfRecs, hasEncryptedFieldSearch, returnUniqueValueFor);
}
@AuraEnabled
public static DataWrapper getMetadataAndData(String objectName, String whereClause, String queryFields) {
DataWrapper response = new DataWrapper();

try {
    List<Dynamic_Search_Data__mdt> metadataRecords = [
        SELECT Column_Data__c,Query_Fields__c, Replace_Fields__c, Sort_By_Options__c, Object_Name__c 
        FROM Dynamic_Search_Data__mdt 
        WHERE Object_Name__c = :objectName
    ];

    if (metadataRecords.isEmpty()) {
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
    String query = 'SELECT ' + validatedFields + ' FROM ' + objectName;
    if (String.isNotBlank(whereClause)) {
        query += ' WHERE ' + whereClause;
    }

    query += ' LIMIT 100';
    List<SObject> queriedRecords = Database.query(query);
    if(metadata.Replace_Fields__c != null && queriedRecords.size() > 0){
        queriedRecords= replaceFieldValues(queriedRecords, metadata.Replace_Fields__c);
    }
    response.data = queriedRecords;
    response.sortByFields = metadata.Sort_By_Options__c;
    response.status = true;
    response.validatedFields = validatedFields;
    response.fieldMappingJson = metadata.Replace_Fields__c;
} catch (Exception e) {
    throw new AuraHandledException(e.getMessage());
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
                String fieldMappingJson) 
                {
                List<SObject> recordsList = new List<SObject>();

    try {

        recordsList=getRecords(ObjectName,SearchFieldNameList,FieldsToFetch,str,selectedRecId,additionalCond,orderBy,numOfRecs, hasEncryptedFieldSearch, returnUniqueValueFor);
        if(recordsList.size() > 0 && fieldMappingJson != null)
        {
            recordsList= replaceFieldValues(recordsList, fieldMappingJson);

        }

    } 
    catch (Exception ex) {
        system.System.debug('Error in ReturnSearchRecords: ' + ex.getMessage());              
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