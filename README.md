# Süsteemide Monitooring ja Jälgitavus - Kursusematerjalid

See repositoorium sisaldab monitooringu ja jälgitavuse kursuse õppematerjale. Kursus on koostatud MkDocs ja Material for MkDocs abil.

## 📚 Kursuse Ülevaade

**Maht:** 50h (põhirada) + 15h (valikmoodulid)  
**Tase:** Keskaste kuni edasijõudnud  
**Keel:** Eesti keel  
**Formaat:** Modulaarne ülesehitus

### Põhirada (50h - kohustuslik)

1. **Linux Logimine** (6h) - Syslog, Journald, Logrotate
2. **Prometheus & Grafana** (11h) - Mõõdikute kogumine ja visualiseerimine
3. **ELK Stack** (11h) - Elasticsearch, Logstash, Kibana
4. **Jaeger & OpenTelemetry** (7h) - Hajutatud jälgimine
5. **Hoiatuste Haldus** (3h) - PagerDuty, Alertmanager
6. **Lõpuprojekt** (12h) - Terviklik monitooringulahendus

### Valikmoodulid (15h - vali 1-2)

- **TICK Stack** (6h) - Telegraf, InfluxDB, Chronograf, Kapacitor
- **Splunk Enterprise** (7h) - Enterprise-taseme lahendused
- **Zabbix** (9h) - Traditsiooniline infrastruktuuri monitooring

## 📁 Materjalide Struktuur

Kogu dokumentatsioon asub `docs/` kaustas:

- **`docs/labs/`** - Praktilised laboritööd
  - `01_linux_logging/` - Linux logide haldus
  - `02_prometheus/` - Prometheus ja Grafana (põhirada)
  - `03_tick_stack/` - TICK Stack (valikmoodul)
  - `04_elk_stack/` - ELK Stack (põhirada)
  - `05_splunk/` - Splunk (valikmoodul)
  - `06_zabbix/` - Zabbix (valikmoodul)
  - `07_jaeger/` - Jaeger ja OpenTelemetry (põhirada)
  - `08_alerting/` - Hoiatuste haldus (põhirada)

- **`docs/materials/lectures/`** - Loengumaterjalid ja teooria
  - `Observability/` - Jälgitavuse alused
  - `Linux/` - Linux logimise teooria
  - `Prometheus/` - Prometheus teooria
  - `Elasticsearch/` - Elasticsearch teooria
  - `Grafana/` - Grafana ja Loki
  - `Splunk/` - Splunk teooria
  - `TICK/` - TICK Stack teooria
  - `Zabbix/` - Zabbix teooria

- **`docs/final_project/`** - Lõpuprojekti materjalid
  - `final_project_building_monsystem.md` - Projekti kirjeldus
  - `help/` - Abistavad materjalid ja starter code

- **`docs/resources/`** - Lisaressursid
  - Seadistuse juhendid (GitHub, VS Code, Digital Ocean)
  - Sertifikaatide haldus
  - Täiendav lugemine

---

## 🛠️ Õpetajale - Saidi Haldamine

### Lokaalne Arendus

1. **Loo virtuaalne keskkond:**
```bash
python3 -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
```

2. **Paigalda sõltuvused:**
```bash
pip install mkdocs-material
```

3. **Käivita arenduserver:**
```bash
mkdocs serve
```

Sait avaneb aadressil: [http://127.0.0.1:8000](http://127.0.0.1:8000)

### Sisu Muutmine

1. **Leia õige `.md` fail** `docs/` kaustas
2. **Redigeeri Markdown formaadis**
3. **Salvesta** - muudatused ilmuvad automaatselt

### Uue Lehe Lisamine

1. Loo uus `.md` fail sobivasse `docs/` alamkausta
2. Lisa `mkdocs.yml` navigatsioonimenyüüsse:

```yaml
nav:
  - Avaleht: index.md
  - Laborid:
      - Uus Labor: labs/09_new_lab/lab.md
```

### Deploymine GitHub Pages

```bash
mkdocs gh-deploy --clean
```

### Material for MkDocs Funktsioonid

**Admonitions (Infokastid):**
```markdown
!!! info "Pealkiri"
    Sisu siia

!!! warning "Hoiatus"
    Tähtis teave
```

**Nupud:**
```markdown
[Loe edasi →](link.md){ .md-button .md-button--primary }
```

**Koodiplokid:**
```markdown
​```bash
echo "Alati märgi keel!"
​```
```

### Kontrollnimekiri Enne Deployimist

- [ ] `mkdocs build` töötab ilma vigadeta?
- [ ] Kõik uued failid on `mkdocs.yml` navigatsioonis?
- [ ] Kõik lingid töötavad?
- [ ] Kõik koodiplokid on keelega märgistatud?

---

## 📖 Kasulikud Lingid

- [MkDocs dokumentatsioon](https://www.mkdocs.org/)
- [Material for MkDocs dokumentatsioon](https://squidfunk.github.io/mkdocs-material/)
- [Markdown juhend](https://www.markdownguide.org/)

---

**Edukat õppimist!** 🚀
