# Lab 4: Elasticsearchi päringud algajatele

## 1. Ettevalmistus

### 1.1 Testkeskkonna loomine
```json
PUT /pood
{
  "mappings": {
    "properties": {
      "nimi": { "type": "text" },
      "hind": { "type": "float" },
      "kategooria": { "type": "keyword" },
      "laos": { "type": "boolean" }
    }
  }
}
```

### 1.2 Näidisandmete lisamine
```json
POST /pood/_bulk
{"index":{}}
{"nimi":"Nike jooksujalatsid","hind":99.99,"kategooria":"jalatsid","laos":true}
{"index":{}}
{"nimi":"Adidas t-särk","hind":29.99,"kategooria":"riided","laos":true}
{"index":{}}
{"nimi":"Tennis pall","hind":4.99,"kategooria":"sport","laos":false}
```

## 2. Lihtsad päringud

### Ülesanne 2.1: Kõikide toodete otsimine
```json
GET /pood/_search
{
  "query": {
    "match_all": {}
  }
}
```
📝 Proovi ja vaata tulemusi

### Ülesanne 2.2: Tekstiotsing
```json
GET /pood/_search
{
  "query": {
    "match": {
      "nimi": "Nike"
    }
  }
}
```
📝 Proovi otsida erinevate sõnadega

## 3. Filtreerimine

### Ülesanne 3.1: Hinnavahemiku filter
```json
GET /pood/_search
{
  "query": {
    "range": {
      "hind": {
        "gte": 20,
        "lte": 100
      }
    }
  }
}
```
📝 Muuda hinnavahemikku ja vaata tulemusi

### Ülesanne 3.2: Kategooria filter
```json
GET /pood/_search
{
  "query": {
    "term": {
      "kategooria": "sport"
    }
  }
}
```
📝 Proovi erinevate kategooriatega

## 4. Kombineeritud päringud

### Ülesanne 4.1: Tekst + hind
```json
GET /pood/_search
{
  "query": {
    "bool": {
      "must": [
        { "match": { "nimi": "Nike" }},
        { "range": { "hind": { "lte": 100 }}}
      ]
    }
  }
}
```

### Ülesanne 4.2: Laos olevad tooted kategooriast
```json
GET /pood/_search
{
  "query": {
    "bool": {
      "must": [
        { "term": { "kategooria": "jalatsid" }},
        { "term": { "laos": true }}
      ]
    }
  }
}
```

## 5. Sorteerimine

### Ülesanne 5.1: Hinna järgi sorteerimine
```json
GET /pood/_search
{
  "sort": [
    { "hind": "asc" }
  ],
  "query": {
    "match_all": {}
  }
}
```
## Lisaülesanded (kui jõuad)

1. Proovi hägust otsingut
```json
GET /pood/_search
{
  "query": {
    "fuzzy": {
      "nimi": {
        "value": "Nika",
        "fuzziness": "AUTO"
      }
    }
  }
}
```

2. Kasuta lehekülgede kaupa kuvamist
```json
GET /pood/_search
{
  "from": 0,
  "size": 2,
  "query": {
    "match_all": {}
  }
}
```