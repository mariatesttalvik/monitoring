# Lab 5: Elasticsearch Agregatsioonid

### Eeldused
- Elasticsearch 7.x või uuem
- Töötav Kibana instance

### Testandmete Ettevalmistus

#### Variant 1: Eelmise Praktikumi Andmed
Kui olete läbinud Praktikum 4, kasutage selles loodud e-poe andmebaasi. See sisaldab vajalikke välju:
- summa
- kategooria
- kuupäev
- piirkond
- tellimus_id

#### Variant 2: Uute Testandmete Laadimine
Kui teil pole eelmise praktikumi andmeid, loome uue andmebaasi:

```json
// 1. Loome indeksi
PUT /epood
{
  "mappings": {
    "properties": {
      "summa": { "type": "float" },
      "kategooria": { "type": "keyword" },
      "kuupäev": { "type": "date" },
      "piirkond": { "type": "keyword" },
      "tellimus_id": { "type": "keyword" }
    }
  }
}

// 2. Lisame näidisandmed
POST /epood/_bulk
{"index":{}}
{"summa": 150.50, "kategooria": "Elektroonika", "kuupäev": "2024-01-15", "piirkond": "Tallinn", "tellimus_id": "T001"}
{"index":{}}
{"summa": 75.20, "kategooria": "Raamatud", "kuupäev": "2024-01-15", "piirkond": "Tartu", "tellimus_id": "T002"}
{"index":{}}
{"summa": 299.99, "kategooria": "Elektroonika", "kuupäev": "2024-01-16", "piirkond": "Pärnu", "tellimus_id": "T003"}
// ... lisage veel 7-10 näidiskirjet
```

#### Andmete Kontroll
Kontrollige andmete olemasolu:
```json
GET /epood/_search
{
  "size": 1,
  "query": {
    "match_all": {}
  }
}
```

### Ülesanne 1: Põhilised Meetrika Agregatsioonid

#### 1.1 Kogumüügi Analüüs
```json
// Arvuta kogumüük
POST /epood/_search
{
  "size": 0,
  "aggs": {
    "kogu_müük": {
      "sum": {
        "field": "summa"
      }
    }
  }
}

// Oodatav väljund:
{
  "aggregations": {
    "kogu_müük": {
      "value": 125789.45
    }
  }
}
```

#### 1.2 Keskmise Tellimuse Suurus
```json
POST /epood/_search
{
  "size": 0,
  "aggs": {
    "keskmine_tellimus": {
      "avg": {
        "field": "summa"
      }
    }
  }
}
```

✍️ **Ülesanne**: Lisage juurde `stats` agregatsioon, mis arvutab min, max, avg, sum ja count väärtused.

### Ülesanne 2: Bucketing Agregatsioonid

#### 2.1 Müük Kategooriate Lõikes
```json
POST /epood/_search
{
  "size": 0,
  "aggs": {
    "kategooriad": {
      "terms": {
        "field": "kategooria.keyword",
        "size": 5
      },
      "aggs": {
        "käive": {
          "sum": {
            "field": "summa"
          }
        }
      }
    }
  }
}
```

📝 **Ülesanne**: Muutke päringut nii, et näeks ka keskmist tellimuse suurust iga kategooria kohta.

#### 2.2 Ajaline Analüüs
```json
POST /epood/_search
{
  "size": 0,
  "aggs": {
    "müük_kuude_kaupa": {
      "date_histogram": {
        "field": "kuupäev",
        "calendar_interval": "month"
      },
      "aggs": {
        "käive": {
          "sum": {
            "field": "summa"
          }
        }
      }
    }
  }
}
```

### Ülesanne 3: Komplekssed Agregatsioonid

#### 3.1 Müük Piirkondade ja Kategooriate Lõikes
```json
POST /epood/_search
{
  "size": 0,
  "aggs": {
    "piirkonnad": {
      "terms": {
        "field": "piirkond.keyword",
        "size": 10
      },
      "aggs": {
        "kategooriad": {
          "terms": {
            "field": "kategooria.keyword",
            "size": 5
          },
          "aggs": {
            "käive": {
              "sum": {
                "field": "summa"
              }
            }
          }
        }
      }
    }
  }
}
```

🔍 **Analüüsiülesanne**: 
1. Millisel piirkonnal on suurim käive?
2. Millised kategooriad on populaarseimad eri piirkondades?

### Ülesanne 4: Pipeline Agregatsioonid

#### 4.1 Müügi Kasv
```json
POST /epood/_search
{
  "size": 0,
  "aggs": {
    "müük_kuude_kaupa": {
      "date_histogram": {
        "field": "kuupäev",
        "calendar_interval": "month"
      },
      "aggs": {
        "käive": {
          "sum": {
            "field": "summa"
          }
        },
        "käibe_kasv": {
          "derivative": {
            "buckets_path": "käive"
          }
        }
      }
    }
  }
}
```

### Ülesanne 5: Visualiseerimine Kibanas

#### 5.1 Tulpdiagrammi Loomine (Vertical Bar Chart)
1. Avage Kibana -> Analytics -> Visualize Library
2. Vajutage "Create visualization"
3. Valige "Vertical bar" visualization
4. Seadistage agregatsiooni:
   ```
   Buckets:
   - X-axis: Terms aggregation
   - Field: kategooria.keyword
   - Size: 10
   Metrics:
   - Y-axis: Sum aggregation
   - Field: summa
   ```
5. Täiendavad seaded:
   - Lisage Labels
   - Valige sobiv värvipalett
   - Seadistage telgede pealkirjad

#### 5.2 Joondiagramm (Line Chart)
1. Looge uus visualiseering
2. Valige "Line" visualization
3. Seadistage:
   ```
   Buckets:
   - X-axis: Date Histogram
   - Field: kuupäev
   - Interval: Monthly
   Metrics:
   - Y-axis: Sum of summa
   ```
4. Kujunduse seaded:
   - Punktide kuvamine
   - Joone stiil
   - Värvi valik
   - Legend

#### 5.3 Dashboard Loomine
1. Minge Dashboards -> Create dashboard
2. Lisage eelnevalt loodud visualiseeringud:
   - Vajutage "Add from library"
   - Valige loodud visualiseeringud
3. Paigutuse seadistamine:
   - Lohistage visualiseeringud soovitud asukohta
   - Muutke suurusi vastavalt vajadusele
4. Dashboard seaded:
   - Lisage pealkiri
   - Seadistage värskendusintervall
   - Määrake ajavahemiku filter

#### 5.4 Täiendavad Visualiseeringud
1. Heat Map (Soojuskaart):
   ```
   Visualization: Heat Map
   Settings:
   - X-axis: Date Histogram (kuupäev)
   - Y-axis: Terms (kategooria)
   - Values: Sum of summa
   ```

2. Metrics (Mõõdikud):
   ```
   Visualization: Metric
   Settings:
   - Metric: Sum of summa
   - Secondary metric: Unique count of tellimus_id
   ```

3. Area Chart (Pinddiagramm):
   ```
   Settings:
   - X-axis: Date Histogram
   - Y-axis: Sum of summa
   - Break down by: kategooria
   - Stacking: Normal
   ```

#### 5.5 Visualiseeringute Eksportimine
1. Dashboardi salvestamine:
   - Vajutage "Save"
   - Määrake nimi ja kirjeldus
2. Eksportimine:
   - CSV formaadis andmed
   - PNG/PDF raportid
   - Dashboardi jagamine


### Abimaterjalid

1. Elasticsearch dokumentatsioon: [Aggregations](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations.html)
2. Kibana dokumentatsioon: [Visualizations](https://www.elastic.co/guide/en/kibana/current/visualize.html)
