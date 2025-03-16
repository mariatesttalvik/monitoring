# Zabbix
## Zabbix. Paigaldamine ja seadistamine

- Zabbixi ajalugu ja arhitektuur
- Andmete kogumine
- Paigaldamine
- Seadistamine

---

## Ajalugu

- Zabbix on avatud lähtekoodiga jälgimis- ja olekute jälgimissüsteem, mille kirjutas Aleksei Vladõšev
- Zabbix sai alguse 1998. aastal Läti pangas siseprojektina
- 7. aprillil 2001 avaldati süsteem GPL litsentsi all
- Esimene stabiilne versioon — 1.0 ilmus 23. märtsil 2004
- Aprillis 2005 loodi Läti ettevõte SIA Zabbix projekti haldamiseks

![Zabbix Logo](https://upload.wikimedia.org/wikipedia/commons/b/bf/Zabbix_logo.png)

---

## Arhitektuur

![PILT: Zabbixi arhitektuuri skeem näitab Zabbix agenti, proxyt, serverit, andmebaasi ja liidest](https://blog.zabbix.com/wp-content/uploads/2021/01/4.jpg)

---

## Andmete kogumine

[![PILT: Andmete kogumise tasemete skeem: riistvara, operatsioonisüsteem, võrk, virtuaalkiht, andmebaaside tööriistad, rakendused](https://blog.zabbix.com/wp-content/uploads/2019/11/10.20.jpg)](https://blog.zabbix.com/zabbix-integration-with-big-data-systems-in-large-scale-environment/8844/)

![Zabbix Big Data Integration](https://blog.zabbix.com/wp-content/uploads/2019/11/2.27.jpg)

[Rohkem leiad: Zabbix integration with Big Data systems in large-scale environment](https://blog.zabbix.com/zabbix-integration-with-big-data-systems-in-large-scale-environment/8844/)

---

## Andmete kogumise meetodid

- Pull
  - Teenuste kontrollid
  - Passiivne agent
  - SSH/Telnet
- Push
  - Aktiivne agent
  - Zabbix Trapper ja SNMP Traps
  - Logifailide jälgimine

---

## Aktiivne/passiivne agent

![Aktiivse ja passiivse agendi töö põhimõtte skeem](https://bestmonitoringtools.com/wp-content/uploads/2020/01/differences_between_Zabbix_agent_active_and_passive_check-768x465.png)

---

## Nõuded

### Riistvara konfiguratsioonide näited

| Nimi | Platvorm | CPU/Mälu | Andmebaas | Jälgitavate seadmete arv |
|------|----------|---------|-----------|--------------------------|
| Väike | Ubuntu Linux | PII 350MHz 256MB | MySQL MyISAM | 20 |
| Keskmine | Ubuntu Linux 64 bit | AMD Athlon 3200+ 2GB | MySQL InnoDB | 500 |
| Suur | Ubuntu Linux 64 bit | Intel Dual Core 6400 4GB | RAID10 MySQL InnoDB või PostgreSQL | >1000 |
| Väga suur | RedHat Enterprise | Intel Xeon 2xCPU 8GB | Fast RAID10 MySQL InnoDB, PostgreSQL või Oracle | >10000 |

---

## Zabbixi paigaldamine (1)

```bash
# Paigaldame Zabbixi hoidla
$ rpm -Uvh https://repo.zabbix.com/zabbix/6.4/rhel/8/x86_64/zabbix-release-6.4-1.el8.noarch.rpm
$ dnf clean all

# Paigaldame zabbix-serveri, zabbix-agendi, zabbix-frontend
$ dnf module switch-to php:7.4
$ dnf install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-sql-scripts 
zabbix-selinux-policy zabbix-agent

# Paigaldame MySQL
$ dnf install mysql-server
$ systemctl start mysqld.service
```

CentOS 8

---

## Zabbixi paigaldamine (2)

```bash
# Andmebaasi initsialiseerimine
$ mysql -uroot 
mysql> create database zabbix character set utf8 collate utf8_bin;
mysql> create user zabbix@localhost identified by 'password';
mysql> grant all privileges on zabbix.* to zabbix@localhost;
mysql> set global log_bin_trust_function_creators = 1;
mysql> quit;

# Zabbixi andmeskeemi import ja log_bin_trust_function_creators väljalülitamine
$ zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix
$ mysql -uroot
mysql> set global log_bin_trust_function_creators = 0;
mysql> quit; 

# Zabbixi serveri andmebaasi parooli seadistamine
$ vim /etc/zabbix/zabbix_server.conf
DBPassword=password
# Teenuse käivitamine

$ systemctl restart zabbix-server zabbix-agent httpd php-fpm
$ systemctl enable zabbix-server zabbix-agent httpd php-fpm
```

CentOS 8

---

## Zabbixi paigaldamine (1)

```bash
# Paigaldame Zabbixi hoidla
$ wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu22.04_all.deb
$ dpkg -i zabbix-release_6.4-1+ubuntu22.04_all.deb
$ apt update

# Paigaldame zabbix-serveri, zabbix-agendi, zabbix-frontend
$ apt install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

# Paigaldame MySQL
$ apt install mysql-server
$ systemctl start mysql.service
```

Ubuntu 22

---

## Zabbixi paigaldamine (2)

```bash
# Andmebaasi initsialiseerimine
$ mysql -uroot 
mysql> create database zabbix character set utf8 collate utf8_bin;
mysql> create user zabbix@localhost identified by 'password';
mysql> grant all privileges on zabbix.* to zabbix@localhost;
mysql> set global log_bin_trust_function_creators = 1;
mysql> quit;

# Zabbixi andmeskeemi import ja log_bin_trust_function_creators väljalülitamine
$ zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix
$ mysql -uroot
mysql> set global log_bin_trust_function_creators = 0;
mysql> quit; 

# Zabbixi serveri andmebaasi parooli seadistamine
$ vim /etc/zabbix/zabbix_server.conf
DBPassword=password

# Teenuse käivitamine
$ systemctl restart zabbix-server zabbix-agent apache2
$ systemctl enable zabbix-server zabbix-agent apache2
```

Ubuntu 22

---

## Esmane seadistamine (1)
http://Server-IP/zabbix

![PILT: Eeltingimuste kontroll](https://bestmonitoringtools.com/wp-content/uploads/image-3.png)

---

## Esmane seadistamine (2)
http://Server-IP/zabbix

![PILT: Eeltingimuste kontroll](https://bestmonitoringtools.com/wp-content/uploads/image-5.png)

---

## Esmane seadistamine (3)
http://Server-IP/zabbix

![PILT: Andmebaasi ühenduse seadistamine](https://bestmonitoringtools.com/wp-content/uploads/image-7.png)

---

## Esmane seadistamine (4)
http://Server-IP/zabbix

![PILT: Zabbixi serveri seadistused](https://bestmonitoringtools.com/wp-content/uploads/image-8.png)
---

## Esmane seadistamine (5)
http://Server-IP/zabbix

![PILT: Seadistuste kokkuvõte](https://bestmonitoringtools.com/wp-content/uploads/image-9.png)

---

## Esmane seadistamine (6)
http://Server-IP/zabbix

![PILT: Edukas paigaldamine]
(https://bestmonitoringtools.com/wp-content/uploads/Zabbix_frontend_install_step_6.png)
---

## Kontroll
http://Server-IP/zabbix (Admin/zabbix)

![PILT: Zabbixi juhtpaneel pärast sisselogimist](https://bestmonitoringtools.com/wp-content/uploads/image-10-1024x576.png)
---

## Seire seadistamine

![PILT: Seire seadistamine](https://assets.zabbix.com/img/icons/features_Messaging_channels_zabbix.svg)
---

## Zabbix-agendi paigaldamine

```bash
# Paigaldame Zabbixi hoidla ja seadistame zabbix-agent
$ rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
$ yum install zabbix-agent

# Määrame serveri
$ vim /etc/zabbix/zabbix_agentd.conf
ServerActive=10.0.0.30

# Käivitame teenuse
$ systemctl enable zabbix-agent
$ systemctl start zabbix-agent
```

Näide CentOS 7 puhul

---

## Zabbixi põhimõistete ülevaade

- Host / Seade – Mõõdikute allikas. Loogiline mõiste. 1 füüsiline seade võib olla esindatud mitme jälgitava seadmena
- Item / Andmeelement – Mõõdik või mistahes andmed. See, mida server saab seadmelt
- Trigger / Päästik – Kirjeldab, milliseid andmeelemendi väärtusi loeme rikkeks
- Action / Tegevus – Viis sündmustele reageerimiseks. Näiteks teavituse saatmine päästiku käivitumisel

---

## Automaatse avastamise ja tegevuste seadistamine (1)
Avastamisreeglite seadistamine

![PILT: Discovery seadistamise ekraanivaade](media/z-discovery-rules.png)
---

## Automaatse avastamise ja tegevuste seadistamine (2)
Tegevuste seadistamine

![PILT: Actions seadistamise ekraanivaade](media/z-actions.png)
---

## Automaatse avastamise ja tegevuste seadistamine (3)
Tegevuste seadistamine

![PILT: Tegevuste tingimuste ja operatsioonide seadistamine](media/z-actions2.png)

---

## Seadme konfigureerimine
Seadmete seadistamine

![PILT: Hosts seadistamise ekraanivaade](media/z-hosts.png)

---

## Andmeelemendi lisamine
Andmeelementide seadistamine

![PILT: Items seadistamise ekraanivaade](media/z-items.png)

---

## Trigger konfigureerimine
Triggeri seadistamine

![PILT: Triggers seadistamise ekraanivaade](media/z-triggers.png)

---

## Teavituste seadistamine

- Kontrollige globaalseid meediumitüüpide seadistusi
  - Administration -> Media types (versioonis 6.4 — Alerts -> Media types)
  - Määrake kõik vajalik: SMTP e-posti jaoks, Telegrami tokenid, SMS-lüüs
- Seadistage kasutajate teavitusmeetodid
  - Administration -> User -> Media (versioonis 6.4 — Users -> User -> Media)
  - Määrake e-posti aadress, Telegrami kasutajanimi, SMS-i telefoninumber
- Seadistage tegevus päästiku jaoks
  - Administration -> Actions -> Trigger actions
    (versioonis 6.4 — Alerts -> Actions -> Trigger actions)
  - Vahekaart Action: saate määrata sõnumi saatmise tingimused
  - Vahekaart Operations: määrake kellele ja kuhu sõnumid saata, eskalatsiooni sammud

---
## Graafikud ja komplekssed ekraanid

[PILT: Zabbix logo koos sinise taustaga tiitellehel]

## Teemad
- Graafikud
- Võrgukaardid
- Paneelid
- Refleksioon

## Graafikud
![PILT:"Graafikud"](https://blog.zabbix.com/wp-content/uploads/2024/06/new_widgets_2-1024x515.png)

**Lihtsad graafikud**
![PILT: Zabbix'i lihtsa graafiku kuvatõmmis, mis näitab Apache mälu kasutust](media/z-graf1.png)
Teenivad andmeelemendiga kogutud andmete visualiseerimiseks

**Kasutaja graafikud**
![PILT: Zabbix'i kasutaja graafiku loomise vaade koos ringdiagrammiga](media/z-graf2.png)
Pakuvad individuaalse seadistamise võimalust

**Situatsioonilised graafikud**
![PILT: Zabbix'i situatsiooniliste graafikute kuvatõmmis ja võrdlevad graafikud](media/z-graf3.png)
Graafikud mitme andmeelemendi võrdlemiseks "lennult"

## Võrgukaardid

![PILT: Zabbix'i võrgukaartide vaade, mis näitab serverite ja agentide ühendusi](media/z-network-map.png)
Infrastruktuuri visualiseerimine

## Paneelid

![PILT: Zabbix'i juhtpaneeli kuvatõmmis](https://bestmonitoringtools.com/wp-content/uploads/zabbix-7-dashboard-big-resolution-dark.webp)
Visualiseerimisplatvorm erinevate tööriistadega (graafikud/kaardid/jne)

---
# Häirete seadistamine

## Teemad

- Teavituste saatmise põhimõtted
- Teavituste edastamise kanalid
- Häirete seadistamine Zabbix'is
- Refleksioon

## Põhilised lähenemisviisid teavituste saatmiseks

### Parameetrite valik

- Tuleb valida parameetrid, mille alusel saadetakse teavitusi
- KÕIGI parameetrite valimine on halb praktika
- Parameetrite valik sõltub peamiselt teenusest ja ärinõuetest

![Parameetrite valik](https://fastercapital.com/i/False-positive-signals--The-Pitfalls-of-Overzealous-Detection--Common-Causes-of-False-Positive-Signals.webp)

### Käivitamislävi

- Määrake käivitamislävi pärast meetrika jälgimist
- Arvestage meetrika tippväärtusi ja nende kestust
- Sageli on vaja rohkem kui ühte käivitusläve
- Võimalik on seadistada mitu teavitustasandit sama meetrika jaoks

![Käivitamislävi](https://www.soliantconsulting.com/wp-content/uploads/2019/06/blog-fm-zabbix-workflow.jpg)

### Kas teavitused sisse lülitada või mitte?

- Teavituste arvu tuleb vähendada
- Kui teavitusele ei reageerita, on parem see välja lülitada, et vältida edaspidi liigset teavitamist
- Kui mõne parameetri osas on kahtlusi, on parem teavitused sisse lülitada, vähemalt alguses

![Olulisuse tasemed](media/z-olulise1.png)

### Olulisuse tase

Olulisuse tase määrab probleemi prioriteedi:
- Parameetrid jaotatakse tavaliselt kahte põhirühma:
  - Kõrge prioriteet — kriitilised probleemid
  - Madal prioriteet — probleemid, millele tuleks tähelepanu pöörata
- Värvikodeering sündmuste visuaalseks kuvamiseks
- Erinevate teavituskanalite seadistamine erinevate olulisustasemete jaoks
- Võimalik seadistada kohandatud olulisuse tasemeid

![Olulisuse tasemed](media/z-olulise2.png)

### Eskalatsioon

Eskalatsioon on protseduur, mis juhib tähelepanu konkreetsele probleemile, kui praegune lahenduskäik ei ole rahuldav:
- Probleemi ja eskalatsiooni põhjuse selge sõnastamine
- Probleemi prioriteedi muutmise põhjus
- Tüüpprobleemide eskaleerimistasemete eelnev planeerimine
- Eskalatsiooniprotsesside seadistamine vastavalt probleemi tasemele

![Eskalatsioon](media/z-escalation.png)

### Eeskirjad ja juhendid

- Kõigi võimalike stsenaariumide jaoks eeskirjade ja juhendite koostamine
- Vajaliku teabe edastamine teavituste adressaatidele
- Eeskirjade ja juhendite pidev täiustamine
- Teavituste seadistamine on lõputu protsess! Seda tuleb meeles pidada

### Häirete testimine

- Vajadus jälgida ja kontrollida teavitussüsteemi ennast
- Tööriistad teavitussüsteemi kontrollimiseks (skriptid, testparameetrid ja päästikud)

### Häirete deduplikatsioon

- Vältige teavitusi üksikutele töötajatele
- Kasutage rühmateavitusi
- Kasutage päästikute sõltuvusi

### Häirete ajakava

- Erinevate teavituskanalite jaotamine päeva ja nädalapäevade kaupa
- Perioodilisi teavitusi samal ajal saab välistada

## Teavituskanalid

### E-post

- Saatmine SMTP kaudu (oma või muu server)
- Teavitused meililistidele ja konkreetsetele kasutajatele
- Kirja malli kohandamine
- Lisateave kirjas
- Mittepealetükkivus

![E-post](media/z-alert1.png)
![E-post](media/z-alert2.png)

### Telegram

https://git.zabbix.com/projects/ZBX/repos/zabbix/browse/templates/media/telegram

- Saatmine veebihaagi kaudu
- Teavituste kiirus
- Adressaatide mugav haldamine (teavitused kanalisse või privaatsõnumisse)
- Lihtsustatud seadistamine (alates Zabbix'i 5. versioonist)

![Telegram](media/z-alert3.png)
![Telegram](media/z-alert4.png)

### Teised sõnumirakendused

https://git.zabbix.com/projects/ZBX/repos/zabbix/browse/templates/media

- Teavitusmeetodi universaalsus (veebihaak)
- Erinevused sõnumimallide vormingus
- Lisavõimalused (graafikutega pildid, emotikonid, värviline esiletõstmine)

![Teised sõnumirakendused](media/z-alert5.png)
![Teised sõnumirakendused](media/z-alert6.png)
![Teised sõnumirakendused](media/z-alert7.png)
![Teised sõnumirakendused](media/z-alert8.png)
### SMS (saatmine läbi lüüsi)

- Teavituste kiirus
- Teavituste universaalsus (sõltumata telefonimudelist)
- Suhteline usaldusväärsus
- Piirangud sõnumite sisule
- Nõuab tasuliste teenuste kasutamist

![SMS läbi lüüsi](media/z-alert9.png)

### SMS (saatmine läbi GSM-modemi)

- Tõrkekindel skeem tõsise avarii korral
- Nõuab modemi töö ja ühenduse kontrollimist
- Skeem ei sõltu objekti sidekanalitest
- Vajab samuti varundamist
- Nõuab tasuliste teenuste kasutamist

![SMS läbi GSM-modemi](media/z-alert10.png)

### Push-teavitused

- Kaasaegne ja võib olla mugav
- Nõuab tasuliste teenuste kasutamist

![Push-teavitused](media/z-alert11.png)

### Piletid teenindustoes

- Mugav ja operatiivne
- Probleemi tuvastamise ja lahendamise protsessi kontroll
- Täiendav eskalatsioon ja teave probleemi kohta
- Võimalik tõhusalt delegeerida ja jagada probleemi töögrupi ülesanneteks

![Teenindustoe piletid](media/z-alert12.png)

### Kõne sõnumiga

- Tõhus teavitamine — äratab keda iganes! (kuigi see pole kindel...)
- Nõuab väga täpset eskalatsiooni seadistust, muidu riskitakse kiire ja püsiva väljalülitamisega
- Nõuab kolmanda osapoole sidevahendeid (kui ettevõttel pole oma analoogseid)

![Kõne sõnumiga](media/z-alert13.png)

## Häirete seadistamine Zabbix'is

### Teavituste loogika

Zabbix'is toimub teavituste seadistamine järgmise loogika alusel:
1. Server jälgib elementi (Item)
2. Päästik (Trigger) aktiveerub, kui element vastab teatud tingimustele
3. Probleem (Problem) luuakse, kui päästik on aktiveeritud
4. Tegevus (Action) käivitatakse, mis saadab teavituse
5. Tegevus dokumenteeritakse tegevuste logis (Action log)

![Teavituste loogika](media/z-not1.png)

### Lahendatud probleemi käsitlemine

Sarnane loogika kehtib ka lahendatud probleemide puhul, kus teavitatakse kasutajaid, kui probleem on lahendatud.

![Lahendatud probleem](media/z-not2.png)

### Teavituste silumine

- Kontrollige Media type tööd Test nupuga
- Kontrollige Action seadistusi
- Kontrollige sündmusi Action log'is
- Kontrollige, kas vajalik Media type on vajalikul kasutajal
- 
---
## Portaalide ja andmebaaside monitoorimine

[![Zabbix Flexible Permissions](https://assets.zabbix.com/img/icons/features_Flexible_permissions_zabbix.svg)](https://www.zabbix.com/)

## Teemad

- Veebiserverite monitoorimine
- Andmebaaside monitoorimine (lähenemisviisid)
- MySQL monitoorimine
- PostgreSQL monitoorimine

---

## Veebiserverite monitoorimine

## Veebportaali monitoorimise mõõdikud (1)

- Serveri põhisüsteemid
  - CPU
  - RAM
  - Kõvaketas
  - Võrk
  - Turvalisus
- Kuidas monitoorime?
  - zabbix-agent serveril + Zabbix standardmallid
  - Prometheus Node exporter + Zabbix standardmallid

[Learn more about Browser Monitoring](https://blog.zabbix.com/an-introduction-to-browser-monitoring/29245/)

<!-- Image followed by a link reference -->
<p align="center">
  <img src="https://assets.zabbix.com/img/icons/features_Collect_from_any_source_zabbix.svg" alt="Zabbix Collect from Any Source">
  <br>
  <a href="https://blog.zabbix.com/an-introduction-to-browser-monitoring/29245/">Read our Introduction to Browser Monitoring</a>
</p>

<!-- Badge style link -->
[![Browser Monitoring](https://img.shields.io/badge/Zabbix-Browser%20Monitoring-red)](https://blog.zabbix.com/an-introduction-to-browser-monitoring/29245/)
You can use any of these examples in your REA

---

## Veebportaali monitoorimise mõõdikud (2)

- Veebiserver
  - Veebiteenuse staatus
  - Portide kättesaadavus
  - Päringud sekundis (RPS)
  - HTTP-lõpetamiskoodid
  - Veebserveri vead
  - SSL sertifikaadid
  - Reageerimisaeg
- Kuidas monitoorime?
  - zabbix-agent serveril + Zabbix standardmallid
  - Simple check Zabbix serverilt
  - Veebistsenaariumid monitooritud serveritelt
  - Kohandatud kasutajaparameetrid (UserParameter)
  - Logisõnumid

---

## Veebportaali monitoorimise mõõdikud (3)

- Rakendusserver
  - Veebserveri teenuse olek
  - Teenuste olekud
  - Päringud sekundis (php, redis, rabbitMQ, muud)
  - Puhvri kasutamine
  - Järjekorra kasutamine
  - Protsesside arv ja olek
  - Teenuste vead logides
- Kuidas monitoorime?
  - zabbix-agent serveril + Zabbix standardmallid
  - Simple check Zabbix serverilt
  - Kohandatud kasutajaparameetrid (UserParameter)
  - Logisõnumid

---

## Veebportaali monitoorimise mõõdikud (4)

- Ärimõõdikud
  - külastused
  - konversioon
  - müügid
  - rakenduse allalaadimised
- Kuidas monitoorime?
  - Kohandatud kasutajaparameetrid
  - Arvutatud andmeelemendid

---

## Näide: Apache monitoorimine (1)

```bash
# status_module mooduli ühendamine
$ apachectl -M | grep status_module
status_module (shared)
# Kui moodul pole ühendatud - tuleb leida ja redigeerida status.conf
# (status.conf sisu - järgmisel slaidil)
$ ls /etc/apache2/mods-available | grep status.conf
status.conf
# Konfiguratsiooni kontrollimine ja mooduli sisselülitamine
$ apachectl -t
$ a2enmod status
$ systemctl restart apache2
$ systemctl status apache2
```

Ubuntu (eeldades, et Zabbix-agent on juba paigaldatud ja käivitatud)

---

## Näide: Apache monitoorimine (2)

```apache
# status.conf
<IfModule mod_status.c>
 # Allow server status reports generated by mod_status,
 # with the URL of http://servername/server-status
 # Uncomment and change the "192.0.2.0/24" to allow access from other hosts.
 <Location /server-status>
 SetHandler server-status
 Require local
 Require ip 127.0.0.1/32
 </Location>
 # Keep track of extended status information for each request
 ExtendedStatus On
 # Determine if mod_status displays the first 63 characters of a request or
 # the last 63, assuming the request itself is greater than 63 chars.
 # Default: Off
 #SeeRequestTail On
 <IfModule mod_proxy.c>
 # Show Proxy LoadBalancer status in mod_status
 ProxyStatus On
 </IfModule>
</IfModule>
```

status.conf

---

## Näide: Apache monitoorimine (3)

```bash
# Mooduli testimine
$ curl http://127.0.0.1/server-status?auto
localhost
ServerVersion: Apache/2.4.29 (Ubuntu) OpenSSL/1.1.1
ServerMPM: prefork
Server Built: 2022-03-16T16:53:42
CurrentTime: Thursday, 10-Aug-2023 22:45:35 UTC
RestartTime: Thursday, 10-Aug-2023 22:45:33 UTC
ParentServerConfigGeneration: 1
ParentServerMPMGeneration: 0
ServerUptimeSeconds: 2
ServerUptime: 2 seconds
Load1: 0.00
Load5: 0.00
Load15: 0.00
...
```

Konsoolist kontroll

---

## Zabbix-agendi seadistamine

<p align="center">
  <img src="media/Zabbix-agend-1.png" alt="PILT: Zabbix-agendi seadistamise ekraanipilt templatesiga" width="600">
  <br>
  <em>PILT: Zabbix-agendi seadistamine</em>
</p>

---

## Näide: töölaud (dashboard)

<p align="center">
  <img src="media/Zabbix-agend-2.png" alt="[PILT: Zabbix töölaua näide Apache ja MySQL monitoorimise graafikutega" width="600">
  <br>
  <em>PILT: Zabbix töölaua näide Apache ja MySQL monitoorimise graafikutega</em>
</p>

---

## Andmebaaside monitoorimine

![Database monitoring](https://blog.zabbix.com/wp-content/uploads/2021/04/5-1.jpg)

**[Article: Out-of-the-box database monitoring](https://blog.zabbix.com/out-of-the-box-database-monitoring/13957/)**

---

## ODBC (Open Database Connectivity) monitoorimine. Zabbix sisseehitatud moodul

- Eelised
  - Zabbixisse sisse ehitatud
  - Toetab paljusid andmebaase (Oracle, MySQL, PostgreSQL, MSSQL, IBM DB2, MongoDB, Firebird jne)
  - Ametlikud mallid populaarsetele andmebaasidele (MySQL, MSSQL, Oracle) (alates veebruar 2020)
- Puudused
  - Töötab ainult serveril, kus on käivitatud zabbix-server ja zabbix-proxy, seetõttu on monitoorimiseks vajalik otsene ühendus andmebaasiga; NAT-i taga asuvate andmebaaside monitoorimine pole võimalik
  - Puudub ühenduste kogu (pool) tugi. Iga päring on uus ühendus andmebaasiga (versioonis 4.4 ilmus db.odbc.get, mistõttu on võimalik vähendada päringute arvu ja andmeid eeltöödelda)
  - Platvormist sõltuv lahendus (lahendust ei saa kasutada seal, kus pole Linux-servereid)

---

## Zabbix agent UserParameter abil

- Eelised
  - Töötab vahetult andmebaasi serveril (agendi aktiivne või passiivne režiim, aktiivse puhul NAT pole probleem)
  - Kiiresti ja suhteliselt lihtsalt saab luua oma lahenduse
  - Ristplatvormilisus tänu skriptidele erinevates keeltes
- Puudused
  - Puudub ühenduste kogu tugi. Iga skripti käivitamine on uus ühendus andmebaasiga
  - Paljude kogutavate mõõdikute ja kõrge küsitlemissageduse korral suureneb serveri koormus (CPU, RAM)
  - Puudub ühtne lahendus Windows/Linux/AIX ja erinevate andmebaaside jaoks
  - Lahenduse kasutamine võib olla võimatu infrastruktuuri piirangute või turvalisuspoliitika tõttu (näiteks väliste skriptide suhtes)
  - Vajalik täiendava tarkvara paigaldamine (näiteks Python)

<p align="center">
  <a href="https://blog.zabbix.com/zabbix-agent-user-parameters/7910/">
    <img src="https://blog.zabbix.com/wp-content/uploads/2019/10/4.23.jpg" alt="UserParameter eeliste ja puuduste loetelu" width="600">
  </a>
  <br>
  <em>PILT: UserParameter eeliste ja puuduste loetelu</em>
  <br>
  <a href="https://blog.zabbix.com/zabbix-agent-user-parameters/7910/">Zabbix Agent User Parameters</a>
</p>

---

## Moodulid Zabbix Agendi jaoks (libzbxpgsql, libzbxredis, zabbix-modulemysql jne)

- Eelised
  - Töötavad vahetult andmebaasi serveril (agendi aktiivne või passiivne režiim, aktiivse puhul NAT pole probleem)
- Puudused
  - Töötavad ainult Linuxil
  - Iga moodul on mõeldud konkreetsele andmebaasile (pole ühtset moodulit kõigile populaarsetele andmebaasidele)
  - Paljude moodulite tugi on lõpetatud, moodulid ja mallid ei arene
  - Puudub ühenduste kogu tugi. Iga päring on uus ühendus andmebaasiga
  - Paljusid mooduleid tuleb ise lähtekoodi põhjal kompileerida, selleks on vaja kvalifitseeritud inseneri

---

## Välised agendid (mamonsu, DBforBIX, ZabbixDBA, zbxdb, zbxora jne)

- Eelised
  - Töötavad vahetult andmebaasi serveril (agendi aktiivne või passiivne režiim, aktiivse puhul NAT pole probleem)
  - Paljud agendid on ristplatvormilised, kuid mitte kõik pole testitud Windows/AIX-il
  - Paljud agendid toetavad ühenduste kogu
- Puudused
  - Mõned agendid on ammu hüljatud ja ei arene, puuduvad valmis mallid erinevate andmebaaside jaoks (DBforBIX, ZabbixDBA)
  - Mõnede agentide keerulised seadistused (DBforBIX, zbxdb)
  - Lahenduse kasutamine võib olla võimatu infrastruktuuri piirangute või turvalisuspoliitika tõttu (näiteks on nõutav PSK/SSL-krüpteerimine monitoorimisandmete edastamisel)
  - Vajalik täiendava tarkvara paigaldamine (näiteks Python, Java või Perl)

---

## Zabbix Agent 2

- Eelised
  - Töötavad vahetult andmebaasi serveril (agendi aktiivne või passiivne režiim, aktiivse puhul NAT pole probleem)
  - Kirjutatud Golangi keeles — ristplatvormil töötav, kuid ainult Linuxi ja Windowsi jaoks
  - Redis, Memcached, PostgreSQL, MySQL monitoorimise tugi "karbist". Hiljuti ilmus Oracle'i liides
  - Alates 17.09.2020 on olemas Windows-teenuse tugi [ZBXNEXT 6023]
- Puudused
  - Kirjutatud Golangi keeles — ebapiisavalt ristplatvormil töötav — AIX versioonid < 7.2 ei ole Golang kompileerija poolt toetatud, Solaris või FreeBSD on küsimärgi all
  - Seni on realiseeritud tugi kaugeltki mitte kõigile populaarsetele andmebaasidele (puudub MSSQL)
  - Ei toeta deemonina töötamist Linuxis

[![Setting up Zabbix Agent 2 for PostgreSQL monitoring](https://blog.zabbix.com/wp-content/uploads/2021/01/4-1.jpg)](https://blog.zabbix.com/setting-up-zabbix-agent-2-for-postgresql-monitoring-and-revealing-how-it-works/13208/)

**[Setting up Zabbix Agent 2 for PostgreSQL monitoring and revealing how it works](https://blog.zabbix.com/setting-up-zabbix-agent-2-for-postgresql-monitoring-and-revealing-how-it-works/13208/)**

---

## Zabbix Agent DBMON

- Eelised
  - Ristplatvormil töötav (toetab kompileerimist Linuxi, Windowsi, AIX, Solarise jt jaoks)
  - Toetab Oracle, MySQL, PostgreSQL, MSSQL monitoorimist kõigil operatsioonisüsteemidel ilma täiendavate skriptideta
  - Kiire monitoorimine, väike CPU ja RAM ressursside kasutus
  - Valmis modulaarsed mallid Oracle, MySQL, PostgreSQL monitoorimiseks erinevatel operatsioonisüsteemidel
  - Minimaalsed agendi seadistused
  - Kompaktne lahendus minimaalse sõltuvusega
- Puudused
  - Seni veel arendamisel ja kõik "funktsioonid" ei pruugi olla kättesaadavad


---

## Näide: MySQL monitoorimine (1)

```bash
# Malli ettevalmistamine
$ vim /etc/zabbix/zabbix_agentd.d/template_db_mysql.conf

UserParameter=mysql.ping[*], mysqladmin -h"$1" -P"$2" ping

UserParameter=mysql.get_status_variables[*], mysql -h"$1" -P"$2" -sNX -e "show global status"

UserParameter=mysql.version[*], mysqladmin -s -h"$1" -P"$2" version

UserParameter=mysql.db.discovery[*], mysql -h"$1" -P"$2" -sN -e "show databases"

UserParameter=mysql.dbsize[*], mysql -h"$1" -P"$2" -sN -e "SELECT COALESCE(SUM(DATA_LENGTH + 
INDEX_LENGTH),0) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='$3'"

UserParameter=mysql.replication.discovery[*], mysql -h"$1" -P"$2" -sNX -e "show slave status"
UserParameter=mysql.slave_status[*], mysql -h"$1" -P"$2" -sNX -e "show slave status"
```

Eeldame, et Zabbix-agent on juba paigaldatud ja käivitatud

---

## Näide: MySQL monitoorimine (2)

```bash
# Kasutaja loomine andmebaasis
$ mysql -uroot -p
> CREATE USER 'zbx_monitor'@'%' IDENTIFIED BY 'TTRy1bRRgLIB';
> GRANT USAGE,REPLICATION CLIENT,PROCESS,SHOW DATABASES,SHOW VIEW ON *.* TO 'zbx_monitor'@'%';
> quit

# Zabbix kasutaja kodukataloogi kontroll ja vajadusel loomine
$ cat /etc/passwd | grep zabbix
zabbix:x:990:986:Zabbix Monitoring System:/var/lib/zabbix:/sbin/nologin
$ mkdir /var/lib/zabbix

# Andmebaasiga ühendumise konfiguratsiooni loomine
$ vim /var/lib/zabbix/.my.cnf
[client]
user='zbx_monitor'
password='TTRy1bRRgLIB'

# Õiguste seadistamine
$ chown -R zabbix. /var/lib/zabbix
$ chmod 400 /var/lib/zabbix/.my.cnf
```

Monitoorimise kasutaja andmebaasis

---

