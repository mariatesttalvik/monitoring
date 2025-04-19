# Grafana

## Sissejuhatus Grafanasse

Grafana on juhtiv avatud lähtekoodiga platvorm monitooringu ja analüütika visualiseerimiseks. See võimaldab organisatsioonidel saada ülevaadet oma andmetest võimsate, kohandatavate juhtpaneelide kaudu.

Check:
https://grafana.com/
Grafana Sandbox

### Mida Grafana Võimaldab:
- **Reaalajas visualiseerimine** süsteemi ja rakenduse jõudluse jälgimiseks
- **Ühendatud monitooring** erinevate andmeallikate lõikes
- **Täiustatud hoiatussüsteem** kriitiliste sündmuste jaoks
- **Meeskonnatöö juhtpaneelid** kogu meeskonna jaoks nähtavuse tagamiseks

## Põhikontseptsioonid

### 1. Andmeallikad

Grafana tugevus seisneb võimes ühenduda praktiliselt iga andmeallikaga:

| Tüüp | Populaarsed Näited | Parim Kasutus |
|------|-----------------|----------|
| **Aegrea Andmebaasid** | Prometheus, InfluxDB, Graphite | Mõõdikud, jälgimisandmed |
| **SQL Andmebaasid** | PostgreSQL, MySQL, Microsoft SQL | Äriandmed, relatsioonilised andmed |
| **Logimisplatvormid** | Elasticsearch, Loki, Splunk | Rakenduse ja süsteemi logid |
| **Pilveteenused** | AWS CloudWatch, Azure Monitor, Google Cloud Monitoring | Pilve infrastruktuur |
| **IoT & Kohandatud** | MQTT, REST API-d, JSON lõpp-punktid | Seadmete andmed, kohandatud integratsioonid |

### 2. Dashboardid (Juhtpaneelid)

Dashboardid on paneelide kogumid, mis annavad visuaalse ülevaate sinu andmetest.

**Dashboardi Anatoomia:**
- **Read**: Organisatsiooniüksused seotud paneelide grupeerimiseks
- **Paneelid**: Individuaalsed visualiseerimisüksused
- **Muutujad**: Dünaamilised valijad, mis filtreerivad juhtpaneeli sisu
- **Annotatsioonid**: Sündmuste markerid aegrea andmetel

**Parimad Praktikad:**
- Loo hierarhilised juhtpaneelid (ülevaade → detailid)
- Kasuta järjekindlaid nimede konventsioone
- Rakenda malle korduvkasutatavate juhtpaneelide jaoks
- Lisa dokumentatsioonilinke ja kirjeldusi

### 3. Paneelid ja Visualiseerimised

Grafana pakub arvukalt visualiseerimistüüpe, mis vastavad sinu konkreetsetele andmevajadustele:

| Visualiseerimine | Parim Kasutus | Näide Kasutusest |
|---------------|---------------|------------------|
| **Aegrea Graafik** | Trendid ajas | CPU/Mälu kasutus |
| **Mõõdik (Gauge)** | Praegused väärtused lävendite suhtes | Ketta ruumi kasutus |
| **Statistika Paneel** | Peamised jõudlusnäitajad | Aktiivsed kasutajad |
| **Tulpdiagramm** | Kategooriate võrdlemine | Päringute arv lõpp-punkti järgi |
| **Soojuskaart** | Jaotuse mustrid | Päringu latentsi jaotus |
| **Tabel** | Detailne andmete uurimine | Tehingute logid |
| **Sektordiagramm** | Proportsionaalne jaotus | Liikluse allikad |
| **Geokaart** | Geograafilised andmed | Kasutaja asukohad |

### 4. Päringukeeled

Igal andmeallikal on oma päringukeel. Siin on kõige levinumad:

**PromQL (Prometheus):**
- Päringute koostamine reaalajas mõõdikute jälgimiseks
- Ideaalne süsteemi jõudluse mõõtmiseks

**SQL:**
- Struktureeritud päringud relatsiooniliste andmete jaoks
- Sobib äriandmete ja kasutajategevuse analüüsimiseks

**Elasticsearch Query DSL:**
- Paindlik päringukeel logide ja dokumentide jaoks
- Võimas täisteksti otsingutel ja mustrite leidmisel

### 5. Hoiatussüsteem

Grafana hoiatussüsteem aitab tuvastada probleeme enne, kui need mõjutavad kasutajaid:

**Hoiatussüsteemi Komponendid:**
- **Reeglid**: Tingimused, mis käivitavad hoiatused
- **Teavitused**: Kuidas hoiatusi edastatakse (e-post, Slack jne)
- **Vaigistused**: Teavituste ajutine peatamine
- **Kontaktpunktid**: Kes milliseid hoiatusi saab

## Praktiline Rakendamine

### Täiemahulise Jälgimise Näide

Loome täieliku jälgimislahenduse veebirakenduse komplekti jaoks:

#### 1. Infrastruktuuri Dashboard

**Võtme Mõõdikud:**
- CPU, Mälu, Ketta, Võrgu kasutus
- Sõlme olek ja kättesaadavus
- Konteineri/podi tervis (konteineriseeritud keskkondade jaoks)

#### 2. Rakenduse Jõudluse Dashboard

**Võtme Mõõdikud:**
- Päringute määrad ja latentsid
- Veamäärad ja peamised vead
- Andmebaasi päringu jõudlus
- Vahemälu tabamuse määrad
- Kasutaja sessiooni mõõdikud

**Täiustatud Rakenduse Mõõdikud:**
- Apdex skoor (Rakenduse jõudlusindeks)
- Kasutaja teekonna ajad
- Front-end ja back-end jõudlus eraldi

#### 3. Ärimõõdikute Dashboard

**Võtme Mõõdikud:**
- Konversiooni määrad
- Tehingute maht
- Tulu
- Kasutajate hankimine ja hoidmine
- Funktsioonide kasutuselevõtt

### Dashboardi Organiseerimise Strateegia

**Soovituslik Struktuur:**
1. **Ülevaate Dashboard**: Kõrgtaseme tervis ja KPI-d
2. **Valdkonna-spetsiifilised Dashboardid**: Infrastruktuur, Rakendused, Äri
3. **Teenuse-spetsiifilised Dashboardid**: Individuaalsed komponendid
4. **Süvitsi Uurimise Dashboardid**: Veaotsingu tööriistad

**Kaustade Struktuuri Näide:**
```
/Dashboardid
  ├── Ülevaade
  │   └── Süsteemi Tervis
  ├── Infrastruktuur
  │   ├── Kubernetes Klaster
  │   ├── Andmebaasi Jõudlus
  │   └── Võrgu Ülevaade
  ├── Rakendused
  │   ├── Frontend Teenused
  │   ├── Backend API-d
  │   └── Autentimisteenus
  └── Äri
      ├── Müügianalüütika
      ├── Kasutaja Teekond
      └── Funktsioonide Kasutus
```

## Täiendavad Teemad

### 1. Grafana Ettevalmistamine

Automatiseeri oma Grafana seadistus konfiguratsiooniga koodis:
- Dashboardide automaatne haldamine
- Andmeallikate automaatne seadistamine
- Versioonihaldus dashboardidele

### 2. Jõudluse Optimeerimine

**Päringu Optimeerimise Tehnikad:**
- Kasuta sobivaid ajavahemikke
- Rakenda rate() ja increase() funktsioonile loenduritele
- Rakenda sildi filtreid vara päringus
- Kasuta salvestusreegleid keerukateks arvutusteks

**Dashboardi Optimeerimine:**
- Jaota paneelide värskenduse sagedusi
- Kasuta malli muutujaid paneelide arvu vähendamiseks
- Rakenda vahemälu kasutamist, kus asjakohane
- Kaalu ajavahemiku nihutamist võrdlusteks

### 3. Autentimine ja Autoriseerimine

Grafana toetab mitmeid autentimismeetodeid:

| Meetod | Parim Kasutus | Konfiguratsiooni Keerukus |
|--------|----------|--------------------------|
| Sisseehitatud Kasutajad | Väikesed meeskonnad, testimine | Madal |
| LDAP/Active Directory | Ettevõtete keskkonnad | Keskmine |
| OAuth (Google, GitHub jne) | Pilvepõhised organisatsioonid | Keskmine |
| SAML | Suured ettevõtted SSO-ga | Kõrge |

## Juurutamise Võimalused

### 1. Grafana Cloud

**Eelised:**
- Hallatav infrastruktuur
- Automaatsed uuendused
- Sisseehitatud mõõdikute kogumine
- Meeskonnatöö funktsioonid

**Hinnamudel:**
- Tasuta tase saadaval (10K seeriat, 14-päevane säilitamine)
- Kasutuspõhine hinnastamine mõõdikute, logide ja jälgede jaoks
- Meeskonnapõhine hinnastamine täiendavate kasutajate jaoks

### 2. Ise Majutatud

**Juurutamise Meetodid:**
- Docker konteinerid
- Kubernetes orkestreerimine
- Traditsioonilised paigaldused (Linux, Windows)

**Kõrge Saadavuse Seadistus:**
- Paigalda mitu Grafana instantsi
- Kasuta jagatud andmebaasi taustasüsteemi (MySQL/PostgreSQL)
- Rakenda koormuse tasakaalustamist
- Seadista jagatud salvestusruum piltide ja pluginate jaoks

tal[5m])) by (status_code, endpoint)

# Vahemikuvektori valijad
process_cpu_seconds_total[5m]

# Nihke modifikaator
rate(http_requests_total[5m] offset 1d)
```

### Kasulikud Grafana Muutujad

```
# Aja muutujad
$__timeFrom()
$__timeTo()
$__interval

# Andmeallika muutujad
${DS:prometheus}

# Kohandatud intervalli muutuja
interval:
- 1m
- 5m
- 15m
- 1h
- 6h
- 12h
- 1d
- 7d
- 30d

# Päringu tulemuse muutuja
Query: label_values(node_cpu_seconds_total, instance)
```

## Lisa B: Veaotsing

### Levinud Probleemid ja Lahendused

| Probleem | Potentsiaalsed Põhjused | Lahendused |
|-------|------------------|-----------|
| Paneelides pole andmeid | Andmeallika ühenduvus | Kontrolli andmeallika tervist, volitusi, võrku |
| Dashboardi aeglane laadimine | Liiga palju paneele, ebaefektiivsed päringud | Optimeeri päringuid, kasuta malli muutujaid |
| Hoiatused ei käivitu | Vale reegli konfiguratsioon | Testi hoiatusreegleid, kontrolli teavituskanaleid |
| Autentimise tõrked | Valesti seadistatud autentimine | Kontrolli autentimise seadeid, vaata logisid |
| Puuduvad mõõdikud | Kollektori probleemid, valed päringud | Valideeri mõõdiku olemasolu andmeallikas |

---

*See materjal on koostatud Grafana versiooni 10.x jaoks. Palun kontrolli ametlikku dokumentatsiooni uusimate funktsioonide ja muudatuste kohta.*