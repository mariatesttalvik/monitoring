# TICK Stack

## Mis on TICK Stack?

TICK Stack on avatud lähtekoodiga tarkvara kogum, mis on mõeldud ajaseeria andmete (time series data) töötlemiseks. "TICK" on lühend, mis tuleb neljast peamisest komponendist:

- **T**elegraf - andmete kogumise tööriist
- **I**nfluxDB - andmebaas andmete salvestamiseks
- **C**hronograf - visuaalne kasutajaliides
- **K**apacitor - andmete töötlemise ja häirete süsteem

## TICK Stack komponendid tabelina

| Komponent | Funktsioon | Alternatiivid | Port |
|-----------|------------|---------------|------|
| **Telegraf** | Andmete kogumine | Prometheus exporters, Collectd, Beats | 8125 |
| **InfluxDB** | Andmete säilitamine | Prometheus, TimescaleDB, OpenTSDB | 8086 |
| **Chronograf** | Visualiseerimine | Grafana, Kibana, Datadog UI | 8888 |
| **Kapacitor** | Andmetöötlus ja häired | Prometheus Alertmanager, Nagios, ElastAlert | 9092 |

## Andmetüübid, mida saab jälgida

| Kategooria | Näited | Jälgimise kasu |
|------------|--------|----------------|
| **Süsteemi ressursid** | CPU, mälu, kettakasutus | Ressursside puuduse ennetamine |
| **Võrk** | Latentsus, läbilaskevõime, paketikadu | Võrguprobleemide tuvastamine |
| **Rakendused** | Vastusaeg, veateated, API päringud | Rakenduste jõudluse parandamine |
| **Andmebaasid** | Päringute arv, täitmisaeg, ühenduste arv | Andmebaasi optimeerimise võimaluste leidmine |
| **Kasutajate aktiivsus** | Sisselogimised, lehekülje vaatamised, ostud | Kasutajakogemuse parandamine |

## Lihtsustatud arhitektuur

```
┌────────────────────┐
│   ANDMEALLIKAD     │ ← Serverid, rakendused, seadmed, sensorid jne
└──────────┬─────────┘
           │
           ▼
┌────────────────────┐
│      TELEGRAF      │ ← Kogub andmeid erinevatest allikatest
└──────────┬─────────┘
           │
           ▼
┌────────────────────┐
│      INFLUXDB      │ ← Salvestab ajaseeria andmed
└────┬─────────┬─────┘
     │         │
     ▼         ▼
┌─────────┐ ┌────────────┐
│CHRONOGRAF│ │ KAPACITOR  │ ← Visualiseerimine ja häirete loomine
└─────────┘ └────────────┘
```

## Komponendid

### 📊 Telegraf - Andmete koguja

**Mis see on?** Telegraf on nagu "koristaja", kes käib ringi ja korjab andmeid kokku.

**Mida see teeb?**
- Kogub erinevaid näitajaid (meetrikaid) sinu süsteemidest
- Suudab koguda andmeid paljudest erinevatest kohtadest (serverid, võrguseadmed, andmebaasid jne)
- Töötab väga efektiivselt ja vajab vähe ressursse

**Näide elust:** Kujuta ette, et Telegraf on nagu elektriarvesti, mis pidevalt jälgib, kui palju elektrit sinu kodu erinevad seadmed tarbivad.

**Kuidas see töötab:**
1. Paigaldad Telegraf oma serverisse või arvutisse
2. Määrad seadistustes, milliseid andmeid soovid koguda
3. Telegraf hakkab automaatselt andmeid koguma ja saatma InfluxDB-sse

### 💾 InfluxDB - Andmete säilitaja

**Mis see on?** InfluxDB on spetsiaalne andmebaas, mis on optimeeritud just ajaseeria andmete salvestamiseks.

**Mida see teeb?**
- Salvestab suuri koguseid ajaseeria andmeid kiiresti ja efektiivselt
- Võimaldab neid andmeid hiljem pärida ja analüüsida
- Suudab töödelda miljoneid andmepunkte sekundis

**Näide elust:** InfluxDB on nagu digitaalne päevik, mis salvestab automaatselt kõik sündmused koos täpse ajatempliga.

**Põhimõisted:**
- **Mõõtmised** (measurements) - andmete kategooriad (nt. CPU kasutus, temperatuur)
- **Väljad** (fields) - tegelikud väärtused (nt. CPU kasutus = 75%)
- **Sildid** (tags) - meta-andmed, mille järgi saab andmeid filtreerida (nt. server = "web-1")
- **Ajatempel** (timestamp) - millal andmed salvestati

### 📈 Chronograf - Andmete visualiseerija

**Mis see on?** Chronograf on veebirakendus, mis võimaldab sul näha ja visualiseerida InfluxDB-s olevaid andmeid.

**Mida see teeb?**
- Loob graafikuid ja visuaalseid töölaudu (dashboards)
- Võimaldab andmeid uurida ilma keerulisi päringuid kirjutamata
- Aitab häireid ja teateid seadistada

**Näide elust:** Chronograf on nagu ilmateade, mis näitab sulle graafiliselt, kuidas temperatuur, niiskus ja õhurõhk on päeva jooksul muutunud.

**Miks see on kasulik:**
- Lihtne graafiline kasutajaliides
- Ei vaja programmeerimisoskusi
- Saad kiiresti ülevaate oma süsteemide seisundist

### ⚡ Kapacitor - Andmete töötleja ja häiresüsteem

**Mis see on?** Kapacitor on mootor, mis võimaldab andmeid töödelda ja nende põhjal häireid luua.

**Mida see teeb?**
- Analüüsib andmeid reaalajas
- Loob häireid, kui midagi olulist juhtub (nt. serveri mälu on otsas)
- Saab andmeid töödelda ja muuta

**Näide elust:** Kapacitor on nagu valvesüsteem, mis jälgib pidevalt su kodu ja annab häiret, kui midagi kahtlast toimub.

**Milleks see kasulik on:**
- Automaatsed hoiatused, kui midagi läheb valesti
- Saad teada probleemidest enne, kui need suureks muutuvad
- Võimaldab automaatseid tegevusi (nt. e-maili saatmine või skripti käivitamine)

## Kasutusnäited

### 1. Serveri jälgimine
Soovid teada, kuidas sinu server töötab - kui palju mälu, protsessorit ja kettaruumi kasutatakse.

**Lahendus TICK Stackiga:**
1. Telegraf kogub serveri ressursside kasutuse andmed
2. InfluxDB salvestab need andmed
3. Chronograf näitab sulle graafilisel kujul, kuidas need näitajad ajas muutuvad
4. Kapacitor saadab sulle e-maili, kui mälu kasutus läheb liiga kõrgeks

### 2. Veebilehe jälgimine
Soovid teada, kas sinu veebileht on kättesaadav ja kui kiiresti see laadib.

**Lahendus TICK Stackiga:**
1. Telegraf kontrollib iga minuti järel, kas veebileht vastab ja kui kiire on vastuse aeg
2. InfluxDB salvestab need andmed
3. Chronograf näitab sulle graafikut, kuidas lehekülje laadimisaeg päeva jooksul muutub
4. Kapacitor saadab sulle SMS-i, kui veebileht ei vasta 5 minuti jooksul

### 3. Temperatuuri jälgimine
Sul on temperatuurisensorid, mis mõõdavad temperatuuri erinevates ruumides.

**Lahendus TICK Stackiga:**
1. Telegraf kogub sensorite andmed
2. InfluxDB salvestab temperatuurid koos ajatempliga
3. Chronograf näitab temperatuuri muutumist ajas igas ruumis
4. Kapacitor saadab häire, kui temperatuur langeb alla 18°C või tõuseb üle 28°C

## Alustamine TICK Stack'iga

### Mida on vaja alustamiseks?

#### Miinimumnõuded arvutile:
- **Protsessor:** Vähemalt 2 tuuma
- **Mälu:** Vähemalt 4GB RAM
- **Kõvaketas:** Vähemalt 10GB vaba ruumi
- **Operatsioonisüsteem:** Linux (Ubuntu 20.04 või uuem), macOS (10.15 või uuem)

#### Soovituslikud nõuded suurema süsteemi jaoks:
- **Protsessor:** 4 või rohkem tuuma
- **Mälu:** 16GB või rohkem RAM
- **Kõvaketas:** SSD tüüpi, vähemalt 100GB
- **Operatsioonisüsteem:** Linux (Ubuntu 22.04 LTS)

## Turvalisus

TICK Stack on turvaline süsteem, kuid on oluline teada põhilisi turvafunktsioone:

- **SSL/TLS krüpteering** - See on nagu tähtsate dokumentide saatmine lukustatud kohvris, et keegi teel neid näha ei saaks.
  
- **Kasutajaõiguste haldus (RBAC)** - See võimaldab määrata, kes mida teha saab. Näiteks üks kasutaja võib ainult andmeid vaadata, teine võib neid muuta.
  
- **Token-põhine autentimine** - See on nagu spetsiaalne võti, mida on vaja süsteemi sisenemiseks. Igal rakendusel või kasutajal on oma unikaalne võti.
  
- **Andmete krüpteerimine** - See tagab, et isegi kui keegi andmetele ligi pääseb, ei saa ta neid lugeda ilma õige võtmeta.

## Probleemide lahendamine

Kui midagi ei tööta, siis esimene koht, kust otsida, on logifailid. Need on nagu süsteemi päevikud, kuhu kirjutatakse kõik, mis juhtub:

```bash
/var/log/telegraf/telegraf.log    - Telegraf'i logid
/var/log/influxdb/influxd.log     - InfluxDB logid
/var/log/chronograf/chronograf.log - Chronograf'i logid
/var/log/kapacitor/kapacitor.log  - Kapacitor'i logid
```

**Tüüpilised probleemid:**

1. **Telegraf ei kogu andmeid** - Kontrolli, kas õigused ja ühendused on korras
2. **InfluxDB ei käivitu** - Kontrolli, kas port 8086 on vaba ja kas sul on piisavalt kettaruumi
3. **Chronograf näitab tühja lehte** - Kontrolli, kas InfluxDB on käivitatud ja ühendus on seadistatud
4. **Häired ei tööta** - Kontrolli, kas Kapacitor on käivitatud ja õigesti seadistatud

## Komponentide asendamine

| Komponent | Populaarne alternatiiv | Eelised | Puudused |
|-----------|------------------------|---------|----------|
| Telegraf | Prometheus eksporterid | Parem integratsioon Kubernetes-ega | Rohkem seadistamist vaja |
| InfluxDB | Prometheus | Parem alerting, paremad Kubernetes integratsioonid | Mitte nii hea kirjutamise jõudlus |
| Chronograf | Grafana | Rohkem visualiseerimise võimalusi, rohkem andmeallikaid | Keerulisem seadistada |
| Kapacitor | Alertmanager | Lihtsam integratsioon Prometheus'ega | Vähem paindlik |

### Olulised mõisted monitoringus:

| Mõiste | Selgitus | Näide TICK Stack'is |
|--------|----------|---------------------|
| **Mõõtepunkt (Metric)** | Konkreetne mõõdetav väärtus | CPU kasutus = 75% |
| **Ajavahemik (Interval)** | Kui tihti andmeid kogutakse | Telegraf kogub andmeid iga 10 sekundi tagant |
| **Retensioon (Retention)** | Kui kaua andmeid säilitatakse | InfluxDB säilitab detailseid andmeid 30 päeva |
| **Häire (Alert)** | Teavitus, kui midagi olulist juhtub | Kapacitor saadab e-maili, kui server läheb maha |
| **Töölaud (Dashboard)** | Visuaalne andmete kogu | Chronograf näitab 4 graafikut ühel lehel |

### Lisaressursid õppimiseks:
- [TICK Stack õpetused](https://docs.influxdata.com/influxdb/v2.0/get-started/)
- [InfluxData YouTube kanal](https://www.youtube.com/influxdata)
- [Community foorumid](https://community.influxdata.com/)
- [GitHub projektid](https://github.com/influxdata)
- [Ametlik dokumentatsioon](https://docs.influxdata.com/) - Põhjalik teabeallikas kõigi komponentide kohta
- [Telegraf pluginad](https://docs.influxdata.com/telegraf/latest/plugins/) - Nimekiri kõigist andmeallikatest, mida Telegraf toetab
- [Kapacitor häired](https://docs.influxdata.com/kapacitor/latest/guides/alerts/) - Juhend häirete seadistamiseks
- [Chronograf töölauad](https://docs.influxdata.com/chronograf/latest/guides/dashboard-template-variables/) - Juhend visuaalsete töölaudade loomiseks
- [YouTube õpetused](https://www.youtube.com/results?search_query=tick+stack+tutorial) - Visuaalsed õpetused alustajatele

---

<div align="center">
  <p>Made with ❤️ from Maria</p>
</div>