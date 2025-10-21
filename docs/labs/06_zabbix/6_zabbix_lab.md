# Labor 1: Zabbix Alused

**Kestus:** 45 min  
**Tase:** Algaja  
**Eeldused:** Docker ja Docker Compose

---

## Õppeväljundid

Pärast labori läbimist õpilane:

1. **Ehitab** Zabbix keskkonna järk-järgult (MySQL → Server → Web → Agent)
2. **Mõistab** iga komponendi rolli monitooringu arhitektuuris
3. **Konfigureerib** esimese monitooringuhosti ja interface'i
4. **Kasutab** passive checks andmete kogumiseks
5. **Vaatab** kogutud mõõdikuid ja graafikuid
6. **Dokumenteerib** seadistuse Git'is

---

## Zabbix Monitooringu Kontseptsioonid

Enne alustamist - põhimõisted:

**Host**  
Süsteem mida monitoorid. Võib olla server, võrguseade, konteiner, rakendus.

**Item**  
Üks mõõdik mida kogutakse. Näiteks: CPU kasutus, vaba mälu, HTTP response time.

**Agent**  
Väike programm monitooringuhostis. Kogub mõõdikuid (CPU, RAM) ja vastab serveri päringutele.

**Server**  
Peamine mootor. Küsib agentidelt andmeid, salvestab MySQL'i, hindab triggereid.

**Template**  
Valmis komplekt item'eid ja triggereid. Näiteks "Linux by Zabbix agent" annab ~100 mõõdikut.

**Passive check**  
Server küsib → Agent vastab. Server kontrollib port 10050.

**Active check**  
Agent saadab → Server võtab vastu. Agent saadab port 10051.

---

## Labori Arhitektuur

```
MySQL (3306)
    ↓
Zabbix Server (10051) ← kuulab agente
    ↓
Zabbix Web (8080)
    ↑
    │ küsib (passive check)
    │
Zabbix Agent (10050)
```

**Andmete voog:**
1. Server küsib agendilt: "Mis on CPU?"
2. Agent vastab: "45%"
3. Server salvestab MySQL'i
4. Web näitab graafikut

---

## Osa 1: Ehita Docker Compose

### Samm 1: Valmista Keskkond

```bash
mkdir ~/zabbix-lab01
cd ~/zabbix-lab01
nano docker-compose.yml
```

Kirjuta põhistruktuur:

```yaml
version: '3.8'

services:

networks:
  zabbix-net:
    driver: bridge

volumes:
```

**Mis see on?**  
Docker Compose fail kirjeldab konteinerid. Me ehitame järk-järgult - üks komponent korraga.

---

### Samm 2: Lisa MySQL

**Miks MySQL esmalt?**  
Zabbix Server vajab andmebaasi kohe käivitumisel. MySQL salvestab:
- Konfiguratsioon (hostid, item'id, triggerid)
- History (kõik kogutud mõõdikud)
- Trends (tunni/päeva keskmised)

Lisa `services:` alla:

```yaml
  mysql-server:
    image: mysql:8.0
    container_name: mysql-server
    environment:
      MYSQL_DATABASE: zabbix
      MYSQL_USER: zabbix
      MYSQL_PASSWORD: zabbix_pwd
      MYSQL_ROOT_PASSWORD: root_pwd
    volumes:
      - mysql-data:/var/lib/mysql
    networks:
      - zabbix-net
    command:
      - mysqld
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_bin
```

**Monitooringu vaatenurgast:**
- `MYSQL_DATABASE: zabbix` - Zabbix Server otsib täpselt seda nime
- `volumes:` - Andmed jäävad alles ka restart'il (history ei kao!)
- `utf8mb4` - Zabbix skeemi nõue (~140 tabelit)

Lisa `volumes:` alla:

```yaml
  mysql-data:
```

**Kontrolli:**
```bash
grep "mysql-server:" docker-compose.yml
```

📝 **Küsimus 1:** Miks me vajame `volumes:`? Mis juhtuks history andmetega ilma selleta?

---

### Samm 3: Lisa Zabbix Server

**Mis on Zabbix Server monitooringu arhitektuuris?**

Server sisaldab mitmeid protsesse:
- **Poller** - Küsib agentidelt andmeid (passive checks)
- **Trapper** - Võtab vastu agentide saadetud andmeid (active checks)
- **Timer** - Hindab triggereid (nt "CPU > 80%?")
- **Alerter** - Saadab teavitusi

Lisa `services:` alla (PÄRAST mysql-server):

```yaml
  zabbix-server:
    image: zabbix/zabbix-server-mysql:ubuntu-7.0-latest
    container_name: zabbix-server
    environment:
      DB_SERVER_HOST: mysql-server
      MYSQL_DATABASE: zabbix
      MYSQL_USER: zabbix
      MYSQL_PASSWORD: zabbix_pwd
      MYSQL_ROOT_PASSWORD: root_pwd
    ports:
      - "10051:10051"
    volumes:
      - zabbix-server-data:/var/lib/zabbix
    networks:
      - zabbix-net
    depends_on:
      - mysql-server
```

**Monitooringu vaatenurgast:**
- `DB_SERVER_HOST: mysql-server` - Docker võrgus kasutatakse konteiner nime hostname'ina
- `ports: 10051` - Server **kuulab** siin (agendid saadavad active checks siia)
- `depends_on:` - Tagab et MySQL käivitub enne

Lisa `volumes:` alla:

```yaml
  zabbix-server-data:
```

**Port 10051 kasutus:**
- Active checks - agent saadab serverile
- Trapper - vabas vormis andmete vastuvõtt
- Zabbix sender - skriptid saadavad andmeid

📝 **Küsimus 2:** Mis vahe on port 10051 ja 10050 vahel? Kumb on serveri, kumb agendi port?

---

### Samm 4: Lisa Zabbix Web

**Mis on Zabbix Web?**  
Nginx + PHP rakendus. Annab veebiliidese monitooringuks.

Web suhtleb kahega:
- **MySQL** - Loeb history andmeid (kiire, otse päring)
- **Zabbix Server API** - Muudab konfiguratsiooni (lisa host, item, trigger)

Lisa `services:` alla:

```yaml
  zabbix-web:
    image: zabbix/zabbix-web-nginx-mysql:ubuntu-7.0-latest
    container_name: zabbix-web
    environment:
      ZBX_SERVER_HOST: zabbix-server
      DB_SERVER_HOST: mysql-server
      MYSQL_DATABASE: zabbix
      MYSQL_USER: zabbix
      MYSQL_PASSWORD: zabbix_pwd
      PHP_TZ: Europe/Tallinn
    ports:
      - "8080:8080"
    networks:
      - zabbix-net
    depends_on:
      - mysql-server
      - zabbix-server
```

**Monitooringu vaatenurgast:**
- `ZBX_SERVER_HOST` - API calls (nt "lisa uus host")
- `DB_SERVER_HOST` - History päringud (näita graafikut)
- `PHP_TZ: Europe/Tallinn` - Graafikute ajad õiges ajavöötmes

📝 **Küsimus 3:** Miks Web vajab KAHTE ühendust (Server JA MySQL)? Mida kummalti küsitakse?

---

### Samm 5: Lisa Zabbix Agent

**Mis on Agent monitooringu arhitektuuris?**

Agent on väike programm monitooringuhostis. See:
- Kogub süsteemi mõõdikuid (CPU, RAM, disk I/O, network)
- Käivitab kohandatud skripte
- Vastab serveri päringutele (passive mode)
- Või saadab ise (active mode)

Lisa `services:` alla:

```yaml
  zabbix-agent:
    image: zabbix/zabbix-agent:ubuntu-7.0-latest
    container_name: zabbix-agent
    environment:
      ZBX_HOSTNAME: "Zabbix server"
      ZBX_SERVER_HOST: zabbix-server
    networks:
      - zabbix-net
    depends_on:
      - zabbix-server
```

**Monitooringu vaatenurgast:**
- `ZBX_HOSTNAME: "Zabbix server"` - **KRIITILISELT OLULINE!** Server grupeerib andmeid hostname järgi
- `ZBX_SERVER_HOST` - Kellele saata active checks (kui kasutatakse)
- Agent kuulab port **10050** (default, ei pea exposima)

**Hostname'i tähtsus:**  
Kui web'is seadistad hosti nimega "Zabbix server", aga agent'il on `ZBX_HOSTNAME: "zabbix-agent"` → andmed ei ühti! Server ei tea, millise hostiga seostada.

Salvesta fail: `Ctrl+O`, `Enter`, `Ctrl+X`

📝 **Küsimus 4:** Miks hostname peab TÄPSELT ühtima web'is ja agent'is? Mis juhtub kui ei ühti?

---

### Samm 6: Kontrolli Struktuuri

```bash
grep "container_name:" docker-compose.yml | wc -l
```

Peab tagastama: `4`

---

### Samm 7: Käivita Süsteem

```bash
docker-compose up -d
```

**Mis nüüd juhtub (esimene kord):**

1. **MySQL (30-60 sek)**
   - Loob andmebaasi struktuuri
   - Import'ib Zabbix skeemi (~140 tabelit: hosts, items, history, trends, triggers, events...)

2. **Zabbix Server (10-20 sek)**
   - Ühendub MySQL'iga
   - Import'ib vaikimisi template'd
   - Käivitab poller/trapper protsessid

3. **Zabbix Web (5-10 sek)**
   - Genereerib PHP konfiguratsiooni
   - Loob ühendused MySQL ja Server'iga

4. **Zabbix Agent (2-3 sek)**
   - Käivitab listening protsessi (port 10050)
   - Registreerib monitooringu moodulid

⏱️ **Oota 2 minutit esimeseks käivituseks**

---

### Samm 8: Kontrolli Komponente

**MySQL valmidus:**
```bash
docker logs mysql-server 2>&1 | grep "ready for connections"
```

Peaks nägema 2 rida. Tähendab: MySQL kuulab ja aktsepteerib ühendusi.

**Zabbix Server käivitus:**
```bash
docker logs zabbix-server 2>&1 | grep "server.*started"
```

Peaks nägema: "Zabbix Server started. Zabbix 7.0.0..."

**Agent passive check test:**
```bash
docker exec zabbix-server zabbix_get -s zabbix-agent -k agent.ping
```

**Mis see käsk teeb:**  
`zabbix_get` on CLI tööriist mis simuleerib passive check'i. Server küsib agendilt `agent.ping` item'i. Peaks tagastama `1`.

Kui tagastab `1` → Agent vastab, ühendus töötab! ✅

✅ **Kontrollpunkt:** Kõik 4 testi õnnestusid

---

## Osa 2: Web Interface

### Samm 1: Ava Brauser

```bash
curl -s http://localhost:8080 | grep -i zabbix | head -1
```

Kui näed HTML'i, web töötab.

Ava: `http://localhost:8080`

---

### Samm 2: Setup Wizard

**⚠️ OLULINE: Docker'iga pole setup wizard'it!**

**Pakettide puhul (apt/yum install):**
- Näeksid setup ekraani
- Konfigureerid DB ühendust käsitsi
- Seadistaks serveri IP
- Kontrolliks PHP sätteid

**Docker'iga:**
- Env vars konfigureerivad automaatselt
- `DB_SERVER_HOST`, `ZBX_SERVER_HOST` jne
- Login ekraan ilmub kohe

**Viide:** [Docker vs Manual Install](https://www.zabbix.com/documentation/7.0/en/manual/installation/containers)

---

### Samm 3: Logi Sisse

**Kasutaja:** `Admin` (suurtäht!)  
**Parool:** `zabbix`

Pärast sisselogimist näed "Global view" dashboardi. See on veel tühi - ühtegi hosti pole konfigureeritud (peale Zabbix serveri enda, aga see tuleb hiljem).

📝 **Küsimus 5:** Miks Docker'is ei ole setup wizard'it, aga pakettidega on?

---

## Osa 3: Lisa Monitooringuhost

### Mis on Host?

**Host** = süsteem mida monitoorid.

Iga host'il on:
- **Hostname** - unikaalne nimi (nt "Zabbix server", "web-01")
- **Interface** - kuidas ühenduda (IP + port + tüüp)
- **Template'd** - valmis item'id ja triggerid
- **Group** - organiseerimiseks (nt "Linux servers", "Databases")

---

### Samm 1: Ava Hosts

**Data collection → Hosts → Create host**

**Zabbix 7.0 menüü muudatus:**  
Varem oli "Configuration". Nüüd "Data collection" - loogilisem (kogud andmeid).

**Viide:** [Host Configuration](https://www.zabbix.com/documentation/7.0/en/manual/config/hosts/host)

---

### Samm 2: Täida Host Andmed

| Väli | Väärtus | Selgitus |
|------|---------|----------|
| **Host name** | `Zabbix server` | Peab ühtima `ZBX_HOSTNAME`'iga! |
| **Groups** | `Linux servers` | Organiseerimine |

---

### Samm 3: Vali Template

**Mis on Template?**

Template = valmis komplekt item'eid ja triggereid. Näiteks "Linux by Zabbix agent":
- ~50 item'i (CPU, mälu, disk, network, processes)
- ~30 triggerit (CPU high, memory low, disk full)
- Graafiku prototüübid
- Discovery reeglid (failisüsteemid, võrguliidesed)

**Ilma template'ita:**  
Peaksid käsitsi lisama iga item'i. 50 item'i × 10 serverit = 500 käsitsi konfiguratsiooni!

**Template'iga:**  
Link template → 50 item'i ilmub automaatselt!

**Vali template:**
- Väljal "Templates" kliki **Select**
- Otsi: `Linux`
- Vali: **"Linux by Zabbix agent"** (MITTE "agent active")

**Passive vs Active template:**
- **"Linux by Zabbix agent"** = Passive checks (server küsib)
- **"Linux by Zabbix agent active"** = Active checks (agent saadab)

Meie kasutame passive mode.

📝 **Küsimus 6:** Mis on template? Miks see on kasulik?

---

### Samm 4: Seadista Interface

**Mis on Interface?**

Interface ütleb serverile KUIDAS hostiga ühenduda:
- **Agent** - Zabbix agent (port 10050)
- **SNMP** - Võrguseadmed (port 161)
- **IPMI** - Serverite riistvaramonitoring
- **JMX** - Java rakendused

**Leia agendi IP:**

```bash
docker inspect zabbix-agent | grep '"IPAddress"' | tail -1
```

Näide: `"IPAddress": "172.20.0.4"`

**Lisa Interface:**
- Kliki **Add**
- Vali **Agent**
- **IP address:** `172.20.0.4` (sinu IP)
- **Connect to:** IP
- **Port:** `10050`

**Port 10050:**  
Agendi listening port. Server saadab siia passive check päringud.

---

### Samm 5: Salvesta

Kliki **Add**.

**Mis nüüd juhtub:**

1. Zabbix Server loob hosti kirje andmebaasis
2. Rakendab template'i (~50 item'i lisatakse automaatselt)
3. Käivitab poller protsessid
4. Hakkab iga 60 sekundi tagant küsima item'eid

⏱️ **Oota 60-90 sekundit**

Server teeb esimese availability check'i.

---

### Samm 6: Kontrolli Ühenduvust

**Data collection → Hosts**

Vaata **"Availability"** veergu:

| Ikoon | Tähendus | Mis see tähendab? |
|-------|----------|-------------------|
| 🟢 **ZBX** | Available | Agent vastab, ühendus töötab ✅ |
| 🔴 **ZBX** | Not available | Ei saa ühendust ❌ |
| ⚪ **ZBX** | Unknown | Veel ei testitud ⏱️ |

**Availability check:**  
Server proovib passive check'i teha. Kui agent vastab → roheline. Kui ei vasta → punane.

**Kui punane:**

**Test 1: Käsitsi passive check**
```bash
docker exec zabbix-server zabbix_get -s 172.20.0.4 -k agent.ping
```

Peaks tagastama `1`.

**Test 2: Kontrolli hostname'i**  
Web'is: `Zabbix server`  
Agent'is: `ZBX_HOSTNAME: "Zabbix server"`  
Kas ühtivad? Suurtähed? Tühikud?

**Test 3: Kontrolli IP'd**  
```bash
docker inspect zabbix-agent | grep IPAddress
```

Kas kasutasid õiget IP'd interface'is?

✅ **Kontrollpunkt:** Roheline ZBX ikoon

📝 **Küsimus 7:** Mida server testib availability check'iga? Mis juhtub kui agent ei vasta?

---

## Osa 4: Vaata Mõõdikuid

### Mis on Item?

**Item** = üks mõõdik mida Zabbix kogub.

Iga item'il on:
- **Key** - unikaalne nimi (nt `system.cpu.util`)
- **Type** - kuidas kogutakse (Agent, HTTP, SNMP, Calculated...)
- **Update interval** - kui sageli (30s, 1m, 5m...)
- **History** - kui kaua säilitada raw data (7 päeva, 30 päeva...)
- **Trends** - agregatsioon (tunni/päeva min/max/avg, 1 aasta)

**Item types:**
- **Zabbix agent** - Passive check (server küsib)
- **Zabbix agent (active)** - Active check (agent saadab)
- **HTTP agent** - HTTP päring
- **Calculated** - Arvutatud teistest item'itest
- **Internal** - Zabbix serveri enda mõõdikud

---

### Samm 1: Latest Data

**Monitoring → Latest data**

Filtris vali: **Zabbix server** → **Apply**

⏱️ Oota 1-2 minutit esimeste andmete saabumiseks.

**Miks andmed ilmuvad:**  
Template "Linux by Zabbix agent" lisas automaatselt ~50 item'i. Server hakkab neid kohe küsima (passive checks).

Peaksid nägema:
- `CPU utilization` - Protsessor kasutus (%)
- `Available memory` - Vaba RAM (bytes)
- `Free disk space on /` - Vaba kettaruum (bytes)
- `System uptime` - Kui kaua süsteem on töötanud (sekundid)

**Update interval:**  
Enamik item'eid uueneb iga 60 sekundi tagant (vaikimisi).

---

### Samm 2: Vaata Item'i Detaile

Kliki item'il **"CPU utilization"**.

Näed:
- **Key:** `system.cpu.util`
- **Type:** Zabbix agent (passive)
- **Update interval:** 1m
- **History storage period:** 7d
- **Trend storage period:** 365d

**History vs Trends:**
- **History** = Raw data (iga mõõtmine eraldi) - säilitatakse 7 päeva
- **Trends** = Agregeeritud (tunni min/max/avg) - säilitatakse 1 aasta

Miks vahet teha? Kettaruum! History võtab palju ruumi. Trends on kompaktsed.

---

### Samm 3: Vaata Graafikut

Kliki **Graph** nupp.

Näed reaalajas CPU utilization graafikut.

**Graafik on olemas, sest:**
- Template lisas item'id ✅
- Server kogub andmeid 1-2 minutit ✅
- History on salvestatud MySQL'i ✅

**Tee CPU koormus (test):**
```bash
docker exec zabbix-agent sh -c "dd if=/dev/zero of=/dev/null &"
sleep 30
docker exec zabbix-agent killall dd
```

Värskenda graafikut - näed spike'i!

---

### Samm 4: Vaata Kõiki Item'eid

**Data collection → Hosts → Zabbix server → Items**

Näed kõiki ~50 item'i template'st:
- CPU items (utilization, load, interrupts...)
- Memory items (available, used, cached...)
- Disk items (free space, inode usage...)
- Network items (incoming/outgoing bytes...)

Iga item kogutakse iga 60 sekundi tagant (passive checks).

✅ **Kontrollpunkt:** Näed mõõdikuid ja graafikuid

📝 **Küsimus 8:** Mis vahe on History ja Trends'il? Miks mõlemad on vajalikud?

---

## Osa 5: Git ja Dokumentatsioon

### Samm 1: Loo .gitignore

**Süsteem töötab edasi!** Me ei peata midagi.

```bash
nano .gitignore
```

Kirjuta:

```
# Docker volumes - liiga suured Git'i jaoks
mysql-data/
zabbix-server-data/

# Logid
*.log
```

**Miks volumes ei pane Git'i?**  
MySQL andmebaas võib olla gigabaidid. Git ei ole mõeldud suurte binaarfailide jaoks.

Salvesta.

---

### Samm 2: Loo README.md

```bash
nano README.md
```

```markdown
# Zabbix 7.0 Monitooringu Labor

Docker Compose põhine Zabbix keskkond.

## Komponendid

- MySQL 8.0 (andmebaas)
- Zabbix Server 7.0 (monitooringu mootor)
- Zabbix Web 7.0 (veebiliides)
- Zabbix Agent 7.0 (self-monitoring)

## Käivitamine

\`\`\`bash
docker-compose up -d
\`\`\`

## Juurdepääs

- **Web:** http://localhost:8080
- **Login:** Admin / zabbix

## Monitooringud

- **Zabbix server** - Self-monitoring (CPU, RAM, disk)
- **Template:** Linux by Zabbix agent (~50 items)

## Peatamine

\`\`\`bash
docker-compose down     # Säilita andmed
docker-compose down -v  # Kustuta kõik
\`\`\`

## Turvalisus

⚠️ **Production'is:**
- Muuda Admin parooli!
- Kasuta \`.env\` faili paroolidele
- Ära pane paroole Git'i

## Viited

- [Zabbix 7.0 Documentation](https://www.zabbix.com/documentation/7.0)
- [Labor juhend](lab01_zabbix_alused.md)
```

Salvesta.

---

### Samm 3: Git Setup

```bash
git init
git add .
git status
```

Peaksid nägema:
```
docker-compose.yml
.gitignore
README.md
```

**EI TOHI** näha:
```
mysql-data/
zabbix-server-data/
```

```bash
git commit -m "Lab 1: Zabbix basic monitoring setup"
```

---

### Samm 4: Push GitHub'i

Loo repo GitHub'is: `zabbix-monitoring-labs`

```bash
git remote add origin https://github.com/<username>/zabbix-monitoring-labs.git
git branch -M main
git push -u origin main
```

✅ **Kontrollpunkt:** Repo on Git'is

---

## Kokkuvõte

Sul on nüüd:
- ✅ Töötav Zabbix 7.0 keskkond
- ✅ Üks monitoritud host (~50 item'i)
- ✅ Dokumenteeritud Git'is

**Peamised Zabbix kontseptsioonid mis peaksid meelde jääma:**

**Monitooringu arhitektuur:**
- **Passive check:** Server küsib → Agent vastab (port 10050)
- **Active check:** Agent saadab → Server võtab vastu (port 10051)
- **Item:** Üks mõõdik (Key + Type + Update interval)
- **Template:** Valmis komplekt item'eid/triggereid (säästab käsitsi konfigu)
- **Hostname:** Peab ühtima agent'is ja web'is (muidu andmed ei seostu)

**Andmete salvestus:**
- **History:** Raw data (iga mõõtmine) - 7 päeva
- **Trends:** Agregeeritud (tunni min/max/avg) - 1 aasta
- **Volumes:** Püsiv salvestus (restart ei kustuta)

---

## Viited

- [Zabbix 7.0 Documentation](https://www.zabbix.com/documentation/7.0)
- [Docker Installation](https://www.zabbix.com/documentation/7.0/en/manual/installation/containers)
- [Host Configuration](https://www.zabbix.com/documentation/7.0/en/manual/config/hosts/host)
- [Items](https://www.zabbix.com/documentation/7.0/en/manual/config/items)
- [Templates](https://www.zabbix.com/documentation/7.0/en/manual/config/templates)