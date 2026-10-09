// Copyright (c) 2026 Emanuele Ciotola. All Rights Reserved.
// PROJECT: G-Scanner — See LICENSE file in root for terms.

const String ppEs = r'''
# Política de Privacidad de G-Scanner

**Versión:** 1.0

**Fecha de entrada en vigor:** 9 de octubre de 2026

**Fecha de última actualización:** 9 de octubre de 2026

---

La presente Política de Privacidad describe las modalidades de tratamiento de los datos personales efectuado a través de la aplicación móvil y web **G-Scanner**, desarrollada en cumplimiento del **Reglamento (UE) 2016/679 (RGPD)** y de la normativa italiana aplicable en materia de protección de datos personales.

---

## Finalidad de la aplicación

G-Scanner es una aplicación que permite a los usuarios consultar información relativa a los productos alimenticios mediante el escaneo de códigos de barras, prestando especial atención a las necesidades de las personas con celiaquía o intolerancia a la lactosa.

La aplicación permite además a los usuarios configurar preferencias alimentarias específicas, recibir indicaciones basadas en filtros informativos preestablecidos y participar en una comunidad a través de la posibilidad de compartir reportes sobre los productos.

**Importante – Limitación de responsabilidad**

La información proporcionada por G-Scanner tiene fines exclusivamente informativos y de apoyo al usuario.

La aplicación **no constituye un dispositivo médico**, **no ofrece asesoramiento médico**, **no tiene valor diagnóstico ni terapéutico** y **no produce efectos ni evaluaciones con valor legal**.

La información mostrada no sustituye en modo alguno:

* el consejo de un médico o de otro profesional sanitario cualificado;

* la consulta de las etiquetas oficiales de los productos alimenticios;

* la información facilitada directamente por el fabricante.

Las evaluaciones generadas por la aplicación se basan exclusivamente en los datos disponibles en la base de datos y en los ajustes configurados por el usuario, y podrían no reflejar variaciones en la composición de los productos, actualizaciones de recetas por parte de los fabricantes o información no disponible.

El usuario está siempre obligado a verificar por sí mismo la composición y el etiquetado de los productos antes de su consumo.

---

## 1. Responsable del Tratamiento

El Responsable del Tratamiento de los datos personales es:

**Emanuele Ciotola**

E-mail:

**[supporto-gscanner@googlegroups.com](mailto:supporto-gscanner@googlegroups.com)**

Para cualquier solicitud relativa al tratamiento de los datos personales o al ejercicio de los derechos previstos por el RGPD, es posible ponerse en contacto con el Responsable a través de la dirección arriba indicada.

---

## 2. Tipos de datos tratados

La aplicación trata exclusivamente los datos necesarios para su funcionamiento y para la prestación de las funciones ofrecidas.

### 2.1 Usuarios anónimos

Cuando se utiliza G-Scanner sin iniciar sesión, los datos personales del usuario y las preferencias configuradas permanecen exclusivamente en el dispositivo y se almacenan localmente mediante **SharedPreferences**.

Entre estos se incluyen:

* el historial de escaneos;

* los ajustes de la aplicación;

* las preferencias relativas a las funciones alimentarias y de salud seleccionadas por el usuario.

Dichos datos personales **no se transmiten a los servidores del Responsable**.

Queda entendido, no obstante, que los **reportes relativos a los productos**, en caso de enviarse a través de la aplicación, se almacenan en la base de datos en la nube (cloud) de la aplicación y se ponen a disposición de los demás usuarios de la comunidad con el fin de mejorar el servicio.

Los reportes publicados en la comunidad pueden contener exclusivamente:

* información relativa al alimento o producto reportado;

* posibles notas introducidas por el usuario;

* el motivo del reporte.

La identidad del usuario que realiza el reporte, incluyendo **nombre, apellidos, dirección de correo electrónico u otros datos identificativos**, **nunca se hace pública ni se asocia de forma visible al reporte bajo ninguna circunstancia**.

Asimismo, los reportes realizados por otros usuarios pueden ser consultados por quienes utilizan la aplicación, independientemente de que se hayan autenticado.

### 2.2 Usuarios autenticados

El usuario puede autenticarse mediante **Firebase Authentication** utilizando una cuenta de:

* Google;

* Facebook.

Tras la autenticación, se recaban del proveedor los datos necesarios para la identificación del usuario, que pueden incluir:

* nombre;

* apellidos;

* dirección de correo electrónico;

* número de teléfono, si está disponible o asociado al perfil utilizado para la autenticación.

A dicha información se asocia un identificador único de usuario (**User ID**).

G-Scanner no accede a las credenciales de autenticación del usuario, tales como contraseñas o herramientas equivalentes, y no trata dicha información.

### 2.3 Datos almacenados en la base de datos en la nube (cloud)

Para los usuarios autenticados se almacenan en **Firebase Firestore**, asociados al identificador del usuario:

* el historial de escaneos;

* la lista de reportes enviados;

* los ajustes relativos a las preferencias alimentarias:

Advertencia de Aditivos;

* Filtro Estricto de Contaminación;

* Intolerancia a la Lactosa;

* posibles ajustes relativos a las advertencias sobre contaminación;

* el idioma seleccionado;

* el tema gráfico elegido.

Los datos identificativos obtenidos mediante la autenticación (nombre, apellidos, dirección de correo electrónico y, en su caso, número de teléfono disponible) se utilizan exclusivamente para:

* permitir la gestión de la cuenta;

* asociar correctamente los datos del usuario a su perfil;

* prestar las funcionalidades reservadas a los usuarios autenticados.

### 2.4 Cookies y Tecnologías de Almacenamiento Local

G-Scanner (tanto en la versión Web App como en la aplicación móvil) no utiliza cookies de elaboración de perfiles, herramientas de rastreo publicitario ni sistemas analíticos de terceros.

La aplicación utiliza exclusivamente tecnologías de almacenamiento local estrictamente necesarias (como SharedPreferences en dispositivos móviles y LocalStorage / Cookies técnicas en navegadores) con el único fin de:

* Mantener activa la sesión del usuario de forma segura a través de Firebase Authentication;

* Almacenar localmente las preferencias del usuario (ej. idioma, tema gráfico) y la confirmación de aceptación de los documentos legales.

Dado que se trata exclusivamente de herramientas técnicas indispensables para la prestación del servicio solicitado por el usuario, de conformidad con la normativa europea (Directiva ePrivacy) y las resoluciones de la Autoridad de Control italiana, no se requiere el consentimiento previo del usuario para su uso. Se informa al usuario de su presencia a través de la presente Política de Privacidad, sin necesidad de banners ni documentos separados.

Los datos almacenados localmente permanecen en el dispositivo del usuario hasta su eliminación o hasta la desinstalación de la aplicación.

### 2.5 Base de datos local para el uso sin conexión

G-Scanner puede permitir al usuario descargar en su dispositivo una copia local de datos relativos a los productos alimenticios, con el fin de posibilitar la consulta y el escaneo de productos incluso en ausencia de una conexión a Internet.

La base de datos sin conexión contiene exclusivamente información relativa a los productos alimenticios necesaria para el funcionamiento de las funciones sin conexión y no contiene ningún dato personal del usuario.

El usuario puede elegir entre distintas configuraciones de la base de datos sin conexión, caracterizadas por un nivel de cobertura diferente y la consiguiente cantidad distinta de datos almacenados en el dispositivo.

Los datos presentes en la base de datos sin conexión constituyen una copia local de los datos disponibles en el momento de su actualización y podrían, por tanto, no reflejar posibles modificaciones o actualizaciones posteriores de la información relativa a los productos.

Los datos consultados a través de la base de datos sin conexión no se asocian automáticamente al perfil personal del usuario ni se utilizan para crear o actualizar dicho perfil.

La base de datos sin conexión puede ser actualizada o eliminada por el usuario mediante las funcionalidades puestas a disposición por la aplicación.

---

## 3. Categorías especiales de datos personales (Art. 9 RGPD)

G-Scanner permite al usuario configurar preferencias personales específicas destinadas a la consulta de información sobre productos alimenticios. Dichos ajustes pueden reflejar el estado de salud o las necesidades dietéticas particulares del usuario y, por lo tanto, pueden constituir **categorías especiales de datos personales**, en virtud del **art. 9 del Reglamento (UE) 2016/679 (RGPD)**.

Los ajustes disponibles en la aplicación son los siguientes:

* **Advertencia de Aditivos**: genera un aviso en presencia de ingredientes como almidones modificados o aromas cuyo origen no se especifique, para que el usuario pueda realizar comprobaciones adicionales.

* **Filtro Estricto de Contaminación**: considera como **"Prohibido"** cualquier alimento cuya etiqueta contenga menciones como **"puede contener trazas de gluten"** o fórmulas equivalentes relativas a la posible contaminación por gluten.

* **Intolerancia a la Lactosa**: comprueba la presencia de ingredientes como lactosa, mantequilla, leche en polvo o suero lácteo, señalando su posible presencia según las funciones de la aplicación.

En el **primer inicio de la aplicación**, están habilitadas por defecto exclusivamente las siguientes opciones:

* Advertencia de Aditivos;

* Filtro Estricto de Contaminación.

La opción **Intolerancia a la Lactosa** está inicialmente desactivada y el usuario puede habilitarla en cualquier momento.

El tratamiento de dicha información se realiza **exclusivamente con el consentimiento explícito previo del usuario**, de conformidad con el **art. 9, apartado 2, letra a) del RGPD**.

El usuario es libre de modificar, activar o desactivar en cualquier momento dichos ajustes de acuerdo con sus necesidades personales.

Dichas elecciones se efectúan bajo la responsabilidad del usuario, el cual reconoce que G-Scanner constituye exclusivamente una **herramienta de apoyo informativo** y no sustituye:

* la comprobación de las etiquetas de los productos;

* la información proporcionada por el fabricante;

* el consejo de un médico o de otro profesional sanitario cualificado.

Por lo tanto, la modificación de los ajustes y el uso de la información facilitada por la aplicación se realizan **bajo el riesgo exclusivo del usuario**.

El usuario puede en cualquier momento modificar sus preferencias o retirar el consentimiento prestado anteriormente, sin que ello afecte a la licitud del tratamiento basado en el consentimiento previo a su retirada.

---

## 4. Finalidades del tratamiento

Los datos personales recabados a través de G-Scanner se tratan para las siguientes finalidades:

* permitir el escaneo de los códigos de barras y la consulta de la información relativa a los productos alimenticios;

* permitir la consulta de la información relativa a los productos incluso en ausencia de una conexión a Internet, mediante la eventual base de datos local descargada por el usuario;

* permitir la personalización de la experiencia del usuario mediante la configuración de preferencias alimentarias y ajustes de la aplicación;

* permitir a los usuarios autenticados sincronizar sus datos entre diferentes dispositivos;

* permitir la participación en la comunidad a través del envío, gestión y consulta de los reportes sobre los productos;

* gestionar la autenticación a través de proveedores externos como Google y Facebook;

* garantizar el correcto funcionamiento técnico de la aplicación, la seguridad de los servicios y la protección de los datos tratados.

---

## 5. Base legitimadora del tratamiento

El tratamiento de los datos personales se basa en:

* el consentimiento explícito del interesado para el tratamiento de las **categorías especiales de datos personales** relativas a la salud (art. 9, apdo. 2, letra a del RGPD);

* la ejecución del servicio solicitado por el usuario y de las funcionalidades ofrecidas por la aplicación;

* el cumplimiento de las obligaciones previstas en la normativa vigente;

* el interés legítimo del Responsable en relación con la seguridad técnica de la aplicación y la prevención del uso indebido del servicio, cuando proceda.

---

## 6. Menores de edad

El uso de G-Scanner está prohibido a los menores de **14 años**.

De conformidad con la normativa italiana sobre el consentimiento digital, la aplicación no está destinada a usuarios menores de 14 años y no recopila de manera consciente datos personales atribuibles a dichas personas.

Si el Responsable tuviera conocimiento de la presencia de datos pertenecientes a un menor de 14 años, procederá a su pronta eliminación.

---

## 7. Acceso a funciones e información del dispositivo

Para garantizar el correcto funcionamiento de las funciones ofrecidas, G-Scanner puede acceder a ciertas funciones e información del dispositivo del usuario.

### Cámara

La cámara se utiliza exclusivamente para permitir el escaneo de los códigos de barras de los productos.

Las imágenes adquiridas a través de la cámara no se guardan, transmiten ni utilizan para ningún otro fin que no sea el escaneo del código de barras.

### Conexión a Internet

La aplicación comprueba, en caso necesario, la disponibilidad de la conexión a Internet con el fin de determinar si pueden utilizarse las funciones que requieren acceso a los servicios en línea.

La conexión a Internet es necesaria, en particular, para:

* realizar la autenticación a través de los proveedores admitidos;

* sincronizar los datos de los usuarios autenticados;

* acceder a los servicios en la nube utilizados por la aplicación;

* recuperar y actualizar la información de los productos mediante los servicios en línea;

* permitir el funcionamiento de las funciones basadas en los datos de la comunidad.

El estado de la conexión se utiliza exclusivamente para la gestión técnica de las funciones de la aplicación y no se recopila, conserva ni utiliza para fines de elaboración de perfiles o rastreo.

### Tema del sistema

El permiso relativo al tema del sistema se utiliza exclusivamente para adaptar automáticamente la interfaz gráfica de la aplicación al modo claro u oscuro configurado en el dispositivo del usuario.

### Idioma del dispositivo e idioma de la interfaz

En el primer inicio, la aplicación puede leer el idioma configurado en el dispositivo con el fin de determinar automáticamente el idioma de la interfaz de la aplicación.

El idioma determinado de este modo se utiliza para configurar la interfaz de la aplicación y, para los usuarios autenticados, puede guardarse en la base de datos asociada a la cuenta con el fin de mantener la preferencia y sincronizarla entre dispositivos.

El idioma de la interfaz no se utiliza para fines de elaboración de perfiles, rastreo ni publicidad.

---

## 8. Ausencia de publicidad, rastreo y recopilación de datos analíticos

G-Scanner adopta una política de protección de la privacidad de los usuarios.

La aplicación:

* es completamente gratuita;

* no contiene publicidad;

* no utiliza herramientas analíticas;

* no utiliza Google Analytics;

* no utiliza Firebase Crashlytics;

* no elabora perfiles de los usuarios;

* no realiza actividades de seguimiento (tracking) de los usuarios;

* no vende datos personales;

* no comunica ni cede datos personales a terceros con fines comerciales.

En particular, **G-Scanner no recopila identificadores publicitarios, información de uso de la aplicación, datos de diagnóstico ni datos técnicos del dispositivo con fines analíticos o de elaboración de perfiles**.

La aplicación no lleva a cabo procesos de control del comportamiento del usuario ni crea perfiles comerciales o publicitarios.

---

## 9. Conservación de los datos

### 9.1 Usuarios anónimos

Cuando el usuario utiliza G-Scanner sin autenticarse, los datos personales y las preferencias configuradas permanecen almacenados exclusivamente a nivel local en el dispositivo a través de **SharedPreferences**.

Dichos datos se conservan hasta que:

* el usuario los elimina a través de las funciones disponibles en la aplicación;

* la aplicación es desinstalada;

* se restablece el dispositivo o se borran los datos locales.

Los reportes relativos a los productos enviados a la comunidad constituyen un tratamiento distinto y se conservan en la base de datos en la nube de la aplicación para permitir su consulta por parte de los demás usuarios.

### 9.2 Base de datos local para el uso sin conexión

Los datos relativos a los productos contenidos en la base de datos sin conexión se conservan localmente en el dispositivo hasta que el usuario:

* elimina la base de datos a través de las funciones disponibles en la aplicación;

* sustituye la base de datos por una configuración diferente;

* desinstala la aplicación;

* borra los datos locales correspondientes, cuando lo prevea el sistema operativo.

La base de datos sin conexión puede actualizarse periódicamente. La versión disponible en el dispositivo podría, por tanto, no coincidir con la versión más reciente de los datos disponibles en línea.

### 9.3 Usuarios autenticados

Para los usuarios autenticados, los datos se conservan mediante una modalidad de **doble almacenamiento**:

* localmente en el dispositivo del usuario, para permitir un uso rápido de la aplicación;

* en la base de datos en la nube de Firebase Firestore, para permitir la sincronización de la información entre distintos dispositivos y el mantenimiento de las funciones asociadas a la cuenta.

Los datos asociados a la cuenta permanecen conservados hasta su eliminación según los procedimientos descritos en el siguiente artículo relativo a la supresión de datos.

---

## 10. Derecho de supresión y gestión de la cuenta (Art. 17 RGPD)

El usuario dispone de dos modalidades distintas para gestionar la eliminación de sus datos.

### 10.1 Eliminación de la cuenta mediante función interna de la aplicación

Si el usuario utiliza la función interna específica de eliminación de cuenta disponible en G-Scanner, se procede a la eliminación del correspondiente **perfil de autenticación de Firebase Authentication**.

Esta operación conlleva:

* la eliminación definitiva de la asociación entre la cuenta y los datos de identificación utilizados para la autenticación;

* la supresión de las referencias relativas a correo electrónico, nombre, apellidos y posibles datos del proveedor asociados al perfil.

Sin embargo, la eliminación del perfil de autenticación **no conlleva automáticamente la destrucción física inmediata de los documentos presentes en Firebase Firestore**.

Los datos que pudieran encontrarse en la base de datos en la nube, tales como:

* historial de escaneos;

* ajustes de la aplicación;

* datos asociados al identificador del usuario;

ya no podrán vincularse a la identidad del usuario y resultan técnicamente inaccesibles mediante el uso normal de la aplicación.

El vínculo entre dichos datos y la identidad del usuario se elimina de forma definitiva.

### 10.2 Borrado completo y definitivo de los datos (Wipe de datos)

Si el usuario desea la eliminación física completa y definitiva de todos los registros asociados a su identificador en los sistemas en la nube, debe enviar una solicitud explícita al Responsable a través de:

**[supporto-gscanner@googlegroups.com](mailto:supporto-gscanner@googlegroups.com)**

La solicitud debe efectuarse **antes de proceder a la eliminación del perfil a través de la aplicación**, utilizando la misma dirección de correo electrónico asociada a la cuenta empleada para el acceso.

Este procedimiento es necesario para que el Responsable pueda verificar la identidad del solicitante y localizar correctamente los registros asociados a la cuenta.

Si el usuario elimina previamente su perfil de la aplicación sin haber enviado la solicitud de eliminación completa, podría no ser posible verificar la identidad del solicitante ni localizar los datos previamente asociados a la cuenta eliminada.

Tras verificar la identidad, el Responsable procederá a la eliminación definitiva de los datos presentes en los sistemas en la nube asociados al identificador del usuario, dentro de los límites técnicamente disponibles y previstos por la normativa aplicable.

---

## 11. Derechos del interesado

En virtud de los artículos 15 y siguientes del RGPD, el interesado puede ejercer los derechos de:

* obtener confirmación sobre la existencia de sus datos personales;

* acceder a los datos personales tratados;

* solicitar la rectificación de los datos inexactos;

* solicitar la supresión de los datos en los supuestos previstos por la normativa;

* obtener la limitación del tratamiento;

* oponerse al tratamiento en los casos permitidos;

* retirar el consentimiento prestado previamente, sin que ello afecte a la licitud del tratamiento basado en dicho consentimiento antes de su retirada;

* recibir sus datos en formato estructurado (portabilidad), cuando proceda;

* presentar una reclamación ante la Autoridad de Control competente en materia de Protección de Datos.

Para el ejercicio de sus derechos, es posible ponerse en contacto con el Responsable del Tratamiento:

**[supporto-gscanner@googlegroups.com](mailto:supporto-gscanner@googlegroups.com)**

---

## 12. Seguridad de los datos

Los datos personales se tratan mediante herramientas informáticas y medidas técnicas y organizativas adecuadas para garantizar su:

* confidencialidad;

* integridad;

* disponibilidad;

* protección frente a accesos no autorizados.

En particular, para los datos almacenados mediante la infraestructura de Firebase, el acceso a los datos en la nube está limitado exclusivamente a las personas autorizadas y se encuentra protegido mediante las medidas técnicas y de seguridad que facilita la infraestructura de Firebase.

El Responsable adopta medidas proporcionales a la naturaleza de los datos tratados, teniendo en cuenta los riesgos asociados al tratamiento, de conformidad con el art. 32 del RGPD.

---

## 13. Modificaciones a la presente Política de Privacidad

El Responsable se reserva el derecho de modificar o actualizar la presente Política de Privacidad para adecuarla a:

* modificaciones normativas;

* evolución técnica de la aplicación;

* variaciones en las modalidades de tratamiento de los datos personales.

La versión actualizada estará disponible dentro de la aplicación y/o a través de los eventuales canales oficiales de G-Scanner, con indicación de la fecha de su última actualización.

---

## 14. Proveedores de Servicios y Transferencia de Datos

Para la prestación de las funciones ofrecidas por G-Scanner, el Responsable recurre a proveedores de servicios tecnológicos que tratan datos personales exclusivamente en la medida necesaria para la ejecución de los servicios solicitados.

### 14.1 Infraestructura en la Nube (Google Firebase)

Para las funciones de autenticación y almacenamiento de datos, G-Scanner utiliza la plataforma **Google Firebase**, proporcionada por **Google Ireland Limited**, con domicilio en Gordon House, Barrow Street, Dublín 4, Irlanda.

En particular, la aplicación utiliza:

* **Firebase Authentication**, para la gestión de la autenticación de los usuarios;

* **Cloud Firestore**, para el almacenamiento y sincronización de los datos de los usuarios autenticados.

Para los tratamientos realizados por cuenta del Responsable en el ámbito de los servicios de Firebase utilizados por la aplicación, **Google Ireland Limited actúa como Encargado del Tratamiento en virtud del art. 28 del RGPD**.

Quedan a salvo las posibles actividades de tratamiento respecto de las cuales Google actúa como responsable independiente, de conformidad con lo establecido en la documentación de privacidad del servicio Firebase.

### 14.2 Localización de los datos y transferencias a terceros países

La base de datos **Cloud Firestore** utilizada por G-Scanner está configurada en la región:

**eur3 – Frankfurt (Alemania)**

correspondiente a infraestructuras ubicadas dentro de la Unión Europea.

El Responsable adopta dicha configuración con el objetivo de favorecer la conservación de los datos personales dentro del Espacio Económico Europeo (EEE).

En caso de que Google realizara transferencias técnicas de datos personales a países situados fuera del Espacio Económico Europeo, dichas transferencias se efectuarán en cumplimiento de los artículos 44 y siguientes del RGPD y estarán garantizadas mediante instrumentos reconocidos legalmente, entre ellos:

* el **Marco de Privacidad de Datos UE-EE. UU. (Data Privacy Framework)**, cuando proceda;

* las **Cláusulas Contractuales Tipo (CCT - Standard Contractual Clauses)** aprobadas por la Comisión Europea.

### 14.3 Servicios de autenticación mediante proveedores externos (Social Login)

El usuario puede elegir autenticarse a través de:

* Google;

* Facebook.

Durante el proceso de autenticación:

* **Google Ireland Limited**;

* **Meta Platforms Ireland Limited**

actúan en calidad de **Responsables Independientes del Tratamiento**, limitándose a las actividades necesarias para la comprobación de las credenciales, la gestión de la identidad digital y la prestación del servicio de autenticación.

G-Scanner recibe exclusivamente los datos necesarios para la creación y gestión de la cuenta, que pueden incluir:

* nombre;

* apellidos;

* dirección de correo electrónico;

* posible número de teléfono disponible.

Para cualquier tratamiento ulterior realizado directamente por los proveedores externos, se remite a las respectivas políticas de privacidad oficiales:

* Política de Privacidad de Google;

* Política de Privacidad de Meta.

El Responsable no se hace cargo de los tratamientos realizados de forma autónoma por dichos proveedores para sus propios fines.

---

## 15. Ausencia de decisiones automatizadas (Art. 22 RGPD)

G-Scanner utiliza filtros y criterios informativos configurados en la aplicación para facilitar orientaciones relativas a los productos alimenticios.

Las clasificaciones generadas por la aplicación, tales como por ejemplo **"Prohibido"**, **"Permitido"**, **"Atención"** o indicaciones equivalentes, constituyen exclusivamente información de apoyo basada en los datos disponibles y en los ajustes seleccionados por el usuario.

**La aplicación no lleva a cabo procesos de toma de decisiones automatizadas que produzcan efectos jurídicos en el usuario o que le afecten significativamente de modo similar, en virtud del art. 22 del RGPD.**

---

## 16. Idioma de las Políticas y de los Términos

La presente Política de Privacidad, así como los Términos y Condiciones de Uso y cualesquiera otros documentos legales relativos a la Aplicación, han sido redactados originalmente en idioma italiano. Cualquier traducción a otros idiomas se facilita exclusivamente a título de cortesía y para facilitar la comprensión por parte del Usuario. En caso de discrepancia, incoherencia o diferencia interpretativa entre la versión en idioma italiano y cualquier versión traducida, prevalecerá la versión en idioma italiano, en la máxima medida permitida por la legislación aplicable.

---

## Contacto del Responsable del Tratamiento

**Emanuele Ciotola**

E-mail:

**[supporto-gscanner@googlegroups.com](mailto:supporto-gscanner@googlegroups.com)**
''';
