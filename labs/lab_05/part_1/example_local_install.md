### Elasticsearchi installimine ja seadistamine lokaalses keskkonnas:

#### 1. samm: Elasticsearchi allalaadimine

- Minge Elasticsearchi ametlikule allalaadimiste lehele: [Elasticsearch Downloads](https://www.elastic.co/downloads).
- Valige oma operatsioonisüsteemile sobiv versioon.
- Laadige Elasticsearchi pakett või arhiiv alla.

#### 2. samm: Arhiivi lahtipakkimine

1. **Windows**: Paremklõpsake ZIP-failil ja valige "Extract All…".
2. **macOS/Linux**: Kasutage käsureal `tar` käsku:
   ```bash
   tar -zxvf elasticsearch-<versioon>.tar.gz
   ```

#### 3. samm: Elasticsearchi seadistamine

- Avage kaust `config` ja redigeerige faili `elasticsearch.yml`.
- Kohandage olulisi parameetreid, näiteks:
  - `cluster.name`: Klastri nimi.
  - `node.name`: Sõlme nimi.
  - `network.host`: IP, millele Elasticsearch peab siduma.

#### 4. samm: Elasticsearchi käivitamine

1. Avage terminal.
2. Navigeerige kausta `bin`.
3. Käivitage Elasticsearch:
   - **Windows**: `.\elasticsearch.bat`
   - **macOS/Linux**: `./elasticsearch`

#### 5. samm: Paigalduse kontrollimine

- Minge brauseris aadressile [http://localhost:9200](http://localhost:9200).
- Kontrollige klastri tervist aadressil [http://localhost:9200/_cluster/health](http://localhost:9200/_cluster/health).

---

### Elasticsearchi klastrite põhiline konfigureerimine:

1. **Klastri nimi**: Unikaalne nimi, nt:
   ```yaml
   cluster.name: my-cluster
   ```
2. **Sõlmede seadistamine**: Defineerige, kas sõlm on master või andmesõlm.
3. **Võrgu seadistamine**:
   ```yaml
   network.host: 0.0.0.0
   ```
4. **Avastamine**:
   ```yaml
   discovery.seed_hosts: ["node1", "node2"]
   ```

---