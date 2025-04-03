
# Documentation: collateChildFieldsOnParent Method

## Overview
The `collateChildFieldsOnParent` method is a utility function designed to aggregate data from child records and update a parent object with a formatted string representation of the collected data. This method is typically used in triggers or batch processes to ensure that parent records maintain an up-to-date collation of relevant child record fields.

## Method Signature
```apex
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
)
```

## Parameters
- **triggerNewRecords**: List of new child records being inserted or updated.
- **triggerOldRecords**: List of old child records being updated or deleted.
- **parentObjectName**: API name of the parent object.
- **childObjectName**: API name of the child object.
- **parentLookupField**: The lookup field on the child object that references the parent.
- **collatFieldNameOnParent**: The field on the parent object where the collated data will be stored.
- **directFieldsToCollatOfChild**: List of field names on the child object to be included in the collation.
- **relatedFieldsToCollatOfChild**: List of related object fields to be included in the collation.
- **fieldDelimiter**: Delimiter used to separate fields within each child record.
- **recordDelimiter**: Delimiter used to separate different child records.
- **withLabel**: Boolean flag indicating whether to include field labels in the collation.
- **blankFieldConsideredInOutput**: Boolean flag indicating whether to include blank fields in the output.

## Process Flow
1. **Extract Parent IDs**
   - Collects parent record IDs from both `triggerNewRecords` and `triggerOldRecords`.
   - Ensures only valid parent IDs are processed.

2. **Retrieve Field Labels**
   - Uses Schema Describe to fetch field labels for `directFieldsToCollatOfChild` and `relatedFieldsToCollatOfChild` if `withLabel` is `true`.

3. **Query Child Records**
   - Constructs a dynamic SOQL query to retrieve child records belonging to the extracted parent IDs.

4. **Collate Data**
   - Iterates through the queried child records.
   - Formats data using the specified field and record delimiters.
   - Applies label formatting if `withLabel` is enabled.
   - Handles special formatting for Date fields (MM/dd/yyyy).

5. **Update Parent Records**
   - Maps the collated data to respective parent records.
   - Creates a list of parent records to update with the collated data.

6. **Publish Platform Event**
   - Creates and publishes a `General_Utility__e` platform event for logging or further processing.

7. **Audit Logging**
   - Uses `HelperAudit.updateAudit` to log method execution details, including errors and success messages.

## Error Handling
- Catches exceptions during processing and logs detailed error messages using `HelperAudit.updateAudit`.
- Ensures database operations are wrapped in try-catch blocks to prevent transaction failures.

## Usage Example
This method is typically called within an Apex trigger:
```apex
trigger ChildObjectTrigger on ChildObject__c (after insert, after update, after delete) {
    collateChildFieldsOnParent(
        Trigger.new,
        Trigger.old,
        'ParentObject__c',
        'ChildObject__c',
        'Parent__c',
        'Collated_Field__c',
        new List<String>{'Field1__c', 'Field2__c'},
        new List<String>{'RelatedObject__r.Field3__c'},
        '|',
        '\n',
        true,
        false
    );
}
```

## Key Considerations
- Ensure the method is invoked only when necessary to optimize performance.
- Be mindful of SOQL limits, especially in bulk processing scenarios.
- Handle potential null values in child records to avoid exceptions.

## Conclusion
The `collateChildFieldsOnParent` method is a powerful utility for consolidating child record data onto a parent object. By leveraging dynamic SOQL queries, schema descriptions, and platform events, it provides a flexible and efficient approach to data collation in Salesforce Apex development.

