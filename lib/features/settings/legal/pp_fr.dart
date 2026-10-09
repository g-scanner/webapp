// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

const String ppFr = r'''
# Politique de Confidentialité de G-Scanner

**Version :** 1.0

**Date d'entrée en vigueur :** 9 octobre 2026

**Date de dernière mise à jour :** 9 octobre 2026

---

La présente Politique de Confidentialité décrit les modalités de traitement des données à caractère personnel effectué par le biais de l'application mobile et web **G-Scanner**, développée conformément au **Règlement (UE) 2016/679 (RGPD)** et à la législation italienne applicable en matière de protection des données personnelles.

---

## Finalités de l'application

G-Scanner est une application qui permet aux utilisateurs de consulter des informations relatives aux produits alimentaires par le biais du scannage des codes-barres, en accordant une attention particulière aux besoins des personnes souffrant de maladie cœliaque ou d'intolérance au lactose.

L'application permet également aux utilisateurs de configurer des préférences alimentaires spécifiques, de recevoir des indications basées sur des filtres d'information prédéfinis et de participer à une communauté en partageant des signalements concernant les produits.

**Important – Limitation de responsabilité**

Les informations fournies par G-Scanner ont exclusivement des fins informatives et de soutien à l'utilisateur.

L'application **ne constitue pas un dispositif médical**, **ne fournit pas de conseils médicaux**, **n'a aucune valeur diagnostique ou thérapeutique** et **ne produit aucun effet ou évaluation ayant une valeur juridique**.

Les informations affichées ne remplacent en aucun cas :

* l'avis d'un médecin ou d'un autre professionnel de santé qualifié ;

* la consultation des étiquettes officielles des produits alimentaires ;

* les informations fournies directement par le fabricant.

Les évaluations générées par l'application se basent exclusivement sur les données disponibles dans la base de données et sur les paramètres configurés par l'utilisateur, et pourraient ne pas refléter les variations dans la composition des produits, les mises à jour des recettes par les fabricants ou les informations non disponibles.

L'utilisateur est toujours tenu de vérifier de manière autonome la composition et l'étiquetage des produits avant leur consommation.

---

## 1. Responsable du Traitement

Le Responsable du traitement des données à caractère personnel est :

**Emanuele Ciotola**

E-mail :

**[supporto-gscanner@googlegroups.com](mailto:supporto-gscanner@googlegroups.com)**

Pour toute demande relative au traitement des données personnelles ou à l'exercice des droits prévus par le RGPD, il est possible de contacter le Responsable à l'adresse susmentionnée.

---

## 2. Catégories de données traitées

L'application traite exclusivement les données nécessaires à son fonctionnement et à la fourniture des fonctionnalités proposées.

### 2.1 Utilisateurs anonymes

Lorsque G-Scanner est utilisée sans se connecter, les données personnelles de l'utilisateur et les préférences configurées restent exclusivement sur l'appareil et sont stockées localement via **SharedPreferences**.

Celles-ci incluent :

* l'historique des scans ;

* les paramètres de l'application ;

* les préférences relatives aux fonctionnalités alimentaires et de santé sélectionnées par l'utilisateur.

Ces données personnelles **ne sont pas transmises aux serveurs du Responsable**.

Il est toutefois entendu que les **signalements relatifs aux produits**, s'ils sont envoyés via l'application, sont stockés dans la base de données cloud de l'application et mis à la disposition des autres utilisateurs de la communauté afin d'améliorer le service.

Les signalements publiés dans la communauté peuvent contenir exclusivement :

* des informations relatives à l'aliment ou au produit signalé ;

* d'éventuelles notes saisies par l'utilisateur ;

* le motif du signalement.

L'identité de l'utilisateur qui effectue le signalement, y compris **nom, prénom, adresse e-mail ou autres données d'identification**, **n'est jamais rendue publique ni associée de manière visible au signalement, en aucune circonstance**.

Les signalements effectués par d'autres utilisateurs peuvent également être consultés par les usagers de l'application, indépendamment de leur authentification.

### 2.2 Utilisateurs authentifiés

L'utilisateur peut s'authentifier via **Firebase Authentication** en utilisant un compte :

* Google ;

* Facebook.

Suite à l'authentification, les données nécessaires à l'identification de l'utilisateur sont recueillies auprès du fournisseur d'identité. Celles-ci peuvent inclure :

* le nom ;

* le prénom ;

* l'adresse e-mail ;

* le numéro de téléphone, si disponible ou associé au profil utilisé pour l'authentification.

À ces informations est associé un identifiant unique de l'utilisateur (**User ID**).

G-Scanner n'accède pas aux identifiants de connexion de l'utilisateur, tels que les mots de passe ou des outils équivalents, et ne traite pas ces informations.

### 2.3 Données stockées dans la base de données cloud

Pour les utilisateurs authentifiés, les données suivantes sont stockées sur **Firebase Firestore** et associées à l'identifiant de l'utilisateur :

* l'historique des scans ;

* la liste des signalements envoyés ;

* les paramètres relatifs aux préférences alimentaires :

Avertissement Additifs ;

* Filtre Strict Contaminations ;

* Intolérance au Lactose ;

* d'éventuels paramètres relatifs aux avertissements sur les contaminations ;

* la langue sélectionnée ;

* le thème graphique choisi.

Les données d'identification obtenues par l'authentification (nom, prénom, adresse e-mail et éventuel numéro de téléphone, si disponible) sont utilisées exclusivement pour :

* permettre la gestion du compte ;

* associer correctement les données de l'utilisateur à son profil ;

* fournir les fonctionnalités réservées aux utilisateurs authentifiés.

### 2.4 Cookies et Technologies de Stockage Local

G-Scanner (aussi bien dans la version Web App que dans l'application Mobile) n'utilise pas de cookies de profilage, d'outils de traçage publicitaire ou de systèmes d'analyse tiers (analytics).

L'application utilise exclusivement des technologies de stockage local strictement nécessaires (telles que SharedPreferences sur les appareils mobiles et LocalStorage / Cookies techniques sur les navigateurs) aux seules fins de :

* Maintenir la session de l'utilisateur active de manière sécurisée via Firebase Authentication ;

* Stocker localement les préférences de l'utilisateur (ex. langue, thème graphique) et la confirmation d'acceptation des documents légaux.

S'agissant exclusivement d'outils techniques indispensables à la fourniture du service demandé par l'utilisateur, conformément à la législation européenne (Directive ePrivacy) et aux dispositions de l'Autorité italienne de protection des données, le consentement préalable de l'utilisateur n'est pas requis pour leur utilisation. L'utilisateur est informé de leur présence par la présente Politique de Confidentialité, sans qu'il soit nécessaire d'afficher une bannière ou des documents séparés.

Les données stockées localement restent sur l'appareil de l'utilisateur jusqu'à leur suppression ou la désinstallation de l'application.

### 2.5 Base de données locale pour l'utilisation hors ligne

G-Scanner peut permettre à l'utilisateur de télécharger sur son appareil une copie locale de données relatives aux produits alimentaires, afin de permettre la consultation et le scannage des produits même en l'absence de connexion Internet.

La base de données hors ligne contient exclusivement des informations relatives aux produits alimentaires nécessaires au fonctionnement des fonctionnalités hors ligne et ne contient aucune donnée personnelle de l'utilisateur.

L'utilisateur peut choisir entre différentes configurations de la base de données hors ligne, caractérisées par un niveau de couverture distinct et une quantité de données stockées sur l'appareil différente.

Les données présentes dans la base de données hors ligne constituent une copie locale des données disponibles au moment de leur mise à jour et peuvent donc ne pas refléter les modifications ou mises à jour ultérieures des informations relatives aux produits.

Les données consultées via la base de données hors ligne ne sont pas automatiquement associées au profil personnel de l'utilisateur, ni utilisées pour créer ou mettre à jour son profil.

La base de données hors ligne peut être mise à jour ou supprimée par l'utilisateur via les fonctionnalités mises à disposition par l'application.

---

## 3. Données appartenant à des catégories particulières (Art. 9 RGPD)

G-Scanner permet à l'utilisateur de configurer des préférences personnelles spécifiques afin de consulter les informations sur les produits alimentaires. Ces paramètres peuvent refléter l'état de santé ou des besoins alimentaires particuliers de l'utilisateur et, par conséquent, peuvent constituer des **catégories particulières de données à caractère personnel**, au sens de l'**article 9 du Règlement (UE) 2016/679 (RGPD)**.

Les paramètres disponibles dans l'application sont les suivants :

* **Avertissement Additifs** : génère un avertissement en présence d'ingrédients tels que des amidons modifiés ou des arômes dont l'origine n'est pas précisée, afin que l'utilisateur puisse effectuer des vérifications supplémentaires.

* **Filtre Strict Contaminations** : considère comme **"Interdit"** tout aliment dont l'étiquette comporte des mentions telles que **"peut contenir des traces de gluten"** ou des formulations équivalentes relatives à une éventuelle contamination par le gluten.

* **Intolérance au Lactose** : vérifie la présence d'ingrédients tels que le lactose, le beurre, le lait en poudre ou le lactosérum, en signalant leur présence éventuelle selon les fonctionnalités de l'application.

Au **premier lancement de l'application**, seules les options suivantes sont activées par défaut :

* Avertissement Additifs ;

* Filtre Strict Contaminations.

L'option **Intolérance au Lactose** est initialement désactivée et peut être activée par l'utilisateur à tout moment.

Le traitement de ces informations s'effectue **exclusivement avec le consentement explicite préalable de l'utilisateur**, conformément à l'**article 9, paragraphe 2, point a) du RGPD**.

L'utilisateur est libre de modifier, d'activer ou de désactiver ces paramètres à tout moment en fonction de ses besoins personnels.

Ces choix sont effectués sous la responsabilité de l'utilisateur, qui reconnaît que G-Scanner constitue exclusivement un **outil de soutien informatif** et ne remplace pas :

* la vérification des étiquettes des produits ;

* les informations fournies par le fabricant ;

* l'avis d'un médecin ou d'un autre professionnel de santé qualifié.

Toute modification des paramètres et l'utilisation des informations fournies par l'application se font donc **aux risques exclusifs de l'utilisateur**.

L'utilisateur peut à tout moment modifier ses préférences ou retirer le consentement précédemment donné, sans porter atteinte à la licéité du traitement fondé sur le consentement effectué avant le retrait de celui-ci.

---

## 4. Finalités du traitement

Les données personnelles collectées via G-Scanner sont traitées pour les finalités suivantes :

* permettre le scannage des codes-barres et la consultation des informations relatives aux produits alimentaires ;

* permettre la consultation des informations relatives aux produits même en l'absence de connexion Internet, au moyen de l'éventuelle base de données locale téléchargée par l'utilisateur ;

* permettre la personnalisation de l'expérience de l'utilisateur via la configuration des préférences alimentaires et des paramètres de l'application ;

* permettre aux utilisateurs authentifiés de synchroniser les données entre différents appareils ;

* permettre la participation à la communauté via l'envoi, la gestion et la consultation des signalements relatifs aux produits ;

* gérer l'authentification via des fournisseurs externes tels que Google et Facebook ;

* garantir le bon fonctionnement technique de l'application, la sécurité des services et la protection des données traitées.

---

## 5. Base juridique du traitement

Le traitement des données personnelles se fonde sur :

* le consentement explicite de la personne concernée pour le traitement des **catégories particulières de données à caractère personnel** relatives à la santé (art. 9, par. 2, let. a du RGPD) ;

* l'exécution du service demandé par l'utilisateur et des fonctionnalités proposées par l'application ;

* le respect des obligations prévues par la législation en vigueur ;

* l'intérêt légitime du Responsable concernant la sécurité technique de l'application et la prévention des utilisations abusives du service, le cas échéant.

---

## 6. Mineurs

L'utilisation de G-Scanner est interdite aux mineurs de **14 ans**.

Conformément à la législation italienne sur le consentement numérique, l'application n'est pas destinée aux utilisateurs de moins de 14 ans et ne collecte pas sciemment des données personnelles relatives à ces sujets.

Si le Responsable prend connaissance de la présence de données appartenant à un mineur de moins de 14 ans, il procédera à leur suppression dans les plus brefs délais.

---

## 7. Accès aux fonctionnalités et informations de l'appareil

Pour garantir le bon fonctionnement des fonctionnalités proposées, G-Scanner peut accéder à certaines fonctionnalités et informations de l'appareil de l'utilisateur.

### Appareil photo

L'appareil photo est utilisé exclusivement pour permettre le scannage des codes-barres des produits.

Les images acquises via l'appareil photo ne sont ni sauvegardées, ni transmises, ni utilisées à d'autres fins que le scannage du code-barres.

### Connexion Internet

L'application vérifie, si nécessaire, la disponibilité de la connexion Internet afin de déterminer si les fonctionnalités nécessitant l'accès aux services en ligne peuvent être utilisées.

La connexion Internet est nécessaire, en particulier, pour :

* effectuer l'authentification via les fournisseurs pris en charge ;

* synchroniser les données des utilisateurs authentifiés ;

* accéder aux services cloud utilisés par l'application ;

* récupérer et mettre à jour les informations sur les produits au moyen des services en ligne ;

* permettre le fonctionnement des fonctionnalités basées sur les données de la communauté.

L'état de la connexion est utilisé exclusivement pour la gestion technique des fonctionnalités de l'application et n'est ni collecté, ni conservé, ni utilisé à des fins de profilage ou de traçage.

### Thème du système

L'autorisation relative au thème du système est utilisée exclusivement pour adapter automatiquement l'interface graphique de l'application au mode clair ou sombre configuré sur l'appareil de l'utilisateur.

### Langue de l'appareil et langue de l'interface

Au premier lancement, l'application peut lire la langue configurée sur l'appareil afin de déterminer automatiquement la langue de l'interface de l'application.

La langue ainsi déterminée est utilisée pour configurer l'interface de l'application et, pour les utilisateurs authentifiés, peut être enregistrée dans la base de données associée au compte afin de conserver cette préférence et de la synchroniser entre les appareils.

La langue de l'interface n'est pas utilisée à des fins de profilage, de traçage ou de publicité.

---

## 8. Absence de publicité, de traçage et de collecte de données analytiques

G-Scanner adopte une politique de protection de la confidentialité des utilisateurs.

L'application :

* est entièrement gratuite ;

* ne contient pas de publicité ;

* n'utilise pas d'outils d'analyse (analytics) ;

* n'utilise pas Google Analytics ;

* n'utilise pas Firebase Crashlytics ;

* n'effectue pas de profilage des utilisateurs ;

* ne mène pas d'activités de traçage des utilisateurs ;

* ne vend pas de données personnelles ;

* ne communique ni ne cède de données personnelles à des tiers à des fins commerciales.

En particulier, **G-Scanner ne collecte pas d'identifiants publicitaires, d'informations d'utilisation de l'application, de données de diagnostic ou de données techniques de l'appareil à des fins d'analyse ou de profilage**.

L'application ne procède à aucun suivi comportemental de l'utilisateur ni ne crée de profils commerciaux ou publicitaires.

---

## 9. Conservation des données

### 9.1 Utilisateurs anonymes

Lorsque l'utilisateur utilise G-Scanner sans s'authentifier, les données personnelles et les préférences configurées restent exclusivement stockées localement sur l'appareil via **SharedPreferences**.

Ces données sont conservées jusqu'à ce que :

* l'utilisateur les supprime via les fonctionnalités disponibles dans l'application ;

* l'application soit désinstallée ;

* l'appareil soit réinitialisé ou que les données locales soient effacées.

Les signalements relatifs aux produits envoyés à la communauté constituent un traitement distinct et sont quant à eux conservés dans la base de données cloud de l'application pour en permettre la consultation par les autres utilisateurs.

### 9.2 Base de données locale pour l'utilisation hors ligne

Les données relatives aux produits contenues dans la base de données hors ligne sont conservées localement sur l'appareil jusqu'à ce que l'utilisateur :

* supprime la base de données via les fonctionnalités disponibles dans l'application ;

* remplace la base de données par une configuration différente ;

* désinstalle l'application ;

* efface les données locales correspondantes, lorsque le système d'exploitation le prévoit.

La base de données hors ligne peut être mise à jour périodiquement. La version disponible sur l'appareil pourrait donc ne pas coïncider avec la version la plus récente des données disponibles en ligne.

### 9.3 Utilisateurs authentifiés

Pour les utilisateurs authentifiés, les données sont conservées selon un mode de **double stockage** :

* localement sur l'appareil de l'utilisateur, pour permettre une utilisation rapide de l'application ;

* dans la base de données cloud Firebase Firestore, pour permettre la synchronisation des informations entre différents appareils et le maintien des fonctionnalités associées au compte.

Les données associées au compte restent conservées jusqu'à leur suppression selon les modalités décrites dans l'article suivant relatif à l'effacement des données.

---

## 10. Droit à l'effacement et gestion du compte (Art. 17 RGPD)

L'utilisateur dispose de deux modalités distinctes pour la gestion de la suppression de ses données.

### 10.1 Suppression du compte via la fonction interne de l'application

Si l'utilisateur utilise la fonction interne de suppression du compte disponible dans G-Scanner, son **profil de connexion Firebase Authentication** est supprimé.

Cette opération entraîne :

* le retrait définitif de l'association entre le compte et les données d'identification utilisées pour l'authentification ;

* l'effacement des références relatives à l'e-mail, nom, prénom et éventuelles données du fournisseur associées au profil.

Toutefois, la suppression du profil d'authentification **n'entraîne pas automatiquement la destruction physique immédiate des documents présents sur Firebase Firestore**.

Les données éventuellement présentes dans la base de données cloud, telles que :

* l'historique des scans ;

* les paramètres de l'application ;

* les données associées à l'identifiant utilisateur ;

ne sont plus associables à l'identité de l'utilisateur et deviennent techniquement inaccessibles par une utilisation normale de l'application.

Le lien entre ces données et l'identité de l'utilisateur est définitivement supprimé.

### 10.2 Effacement complet et définitif des données (Wipe des données)

Si l'utilisateur souhaite l'effacement physique complet et définitif de tous les enregistrements associés à son identifiant présents dans les systèmes cloud, il doit adresser une demande explicite au Responsable via :

**[supporto-gscanner@googlegroups.com](mailto:supporto-gscanner@googlegroups.com)**

La demande doit être effectuée **avant de procéder à la suppression du profil via l'application**, en utilisant la même adresse e-mail que celle associée au compte utilisé pour la connexion.

Cette procédure est nécessaire pour que le Responsable puisse vérifier l'identité du demandeur et localiser correctement les enregistrements associés au compte.

Si l'utilisateur supprime préalablement son profil depuis l'application sans avoir envoyé la demande d'effacement complet, il se peut qu'il ne soit plus possible de vérifier l'identité du demandeur ni de localiser les données précédemment associées au compte supprimé.

Suite à la vérification de l'identité, le Responsable procédera à l'effacement définitif des données présentes dans les systèmes cloud et associées à l'identifiant de l'utilisateur, dans les limites techniquement disponibles et prévues par la législation applicable.

---

## 11. Droits de la personne concernée

Conformément aux articles 15 et suivants du RGPD, la personne concernée peut exercer le droit de :

* obtenir la confirmation de l'existence de ses données personnelles ;

* accéder aux données personnelles traitées ;

* demander la rectification des données inexactes ;

* demander l'effacement des données dans les cas prévus par la législation ;

* obtenir la limitation du traitement ;

* s'opposer au traitement dans les cas autorisés ;

* retirer le consentement précédemment donné, sans porter atteinte à la licéité du traitement effectué avant le retrait de celui-ci ;

* recevoir ses données dans un format structuré (portabilité des données), le cas échéant ;

* introduire une réclamation auprès de l'Autorité de contrôle pour la protection des données personnelles.

Pour l'exercice de ses droits, il est possible de contacter le Responsable :

**[supporto-gscanner@googlegroups.com](mailto:supporto-gscanner@googlegroups.com)**

---

## 12. Sécurité des données

Les données personnelles sont traitées au moyen d'outils informatiques et de mesures techniques et organisationnelles appropriées afin de garantir leur :

* confidentialité ;

* intégrité ;

* disponibilité ;

* protection contre les accès non autorisés.

En particulier, pour les données stockées via l'infrastructure Firebase, l'accès aux données cloud est limité exclusivement aux personnes autorisées et est protégé par les mesures techniques et de sécurité mises à disposition par l'infrastructure Firebase.

Le Responsable adopte des mesures proportionnées à la nature des données traitées, en tenant compte des risques inhérents au traitement, conformément à l'art. 32 du RGPD.

---

## 13. Modifications de la présente Politique de Confidentialité

Le Responsable se réserve le droit de modifier ou de mettre à jour la présente Politique de Confidentialité afin de l'adapter aux :

* modifications législatives ;

* évolutions techniques de l'application ;

* variations des modalités de traitement des données à caractère personnel.

La version mise à jour sera rendue disponible au sein de l'application et/ou à travers les éventuels canaux officiels de G-Scanner, avec l'indication de la date de la dernière mise à jour.

---

## 14. Prestataires de Services et Transfert de Données

Pour la fourniture des fonctionnalités proposées par G-Scanner, le Responsable fait appel à des prestataires de services technologiques qui traitent des données personnelles exclusivement dans les limites nécessaires à l'exécution des services demandés.

### 14.1 Infrastructure Cloud (Google Firebase)

Pour les fonctionnalités d'authentification et de stockage des données, G-Scanner utilise la plateforme **Google Firebase**, fournie par **Google Ireland Limited**, dont le siège est situé à Gordon House, Barrow Street, Dublin 4, Irlande.

En particulier, l'application utilise :

* **Firebase Authentication**, pour la gestion de l'authentification des utilisateurs ;

* **Cloud Firestore**, pour le stockage et la synchronisation des données des utilisateurs authentifiés.

Pour les traitements effectués pour le compte du Responsable dans le cadre des services Firebase utilisés par l'application, **Google Ireland Limited agit en qualité de Sous-traitant au sens de l'art. 28 du RGPD**.

Ceci s'entend sans préjudice des éventuelles activités de traitement pour lesquelles Google agit en tant que responsable indépendant du traitement, conformément aux dispositions de la documentation de confidentialité du service Firebase.

### 14.2 Localisation des données et transferts vers des pays tiers

La base de données **Cloud Firestore** utilisée par G-Scanner est configurée dans la région :

**eur3 – Francfort (Allemagne)**

ce qui correspond à des infrastructures localisées au sein de l'Union Européenne.

Le Responsable adopte cette configuration dans le but de favoriser la conservation des données personnelles à l'intérieur de l'Espace Économique Européen (EEE).

Dans le cas où Google procéderait à des transferts techniques de données à caractère personnel vers des pays situés en dehors de l'Espace Économique Européen, ces transferts seront effectués dans le respect des articles 44 et suivants du RGPD et garantis par des mécanismes légalement reconnus, parmi lesquels :

* le **Cadre de protection des données UE-États-Unis (Data Privacy Framework)**, le cas échéant ;

* les **Clauses Contractuelles Types (CCT)** approuvées par la Commission Européenne.

### 14.3 Services d'authentification via des fournisseurs externes (Social Login)

L'utilisateur peut choisir de s'authentifier via :

* Google ;

* Facebook.

Lors de la procédure d'authentification :

* **Google Ireland Limited** ;

* **Meta Platforms Ireland Limited**

agissent en qualité de **Responsables Indépendants du Traitement**, limitativement aux activités nécessaires à la vérification des identifiants de connexion, à la gestion de l'identité numérique et à la fourniture du service d'authentification.

G-Scanner reçoit exclusivement les données nécessaires à la création et à la gestion du compte, qui peuvent inclure :

* le nom ;

* le prénom ;

* l'adresse e-mail ;

* l'éventuel numéro de téléphone disponible.

Pour tout autre traitement effectué directement par les fournisseurs externes, il convient de se référer à leurs politiques de confidentialité officielles respectives :

* Politique de Confidentialité de Google ;

* Politique de Confidentialité de Meta.

Le Responsable n'est pas responsable des traitements effectués de manière indépendante par ces fournisseurs pour leurs propres finalités.

---

## 15. Absence de prise de décision automatisée (Art. 22 RGPD)

G-Scanner utilise des filtres et des critères d'information configurés par l'application pour fournir des indications relatives aux produits alimentaires.

Les classifications générées par l'application, telles que par exemple **"Interdit"**, **"Autorisé"**, **"Attention"** ou des indications équivalentes, constituent exclusivement des informations de soutien basées sur les données disponibles et sur les paramètres sélectionnés par l'utilisateur.

**L'application ne procède à aucune prise de décision automatisée produisant des effets juridiques ou vous affectant de manière significative de façon similaire au sens de l'art. 22 du RGPD.**

---

## 16. Langue des Informations et des Conditions

La présente Politique de Confidentialité, ainsi que les Conditions Générales d'Utilisation et tout autre document légal relatif à l'Application, sont rédigés à l'origine en langue italienne. Les traductions éventuelles dans d'autres langues sont fournies exclusivement à titre de courtoisie et pour faciliter la compréhension de l'Utilisateur. En cas de divergences, d'incohérences ou de différences d'interprétation entre la version en langue italienne et toute version traduite, la version en langue italienne prévaudra, dans les limites maximales autorisées par la législation applicable.

---

## Contacts du Responsable du Traitement

**Emanuele Ciotola**

E-mail :

**[supporto-gscanner@googlegroups.com](mailto:supporto-gscanner@googlegroups.com)**
''';
