--проверка работы бд в FULL Recovery Model
SELECT name, recovery_model_desc
FROM sys.databases
WHERE name = 'SchoolDB'

--Код для FULL BACKUP (ежедневно в 02:00)
BACKUP DATABASE SchoolDB
TO DISK = 'D:\Backups\SchoolDB_Full.bak'
WITH INIT, FORMAT, COMPRESSION, STATS = 10

--Код для DIFFERENTIAL BACKUP (ежедневно в 14:00)
BACKUP DATABASE SchoolDB
TO DISK = 'D:\Backups\SchoolDB_Diff.bak'
WITH DIFFERENTIAL, INIT, COMPRESSION, STATS = 10

--Код резервного копирования журнала транзакций 
--(каждые 30 минут)
BACKUP LOG SchoolDB
TO DISK = 'D:\Backups\Logs\SchoolDB_Log.trn'
WITH INIT, COMPRESSION, STATS = 10

--Код Tail-Log Backup только при аварии
BACKUP LOG SchoolDB
TO DISK = 'D:\Backups\Logs\SchoolDB_TailLog.trn'
WITH NO_TRUNCATE, NORECOVERY, STATS = 5


RESTORE DATABASE SchoolDB
FROM DISK = 'D:\Backups\SchoolDB_Full.bak'
WITH NORECOVERY, REPLACE, STATS = 10;

RESTORE DATABASE SchoolDB
FROM DISK = 'D:\Backups\SchoolDB_Diff.bak'
WITH NORECOVERY, STATS = 10;

RESTORE LOG SchoolDB
FROM DISK = 'D:\Backups\Logs\SchoolDB_Log.trn'
WITH NORECOVERY, STATS = 10;

RESTORE LOG SchoolDB
FROM DISK = 'D:\Backups\Logs\SchoolDB_TailLog.trn'
WITH RECOVERY, STATS = 10;


DBCC CHECKDB('MyDB');
RESTORE DATABASE MyDB
PAGE = '1:123, 1:124'
FROM DISK = 'MyDB_full.bak'
WITH NORECOVERY;
RESTORE LOG MyDB
FROM DISK = 'MyDB_log.trn'
WITH RECOVERY;



