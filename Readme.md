### Version history

* 0.1.0 : Added a column `mailbox_id` to sql. (Mail will be store in /mail-storage/`mailbox_id`.)
* 0.1.1 : Added default mailboxes (Trash, Sent, etc...)

### Environment

(name : sample)

* MYHOSTNAME : mail.domain.com
* MYDOMAIN : domain.com
* BOUNCE_NOTICE_RECIPIENT : admin@domain.com
* POSTMASTER_ADDRESS : admin@domain.com
* DB_HOST : db
* DB_NAME : mailserver
* DB_USER : mailserver
* DB_PASS : password



### SQL

```sql

CREATE TABLE `mail_alas` (
  `id` int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `domain_id` int(11) NOT NULL,
  `source` varchar(128) NOT NULL,
  `destination` varchar(128) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `mail_vdom` (
  `id` int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `domain` varchar(128) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `mail_user` (
  `idx` int(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `mailbox_id` varchar(40) NOT NULL COMMENT 'UUID format',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `domain_id` int(11) NOT NULL,
  `email_username` varchar(128) NOT NULL,
  `password` varchar(512) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


ALTER TABLE `mail_alas`
  ADD UNIQUE KEY `source` (`domain_id`,`source`) USING BTREE;

ALTER TABLE `mail_vdom`
  ADD UNIQUE KEY `domain` (`domain`);

ALTER TABLE `mail_user`
  ADD UNIQUE KEY `uq_email` (`domain_id`,`email_username`);
ALTER TABLE `mail_user`
  ADD CONSTRAINT FOREIGN KEY (`domain_id`) REFERENCES `mail_vdom`(`id`);


```



## Kubernetes

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mailserver-pv
spec:
  capacity:
    storage: 256Gi
  accessModes:
  - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: mailserver-storage
  local:
    path: /data/mail
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - kube-master
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mailserver-pvc
spec:
  storageClassName: mailserver-storage
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: "256Gi"

---

kind: Deployment
apiVersion: apps/v1
metadata:
  name: mailserver
  labels:
    app: mailserver-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mailserver-app
  template:
    metadata:
      labels:
        app: mailserver-app
    spec:
      volumes:
      - name: data-mail
        persistentVolumeClaim:
          claimName: mailserver-pvc
      - name: secret-tls
        secret:
          secretName: your-cert # NEED tls.crt (certificate chain) & tls.key (private key)
      containers:
      - name: mailserver-container
        image: "YOUR IMAGE"
        volumeMounts:
        - name: data-mail
          readOnly: false
          mountPath: "/mail-storage/"
        - name: secret-tls
          readOnly: true
          mountPath: "/secret/"
        ports:
        - containerPort: 25
        - containerPort: 587
        - containerPort: 485
        - containerPort: 110
        - containerPort: 995
        - containerPort: 143
        - containerPort: 993
        env:
        - name: MYHOSTNAME
          value: ?
        - name: MYDOMAIN
          value: ?
        - name: BOUNCE_NOTICE_RECIPIENT
          value: ?
        - name: POSTMASTER_ADDRESS
          value: ?
        - name: DB_HOST
          value: ?
        - name: DB_NAME
          value: ?
        - name: DB_USER
          value: ?
        - name: DB_PASS
          value: ?

---

kind: Service
apiVersion: v1
metadata:
  name: mailserver
  labels:
    app: mailserver-app
spec:
  type: LoadBalancer
  selector:
    app: mailserver-app
  ports:
  - name: mail-25
    port: 25
    targetPort: 25
  - name: mail-587
    port: 587
    targetPort: 587
  - name: mail-465
    port: 465
    targetPort: 465
  - name: mail-110
    port: 110
    targetPort: 110
  - name: mail-995
    port: 995
    targetPort: 995
  - name: mail-143
    port: 143
    targetPort: 143
  - name: mail-993
    port: 993
    targetPort: 993


```

