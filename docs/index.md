# Süsteemide Monitooring ja Jälgitavus

**Kursuse maht:** 50h (põhirada) + 15h (valikmoodulid) • **Tase:** Keskaste kuni edasijõudnud • **Eeldused:** Linux põhiteadmised, võrgutehnoloogia alused

Kaasaegses IT-taristus ei piisa enam lihtsalt süsteemide käigushoidmisest. Tõeliselt usaldusväärsete teenuste tagamiseks peab olema võimalik jälgida, mõõta ja analüüsida kogu infrastruktuuri toimimist reaalajas. See kursus annab praktilised oskused ja teoreetilised teadmised, mis on vajalikud tänapäevase monitooringu- ja jälgitavuslahenduse loomiseks ja haldamiseks.

Kursus on üles ehitatud **modulaarselt** - põhirada annab vajaliku aluse ja praktilised oskused, valikmoodulid võimaldavad süvendada teadmisi konkreetsete tööriistade ja tehnoloogiate osas.

!!! info "Miks on monitooring oluline?"
    Professionaalses keskkonnas ei küsita mitte "kas", vaid "millal" midagi läheb valesti. Hea monitooringulahendus võimaldab avastada probleeme enne, kui need jõuavad kasutajateni, analüüsida jõudlust andmepõhiselt ning planeerida ressursse targalt. Monitooring ei ole lihtsalt logide lugemine - see on süsteemne lähenemine, kuidas hoida teenused töös ja kasutajad rahul.

## Mida Selles Kursuses Õpid

Kursus keskendub kolmele põhisambale, mis moodustavad tänapäevase jälgitavuse (**observability**):

**Mõõdikud (Metrics)** - Õpid koguma ja visualiseerima süsteemi jõudlusnäitajaid, seadistama hoiatusi ning tuvastama kitsaskohti enne, kui need muutuvad kriitiliseks probleemiks.

**Logid (Logs)** - Valdad hajutatud logide kogumist, struktureerimist ja analüüsimist, muutes tuhanded logiread arusaadavaks informatsiooniks, mis aitab kiiresti tõrkeotsingut teha.

**Jäljed (Traces)** - Suudad jälgida üksikuid päringuid läbi mikroteenus­te arhitektuuri, tuvastades täpselt, kus latentsus tekib ja millised komponendid aeglustavad kasutajakogemust.

## Kursuse Ülesehitus

### Põhirada (50h - kohustuslik)

Põhirada annab tervikliku ülevaate monitooringu kolmest sambast ja praktilised oskused nende rakendamiseks.

| Moodul | Tehnoloogia | Maht | Fookus |
|--------|-------------|------|--------|
| **1. Linux Logimine** | Syslog, Journald, Logrotate | 6h | Operatsioonisüsteemi logid |
| **2. Prometheus & Grafana** | Prometheus, Node Exporter, Alertmanager, Grafana | 11h | Mõõdikute kogumine ja visualiseerimine |
| **3. ELK Stack** | Elasticsearch, Logstash, Kibana | 11h | Tsentraliseeritud logihaldus |
| **4. Jaeger & OpenTelemetry** | Jaeger, OpenTelemetry | 7h | Hajutatud jälgimine (tracing) |
| **5. Zabbix** | Zabbix Server, Agent, Frontend | 9h | Traditsiooniline infrastruktuuri monitooring |
| **6. Lõpuprojekt** | Integratsioon | 6h | Terviklik monitooringulahendus |

**Kokku:** 50h (35h kontaktõpe + 15h kodutööd ja projekt)

### Valikmoodulid (15h - vali 1-2)

Süvenda oma teadmisi konkreetsete tehnoloogiate ja kasutusjuhtude osas.

| Moodul | Tehnoloogia | Maht | Millal valida |
|--------|-------------|------|---------------|
| **TICK Stack** | Telegraf, InfluxDB, Chronograf, Kapacitor | 6h | Aegridade andmebaaside sügavam õppimine |
| **Splunk Enterprise** | Splunk Cloud, Splunk Enterprise | 7h | Enterprise-taseme lahendused |
| **Hoiatuste Haldus** | PagerDuty, Alertmanager | 3h | Incident management ja alerting |

!!! tip "Kuidas kursust läbida?"
    Kursus on üles ehitatud nii, et saad materjale läbida omas tempos, aga tunnis teeme laboritöid koos ja lahendame probleeme. **Põhirada** annab sulle vajaliku aluse - õpid kolme põhisambal (metrics, logs, traces) ja kuidas neid praktiliselt rakendada. Iga labor algab lühikese teooria blokiga, seejärel praktilise ülesandega. Kui jääd kinni, on tõrkeotsingute sektsioon iga labori lõpus. **Valikmoodulid** võimaldavad süvendada teadmisi - vali need, mis sind kõige rohkem huvitavad või mida tahad paremini õppida.

## Kursuse Struktuur

### Loengumaterjalid

Teoreetilised materjalid selgitavad monitooringu põhimõtteid, arhitektuure ja parimaid praktikaid. Need on mõeldud lugemiseks enne laborit või kui tahad mingit teemat sügavamalt mõista. Iga teema puhul käsitleme:

- **Miks** see tehnoloogia eksisteerib ja milliseid probleeme lahendab - kontekst ja motivatsioon
- **Kuidas** see tehniliselt töötab ja millised on põhikomponendid - sisemine arhitektuur
- **Millal** kasutada konkreetset tööriista ja kuidas see võrdlub alternatiividega - otsustamise kriteeriumid
- **Praktikas** näited reaalsetest kasutusjuhtudest ja tööstuse standarditest - kuidas firmas kasutatakse

Sa ei pea kõike pähe õppima. Oluline on mõista põhimõtteid ja oskus leida infot, kui on vaja.

### Laborikeskkond

Kõik laborid on kavandatud nii, et need on teosta­tavad isiklikus arenduskeskkonnas. Kasutame peamiselt:

- **Docker** konteineri­tehno­loogiat kiireks keskkonna seadistuseks
- **Virtual machines** komplekssete topoloogiate jaoks
- **Cloud platvorme** (Digital Ocean) reaalsete stsenaariumite simuleerimiseks

### Lõpuprojekt

Kursuse lõpus projekteerid ja implementeerid tervikliku monitooringulahenduse kujuteldavale e-kaubanduse platvormile, mis kogeb salapäraseid jõudlusprobleeme. Projekt hõlmab:

- Monitooringu arhitektuuri kavandamist
- Mõõdikute, logide ja jälgede kogumist
- Dashboard'ide loomist ja hoiatuste seadistamist
- Probleemide analüüsimist ja lahenduste dokumenteerimist

## Eeldused

Enne kursusega alustamist peaksid olema tuttav järgnevate teemadega:

**Linux käsurea kasutamine** - Oskad navigeerida failisüsteemis, redigeerida faile (`vim`, `nano`) ning käivitada põhilisi süsteemikäske.

**Võrgutehnoloogia alused** - Mõistad TCP/IP põhimõtteid, oskad kasutada `ping`, `curl`, `netstat` vms tööriistu ning tead, mis on DNS ja HTTP.

**Tekstiredaktor ja terminal** - Oled mugav töötama terminalis ning oskad kasutada vähemalt ühte tekstiredaktorit (VS Code, Vim või muu).

**Git põhialused** - Oskad kloonida repositooriume ja teha põhilisi Git operatsioone (vajalik kodutööde esitamiseks).

!!! warning "Tehniline keskkond"
    Laborite läbimiseks vajad arvutit, kus on võimalik installida Docker ja luua virtuaalmasinaid. Kui sul on kooli arvuti, siis enamasti need nõuded on täidetud. Kui kasutad oma arvutit: minimaalsed nõuded on 8GB RAM, 50GB vaba kettaruumi, Linux/macOS/Windows 10 Pro+ operatsioonisüsteem. Kui sul on vana või nõrgem arvuti, räägi õpetajaga - võib-olla saame lahenduse.

## Ressursid ja Abi

### Alustamine

[GitHub juhend →](resources/github-guide.md){ .md-button }
[VS Code seadistamine →](resources/vscode-guide.md){ .md-button }
[Digital Ocean konto →](resources/konto-digital_ocean.md){ .md-button }

### Täiendav Õppematerjal

- **Loengud** - Põhjalikud teoreetilised materjalid igast teemast
- **Näidiskonfiguratsioonid** - Valmis seadistus­failid ja skriptid
- **Probleemilahendus** - Levinumad vead ja nende kõrvaldamise viisid
- **Täiendav lugemine** - Viited ametlikele dokumentatsioonidele ja artiklit­ele

### Abi Saamine

Kui jääd labori käigus kinni:

1. **Kontrolli troubleshooting sektsiooni** labori dokumentatsioonis
2. **Loe vigade teateid tähelepanelikult** - sageli on lahendus veas endas
3. **Kasuta ametlikku dokumentatsiooni** - igal tööriistal on põhjalik dokumentatsioon
4. **Küsi kaaslastelt** - peer learning on võimas õppevahend
5. **Pöördu õpetaja poole** - kui oled eelneva proovinud

## Mida Oskad Pärast Kursust

Kursuse eduka läbimise järel oskad:

- ✅ Seadistada ja kasutada peamisi monitooringu tööriistu (Prometheus, ELK, Jaeger)
- ✅ Koguda ja analüüsida süsteemi mõõdikuid, logisid ja jälgi
- ✅ Luua dashboarde, mis näitavad süsteemi seisundit visuaalselt
- ✅ Seadistada hoiatusi, mis annavad teada, kui midagi läheb valesti
- ✅ Leida ja lahendada jõudlusprobleeme andmete põhjal
- ✅ Mõista, kuidas professionaalid monitoorivad tootmiskeskkondi
- ✅ Debugida ja tõrkeid otsida süstemaatiliselt, mitte juhuslikult

Enamik neid tööriistu ja tehnikaid on kasutusel päris firmades, seega see, mida siin õpid, on kohe rakendatav ka praktilises töös või praktika ajal.

## Alusta Siit

### Põhirada

Alusta siit ja järgi mooduleid numbrilises järjekorras:

[1. Linux Logimine →](labs/01_linux_logging/1_linux_logging_lab.md){ .md-button .md-button--primary }
[2. Prometheus & Grafana →](labs/02_prometheus/lab02_prometheus_part1.md){ .md-button .md-button--primary }
[3. ELK Stack →](labs/04_elk_stack/lab04_elastic.md){ .md-button .md-button--primary }
[4. Jaeger & OpenTelemetry →](labs/07_jaeger/1_jaeger_app_traces.md){ .md-button .md-button--primary }
[5. Zabbix →](labs/06_zabbix/monitoring-lab-manual-part1.md){ .md-button .md-button--primary }
[6. Lõpuprojekt →](final_project/final_project_building_monsystem.md){ .md-button .md-button--primary }

### Valikmoodulid

Vali 1-2 moodulit, mis sind kõige rohkem huvitavad:

[TICK Stack →](labs/03_tick_stack/lab03_tick_part1.md){ .md-button }
[Splunk Enterprise →](labs/05_splunk/splunk_cloud_lab.md){ .md-button }
[Hoiatuste Haldus →](labs/08_alerting/pagerduty.md){ .md-button }

### Lisaressursid

[Loengud ja teooria →](materials/lectures/Observability/intro_logging_monitoring_observability.md){ .md-button }
[Seadistuse juhendid →](resources/github-guide.md){ .md-button }

---

*Kursus on koostatud praktikutele, kes kasutavad neid tööriistu igapäevaselt production keskkonnas. Edukat õppimist!*
