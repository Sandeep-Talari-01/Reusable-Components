### Method: reduceChunks

#### Description:
The `reduceChunks` method reorganizes a list of Salesforce `SObject` records by grouping them based on their object type. The method preserves the order of records but ensures that all records of the same type are grouped together.

#### Parameters:
- `sObjList` (List<SObject>): A list of `SObject` records to be processed and reorganized.

#### Functionality:
1. Iterates through the provided list of `SObject` records.
2. Clones each record while preserving its ID (if present) and adds it to a temporary map that categorizes objects by type.
3. Clears the original `sObjList`.
4. Reconstructs `sObjList` by adding back all records in type-grouped order.

#### Key Operations:
- Uses `clone(preserveId, true, false, false)` to create a copy of each `SObject`.
- Categorizes records by their object type using a map (`sObjType_sObjectsMap`).
- Clears the original list and repopulates it in a grouped manner.

#### Example Usage:
```apex
List<SObject> records = new List<SObject>{
    new Account(Name = 'Acme Corp'),
    new Contact(FirstName = 'John', LastName = 'Doe'),
    new Account(Name = 'Tech Inc'),
    new Contact(FirstName = 'Jane', LastName = 'Smith')
};

reduceChunks(records);
// Now, 'records' will have all Account records followed by all Contact records.
```

#### Considerations:
- The method assumes that all records in `sObjList` belong to known `SObject` types.
- It modifies the original list (`sObjList`) in-place.
- The function does not guarantee any particular sorting order beyond grouping by object type.

