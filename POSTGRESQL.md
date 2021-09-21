# Setup PostgreSQL for Datashark

Connect to PostgreSQL server as `postgres` user :

```bash
sudo su - postgres
psql
```

Create `datashark` role and database :

```sql
CREATE ROLE datashark LOGIN INHERIT NOCREATEDB NOSUPERUSER NOCREATEROLE PASSWORD 'datashark';
CREATE DATABASE datashark OWNER datashark;
```

Edit `pg_hba.conf` :

```
#       DATABASE    USER        ADDRESS           METHOD
host    datashark   datashark   subnet/netmask    md5
```

Try to connect to datashark database :

```bash
psql -h HOST -p 5432 datashark datashark
# enter the password and hit enter
# you should be connected by now
```
