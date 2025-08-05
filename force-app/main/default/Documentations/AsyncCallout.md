# 📬 AsyncCallout - India Postal API Integration

Apex utility class to integrate Salesforce with the [India Postal Pincode API](https://api.postalpincode.in). This class allows querying post office information by name and returns structured data for internal use in Salesforce.

---

## 📌 Use Case

This integration helps fetch post office details dynamically from a government API using the post office name. Useful in:

- Auto-filling address-related fields
- Validating postal service info
- Enriching contact or location data
- Pre-filling data in flows or LWC forms

---

## 🚀 Features

- 🔍 **Search by Post Office Name**
- 🌐 External HTTP GET callout
- 🔒 Uses `UTF-8` encoding to support special characters
- 🔧 JSON parsing with error handling
- ✅ Returns strongly typed data via wrapper class

---

## 🧱 API Reference

### 🔧 API Endpoint

```
GET https://api.postalpincode.in/postoffice/{PostOfficeName}
```

### ✅ Sample Response

```json
[
  {
    "Message": "Number of Post office(s) found: 1",
    "Status": "Success",
    "PostOffice": [
      {
        "Name": "Vepagunta (Chittoor)",
        "BranchType": "Sub Post Office",
        "Circle": "Andhra Pradesh",
        "Division": "Tirupati",
        "Region": "Kurnool",
        "State": "Andhra Pradesh",
        "Country": "India",
        "Pincode": "517584"
      }
    ]
  }
]
```

---

## 🧩 Apex Class Overview

### 🔹 Class: `AsyncCallout`

#### Method: `getPostOfficeData(String postOfficeName)`

Fetches data for a given post office name.

| Parameter         | Type    | Description                          |
|------------------|---------|--------------------------------------|
| `postOfficeName` | String  | Name of the post office to search    |

| Returns           | Type                      | Description                              |
|------------------|---------------------------|------------------------------------------|
| `List<PostOfficeData>` | Custom Wrapper Class | List of structured post office objects    |

#### Wrapper Class: `PostOfficeData`

| Field        | Type   | Description                  |
|--------------|--------|------------------------------|
| `name`       | String | Post office name             |
| `branchType` | String | Branch type (e.g., Sub PO)   |
| `circle`     | String | Postal Circle                |
| `division`   | String | Postal Division              |
| `region`     | String | Postal Region                |
| `state`      | String | State name                   |
| `pincode`    | String | 6-digit postal code          |

---

## ⚙️ How It Works (Flow)

1. Encode post office name to avoid URL breaking (`UTF-8`)
2. Set up HTTP GET request with correct headers
3. Call external API endpoint
4. Parse the JSON body
5. Extract `PostOffice` node
6. Map each entry into a `PostOfficeData` wrapper
7. Return the list

---

## 🧪 Sample Usage

```apex
List<AsyncCallout.PostOfficeData> result = AsyncCallout.getPostOfficeData('Madhapur');

for (AsyncCallout.PostOfficeData office : result) {
    System.debug(office.name + ' - ' + office.pincode);
}
```

---

## 🛡 Best Practices

- ✅ Use `EncodingUtil.urlEncode()` to handle special characters
- ✅ Check `response.getStatusCode()` before parsing
- ✅ Use wrapper classes for maintainable data mapping
- ✅ Wrap logic in try-catch blocks for safe callouts
- ⚠️ Always add `@future(callout=true)` or `Queueable` if calling this from a trigger or async context

---

**Note: Please add the URL in Remote Site Settings.**


## 👨‍💻 Author

**Sandeep Talari**  
*Product Engineer @ Maxval | Salesforce Developer | Rising Star 🏆*
