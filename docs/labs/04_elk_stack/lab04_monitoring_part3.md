# Labor 3 - Grafana ja Loki seadistamine

## Sissejuhatus

Selles labori viimases osas seadistate Grafana visualiseerimissüsteemi ja Loki logikogumise lahenduse. 

## 1. Docker Compose faili täiendamine

Enne labori alustamist on vaja kontrollida ja täiendada Docker Compose faili, et kõik teenused oleksid õigesti seadistatud.

### 1.1 Loki teenuse täiendamine

Avage Docker Compose fail:
```bash
nano docker-compose.yml
```

Leidke Loki teenuse konfiguratsioon ja lisage puuduv volume:
```yaml
loki:
  image: grafana/loki:2.7.3
  container_name: loki
  command: -config.file=/etc/loki/local-config.yaml
  ports:
    - "3100:3100"
  volumes:
    - ./data/loki:/etc/loki  # LISA SEE RIDA!
  restart: unless-stopped
  networks:
    - monitoring-network
```

### 1.2 Promtail teenuse täiendamine

Leidke Promtail teenuse konfiguratsioon ja lisage puuduv volume:
```yaml
promtail:
  image: grafana/promtail:2.7.3
  container_name: promtail
  volumes:
    - /var/log:/var/log
    - ./data/promtail:/etc/promtail
    - /var/lib/docker/containers:/var/lib/docker/containers:ro  # LISA SEE RIDA!
    # Docker socketi volume on juba olemas, mis on hea
  command: -config.file=/etc/promtail/config.yml
  depends_on:
    - loki
  restart: unless-stopped
  networks:
    - monitoring-network
```

### 1.3 Rakenda muudatused

Salvestage muudatused ja taaskäivitage teenused:
```bash
docker-compose down loki promtail
docker-compose up -d loki promtail
```

## 2. Loki ja Promtail seadistamine

### 2.1 Loo vajalikud kataloogid

```bash
mkdir -p ./data/loki
mkdir -p ./data/promtail
```

### 2.2 Loo Loki konfiguratsioonifail

```bash
nano ./data/loki/local-config.yaml
```

Kopeeri sinna järgmine sisu:
```yaml
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 5m
  chunk_retain_period: 30s

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /tmp/loki/boltdb-shipper-active
    cache_location: /tmp/loki/boltdb-shipper-cache
    cache_ttl: 24h
    shared_store: filesystem
  filesystem:
    directory: /tmp/loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h
```

### 2.3 Loo Promtail konfiguratsioonifail

```bash
nano ./data/promtail/config.yml
```

Kopeeri sinna järgmine sisu:
```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /etc/promtail/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*.log

  - job_name: containers
    static_configs:
      - targets:
          - localhost
        labels:
          job: containerlogs
          __path__: /var/lib/docker/containers/*/*.log

  - job_name: zabbix
    static_configs:
      - targets:
          - localhost
        labels:
          job: zabbix
          __path__: /var/log/zabbix/*.log

  - job_name: nginx
    static_configs:
      - targets:
          - localhost
        labels:
          job: nginx
          __path__: /var/log/nginx/*.log

  - job_name: mysql
    static_configs:
      - targets:
          - localhost
        labels:
          job: mysql
          __path__: /var/log/mysql/*.log
          
  # Docker konteineri logide jälgimine
  - job_name: docker
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        regex: '/(.*)'
        target_label: 'container'
```

### 2.4 Taaskäivita Loki ja Promtail teenused

```bash
docker-compose restart loki promtail
```

### 2.5 Kontrolli, et teenused töötavad

```bash
docker-compose ps loki promtail
docker-compose logs loki | tail
docker-compose logs promtail | tail
```

## 3. Grafana põhiseadistus

### 3.1 Ligipääs Grafana veebiliidesele

1. Ava veebibrauser ja navigeeri URL-ile:
   ```
   http://your-server-ip:3000
   ```

2. Logi sisse vaikimisi kasutajanime ja parooliga:
   - Kasutajanimi: **admin**
   - Parool: **admin**

3. Kui sul palutakse parooli muuta, sisesta uus turvaline parool ja kliki **Submit**.

### 3.2 Lisa Loki andmeallikas

1. Navigeeri **Configuration** → **Data Sources** vasakul menüüs.

2. Kliki **Add data source**.

3. Otsi ja vali "Loki" nimekirjast.

4. Sisesta järgmised seaded:
   - Name: **Loki**
   - URL: **http://loki:3100**
   - Access: **Server (default)**

5. Kliki **Save & Test**.

   Peaksid nägema rohelist teadet, mis kinnitab edukat ühendust Lokiga.

### 3.3 Logide vaatamine Lokis

1. Kliki **Explore** ikoonil (kompass) vasakul menüüs.

2. Vali **Loki** andmeallikate rippmenüüst lehe ülaosas.

3. Sisesta lihtne päring logide nägemiseks:
   ```
   {job="varlogs"}
   ```

4. Klikki **Run query** logide nägemiseks.

5. Docker konteineri logide jaoks kasuta:
   ```
   {job="docker"}
   ```

6. Otsinguid saad täpsustada lisades teksti otsingutingimusi:
   ```
   {job="docker"} |= "error"
   ```
   See näitab ainult Docker logisid, mis sisaldavad sõna "error".

7. Kasuta ajavahemiku valijat üleval paremal, et kohandada, millise perioodi logisid kuvatakse.

**Märkus:** Võib kuluda mõni minut, enne kui Promtail kogub logisid ja saadab need Lokisse. Kui te logisid kohe ei näe, oodake mõni minut ja proovige uuesti.

### 3.4 Lisa Zabbix andmeallikas

Kui sa ei leia Zabbix andmeallikat, siis installi see:
```bash
docker exec -it grafana sh
docker exec -it grafana grafana-cli plugins install alexanderzobnin-zabbix-app
docker ps | grep grafana
docker-compose restart grafana
```

Seejärel seadista Zabbix andmeallikas:
- Konfigureeri Zabbix andmeallikas:
  URL väljale: http://zabbix-web:8080/api_jsonrpc.php
- Kasutajanimi: Admin
- Parool: zabbix

```bash
Võib-olla pead lisama ka MySQL andmeallika (ZabbixDB)

Configuration → Data Sources
Click "Add data source"
Select "MySQL" as the data source type
Configure the MySQL connection:

Name: ZabbixDB (või mis tahes nimi, mida eelistad)
Host: zabbix-mysql
Database: zabbix
User: zabbix
Password: zabbix_pwd

Click "Save & Test" to verify the connection works
```

## 4. Esimese logidashboardi loomine

Loome lihtsa dashboardi logide jälgimiseks:

1. Navigeeri vasakult menüüst **Dashboards** → **+ New Dashboard**.

2. Kliki **Add visualization**.

3. Päringueditoris vali andmeallikaks **Loki**.

4. Lisa teine paneel süsteemi logidega, klikkides uuesti **Add panel** ja kasutades päringut:
   ```
   {job="varlogs"}
   ```
   
5. Salvesta dashboard klikkides kettaikooni üleval paremal ja anna talle nimi, nt "System Monitoring".

## 5. Testlogide genereerimine

Genereerime mõned testilogid, et neid oleks võimalik visualiseerida:

1. Genereeri süsteemi logid:
   ```bash
   docker-compose exec zabbix-agent bash -c 'for i in {1..20}; do logger "INFO: System check completed successfully at $(date)"; sleep 1; done'
   ```

2. Genereeri vealogid:
   ```bash
   docker-compose exec zabbix-agent bash -c 'for i in {1..5}; do logger "ERROR: Database connection timeout at $(date)"; sleep 1; done'
   ```

3. Genereeri veebiseveri logid, tehes HTTP päringuid:
   ```bash
   for i in {1..10}; do curl http://localhost:8080/ >/dev/null 2>&1; curl http://localhost:8080/login.php >/dev/null 2>&1; sleep 1; done
   ```

## 6. Logi analüüsi dashboardi loomine Grafanas

Loome dashboardi logide analüüsimiseks:

1. Navigeeri **Dashboards** → **New Dashboard**.

2. Kliki **Add new panel**.

3. Vali **Loki** andmeallikaks.

4. Sisesta LogQL päring süsteemi logide nägemiseks:
   ```
   {job="varlogs"}
   ```

5. Konfigureeri paneel:
   - Title: **System Logs**
   - Visualization: Vali **Logs**
   - Kliki **Apply**

6. Lisa paneel vealogide jaoks:
   - Kliki **Add new panel**
   - Vali **Loki** andmeallikaks
   - Sisesta LogQL päring:
     ```
     {job="varlogs"} |= "ERROR"
     ```
   - Title: **Error Logs**
   - Visualization: Vali **Logs**
   - Kliki **Apply**

7. Lisa paneel logide mahu jälgimiseks:
   - Kliki **Add new panel**
   - Vali **Loki** andmeallikaks
   - Sisesta LogQL päring:
     ```
     sum(count_over_time({job="varlogs"}[5m])) by (job)
     ```
   - Title: **Log Volume (5m intervals)**
   - Visualization: Vali **Time series**
   - Kliki **Apply**

8. Lisa paneel veamäära nägemiseks:
   - Kliki **Add new panel**
   - Vali **Loki** andmeallikaks
   - Sisesta kaks päringut:
     - A: `sum(count_over_time({job="varlogs"} |= "ERROR"[5m]))`
     - B: `sum(count_over_time({job="varlogs"}[5m]))`
   - Transform vahelehel lisa "Reduce" transformatsioon:
     - Mode: **Binary operation**
     - Operation: **A/B** (jagamine)
     - Multiply by: **100** (protsendi saamiseks)
   - Title: **Error Rate (%)**
   - Visualization: Vali **Gauge**
   - Kliki **Apply**

9. Salvesta dashboard:
   - Kliki salvestamise ikooni (💾) üleval paremal
   - Name: **Log Analysis**
   - Folder: **Application Monitoring**
   - Kliki **Save**

## 7. LogQL päringute loomine spetsiifiliste mustrite jaoks

LogQL on Loki päringukeel. Harjutame mõnede keerukamate päringute loomist:

1. Lisa uus paneel oma Log Analysis dashboardi.

2. Vali **Loki** andmeallikaks.

3. Proovi järgmisi LogQL päringuid:

   a. Filtreeri konkreetsete tekstimustrite järgi:
   ```
   {job="varlogs"} |= "connection" |= "timeout"
   ```

   b. Loenda vigu aja jooksul:
   ```
   count_over_time({job="varlogs"} |= "ERROR"[1h])
   ```

   c. Eraldage ja loendage veatüüpide järgi, kasutades regex mustrit:
   ```
   sum by (error_type) (count_over_time({job="varlogs"} |~ "ERROR: ([a-zA-Z ]+)" [1h]))
   ```

4. Konfigureeri paneel:
   - Title: **Error Patterns**
   - Vali sobiv visualiseerimisviis vastavalt päringule
   - Kliki **Apply**

5. Salvesta dashboard.

## 8. Logide ja mõõdikute ühendamine

Tervikliku monitooringu võimsus seisneb logide ja mõõdikute ühendamises. Loome dashboardi, mis näitab seda:

1. Navigeeri **Dashboards** → **New Dashboard**.

2. Kliki **Add new panel**.

3. Loo mitme paneeliga paigutus:
   - CPU kasutamise graafik (Zabbixist)
   - Süsteemi logid (Lokist)
   - Veebi reageerimisaeg (Zabbixist)
   - Veebi juurdepääsulogid (Lokist)

4. Kasuta mall-muutujaid, et võimaldada filtreerimist hosti järgi:
   - Kliki hammasratta ikoonil üleval paremal, et pääseda dashboardi seadeteni
   - Vali "Variables" ja kliki "Add variable"
   - Name: **host**
   - Type: **Query**
   - Data source: **Zabbix**
   - Query type: **Host**
   - Kliki **Update**

5. Pane oma paneelid kasutama hosti muutujat, valides selle hosti rippmenüüst.

6. Salvesta dashboard:
   - Name: **Unified Monitoring**
   - Folder: **Infrastructure Monitoring**
   - Kliki **Save**

## 9. Lõpuülesanded

### 9.1 Dashboardi rotatsiooni seadistamine

NOC (Network Operations Center) ekraani jaoks võite seadistada automaatse dashboardide rotatsiooni:

1. Installi Dashboard Carousel plugin:
   ```bash
   docker-compose exec grafana grafana-cli plugins install smartmakers-trafficlight-panel
   docker-compose restart grafana
   ```

2. Navigeeri **Dashboards** → **Playlists**.

3. Kliki **New playlist**.

4. Sisesta üksikasjad:
   - Name: **Monitoring Overview**
   - Interval: **1m** (1 minut)
   - Vali oma dashboardid, mida kaasata
   - Kliki **Save**

5. Esitusloendi käivitamiseks kliki playlist ja seejärel **Start playlist**.

### 9.2 Dashboardi jagamise seadistamine

Seadistame meeskonnapääsu dashboardide jagamiseks:

1. Navigeeri **Configuration** → **Users**.

2. Kliki **Invite**, et lisada uus vaatajakasutaja.

3. Sisesta e-posti aadress ja vali **Viewer** roll.

4. Kliki **Submit**.

### 9.3 Kontrolli kogu monitooringusüsteemi

Veendume, et kõik komponendid töötavad koos:

1. Navigeeri läbi kõigi oma dashboardide, et kontrollida, kas need näitavad andmeid.

2. Genereeri mõned testsündmused:
   ```bash
   # Genereeri CPU koormus
   docker-compose exec zabbix-agent stress --cpu 2 --timeout 60
   
   # Genereeri logisündmused
   docker-compose exec zabbix-agent bash -c 'for i in {1..10}; do logger "WARNING: High CPU detected at $(date)"; sleep 1; done'
   ```

3. Kontrolli, et:
   - Mõõdikud Grafanas näitavad CPU tõusu
   - Logid Lokis näitavad hoiatusteated
   - Ühendatud dashboard näitab mõlemad koos

4. Proovi andmete filtreerimist dashboard muutujate abil.

### 9.4 Tee nõutavad ekraanipildid esitamiseks

Tee järgmised ekraanipildid:

1. Zabbix hosti konfiguratsiooniekraan koos elementide ja päästikutega
2. Sinu süsteemi monitooringu dashboard Grafanas
3. Logi analüüsimise dashboard, mis näitab mustreid ja korrelatsioone

## Kontrollnimekiri labori lõpetamiseks

- [ ] Docker Compose fail on korrektselt muudetud
- [ ] Loki ja Promtail on seadistatud ja töötavad
- [ ] Grafana on seadistatud ja ühendatud Lokiga
- [ ] Testlogid on genereeritud
- [ ] Logi analüüsimise dashboard on loodud
- [ ] Logid ja mõõdikud on ühises dashboardis ühendatud
- [ ] Dashboardi automaatne rotatsioon on seadistatud
- [ ] Vajalikud ekraanipildid on tehtud