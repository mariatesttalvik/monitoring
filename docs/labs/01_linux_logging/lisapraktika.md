# Linux Logimise Lisapraktika

**Eeldused:** Põhilab on tehtud (keskne logiserver 2 VM-ga töötab)

Need harjutused laiendavad põhilabori funktsionaalsust production-tasemel lahendustega. Iga harjutus keskendub ühele tehnikale, mida kasutatakse reaalsetes IT-keskkondades.

---

## 1. Logide Automaatne Pööramine (Log Rotation)

Põhilabors lõime logiserveri, kus kõik logid lähevad `/var/log/remote/syslog.log` faili. Probleem: see fail kasvab lõpmatult. Päris elus täidaks see ketta mõne nädalaga. logrotate lahendab selle automaatselt.

**Probleem:** Ilma log rotation'ita täitub ketas logidega. Näiteks server, mis saab 1000 logisõnumit tunnis, genereerib ~100MB logisid päevas. Kuu ajaga on see 3GB. Aasta jooksul 36GB - ainult ühe teenuse logid!

**Lahendus:** logrotate pöörab logifaile automaatselt - vana fail arhiveeritakse ja kompresseeritakse, uus tühi fail luuakse. Saad määrata kui kaua logisid säilitada ja kui tihti neid pöörata.

### Kuidas logrotate töötab

logrotate käivitatakse cron'i kaudu iga päev (vaata `/etc/cron.daily/logrotate`). See loeb konfiguratsioone `/etc/logrotate.d/` kaustast ja rakendab reegleid.

Protsess:

1. Kontrollitakse kas fail vajab pööramist (nt kas päev on möödas)
2. Vana fail nimetatakse ümber: `syslog.log` → `syslog.log.1`
3. Eelmine `syslog.log.1` → `syslog.log.2.gz` (kompresseeritakse)
4. Luuakse uus tühi `syslog.log`
5. rsyslog saab signaali (`HUP`) et avada uus fail

### Konfiguratsioon

Loome logiserveri (VM1) jaoks logrotate konfiguratsiooni:

```bash
# VM1 (LogServer)
sudo nano /etc/logrotate.d/remote-logs
```

Lisa järgmine konfiguratsioon:

```
/var/log/remote/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 syslog adm
    sharedscripts
    postrotate
        /usr/bin/killall -HUP rsyslogd
    endscript
}
```

**Selgitus:**

| Parameeter | Tähendus |
|------------|----------|
| `daily` | Pöörab logisid iga päev |
| `rotate 7` | Hoiab 7 päeva logisid (pärast seda kustutab) |
| `compress` | Kompresseerib vanad logid gzip'ga |
| `delaycompress` | Jätab kõige uuema roteeritud faili kompresseerimata (võib veel midagi kirjutada) |
| `missingok` | Ei anna viga kui logifail puudub |
| `notifempty` | Ei pööra tühje faile |
| `create 0644 syslog adm` | Loob uue faili õigustega 644, omanik syslog:adm |
| `postrotate` | Käsk mis käivitatakse pärast pööramist |
| `killall -HUP rsyslogd` | Saadab rsyslog'ile signaali, et avada uus logifail |

**Harjutus: Seadista logrotate oma logiserveri jaoks**

**Nõuded:**

- [ ] Loo konfiguratsioon `/etc/logrotate.d/remote-logs`
- [ ] Logid pööratakse iga päev kell 00:00
- [ ] Säilitatakse 14 päeva logisid (mitte 7)
- [ ] Vanemad kui 7 päeva logid kompresseeritakse
- [ ] Kui pööramine toimub, rsyslog'ile saadetakse HUP signaal

**Näpunäiteid:**

- Testi konfiguratsiooni süntaksit: `sudo logrotate -d /etc/logrotate.d/remote-logs`
- Testi käsitsi pööramist: `sudo logrotate -f /etc/logrotate.d/remote-logs`
- Vaata kas pööratud failid ilmusid: `ls -lh /var/log/remote/`
- Kontrolli kas kompresseerimine toimis: `file /var/log/remote/*.gz`

**Testimine:**

```bash
# Testi logrotate konfiguratsiooni (dry-run)
sudo logrotate -d /etc/logrotate.d/remote-logs

# Käivita logrotate käsitsi (sundpööramine)
sudo logrotate -f /etc/logrotate.d/remote-logs

# Kontrolli kas failid pöördusid
ls -lh /var/log/remote/

# Peaksid nägema:
# syslog.log       <- uus tühi fail
# syslog.log.1     <- eelmise päeva logid (komprimeerimata)
# syslog.log.2.gz  <- 2 päeva tagasi (kompresseeritud)

# Vaata kompresseeritud faili sisu (ilma dekompresseerimata)
zcat /var/log/remote/syslog.log.2.gz | head -20

# Kontrolli faili õigusi
ls -l /var/log/remote/syslog.log
# Peaks olema: -rw-r--r-- syslog adm
```

**Boonus:**

- Seadista erinevad rotation reeglid auth logidele (hoia 30 päeva) ja test logidele (hoia 3 päeva)
- Lisa email teatis kui logifail ületab 100MB
- Loo skript mis kustutab kõik logid vanemad kui 90 päeva

---

## 2. Turvalisuse Jälgimine auditd'ga

Logiserver on oluline turvakomponent - kui keegi muudab logisid, võib tõendusmaterjal kaduda. auditd jälgib failisüsteemi muudatusi ja salvestab kes, mida, millal tegi. See on nõutud paljudes compliance standardites (PCI-DSS, HIPAA).

**Probleem:** rsyslog logib mis süsteemis toimub, aga EI logi kes logifaile ennast muudab. Kui ründaja kustuks `/var/log/remote/syslog.log`, ei oleks jälge. Samuti peame teadma kes rsyslog'i konfiguratsiooni muudab.

**Lahendus:** auditd jälgib konkreetseid faile ja katalooge ning logib kõik nende muutmise katsed. Need logid on kaitstud ja neid ei saa kergesti kustutada.

### auditd vs rsyslog

| Omadus | rsyslog | auditd |
|--------|---------|--------|
| Mida jälgib | Rakenduste ja süsteemi sõnumid | Failisüsteemi muudatused, syscall'id |
| Eesmärk | Üldine logimine | Turvalisuse audit |
| Logi asukoht | `/var/log/syslog` | `/var/log/audit/audit.log` |
| Kaitse | Tavaliselt pole | Kaitstud kernel'i tasemel |
| Kasutus | Troubleshooting, monitooring | Compliance, forensics |

### Paigaldamine ja seadistamine

```bash
# VM1 (LogServer)
# Paigalda auditd
sudo apt install -y auditd audispd-plugins

# Kontrolli kas töötab
sudo systemctl status auditd
```

auditd peaks olema "active (running)".

### Jälgimise reeglite lisamine

Kasutame `auditctl` käsku reeglite loomiseks. Need reeglid kaovad pärast reboot'i, nii et peame need salvestama konfiguratsioonifaili.

```bash
# Lisa jälgimise reeglid
sudo auditctl -w /var/log/remote -p wa -k log_directory_changes
sudo auditctl -w /etc/rsyslog.conf -p wa -k rsyslog_config_changes
sudo auditctl -w /etc/rsyslog.d/ -p wa -k rsyslog_config_changes

# Kontrolli reegleid
sudo auditctl -l
```

**Selgitus:**

- `-w /path` = watch (jälgi seda teed)
- `-p wa` = permissions: **w**rite, **a**ttribute change
- `-k key_name` = märksõna (kasutad hiljem otsinguks)

Teised võimalused:
- `-p r` = read (lugedes)
- `-p x` = execute (käivitades)
- `-p wx` = write või execute

### Reeglite püsivaks tegemine

```bash
# Salvesta reeglid konfiguratsioonifaili
sudo nano /etc/audit/rules.d/logging.rules
```

Lisa sinna:

```
# Jälgi logiserveri kataloogi
-w /var/log/remote -p wa -k log_directory_changes

# Jälgi rsyslog konfiguratsioone
-w /etc/rsyslog.conf -p wa -k rsyslog_config_changes
-w /etc/rsyslog.d/ -p wa -k rsyslog_config_changes

# Jälgi auditd enda konfiguratsiooni
-w /etc/audit/ -p wa -k audit_config_changes
```

Laadi reeglid:

```bash
sudo augenrules --load
```

### Logide vaatamine ausearch'iga

```bash
# Otsi kõiki muudatusi logide kataloogis
sudo ausearch -k log_directory_changes

# Otsi tänaseid sündmusi
sudo ausearch -k log_directory_changes -ts today

# Otsi konkreetse kasutaja tegevusi
sudo ausearch -ua sysadmin

# Otsi konkreetse faili sündmusi
sudo ausearch -f /var/log/remote/syslog.log

# Vormindatud väljund (loetavam)
sudo ausearch -k log_directory_changes -i
```

### Aruannete loomine aureport'iga

```bash
# Üldine kokkuvõte
sudo aureport

# Failide muudatuste aruanne
sudo aureport -f

# Kasutajate tegevuste aruanne
sudo aureport -u

# Ajaperioodi aruanne
sudo aureport -ts yesterday -te today
```

**Harjutus: Seadista auditd jälgima logiserveri turvasündmusi**

**Nõuded:**

- [ ] auditd on paigaldatud ja käivitatud
- [ ] Jälgitakse `/var/log/remote` kataloogi muudatusi
- [ ] Jälgitakse kõiki rsyslog konfiguratsioonifaile
- [ ] Jälgitakse `/etc/passwd` faili muudatusi (bonus turvalisuseks)
- [ ] Reeglid on salvestatud ja püsivad reboot'i järel
- [ ] Testimisel: manuaalne muudatus logib sündmuse

**Näpunäiteid:**

- Testi reegleid: puuduta faili (`touch /var/log/remote/test.log`) ja otsi ausearch'iga
- Vaata audit logi reaalajas: `sudo tail -f /var/log/audit/audit.log`
- Kui ei näe sündmusi, kontrolli kas auditd töötab: `systemctl status auditd`
- aureport annab hea ülevaate: `sudo aureport -f`

**Testimine:**

```bash
# Testi kas jälgimine töötab
# 1. Tee muudatus
sudo touch /var/log/remote/test_file.txt

# 2. Otsi sündmust
sudo ausearch -k log_directory_changes -i

# Peaksid nägema:
# type=SYSCALL ... syscall=openat success=yes ... comm="touch" exe="/usr/bin/touch"
# type=PATH ... name="/var/log/remote/test_file.txt" ... 

# 3. Testi rsyslog konfigi muudatust
sudo nano /etc/rsyslog.conf
# (muuda midagi, salvesta)

# 4. Otsi muudatust
sudo ausearch -k rsyslog_config_changes -ts recent -i

# 5. Vaata üldist statistikat
sudo aureport -f | head -20

# 6. Kontrolli päeva kokkuvõtet
sudo aureport --summary
```

**Boonus:**

- Seadista jälgima SSH konfiguratsioonifaile (`/etc/ssh/sshd_config`)
- Jälgi kõiki sudo käske: `-a always,exit -F arch=b64 -S execve -F euid=0 -k root_commands`
- Loo igapäevane cron job mis saadab aureport kokkuvõtte emailile

---

## 3. Reaalajas Logide Dashboard

Production keskkonnas ei saa sa ainult logifaile vaadata - vajad visuaalset ülevaadet mis süsteemis toimub. Loome lihtsa bash-põhise dashboard'i, mis näitab olulisemaid metrikaid reaalajas.

**Probleem:** `tail -f /var/log/remote/syslog.log` näitab logisid, aga sa ei näe kohe probleeme. Pead käsitsi otsima vigu, loendama sündmusi, jälgima kettakasutust. Suurtes süsteemides on see võimatu.

**Lahendus:** Lihtsate skriptidega saad luua dashboard'i mis näitab:
- Vigade arv viimase 5 minuti jooksul
- Hoidiste ja kriitilistesündmuste loend
- Kettakasutus logide jaoks
- Kõige aktiivsemad kliendid (kes saadab kõige rohkem logisid)
- Reaalajas sündmused

### Dashboard skripti loomine

```bash
# VM1 (LogServer)
# Paigalda vajalikud tööriistad
sudo apt install -y bc sysstat

# Loo dashboard skript
sudo nano /opt/log_dashboard.sh
```

Lisa järgmine sisu:

```bash
#!/bin/bash

# Logide Dashboard - Reaalajas Monitooring
# Käivita: /opt/log_dashboard.sh

LOG_FILE="/var/log/remote/syslog.log"
REFRESH_INTERVAL=5

# Funktsioon: Loe vigade arv
count_errors() {
    local minutes=$1
    local since=$(date -d "$minutes minutes ago" "+%b %d %H:%M")
    grep -c "error\|ERROR\|Error" $LOG_FILE | tail -1000 | wc -l
}

# Funktsioon: Leia top 5 kõige aktiivsemad kliendid
top_clients() {
    tail -1000 $LOG_FILE | \
        awk '{print $4}' | \
        sort | uniq -c | \
        sort -rn | \
        head -5
}

# Peamine tsükkel
while true; do
    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║     LOGISERVERI DASHBOARD - $(date '+%H:%M:%S')      ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    
    # Vigade loendur
    ERROR_COUNT=$(tail -1000 $LOG_FILE | grep -ic "error")
    WARN_COUNT=$(tail -1000 $LOG_FILE | grep -ic "warn")
    
    echo "STATISTIKA (viimased 1000 rida):"
    echo "   Vigu:     $ERROR_COUNT"
    echo "   Hoiatusi: $WARN_COUNT"
    echo ""
    
    # Kettakasutus
    echo "KETTARUUM:"
    df -h /var/log/remote | tail -1 | \
        awk '{printf "   Kasutatud: %s / %s (%s)\n", $3, $2, $5}'
    
    # Logifailide suurused
    LOG_SIZE=$(du -sh /var/log/remote | awk '{print $1}')
    echo "   Logide suurus: $LOG_SIZE"
    echo ""
    
    # Aktiivsemad kliendid
    echo "TOP 5 AKTIIVSED KLIENDID:"
    top_clients | while read count client; do
        printf "   %-20s %5d logisõnumit\n" "$client" "$count"
    done
    echo ""
    
    # Viimased kriitilistesündmused
    echo "VIIMASED VEAD:"
    tail -1000 $LOG_FILE | grep -i "error" | tail -3 | \
        cut -c 1-80 | sed 's/^/   /'
    echo ""
    
    echo "───────────────────────────────────────────────────"
    echo "  Uuendamine iga ${REFRESH_INTERVAL}s | Ctrl+C = välju"
    
    sleep $REFRESH_INTERVAL
done
```

Anna käivitamisõigused:

```bash
sudo chmod +x /opt/log_dashboard.sh
```

### Dashboard'i täiendused

Loome veel paar kasulikku skripti:

**1. Vigade analüüsija:**

```bash
sudo nano /opt/analyze_errors.sh
```

```bash
#!/bin/bash
# Analüüsi vigu logides

LOG_FILE="/var/log/remote/syslog.log"

echo "=== VIGADE ANALÜÜS ==="
echo ""
echo "Vigade tüübid (top 10):"
grep -i "error" $LOG_FILE | \
    awk -F "error" '{print $2}' | \
    cut -d ' ' -f 1-5 | \
    sort | uniq -c | \
    sort -rn | \
    head -10

echo ""
echo "Vigu tunni kaupa (viimased 24h):"
for hour in {0..23}; do
    h=$(printf "%02d" $hour)
    count=$(grep "$(date '+%b %d') $h:" $LOG_FILE | grep -ic "error")
    if [ $count -gt 0 ]; then
        printf "%s:00 - %4d vigu\n" "$h" "$count"
    fi
done
```

```bash
sudo chmod +x /opt/analyze_errors.sh
```

**2. Klientide aktiivsuse raport:**

```bash
sudo nano /opt/client_report.sh
```

```bash
#!/bin/bash
# Klientide aktiivsuse raport

LOG_FILE="/var/log/remote/syslog.log"

echo "=== KLIENTIDE RAPORT ==="
echo ""
echo "Logisõnumeid kliendi kohta:"
awk '{print $4}' $LOG_FILE | \
    sort | uniq -c | \
    sort -rn | \
    awk '{printf "%-30s %10d sõnumit\n", $2, $1}'

echo ""
echo "Kokku unikaalseid kliente: $(awk '{print $4}' $LOG_FILE | sort -u | wc -l)"
echo "Kokku logisõnumeid: $(wc -l < $LOG_FILE)"
```

```bash
sudo chmod +x /opt/client_report.sh
```

**Harjutus: Loo oma logiserveri monitooringu dashboard**

**Nõuded:**

- [ ] Dashboard skript on loodud ja täidetav
- [ ] Näitab vigade ja hoiatuste arvu
- [ ] Näitab kettakasutust logide jaoks
- [ ] Näitab top 5 aktiivseimat klienti
- [ ] Näitab viimased 5 viga või kriitilist sündmust
- [ ] Uuendab andmeid iga 5 sekundi tagant
- [ ] Lisa boonus: värviline väljund (punane = viga, kollane = hoiatus)

**Näpunäiteid:**

- Kasuta `grep -i` vigade otsimiseks (case-insensitive)
- `awk '{print $4}'` võtab 4. veeru (hostname)
- `sort | uniq -c` loendab kordumisi
- `tail -1000` piir ab jõudlust (ei töötle kogu faili)
- Värvi lisamiseks: `echo -e "\033[31mPunane tekst\033[0m"`

**Testimine:**

```bash
# Käivita dashboard
/opt/log_dashboard.sh

# Teises terminalis genereeri teste logisid (VM2)
for i in {1..50}; do
    logger -p daemon.error "TEST ERROR #$i: $(date)"
    logger -p daemon.warn "TEST WARNING #$i: $(date)"
    sleep 1
done

# Dashboard peaks näitama:
# - Vigade arvu kasvamas
# - Sinu kliendi nime top 5-s
# - Teste vigasid viimaste vigade nimekirjas

# Testi ka teisi skripte
/opt/analyze_errors.sh
/opt/client_report.sh
```

**Boonus:**

- Lisa dashboard'i CPU ja RAM kasutus: `top -bn1 | grep "Cpu\|Mem"`
- Saada email kui vigade arv ületab 100 viimase 5 minuti jooksul
- Loo web-põhine dashboard kasutades Python Flask'i või Node.js
- Salvesta statistika SQLite andmebaasi ja tee trendi graafikud

---

## Kokkuvõte

Nende 3 harjutusega omandad olulised production-level oskused:

1. **logrotate** - logid ei täida kettaruumi, säilitatakse aja jooksul
2. **auditd** - turvalisuse jälgimine, compliance nõuete täitmine
3. **Dashboard** - reaalajas ülevaade süsteemi seisundist

Need tehnikad on kasutusel igas professionaalses IT-keskkonnas. Järgmised sammud:

- **ELK Stack moodul** - õpid Elasticsearch/Logstash/Kibana kasutamist, mis on võimsam kui bash skriptid
- **Zabbix moodul** - alerting ja pikaajaline monitooring
- **Production deployment** - seadista see süsteem pärisele serverile (mitte VM-le)

Edu!

