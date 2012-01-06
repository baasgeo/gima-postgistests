declare @sttime  datetime
set @sttime=getdate()
print @sttime
Select * from Table1
SELECT RTRIM(CAST(DATEDIFF(MS, @sttime, GETDATE()) AS CHAR(10))) AS 'TimeTaken' 