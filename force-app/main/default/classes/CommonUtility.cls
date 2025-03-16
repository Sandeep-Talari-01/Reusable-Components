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

}