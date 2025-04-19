## Lab 3: Searching and Querying

During this lab, you created indices, added data, performed searches and aggregations, and experimented with relevance boosting techniques. These skills are essential for managing and analyzing large datasets in Elasticsearch.

### **1. Creating an Index and Preparing Data**

1. Create a new index with the necessary structure:

```json
PUT /products
{
  "mappings": {
    "properties": {
      "title": { "type": "text" },
      "author": {
        "type": "text",
        "fields": {
          "keyword": { "type": "keyword" }
        }
      },
      "price": { "type": "float" },
      "published_date": { "type": "date" }
    }
  }
}
```

2. Add sample documents:

```json
POST /products/_bulk
{ "index": {} }
{ "title": "Elasticsearch Basics", "author": "Navya", "price": 100, "published_date": "2023-01-10" }
{ "index": {} }
{ "title": "Advanced Search Techniques", "author": "John Doe", "price": 200, "published_date": "2023-05-15" }
{ "index": {} }
{ "title": "Query DSL Guide", "author": "Jane Smith", "price": 150, "published_date": "2022-10-20" }
```

### **2. Simple Searches**

1. Search for documents where the title contains the word "Elasticsearch":

```json
GET /products/_search
{
  "query": {
    "match": {
      "title": "Elasticsearch"
    }
  }
}
```

2. Search for documents where the author is "John Doe":

```json
GET /products/_search
{
  "query": {
    "term": {
      "author.keyword": "John Doe"
    }
  }
}
```

3. Search for documents where the price is between 100 and 200:

```json
GET /products/_search
{
  "query": {
    "range": {
      "price": {
        "gte": 100,
        "lte": 200
      }
    }
  }
}
```

### **3. Boolean Queries**

1. Find documents where:
   - The title contains "Search"
   - The price is greater than 100.

```json
GET /products/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "title": "Search" }},
        { "range": { "price": { "gte": 100 }} }
      ]
    }
  }
}
```

### **4. Aggregations**

1. Group documents by authors:

```json
GET /products/_search
{
  "aggs": {
    "authors": {
      "terms": {
        "field": "author.keyword"
      }
    }
  }
}
```

2. Display the number of posts per month:

```json
GET /products/_search
{
  "aggs": {
    "posts_per_month": {
      "date_histogram": {
        "field": "published_date",
        "calendar_interval": "month"
      }
    }
  }
}
```

3. Split prices into ranges and display counts:

```json
GET /products/_search
{
  "aggs": {
    "price_ranges": {
      "range": {
        "field": "price",
        "ranges": [
          { "from": 0, "to": 100 },
          { "from": 100, "to": 200 },
          { "from": 200 }
        ]
      }
    }
  }
}
```

### **5. Relevance Boosting**

1. Boost the relevance of documents where specific terms appear in the title:

```json
GET /products/_search
{
  "query": {
    "multi_match": {
      "query": "Elasticsearch tutorial",
      "fields": ["title^2", "description"]
    }
  }
}
```

2. Use date-based relevance boosting:

```json
GET /products/_search
{
  "query": {
    "function_score": {
      "query": { "match_all": {} },
      "functions": [
        {
          "gauss": {
            "published_date": {
              "origin": "2023-01-01",
              "scale": "30d"
            }
          }
        }
      ]
    }
  }
}
```

---

### Additional Exercises

1. **Autocomplete:**

   - Create an index with an ngram analyzer:

   ```json
   PUT /autocomplete
   {
     "settings": {
       "analysis": {
         "analyzer": {
           "ngram_analyzer": {
             "type": "custom",
             "tokenizer": "ngram_tokenizer"
           }
         },
         "tokenizer": {
           "ngram_tokenizer": {
             "type": "ngram",
             "min_gram": 2,
             "max_gram": 3,
             "token_chars": ["letter"]
           }
         }
       }
     },
     "mappings": {
       "properties": {
         "name": {
           "type": "text",
           "analyzer": "ngram_analyzer",
           "search_analyzer": "standard"
         }
       }
     }
   }
   ```

2. **Statistical Analysis:**

   - Retrieve price statistics:

   ```json
   GET /products/_search
   {
     "aggs": {
       "price_stats": {
         "stats": {
           "field": "price"
         }
       }
     }
   }
   ```

---
