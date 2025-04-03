## Method: buildEmailMessage

### Description
The `buildEmailMessage` method constructs an `EmailMessage` record from a given `Messaging.SingleEmailMessage` instance and associates it with a related record in Salesforce.

### Parameters
- **email** (`Messaging.SingleEmailMessage`): The email message that needs to be converted into an `EmailMessage` record.
- **relatedToId** (`ID`): The ID of the record to which the email message should be related.

### Return Value
- Returns an instance of `EmailMessage` with populated fields based on the provided `email` object and associated record.

### Processing Steps
1. **Retrieve Field Length Limits:**
   - The maximum allowed length for `TextBody`, `HtmlBody`, and `Subject` fields is obtained using `getDescribe().getLength()`.
   
2. **Extract and Abbreviate Email Content:**
   - `plainTextBody`, `htmlBody`, and `subject` are retrieved from the `email` object and truncated to fit within their respective field limits.
   
3. **Fetch Org-Wide Email Address:**
   - The method queries the `OrgWideEmailAddress` object to retrieve the first available org-wide email address (if any).
   
4. **Create an EmailMessage Record:**
   - A new `EmailMessage` instance is created with the extracted details:
     - `TextBody`, `HtmlBody`, `Subject`
     - `Incoming` set to `false` (indicating an outgoing email)
     - `FromAddress` set to the org-wide email address
     - `MessageDate` set to the current DateTime
     - `RelatedToId` associated with the provided `relatedToId`
     - `Status` set to `3` (which typically denotes a sent email in Salesforce)
   
5. **Populate Recipient Information:**
   - `toAddress` is set using `email.toAddresses`, joined as a semicolon-separated string.
   - If `OrgWideEmailAddressId` is available, `toAddress` is updated accordingly.
   - `ccAddress` is populated similarly using `email.ccAddresses`.

6. **Return the Constructed EmailMessage Object**
   - The populated `EmailMessage` instance is returned.

### Example Usage
```apex
Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
email.setToAddresses(new List<String>{'example@example.com'});
email.setCcAddresses(new List<String>{'cc@example.com'});
email.setPlainTextBody('This is a test email body.');
email.setHtmlBody('<p>This is a test email body.</p>');
email.setSubject('Test Email');

ID relatedRecordId = '001XXXXXXXXXXXX'; // Example related record ID
EmailMessage emailMessage = YourClass.buildEmailMessage(email, relatedRecordId);
insert emailMessage;
```

### Notes
- The method assumes that at least one `OrgWideEmailAddress` exists in the org; otherwise, `FromAddress` will be empty.
- If `email.toAddresses` or `email.ccAddresses` is empty, their corresponding fields in `EmailMessage` will also remain empty.
- `Status = '3'` represents an outgoing email status; adjust this based on your org's configuration if needed.

