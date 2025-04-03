/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-03-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class EmailMessage
{
public static EmailMessage buildEmailMessage(Messaging.SingleEmailMessage email,ID relatedToId){ 
        Integer maxLengthPlainTextBody = EmailMessage.TextBody.getDescribe().getLength();
        Integer maxLengthHtmlBody = EmailMessage.HtmlBody.getDescribe().getLength();
        Integer maxLengthSubject = EmailMessage.Subject.getDescribe().getLength();        
        String plainTextBody = ( String.isBlank( email.plainTextBody ) ? '' : email.plainTextBody.abbreviate( maxLengthPlainTextBody ) );
        String htmlBodyFull = ( String.isBlank( email.htmlBody ) ? '' : email.htmlBody.abbreviate( maxLengthHtmlBody ) );
        String subject = ( String.isBlank( email.subject ) ? '' : email.subject.abbreviate( maxLengthSubject ) );
        String plainText,htmlBody0='';
        Integer htmlBodyLength;
        string orgWideEmailAddressId='';
        List<OrgWideEmailAddress> EmailAddressId=[SELECT Id FROM OrgWideEmailAddress order by createdDate asc LIMIT 1];
        if(EmailAddressId.size()>0){
            orgWideEmailAddressId=EmailAddressId[0].Id;
        }
        EmailMessage message = new EmailMessage(
            
            textBody = plainTextBody,
            htmlBody = htmlBodyFull,
            subject = subject,
            incoming = false,
            FromAddress = orgWideEmailAddressId,
            MessageDate = DateTime.now(),
            RelatedToId = relatedToId,
            status = '3'    
        );
                system.debug('id3'+relatedToId);

        if(email.toAddresses != null && email.toAddresses.size() > 0){
            message.toAddress = String.join( email.toAddresses, ';' );
        }
                if(email.orgwideemailaddressid != null){
            message.toAddress = String.join( email.toAddresses, ';' );
        }
        
        if(email.ccAddresses != null && email.ccAddresses.size() > 0){
            message.ccAddress = String.join( email.ccAddresses, ';' );
        }        
        return message;
    }
}
