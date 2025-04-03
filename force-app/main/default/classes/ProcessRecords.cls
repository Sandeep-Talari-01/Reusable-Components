public without sharing class ProcessRecords {

public static void reduceChunks(List<SObject> sObjList){
        Map<String, List<SObject>> sObjType_sObjectsMap = new Map<String, List<SObject>>();
        for (SObject sObj : sObjList) {
            Boolean preserveId = String.isNotBlank((String)sObj.get('Id')) ? true : false;
            SObject sObjClone = sObj.clone(preserveId, true, false, false);
            String sObjType = String.valueOf(sObjClone.getSObjectType());
            List<SObject> tempChunkRecList = new List<SObject>();
            if (sObjType_sObjectsMap.containsKey(sObjType)) {
                tempChunkRecList = sObjType_sObjectsMap.get(sObjType);
            }
            tempChunkRecList.add(sObjClone);
            sObjType_sObjectsMap.put(sObjType, tempChunkRecList);
        }
        sObjList.clear();
        for (String key : sObjType_sObjectsMap.keySet()) {
            sObjList.addAll(sObjType_sObjectsMap.get(key));
        }
    }
}
