# Labor 2: Veebirakenduste Monitoorimine

**Kestus:** 60 min  
**Tase:** Keskmine  
**Eeldused:** Labor 1 läbitud, Zabbix 7.0 töötab

---

## Õppeväljundid

Pärast labori läbimist õpilane:

1. **Paigaldab** Flask veebirakenduse ja konfigureerib HTTP monitooringu
2. **Mõistab** HTTP agent, web scenario ja dependent item kontseptsioone
3. **Kasutab** JSONPath'i API vastuste parsimiseks
4. **Loob** triggereid veebirakenduse probleemide tuvastamiseks
5. **Ehitab** kohandatud dashboardi visualiseerimiseks
6. **Eristab** erinevaid monitooringu tüüpe ja nende kasutusjuhte

---

## Zabbix Monitooringu Kontseptsioonid (Labor 2)

**HTTP Agent**  
Item type mis teeb HTTP päringuid URL'ile. Ei vaja agenti hostis - lihtsalt curl-like päring. Mõõdab response time ja salvestab vastuse (HTML/JSON).

**Web Scenario**  
Mitme-sammuline test (user journey). Näiteks: 1) Ava login, 2) Sisesta credentials, 3) Kontrolli dashboard. Iga samm = eraldi HTTP päring järjest.

**Dependent Item**  
Item mis kasutab teise item'i andmeid. Näiteks: 1 HTTP päring tagastab JSON → 5 dependent item'i parse'ivad erinevaid välju. Säästab võrguliiklust!

**JSONPath**  
JSON andmete filtreerimine. Näiteks: `$.uptime` võtab JSON'ist `{"uptime": 3600}` → `3600`.

**Trigger**  
Tingimus mis loob probleemi. Näiteks: `last(/flask-app/response.time)>2000` → kui response > 2 sek, tekib alarm.

**Severity**  
Probleemi tõsidus: Not classified < Information < Warning < Average < High < Disaster.

---

## Labori Arhitektuur

```
                Zabbix Server
                      │
      ┌───────────────┼───────────────┐
      │               │               │
  HTTP Agent    Web Scenario    Zabbix Agent
      │               │               │
      ▼               ▼               ▼
  ┌─────────────────────────────────────┐
  │      Flask Web App (port 5000)      │
  │  /          - home page             │
  │  /health    - health check (JSON)   │
  │  /metrics   - app metrics (JSON)    │
  │  /slow      - slow endpoint (3s)    │
  └─────────────────────────────────────┘
```

**Monitooringu tüübid:**
- **HTTP Agent** → Lihtne URL check (kas vastab? kui kiire?)
- **Web Scenario** → Kasutaja teekond (multi-step)
- **Dependent Items** → Parse JSON (üks päring → mitu mõõdikut)

---

## Osa 1: Lisa Flask Rakendus

### Samm 1: Loo Flask App

**Miks Flask?**  
Lihtne Python veebirakendus. Pakub JSON API endpoint'e mida Zabbix saab monitoorida.

```bash
cd ~/zabbix-lab01
mkdir flask-app
cd flask-app
nano app.py
```

Kirjuta:

```python
from flask import Flask, jsonify
import time
import random

app = Flask(__name__)

start_time = time.time()
request_count = 0

@app.route('/')
def home():
    global request_count
    request_count += 1
    return "Flask App is running!"

@app.route('/health')
def health():
    uptime = int(time.time() - start_time)
    return jsonify({
        "status": "healthy",
        "uptime_seconds": uptime,
        "requests_total": request_count
    })

@app.route('/metrics')
def metrics():
    return jsonify({
        "requests_total": request_count,
        "active_users": random.randint(10, 100),
        "error_rate": round(random.uniform(0, 5), 2),
        "response_time_ms": random.randint(50, 500)
    })

@app.route('/slow')
def slow():
    time.sleep(3)
    return "This endpoint is slow!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

Salvesta.

**Mis need endpoint'id teevad:**
- `/` - Põhileht, counter
- `/health` - Health check JSON (uptime, requests)
- `/metrics` - Rakenduse mõõdikud JSON (users, errors)
- `/slow` - Aeglane endpoint (3 sek vastus - triggerite testimiseks!)

📝 **Küsimus 1:** Miks `/slow` endpoint on kasulik monitooringu testimiseks?

---

### Samm 2: Loo Dockerfile

```bash
nano Dockerfile
```

Kirjuta:

```dockerfile
FROM python:3.9-alpine
WORKDIR /app
RUN pip install flask
COPY app.py .
CMD ["python", "app.py"]
```

Salvesta.

**Alpine image:**  
Väike (~50MB vs ~900MB). Piisav lihtsale Flask app'ile.

---

### Samm 3: Lisa docker-compose.yml'i

```bash
cd ..
nano docker-compose.yml
```

Lisa `services:` sektsiooni (pärast zabbix-agent):

```yaml
  flask-app:
    build: ./flask-app
    container_name: flask-app
    ports:
      - "5000:5000"
    networks:
      - zabbix-net
    depends_on:
      - zabbix-server
```

**Monitooringu vaatenurgast:**
- `ports: 5000` - HTTP access (Zabbix teeb siia päringuid)
- `zabbix-net` - Samas võrgus serveriga (muidu ei näe)
- `build:` - Ehitab Flask image'i Dockerfile'ist

Salvesta: `Ctrl+O`, `Enter`, `Ctrl+X`

---

### Samm 4: Käivita Flask

```bash
docker-compose up -d --build
```

`--build` ehitab Flask image'i.

**Testi:**

```bash
curl http://localhost:5000
```

Peaks tagastama: `Flask App is running!`

```bash
curl http://localhost:5000/health
```

Peaks tagastama JSON: `{"status":"healthy","uptime_seconds":5,...}`

**Leia Flask IP:**

```bash
docker inspect flask-app | grep '"IPAddress"' | tail -1
```

Näide: `"IPAddress": "172.20.0.5"`

✅ **Kontrollpunkt:** Flask vastab

---

## Osa 2: HTTP Agent Monitoring

### Mis on HTTP Agent Item?

**HTTP Agent** = item type mis teeb HTTP päringuid.

Erinevus Zabbix Agent'ist:
- **Zabbix Agent** - Vajab agenti hostis, kogub süsteemi mõõdikuid (CPU, RAM)
- **HTTP Agent** - EI vaja agenti, lihtsalt HTTP päring URL'ile

Kasulik:
- Veebirakenduste monitoorimiseks
- API endpoint'ide kontrollimiseks
- Response time mõõtmiseks

---

### Samm 1: Lisa Host

**Data collection → Hosts → Create host**

| Väli | Väärtus | Selgitus |
|------|---------|----------|
| **Host name** | `flask-app` | Rakenduse nimi |
| **Groups** | `Applications` | Loo uus group |
| **Templates** | Pole | Lisame item'id käsitsi |

**Miks pole template'i?**  
Veebirakendused on erinevad. Pole universaalset template'i. Loome custom item'id.

**Interface:**
- Tüüp: **Agent**
- IP: `172.20.0.5` (sinu Flask IP)
- Port: `10050`

**NB!** Flask'is POLE agenti. Aga HTTP checks ei vaja seda - interface on ainult hosti identifitseerimiseks.

Salvesta.

---

### Samm 2: Loo HTTP Check Item

**Data collection → Hosts → flask-app → Items → Create item**

### Mis on Item components?

Iga item'il on:
- **Name** - Inimloetav nimi
- **Type** - Kuidas kogutakse (HTTP agent, Zabbix agent...)
- **Key** - Unikaalne identifikaator (nt `flask.home.response`)
- **URL** - Kuhu teha päring (HTTP agent puhul)
- **Update interval** - Kui sageli küsida

**Loo Basic Check:**

| Väli | Väärtus | Selgitus |
|------|---------|----------|
| **Name** | `Flask: Home page response` | Kirjeldav nimi |
| **Type** | `HTTP agent` | Teeb HTTP päringu |
| **Key** | `flask.home.response` | Unikaalne key |
| **URL** | `http://172.20.0.5:5000/` | Flask endpoint |
| **Request type** | `GET` | HTTP meetod |
| **Update interval** | `30s` | Iga 30 sek |

Salvesta.

**Mis see teeb:**  
Iga 30 sekundi tagant: Server teeb GET päring → Salvestab vastuse → History MySQL'i.

📝 **Küsimus 2:** Miks HTTP Agent ei vaja Zabbix agenti hostis?

---

### Samm 3: Loo Response Time Item

**Mis on Response Time?**  
Aeg millisekundites, mis kulus HTTP vastuse saamiseks. Zabbix mõõdab automaatselt.

**Create item:**

| Väli | Väärtus |
|------|---------|
| **Name** | `Flask: Response time` |
| **Type** | `HTTP agent` |
| **Key** | `flask.response.time` |
| **URL** | `http://172.20.0.5:5000/` |
| **Request type** | `GET` |
| **Update interval** | `30s` |
| **Type of information** | `Numeric (float)` |
| **Units** | `ms` |

Salvesta.

**Response time mõõtmine:**  
Zabbix teeb HTTP päringu → mõõdab aega → salvestab millisekundites.

---

### Samm 4: Vaata Andmeid

⏱️ Oota 1-2 min

**Monitoring → Latest data → flask-app**

Peaksid nägema:
- `Flask: Home page response` (HTML text)
- `Flask: Response time` (nt 45 ms)

**Vaata graafikut:**  
Kliki response time item'il → **Graph**

**Graafik ilmub, sest:**
- Item'id on loodud ✅
- Server küsib iga 30 sek ✅
- History kogutakse ✅

✅ **Kontrollpunkt:** Näed response time graafikut

---

## Osa 3: JSON Parsing (Dependent Items)

### Mis on Dependent Item?

**Dependent Item** = item mis kasutab teise item'i andmeid.

**Probleem ilma Dependent Item'ita:**  
`/health` tagastab JSON: `{"status":"healthy","uptime_seconds":3600,"requests_total":150}`

Kui tahad 3 eraldi mõõdikut → 3 eraldi HTTP päringut! Raiskamine!

**Lahendus Dependent Item'iga:**  
1. **Master item** - Teeb 1 HTTP päringu, salvestab JSON
2. **Dependent items** - Parse'ivad JSON'ist erinevaid välju

**Tulemus:** 1 HTTP päring → 3 mõõdikut! ✅

---

### Samm 1: Loo Master Item

**Create item:**

| Väli | Väärtus |
|------|---------|
| **Name** | `Flask: Health status (raw)` |
| **Type** | `HTTP agent` |
| **Key** | `flask.health.raw` |
| **URL** | `http://172.20.0.5:5000/health` |
| **Update interval** | `1m` |
| **Type of information** | `Text` |

Salvesta.

See salvestab kogu JSON vastuse.

---

### Samm 2: Loo Dependent Item - Uptime

**Mis on JSONPath?**

JSONPath = JSON'i filtreerimine. Syntax nagu XPath.

Näide JSON:
```json
{
  "status": "healthy",
  "uptime_seconds": 3600,
  "requests_total": 150
}
```

JSONPath `$.uptime_seconds` → `3600`

**Create item:**

| Väli | Väärtus |
|------|---------|
| **Name** | `Flask: Uptime` |
| **Type** | `Dependent item` |
| **Key** | `flask.uptime` |
| **Master item** | `Flask: Health status (raw)` |
| **Type of information** | `Numeric (unsigned)` |
| **Units** | `uptime` |

**Preprocessing (OLULINE!):**
- **Type:** `JSONPath`
- **Parameters:** `$.uptime_seconds`

Salvesta.

**Mis juhtub:**  
Master item kogub JSON → Dependent item võtab `uptime_seconds` → Salvestab eraldi mõõdikuna.

📝 **Küsimus 3:** Miks Dependent Item on parem kui iga mõõdiku jaoks eraldi HTTP päring?

---

### Samm 3: Loo Dependent Item - Requests Total

**Create item:**

| Väli | Väärtus |
|------|---------|
| **Name** | `Flask: Total requests` |
| **Type** | `Dependent item` |
| **Key** | `flask.requests.total` |
| **Master item** | `Flask: Health status (raw)` |
| **Type of information** | `Numeric (unsigned)` |

**Preprocessing:**
- **Type:** `JSONPath`
- **Parameters:** `$.requests_total`

Salvesta.

---

### Samm 4: Parse Metrics Endpoint

**Loo master item:**

| Väli | Väärtus |
|------|---------|
| **Name** | `Flask: Metrics (raw)` |
| **Type** | `HTTP agent` |
| **Key** | `flask.metrics.raw` |
| **URL** | `http://172.20.0.5:5000/metrics` |
| **Update interval** | `1m` |
| **Type of information** | `Text` |

**Loo 3 dependent item'i:**

**1. Active users:**
- Name: `Flask: Active users`
- Key: `flask.users.active`
- Master: `Flask: Metrics (raw)`
- JSONPath: `$.active_users`

**2. Error rate:**
- Name: `Flask: Error rate`
- Key: `flask.error.rate`
- Master: `Flask: Metrics (raw)`
- JSONPath: `$.error_rate`
- Units: `%`

**3. App response time:**
- Name: `Flask: App response time`
- Key: `flask.app.response.time`
- Master: `Flask: Metrics (raw)`
- JSONPath: `$.response_time_ms`
- Units: `ms`

---

### Samm 5: Vaata Kõiki Item'eid

**Data collection → Hosts → flask-app → Items**

Peaksid nägema:
- 2 HTTP agent items (master items)
- 5 Dependent items (parse JSON)
- Kokku: 7 item'i

**Monitoring → Latest data → flask-app**

⏱️ Oota 1-2 min

Peaksid nägema kõiki 7 mõõdikut värskendumas!

✅ **Kontrollpunkt:** JSON parsing töötab

---

## Osa 4: Web Scenarios

### Mis on Web Scenario?

**Web Scenario** = mitme-sammuline test (user journey).

**Näide:**  
1. **Step 1:** GET `/` → Kontroll kas leht avaneb
2. **Step 2:** GET `/health` → Kontroll kas API vastab
3. **Step 3:** GET `/metrics` → Kontroll kas metrics töötab

Iga samm mõõdab:
- Response time
- HTTP status code
- Required string (kas leitud?)

**Kasutus:**  
Simuleerib kasutaja tegevust. Näiteks: login → dashboard → logout.

**Vahe HTTP Agent'ist:**  
- **HTTP Agent** - Üks päring
- **Web Scenario** - Mitu päringut järjest (session, cookies säilivad)

---

### Samm 1: Loo Web Scenario

**Data collection → Hosts → flask-app → Web scenarios → Create web scenario**

| Väli | Väärtus |
|------|---------|
| **Name** | `Flask: User journey` |
| **Update interval** | `1m` |
| **Agent** | `Mozilla/5.0` |

---

### Samm 2: Lisa Steps

**Step 1:**
- **Name:** `Home page`
- **URL:** `http://172.20.0.5:5000/`
- **Required status codes:** `200`

**Step 2:**
- **Name:** `Health check`
- **URL:** `http://172.20.0.5:5000/health`
- **Required status codes:** `200`
- **Required string:** `healthy`

**Step 3:**
- **Name:** `Metrics`
- **URL:** `http://172.20.0.5:5000/metrics`
- **Required status codes:** `200`

Salvesta.

**Mis juhtub:**  
Iga minut käib läbi kõik 3 sammu. Kui mõni fail'ib (vale status code või string puudub) → Problem!

📝 **Küsimus 4:** Millal kasutaksid Web Scenario vs lihtsat HTTP Agent check'i?

---

### Samm 3: Vaata Scenario Tulemusi

⏱️ Oota 2 min

**Monitoring → Hosts → flask-app → Web**

Näed:
- Download speed (per step)
- Response time (per step)
- Failed step (0 = OK, 1 = failed)

**Kliki scenario nimel** → näed kõigi sammude response time graafikut!

✅ **Kontrollpunkt:** Web scenario töötab

---

## Osa 5: Triggerid

### Mis on Trigger?

**Trigger** = tingimus mis loob probleemi.

Komponendid:
- **Expression** - Tingimus (nt `last(/flask-app/flask.response.time)>2000`)
- **Severity** - Tõsidus (Warning, Average, High...)
- **Problem event** - Kui tingimus TRUE → Problem
- **OK event** - Kui tingimus FALSE → Problem lahendatud

**Severity tasemed:**
- **Not classified** - Määramata
- **Information** - Info
- **Warning** - Hoiatus
- **Average** - Keskmine probleem
- **High** - Kõrge prioriteet
- **Disaster** - Katastroof

---

### Samm 1: Loo Response Time Trigger

**Data collection → Hosts → flask-app → Triggers → Create trigger**

| Väli | Väärtus |
|------|---------|
| **Name** | `Flask: High response time` |
| **Severity** | `Warning` |

**Expression:**
- Kliki **Add**
- Item: `flask.response.time`
- Function: `last()`
- Operator: `>`
- Value: `2000`

Peaks olema: `last(/flask-app/flask.response.time)>2000`

**Mis see tähendab:**  
Viimane response time > 2000ms (2 sek) → Alarm!

Salvesta.

---

### Samm 2: Loo Error Rate Trigger

**Create trigger:**

| Väli | Väärtus |
|------|---------|
| **Name** | `Flask: High error rate` |
| **Severity** | `Average` |

**Expression:** `last(/flask-app/flask.error.rate)>10`

Alarm kui error rate > 10%.

Salvesta.

📝 **Küsimus 5:** Mis vahe on Warning ja Average severity'l? Kumb on tõsisem?

---

### Samm 3: Testi Triggereid

**Tee aeglane päring:**

```bash
curl http://localhost:5000/slow
```

Kulub 3 sekundit (> 2s trigger threshold!)

**Vaata probleeme:**

**Monitoring → Problems**

⏱️ Oota 1-2 min (next update interval)

Peaksid nägema:  
🔴 **Flask: High response time** (Warning)

**Lahenda probleem (tee kiired päringud):**

```bash
for i in {1..5}; do curl http://localhost:5000/; done
```

Response time < 2s → Problem lahendub automaatselt!

✅ **Kontrollpunkt:** Trigger aktiveerub ja lahendub

---

## Osa 6: Dashboard

### Mis on Dashboard?

**Dashboard** = kohandatud vaade mõõdikutele.

Widget'id:
- **Graph** - Ajaloolised andmed graafikuna
- **Item value** - Üks väärtus suurelt
- **Gauge** - Visuaalne meter (nt 0-100%)
- **Problems** - Aktiivsed probleemid
- **Map** - Võrgu topol puhul

---

### Samm 1: Loo Dashboard

**Dashboards → Create dashboard**

| Väli | Väärtus |
|------|---------|
| **Name** | `Flask Monitoring` |
| **Default page name** | `Overview` |

Salvesta.

---

### Samm 2: Lisa Widgets

Kliki dashboard'il → **Edit dashboard** → **Add widget**

**Widget 1: Response Time Graph**

- **Type:** `Graph`
- **Name:** `Response Time`
- **Data set:**
  - Host: `flask-app`
  - Item: `Flask: Response time`
- **Time period:** `Last hour`
- **Width:** `6` (pool ekraanist)

Add.

**Widget 2: Active Users**

- **Type:** `Item value`
- **Name:** `Active Users`
- **Item:** `flask-app: Flask: Active users`
- **Show:** `As is` + `Change indicator`
- **Width:** `3`

Add.

**Widget 3: Error Rate Gauge**

- **Type:** `Gauge`
- **Name:** `Error Rate`
- **Item:** `flask-app: Flask: Error rate`
- **Min:** `0`
- **Max:** `100`
- **Thresholds:**
  - `0-5` → Green
  - `5-10` → Yellow
  - `10-100` → Red
- **Width:** `3`

Add.

**Widget 4: Problems**

- **Type:** `Problems`
- **Name:** `Flask Issues`
- **Show:** `Recent problems`
- **Host groups:** `Applications`
- **Width:** `6`

Add.

**Widget 5: Uptime**

- **Type:** `Item value`
- **Name:** `Application Uptime`
- **Item:** `flask-app: Flask: Uptime`
- **Show:** `As is`
- **Advanced configuration → Units:** `uptime`
- **Width:** `6`

Add.

Salvesta dashboard.

---

### Samm 3: Vaata Dashboard'i

**Dashboards → Flask Monitoring**

Näed:
- Response time graafikut ✅
- Active users count ✅
- Error rate gauge (värvidega!) ✅
- Probleeme (kui on) ✅
- Uptime ✅

📝 **Küsimus 6:** Miks Gauge widget sobib error rate'ile paremini kui lihtne number?

✅ **Kontrollpunkt:** Dashboard kuvab kõik widgetid

---

## Osa 7: Git Update

### Samm 1: Kontrolli Flask Files

```bash
ls -la flask-app/
```

Peaksid nägema:
- `app.py`
- `Dockerfile`

---

### Samm 2: Uuenda README

```bash
nano README.md
```

Lisa **Komponendid** sektsiooni:

```markdown
- Flask App (veebirakendus - Python/Flask)
```

Lisa uus sektsioon enne **Turvalisus**:

```markdown
## Monitooringud

### Flask App
- **URL:** http://localhost:5000
- **HTTP Agent checks:** Response time, status
- **Web Scenario:** 3-step user journey
- **Custom metrics:** Active users, error rate (JSON parsing)
- **Triggerid:** Response time > 2s, Error rate > 10%
- **Dashboard:** Flask Monitoring

### Zabbix Server
- **Template:** Linux by Zabbix agent
- **Items:** ~50 (CPU, RAM, disk, network)
```

Salvesta.

---

### Samm 3: Commit

```bash
git add .
git status
```

Peaksid nägema:
- `flask-app/app.py` (new)
- `flask-app/Dockerfile` (new)
- `docker-compose.yml` (modified)
- `README.md` (modified)

```bash
git commit -m "Lab 2: Add Flask web app monitoring"
git push
```

✅ **Kontrollpunkt:** Muudatused Git'is

---

## Kokkuvõte

Sul on nüüd:
- ✅ Flask veebirakendus
- ✅ HTTP agent monitoring (response time, status)
- ✅ JSON parsing (dependent items, JSONPath)
- ✅ Web scenario (3-step user journey)
- ✅ Triggerid (2 sek, 10% error rate)
- ✅ Dashboard (5 widgets)

**Peamised Zabbix kontseptsioonid mis peaksid meelde jääma:**

**Item types:**
- **HTTP Agent:** HTTP päring URL'ile, ei vaja agenti (veebirakendused)
- **Dependent Item:** Kasutab teise item'i andmeid (JSON parsing, 1 päring → mitu mõõdikut)
- **Web Scenario:** Mitme-sammuline test (user journey, session)

**Andmete töötlus:**
- **JSONPath:** JSON filtreerimine (`$.field`)
- **Preprocessing:** Andmete töötlus enne salvestamist

**Probleemide tuvastus:**
- **Trigger:** Tingimus mis loob alarmi
- **Severity:** Probleemi tõsidus (Info → Warning → Average → High → Disaster)
- **Expression:** `last()`, `avg()`, `min()`, `max()` funktsioonid

**Visualiseerimine:**
- **Dashboard:** Kohandatud vaade
- **Widgets:** Graph, Item value, Gauge, Problems...

---

## Viited

- [HTTP Agent](https://www.zabbix.com/documentation/7.0/en/manual/config/items/itemtypes/http)
- [Dependent Items](https://www.zabbix.com/documentation/7.0/en/manual/config/items/itemtypes/dependent_items)
- [Web Scenarios](https://www.zabbix.com/documentation/7.0/en/manual/web_monitoring)
- [Triggers](https://www.zabbix.com/documentation/7.0/en/manual/config/triggers)
- [Dashboards](https://www.zabbix.com/documentation/7.0/en/manual/web_interface/frontend_sections/dashboards)
- [JSONPath](https://www.zabbix.com/documentation/7.0/en/manual/config/items/preprocessing/jsonpath_functionality)
