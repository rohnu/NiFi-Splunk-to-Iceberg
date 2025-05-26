# NiFi-Splunk-to-Iceberg
# NiFi-Splunk-to-Iceberg

## 📊 A Scalable Alternative to Cribl for Splunk Data Export

Apache NiFi-based pipeline for extracting logs from Splunk, transforming them, and storing them in Apache Iceberg tables for analytics. Built and validated on Cloudera Data Platform (CDP).

---

### 🔥 Why Use This?

| Feature              | scribl.py + Cribl | NiFi + Iceberg           |
|----------------------|-------------------|--------------------------|
| REST API Flexibility | ❌                | ✅                       |
| Data Preprocessing   | ❌                | ✅ (SQL, Filters, Joins) |
| Multi-format Support | ❌                | ✅ (JSON, CSV, Avro)     |
| CDP Integration      | ❌                | ✅                       |
| Fault Tolerance      | ❌                | ✅                       |

---

### 🧭 Architecture

```
+-------------+        +---------------+        +--------------------+        +------------------+
| Splunk REST |  ==>   | Apache NiFi   |  ==>   | Apache Iceberg     |  ==>   | Analytics Engine |
| API         |        | (CFM 4.0.0)   |        | (via HiveCatalog)  |        | (e.g., Spark SQL)|
+-------------+        +---------------+        +--------------------+        +------------------+
```

---

### 🛠️ Prerequisites

- Apache NiFi (CFM 4.0.0)
- CDP Private Cloud 7.1.9 or 7.3.1
- Splunk Enterprise
- Hive Metastore with Iceberg support

---

### 🔄 NiFi Data Flow

1. **GenerateFlowFile** – POST body for Splunk search query
2. **InvokeHTTP** – REST call to Splunk `/search/jobs/export`
3. **SplitText** – Line-by-line JSON record split
4. **EvaluateJsonPath** – Extract `$.result`
5. **ConvertRecord** – JSON to CSV or Avro
6. **QueryRecord** – SQL projection & filtering
7. **PutIceberg** – Store to Iceberg Table via Hive Catalog

---

### 🔐 SSL Setup

```bash
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.pem
...
keytool -importcert -alias splunk-ca -file rootCA.pem -keystore splunk-truststore.jks -storepass changeit -storetype JKS
```

Place the truststore in `/etc/nifi/certs` and use it in NiFi's `StandardSSLContextService`.

---

### 🕑 Scheduling

- GenerateFlowFile: 1-minute intervals
- Others: event-driven

---

### 🧪 Test Data Setup

```bash
#!/bin/bash
DUMMY_LOG=/var/log/dummy_app.log
...
echo "[INFO] User login from IP ..." >> "$DUMMY_LOG"
splunk add monitor "$DUMMY_LOG" -index main -sourcetype dummy_logs -auth admin:***
```

---

### 👥 Authors

- Ramprasad Ohnu – Solutions Architect
- Mala Chikka Kempanna – Senior Solutions Architect
- Aravind Naidu Swarna – Solutions Architect
- Matthew Dinep – Senior Solutions Architect
- Jason Bongard – Practice Director
- Ian Brooks – Principal Sales Engineer

---

### 📚 References

- [NiFi PutIceberg Docs](https://nifi.apache.org/docs/nifi-docs/components/org.apache.nifi.processors.iceberg.PutIceberg)
- [Splunk REST API Docs](https://docs.splunk.com/Documentation/Splunk/latest/RESTREF/RESTsearch)
- [scribl.py repo](https://github.com/tknoblau/scribl)
- [NiFi Python Developer Guide](https://nifi.apache.org/nifi-docs/python-developer-guide.html)

---

> "This solution validates Cloudera’s native capability to replace tools like Cribl using open, flexible pipelines with NiFi + Iceberg."

