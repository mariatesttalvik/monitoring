# Linux Logimise Labor - Vagrant Setup

## Mis on Vagrant?

Vagrant on tööriist, mis loob ja seadistab virtuaalmasinad automaatselt. Sa ei pea käsitsi VirtualBoxi seadistama - Vagrant teeb selle sinu eest!

## Eeldused

Sul peab olema paigaldatud:
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) (7.0+)
- [Vagrant](https://www.vagrantup.com/downloads) (2.3+)

**Kontrolli kas on paigaldatud:**
```bash
vagrant --version
vboxmanage --version
```

## Kiire alustamine

### 1. Käivita mõlemad VM-id

```bash
# Loo ja käivita mõlemad masinad
vagrant up

# See võtab 5-10 minutit esimesel korral
# Vagrant laeb Ubuntu 22.04 image ja seadistab kõik automaatselt
```

### 2. Logi sisse

**LogServer (VM1):**
```bash
vagrant ssh logserver
```

**LogClient (VM2):**
```bash
# Teine terminal
vagrant ssh logclient
```

### 3. Testi

**LogClient-is:**
```bash
# Saada testlogi
logger "TERE! See on Vagrant test!"

# Või käivita automaatne testija
./test-logs.sh
```

**LogServer-is:**
```bash
# Vaata logisid
tail -f /var/log/remote/syslog.log
```

Peaksid nägema oma sõnumit! 🎉

## Vagrant põhikäsud

| Käsk | Mis see teeb |
|------|--------------|
| `vagrant up` | Käivita VM-id (loob kui ei ole) |
| `vagrant halt` | Peata VM-id |
| `vagrant reload` | Taaskäivita VM-id |
| `vagrant destroy` | Kustuta VM-id |
| `vagrant status` | Vaata VM-ide staatust |
| `vagrant ssh logserver` | Logi serverisse |
| `vagrant ssh logclient` | Logi klienti |

## Peatamine ja taaskäivitamine

```bash
# Peata mõlemad
vagrant halt

# Käivita uuesti
vagrant up

# Või ainult üks
vagrant up logserver
```

## Kui midagi läks valesti

### Alusta nullist:

```bash
# Kustuta kõik
vagrant destroy -f

# Loo uuesti
vagrant up
```

### Vaata VM-i logisid:

```bash
# Serveris
vagrant ssh logserver
sudo journalctl -u rsyslog -n 50

# Kliendis
vagrant ssh logclient
sudo journalctl -u rsyslog -n 50
```

## Mis Vagrant automaatselt seadistab?

### LogServer (192.168.100.10):
- ✅ rsyslog paigaldatud
- ✅ UDP port 514 kuulamine
- ✅ Kaust `/var/log/remote/` loodud
- ✅ Logid salvestatakse `/var/log/remote/syslog.log`

### LogClient (192.168.100.20):
- ✅ rsyslog paigaldatud
- ✅ Logide edastamine serverisse
- ✅ Testskript `/home/vagrant/test-logs.sh`

## IP aadressid

| VM | IP | Hostname |
|----|----|----|
| LogServer | 192.168.100.10 | logserver |
| LogClient | 192.168.100.20 | logclient |

## Troubleshooting

### VM ei käivitu

```bash
# Kontrolli VirtualBoxi
vboxmanage list vms

# Kontrolli Vagrant staatust
vagrant status

# Proovi uuesti
vagrant destroy -f
vagrant up
```

### Logid ei jõua kohale

```bash
# Serveris kontrolli kas kuulab
vagrant ssh logserver
sudo ss -uln | grep 514

# Kliendis kontrolli konfigi
vagrant ssh logclient
cat /etc/rsyslog.d/forward.conf
```

### "Võrk ei tööta"

```bash
# Serveris
vagrant ssh logserver
ping 192.168.100.20

# Kliendis
vagrant ssh logclient
ping 192.168.100.10
```

## Failide jagamine

Vagrant jagab kausta automaatselt:
- Host: `./` (kus Vagrantfile on)
- VM: `/vagrant/`

```bash
vagrant ssh logserver
ls /vagrant/
# Näed samu faile mis host masinas!
```

## Eelised vs käsitsi seadistamine

| Aspekt | Käsitsi | Vagrant |
|--------|---------|---------|
| Aeg | 2-3h | 10 min |
| Kordamine | Peab kõike uuesti tegema | `vagrant up` |
| Vigade risk | Kõrge | Madal |
| Dokumenteerimine | Käsitsi | Vagrantfile = doku |
| Jagamine | Raske | Lihtne (jagad Vagrantfile) |

## Järgmised sammud

1. Käivita VM-id: `vagrant up`
2. Logi sisse ja testi: `vagrant ssh logserver` ja `vagrant ssh logclient`
3. Kui põhiline töötab, tee labori ülesanded käsitsi VM-ides
4. Kui valmis: `vagrant destroy`

> **Märkus:** Lisaülesanded (TCP, auth logid, logrotate) tee käsitsi VM-ides - see on osa õppimisest!

**Edu laboriga! 🚀**
