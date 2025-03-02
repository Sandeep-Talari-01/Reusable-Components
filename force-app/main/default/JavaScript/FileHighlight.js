 

import getKeywordColorMap from "@salesforce/apex/CommonUtility.getKeywordColorMap"; 

const contentDocumentLinkColumns = [
    {
      label: "File Name",
      fieldName: "id",
      type: "filePreview",
      sortable: "true",
      wrapText: true,
      typeAttributes: {
        anchorText: { fieldName: "title" },
        versionId: { fieldName: "latestVersionId" }
      },
      cellAttributes: { alignment: 'center' , class: { fieldName: 'cssClass' }}
    },
    { label: "Uploaded Date", fieldName: "createdDate", sortable: "true", type: "date" ,cellAttributes: { alignment: 'center' , class: { fieldName: 'cssClass' }}},
    { label: "Uploaded by", fieldName: "createdBy", wrapText: true, sortable: "true", type: "string",cellAttributes: { alignment: 'center' , class: { fieldName: 'cssClass' }} },
    { type: "action", typeAttributes: { rowActions: actions },cellAttributes: { alignment: 'center' , class: { fieldName: 'cssClass' }} }
  ];
files=[];
// Get the keyword color map from the server
 getKeywordColorMap()
      .then(result => {
        if (result) {
          console.log('Metadata result--->', JSON.stringify(result));

          const excludeKeywordsList = result.excludeKeywordsList || [];
          const includeMap = result.includeMap || {};

          const keywordColorMap = new Map();
          Object.keys(includeMap).forEach(colorCode => {
            const keywords = includeMap[colorCode];
            keywords.forEach(keyword => {
              const processedKeyword = keyword.toLowerCase().trim();
              
              keywordColorMap.set(processedKeyword, {
                original: keyword,
                exact: processedKeyword,
                colorCode: colorCode
              });
            });
          });

          console.log('keywordColorMap--->', JSON.stringify(Object.fromEntries(keywordColorMap)));

          const processedExcludeKeywords = excludeKeywordsList.map(keyword => 
            keyword.toLowerCase().trim()
          );

          this.files = this.files.map(row => {
            const lowerCaseTitle = row.title.toLowerCase().trim();
            const titleWords = lowerCaseTitle.split(/\s+/);

            const shouldExclude = processedExcludeKeywords.some(excludeKeyword => {
              const excludeWords = excludeKeyword.split(/\s+/);
              
              let foundIndex = -1;
              return excludeWords.every((word, index) => {
                if (index === 0) {
                  foundIndex = titleWords.findIndex(titleWord => 
                    titleWord === word
                  );
                  return foundIndex !== -1;
                } else {
                  const nextWordIndex = foundIndex + index;
                  return nextWordIndex < titleWords.length && 
                  titleWords[nextWordIndex] === word;
                }
              });
            });

            if (shouldExclude) {
              console.log('File excluded due to matching exclude keyword:', lowerCaseTitle);
              return row;
            }

            for (const [keyword, matchInfo] of keywordColorMap) {
              if (lowerCaseTitle === keyword) {
                const colorClass = 'slds-icon-custom-' + matchInfo.colorCode + ' slds-text-color_default';
                console.log('Exact match found for keyword:', keyword, 'Color code:', matchInfo.colorCode);
                return {
                  ...row,
                  cssClass: colorClass
                };
              }
            }

            let bestMatch = null;
            let bestMatchLength = 0;

            for (const [keyword, matchInfo] of keywordColorMap) {
              const keywordWords = keyword.split(/\s+/);
              
              let foundIndex = -1;
              const isMatch = keywordWords.every((word, index) => {
                if (index === 0) {
                  foundIndex = titleWords.findIndex(titleWord => 
                    titleWord.includes(word) || word.includes(titleWord)
                  );
                  return foundIndex !== -1;
                } else {
                  const nextWordIndex = foundIndex + index;
                  return nextWordIndex < titleWords.length && 
                    (titleWords[nextWordIndex].includes(word) || 
                    word.includes(titleWords[nextWordIndex]));
                }
              });

              if (isMatch && keyword.length > bestMatchLength) {
                bestMatch = matchInfo;
                bestMatchLength = keyword.length;
              }
            }

            if (bestMatch) {
              const colorClass = 'slds-icon-custom-' + bestMatch.colorCode + ' slds-text-color_default';
              console.log('Partial match found for keyword:', bestMatch.exact, 'Color code:', bestMatch.colorCode);
              return {
                ...row,
                cssClass: colorClass 
              };
            }

            return row;
          });

          console.log('Updated files--->', JSON.stringify(this.files));
        }
      })
      .catch(error => {
        console.log('Error in getKeywordColorMap:', error);
      }); 
      












