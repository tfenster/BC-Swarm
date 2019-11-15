use [CRONUS]

-- delete windows users
declare @deleteUserSQL nvarchar(max)
set @deleteUserSQL = ''

select @deleteUserSQL = @deleteUserSQL + 
'
print ''Dropping ' + name + '''
drop user [' + name + ']
'
from sysusers
where isntuser = 1 or isntgroup = 1

print @deleteUserSQL
execute(@deleteUserSQL)

-- delete view
DROP VIEW [dbo].[deadlock_report_ring_buffer_view]