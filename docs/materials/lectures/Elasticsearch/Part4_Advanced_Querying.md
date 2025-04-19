# Lecture 4: Elasticsearchi päringud

- [Lecture 4: Elasticsearchi päringud](#lecture-4-elasticsearchi-päringud)
  - [1. Query DSL põhikomponendid](#1-query-dsl-põhikomponendid)
  - [2. Liitpäringud](#2-liitpäringud)
  - [3. Täistekstotsing ja hägus otsing](#3-täistekstotsing-ja-hägus-otsing)
  - [4. Lehekülgede kaupa kuvamine ja sorteerimine](#4-lehekülgede-kaupa-kuvamine-ja-sorteerimine)


## 1. Query DSL põhikomponendid

Query DSL on Elasticsearchi enda päringukeel, mis võimaldab meil luua keerukaid otsinguid. See koosneb neljast põhikomponendist:

| Komponent | Kirjeldus | Näide |
|-----------|-----------|--------|
| Query | Põhiline otsingu element | `{"match": {...}}` |
| Filter | Filtreerib tulemusi | `{"term": {...}}` |
| Aggregations | Statistilised operatsioonid | `{"aggs": {...}}` |
| Sort | Tulemuste sorteerimine | `{"sort": [...]}` |

Vaatame lihtsat Query DSL näidet:
```json
{
  "query": {
    "match": {
      "title": "Elasticsearch"
    }
  }
}
```

See päring otsib kõiki dokumente, mille pealkirjas esineb sõna "Elasticsearch".

## 2. Liitpäringud

Liitpäringud võimaldavad meil kombineerida mitu erinevat otsingutingimust. Need on eriti kasulikud keerukamate otsingute jaoks.

| Päringu tüüp | Kirjeldus | Kasutus |
|--------------|-----------|---------|
| bool | Kombineerib mitu päringut | Keerukad otsingud |
| must | Peab vastama kõigile tingimustele | AND operatsioon |
| must_not | Ei tohi vastata tingimustele | NOT operatsioon |
| should | Võib vastata tingimustele | OR operatsioon |

Näiteks kui soovime leida Elasticsearchi artikleid, millel on vähemalt 1000 vaatamist:
```json
{
  "query": {
    "bool": {
      "must": [
        { "match": { "title": "Elasticsearch" }},
        { "range": { "views": { "gte": 1000 }}}
      ]
    }
  }
}
```

## 3. Täistekstotsing ja hägus otsing

Täistekstotsing on üks Elasticsearchi võimsamaid funktsioone. See võimaldab meil otsida teksti dokumentide sisust.

| Otsingu tüüp | Kasutus | Näide |
|--------------|---------|--------|
| Match | Tavaline tekstiotsing | `{"match": {"description": "otsing"}}` |
| Fuzzy | Hägus otsing | `{"fuzzy": {"title": {"value": "elastik"}}}` |

Hägus otsing on eriti kasulik, kui kasutajad teevad trükivigu. Näiteks:
```json
{
  "query": {
    "fuzzy": {
      "title": {
        "value": "elastiksearch",
        "fuzziness": "AUTO"
      }
    }
  }
}
```

See päring leiab dokumendid isegi kui kasutaja kirjutas "Elasticsearch" valesti.

## 4. Lehekülgede kaupa kuvamine ja sorteerimine

Suurte andmehulkade puhul on oluline tulemusi lehekülgede kaupa kuvada ja sorteerida.

| Parameeter | Kirjeldus | Vaikeväärtus |
|------------|-----------|--------------|
| from | Alguspositsioon | 0 |
| size | Tulemuste arv | 10 |
| sort | Sorteerimise väli | _score |

Näide kuidas kuvada 20 tehnoloogia kategooria artiklit, sorteerituna kuupäeva järgi:
```json
{
  "from": 0,
  "size": 20,
  "sort": [
    { "date": { "order": "desc" }}
  ],
  "query": {
    "match": {
      "category": "Technology"
    }
  }
}
```