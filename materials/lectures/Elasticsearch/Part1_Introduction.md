# Lecture 1: Elasticsearch Introduction

### Mis on ELK?

![ELK](https://s3-ap-south-1.amazonaws.com/trt-blog-ghost/2023/01/The-Elastic-Stack.jpg)

Elastic Stack on avatud lähtekoodiga tööriistade komplekt andmete analüüsiks, töötlemiseks, salvestamiseks ja visualiseerimiseks. Seda tuntakse kui ELK Stack (Elasticsearch, Logstash, Kibana), kuhu kuulub ka Beats.

## Kibana – andmete visualiseerimine
**Kibana** pakub sektordiagramme, joondiagramme, histogramme ja kaarte. Sellega saab visualiseerida Elasticsearchi andmeid ja kujundada soovitud viisil.

## Logstash – andmete töötlemine
**Logstash** kogub ja töötleb andmeid erinevatest allikatest ning saadab need Elasticsearchi.

![Introduction to Elasticsearch Architecture](https://miro.medium.com/v2/resize:fit:720/format:webp/1*rfcn4XSrNI1KZFbq89l7Jw.png)

*Introduction to Elasticsearch Architecture*

*Source: [Medium](https://medium.com)*

![Elasticsearch Scaling Strategies](https://miro.medium.com/v2/resize:fit:720/format:webp/1*c-7HdcP9m17PEi2a0qLg_w.png)

*Elasticsearch Scaling Strategies*

*Source: [Medium](https://medium.com)*


## Beats – andmete saatmine
**Beats** on kergkaalulised agendid, mis saadavad andmeid masinatest Logstashi või otse Elasticsearchi. Näiteks: **Filebeat** jälgib logifaile ja impordib need.

Elastic Stack tsentraliseerib andmed ja pakub võimsaid tööriistu analüüsiks ja visualiseerimiseks.

![Elasticsearchi](https://www.bigdatawire.com/wp-content/uploads/2019/03/elasticsearch_logo.png)

![ELK TLS Docker Diagram](https://raw.githubusercontent.com/wiki/swimlane/elk-tls-docker/images/elk-tls-docker-diagram.png)

*ELK TLS Docker Architecture Diagram*

*Source: [Swimlane GitHub Wiki](https://github.com/swimlane/elk-tls-docker/wiki)*

### Beats Family Table

| **Beat**       | **Purpose**                                                                                                                                                                |
|-----------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Filebeat**   | Lightweight shipper for logs and other data. Collects logs from various sources like security devices, cloud, containers, hosts, and OT, simplifying log forwarding. (7)   |
| **Metricbeat** | Lightweight shipper for metric data. Gathers system and service metrics, such as CPU, memory, Redis, NGINX, and more. Simplifies system and service monitoring. (8)       |
| **Packetbeat** | Lightweight shipper for network data, enabling real-time monitoring of network activity.                                                                                   |
| **Winlogbeat** | Lightweight shipper for Windows event logs, focused on centralizing Windows-specific log data.                                                                             |
| **Auditbeat**  | Lightweight shipper for audit data, designed for security auditing and compliance monitoring.                                                                              |
| **Heartbeat**  | Lightweight shipper for uptime monitoring. Automates anomaly detection and accelerates root cause analysis with AIOps. (9)                                                |

### Mis on Elasticsearch?

Elasticsearch on avatud lähtekoodiga hajutatud otsingu- ja analüüsimootor, mis on loodud horisontaalseks skaleeritavuseks, reaalajas otsinguks ja kõrgeks töökindluseks. Kuuludes NoSQL-andmebaaside hulka, on see ehitatud Apache Lucene otsingumootori raamatukogu peale.

Elasticsearchi kasutatakse laialdaselt:
- Logide ja sündmuste andmete analüüsiks
- Täistekstiotsinguks
- Ärilisteks analüütikateks
- Rakenduste jälgimiseks

Elasticsearch salvestab andmeid skeemivabas JSON-formaadis, mis teeb selle paindlikuks ja kohanemisvõimeliseks erinevate andmemudelite ja struktuuridega. Hajutatud RESTful API abil saavad arendajad hõlpsasti teostada keerukaid otsinguid, koondamisi ja analüüse suurte andmekogumite põhjal.

### Elasticsearchi põhifunktsioonid:

| **Funktsioon**                  | **Kirjeldus**                                                                                                                                                       |
|----------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Hajutatud ja skaleeritav**    | Loodud hajutatud keskkonna jaoks, võimaldades horisontaalset skaleerimist mitme sõlme vahel ning lihtsat sõlmede lisamist kasvava töökoormuse tarbeks.               |
| **Reaalajas otsing ja analüütika** | Võimaldab peaaegu reaalajas andmepäringuid ja analüüsi, tagades ajakohased ülevaated kiiresti muutuvate andmekogumite põhjal.                                        |
| **Täistekstiotsing**            | Võimas täistekstiotsingu tugi keerukate päringute jaoks, sh hägusad otsingud, metamärgid ja lähedusotsingud, kasutades päringu DSL-i.                                |
| **Skeemivabad JSON-dokumendid** | Andmed salvestatakse skeemivabade JSON-dokumentidena, mis võimaldab paindlikkust andmestruktuuri muutmisel.                                                       |
| **Kõrge töökindlus ja veataluvus** | Sisseehitatud andmete replikatsioon ja veataluvus tagavad töökindluse ka rikete korral, hajutades andmed ja säilitades replikad mitme sõlme vahel.                |
| **RESTful API**                 | Intuitiivne RESTful API standardsete HTTP-meetoditega (GET, POST, PUT, DELETE), mis muudab süsteemi lihtsasti kasutatavaks erinevate programmeerimistasemete jaoks. |
| **Rikkalikud päringu- ja koondamisvõimalused** | Lai valik tööriistu keerukate andmeanalüüside ja visualiseerimiste teostamiseks, kasutades mõõdikuid, histogramme ja segmentimistoiminguid.                     |

---

### Elasticsearchi roll DevOpsis:

Ülevaade Elasticsearchi kasutusaladest:  

| **Kasutusvaldkond**       | **Kirjeldus**                                                                                                                                                           | **Näited**                                                                                   |
|---------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| **Logihaldus ja analüüs** | **Tsentraliseeritud logimine**: Elasticsearch kogub ja hoiab logisid erinevatest süsteemidest, tehes need analüüsimiseks kergesti kättesaadavaks.                           | Rakenduse tõrkeotsing, infrastruktuuri jälgimine                                           |
|                           | **Reaalajas jälgimine**: Võimaldab jälgida süsteemi tervist ja jõudlust reaalajas, tuvastada anomaaliaid ja kitsaskohti.                                                 | Serveri jõudluse mõõdikud, API kasutuse analüüs                                            |
|                           | **Hoiatused ja teavitused**: Integreerub automaatsete hoiatusmehhanismidega, et ennetada probleeme enne, kui need mõjutavad süsteemi tööd.                                  | E-posti teated, Slacki teavitused kriitiliste sündmuste korral                            |
| **Andmeotsing ja analüüs**| **Kiire otsing ja filtreerimine**: Elasticsearch indekseerib andmed viisil, mis muudab kiire ja tõhusa otsingu võimalikuks.                                               | E-kaubanduse otsing, logianalüüs                                                           |
|                           | **Andmeanalüütika**: Elasticsearchi abil saab läbi viia keerukaid analüüse, kasutades aggregatsioone ja visualiseerides tulemusi (nt Kibana abil).                         | Müügimustrite analüüs, trendide tuvastamine                                                |
| **Masinõpe ja AI**        | **Anomaaliate tuvastamine**: Masinõppe algoritme saab kasutada ebatavalise käitumise tuvastamiseks andmevoogudes.                                                        | Panga kahtlaste tehingute tuvastamine, küberrünnakute jälgimine                            |
|                           | **Kohandatud ML-mudelid**: Elasticsearch toetab kohandatud masinõppemudelite kasutamist, et rikastada analüüse ja otsuseid.                                             | Prognoosimudelid, klassifikatsioon                                                        |
| **Andmete tsentraliseerimine**| **Erinevate andmeallikate ühendamine**: Elasticsearch saab andmeid indekseerida erinevatest allikatest, pakkudes ühtset platvormi analüüsideks ja ülevaadeteks.                  | ERP ja CRM süsteemide integreeritud vaade                                                  |
| **Jõudluse optimeerimine**| **Reaalajas päringud ja andmetöötlus**: Optimeeritud otsingumootorina sobib Elasticsearch suure andmemahu kiireks töötlemiseks ja andmeanalüüsiks.                         | Logide töötlemine miljonite sündmuste hulgast, veebilehe otsingumootor                     |
| **Audit ja turvalisus**   | **Auditlogide haldus**: Võimaldab säilitada ja analüüsida auditeerimise eesmärgil logisid ning vastavuse jälgimist.                                                      | IT süsteemide turbeauditid, vastavusnõuete analüüs                                         |
|                           | **Küberturvalisus**: Elasticsearch aitab tuvastada ja analüüsida turvalisuse anomaaliaid, et ennetada küberrünnakuid ja turbeintsidente.                                  | IPS/IDS süsteemide andmeanalüüs, kahtlase liikluse jälgimine                               |

---

### Olulised mõisted: 

![Component Relation](https://miro.medium.com/v2/resize:fit:1200/1*jLRM0WF8p-uxwWZzuhMYcA.png)

| **Mõiste**              | **Kirjeldus**                                                                                                         | **Näide**                                                                                         |
|-------------------------|-----------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------|
| **Node**               | Üksik Elasticsearchi instants, mis töötab ühel masinal. Igal sõlmel on kindel roll klastris.                           | Andmesõlm, mis salvestab logifaile; koordineeriv sõlm, mis edastab päringuid.                     |
| **Cluster**            | Ühe või mitme sõlme kogum, mis töötavad koos andmete salvestamiseks ja haldamiseks.                                   | Klastris on 3 sõlme: 2 andmesõlme ja 1 master-kõlblik sõlm.                                       |
| **Index**              | Loogiline nimeruum, mis esindab dokumentide kogumit sarnaste omadustega.                                              | Logide indeks, mis sisaldab serverite vigade ja päringute andmeid.                                |
| **Shard**              | Indeksi andmesalvestuse üksik osa, mis võimaldab andmeid jaotada sõlmede vahel.                                        | Indeks "server_logs" on jagatud 5 shardiks, millest igal ühel on oma replika.                     |
| **Replication**        | Protsess shardide koopiate loomise ja hoidmise kohta mitmes sõlmes.                                                   | Indeksi iga shard on replitseeritud 1 kord, tagades andmete kättesaadavuse isegi ühe sõlme tõrke korral. |
| **Cluster State**      | Klastri konfiguratsiooni ja metaandmete globaalne hoidla, mis sisaldab indeksite ja shardide jaotuse infot.           | Klastri olek salvestab teavet uue indeksi loomise ja shardide jaotuse kohta sõlmede vahel.         |

