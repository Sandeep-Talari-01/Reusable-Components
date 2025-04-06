/**
 * @description       : 
 * @author            : Sandeep Talari
 * @group             : 
 * @last modified on  : 04-07-2025
 * @last modified by  : Sandeep Talari
 * @method            : getPostOfficeData
 * @access            : public static
 * @description       : Takes a post office name as input, makes a GET callout to the postal pincode API,
 *                      parses the response JSON, and returns a list of PostOfficeData wrapper instances.
 * 
 * @param postOfficeName : Name of the post office (e.g., 'Vepagunta', 'Madhapur').
 *                         Special characters and spaces will be URL encoded for safety.
 * 
 * @return            : List<PostOfficeData> — a list of structured post office records.
 * 
 * @example
 *   List<AsyncCallout.PostOfficeData> results = AsyncCallout.getPostOfficeData('Vepagunta');
 *   for (AsyncCallout.PostOfficeData data : results) {
 *       System.debug(data.name + ' - ' + data.pincode);
 *   }
 */
 public class AsyncCallout{

   
    @AuraEnabled
    public static List<PostOfficeData> getPostOfficeData(string postOfficeName)
    {
        List<PostOfficeData> datalist= new List<PostOfficeData>();
        string encodedName=EncodingUtil.urlEncode(postOfficeName,'UTF-8');
        try{
             http http= new http();
             HttpRequest request=new HttpRequest();
             request.setHeader('content-type','application/json');
             request.setMethod('GET');
             request.setEndpoint('https://api.postalpincode.in/postoffice/'+encodedName);
            httpResponse response= http.send(request);

          if (response.getStatusCode() == 200) {
                List<Object> rawData = (List<Object>) JSON.deserializeUntyped(response.getBody());

                if (!rawData.isEmpty()) {
                    Map<String, Object> firstEntry = (Map<String, Object>) rawData[0];
                    List<Object> postOffices = (List<Object>) firstEntry.get('PostOffice');

                    if (postOffices != null && !postOffices.isEmpty()) {
                        for (Object record : postOffices) {
                            Map<String, Object> recordMap = (Map<String, Object>) record;
                            PostOfficeData singleOfficeData = new PostOfficeData();
                            singleOfficeData.name = (String) recordMap.get('Name');
                            singleOfficeData.branchType = (String) recordMap.get('BranchType');
                            singleOfficeData.circle = (String) recordMap.get('Circle');
                            singleOfficeData.division = (String) recordMap.get('Division');
                            singleOfficeData.region = (String) recordMap.get('Region');
                            singleOfficeData.state = (String) recordMap.get('State');
                            singleOfficeData.pincode = (String) recordMap.get('Pincode');
                            singleOfficeData.response = true;
                            singleOfficeData.message = 'Found';
                            datalist.add(singleOfficeData);
                        }
                    } else {
                        PostOfficeData notFound = new PostOfficeData();
                        notFound.response = false;
                        notFound.message = 'No post office data found';
                        datalist.add(notFound);
                    }
                }
            } else {
                PostOfficeData errorData = new PostOfficeData();
                errorData.response = false;
                errorData.message = 'API call failed with status code: ' + response.getStatusCode();
                datalist.add(errorData);
            }
        } catch (Exception ex) {
            PostOfficeData errorData = new PostOfficeData();
            errorData.response = false;
            errorData.message = 'Exception occurred: ' + ex.getMessage();
            datalist.add(errorData);
            System.debug('Exception occurred ---> ' + ex.getMessage());
        }

        return datalist;
    }
    
    public class PostOfficeData
    {
        @AuraEnabled
        public string name{get; set;}
        @AuraEnabled
        public string branchType{get; set;}
        @AuraEnabled
        public string circle {get; set;}
        @AuraEnabled
        public string division {get; set;}
        @AuraEnabled
        public string region{get; set;}
        @AuraEnabled
        public string state{get; set;}
        @AuraEnabled
        public string pincode{get; set;}
        @AuraEnabled 
        public Boolean response { get; set; }
        @AuraEnabled
        public String message { get; set; }
    }

}
