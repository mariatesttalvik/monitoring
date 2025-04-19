# Elasticsearch Turvalisus

- [Elasticsearch Turvalisus](#elasticsearch-turvalisus)
  - [1. Autentimine ja Autoriseerimine](#1-autentimine-ja-autoriseerimine)
  - [2. Sertifikaadid ja CA (Certificate Authority)](#2-sertifikaadid-ja-ca-certificate-authority)
  - [3. Võrgu Turvalisus](#3-võrgu-turvalisus)
  - [4. Andmete Turvalisus](#4-andmete-turvalisus)
    - [Krüpteerimine:](#krüpteerimine)
    - [Auditi Logimine:](#auditi-logimine)
  - [5. Parimad Turvalisuse Tavad](#5-parimad-turvalisuse-tavad)
  - [6. Levinud Turvaprobleemid](#6-levinud-turvaprobleemid)
  - [7. Turvatestid ja Monitooring](#7-turvatestid-ja-monitooring)

## 1. Autentimine ja Autoriseerimine

Elasticsearch kasutab kasutajate tuvastamiseks mitut meetodit:
* Native Realm - sisseehitatud kasutajahaldus
* LDAP/Active Directory integratsioon
* Single Sign-On (SSO)
* OpenID Connect
* SAML autentimine

Kasutajate õiguste haldamiseks kasutatakse rollipõhist juurdepääsukontrolli (RBAC). See võimaldab määrata täpselt, milliseid toiminguid kasutaja teha saab. Näiteks:
* Andmeanalüütik - ainult lugemisõigused konkreetsetele indeksitele
* Süsteemiadministraator - täielik klastri haldamise õigus
* Monitooringu kasutaja - ainult jälgimise õigused

## 2. Sertifikaadid ja CA (Certificate Authority)

Elasticsearch'i CA süsteem toimib usalduse alusena kogu klastrile. Peamised komponendid:
* Root CA - peamine sertifitseerimiskeskus
* Vahe-CA-d - täiendav turvakiht
* Node'ide sertifikaadid - iga node'i unikaalne identiteet
* Kliendisertifikaadid - välist juurdepääsu vajavate rakenduste jaoks

## 3. Võrgu Turvalisus

Transport Layer Security (TLS) tagab turvalise suhtluse:
* Node'ide vaheline krüpteering
* Klient-node krüpteering
* Sertifikaatide valideerimine

IP filtreerimine võimaldab:
* Juurdepääsu piiramist IP-aadresside põhjal
* Võrgu segmenteerimist
* Tulemüüri reeglite seadistamist

## 4. Andmete Turvalisus

### Krüpteerimine:
* Node'i tasemel krüpteering
* Indeksi tasemel krüpteering
* Võtmete turvaline haldamine

### Auditi Logimine:
* Kasutajate tegevuste jälgimine
* Turvasündmuste logimine
* Vastavuse jälgimine regulatsioonidele

## 5. Parimad Turvalisuse Tavad

Paroolihaldus:
* Tugevad parooli nõuded
* Regulaarne paroolide uuendamine
* Parooli ajaloo jälgimine

Süsteemi Hooldus:
* Elasticsearch'i uuenduste paigaldamine
* Turvaparanduste haldamine
* Versiooniühilduvuse tagamine

## 6. Levinud Turvaprobleemid

Konfiguratsiooni Vead:
* Vaikimisi paroolide kasutamine
* Väljalülitatud turvafunktsioonid
* Liiga laialdased õigused

Võrgu Haavatavused:
* Avalikult ligipääsetavad klastrid
* Turvamata pordid
* Puuduv TLS

## 7. Turvatestid ja Monitooring

Regulaarsed turvatestid aitavad tuvastada:
* Turvaauke
* Valesid konfiguratsioone
* Potentsiaalseid ohte

Monitooring peab jälgima:
* Ebatavalisi juurdepääsukatseid
* Ressursikasutust
* Turvaintsidente