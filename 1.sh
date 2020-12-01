dbi -q "SELECT poolid, poolname, packagefordynamiceusers, packagepurchaseinterval, expirytime  from tblippool where macbaseddynamiceusers = 'Y';" > package.tmp

policynamepostfix="_macpolicy"
policytype=0	#mac
renewaltype=1	#intervalbased
interval=-1
time=-1
renewalcount=1
zoneid=-1
packageid=0ffff
devicecount=1
usernametype=4
passwordtype=3

while read line 
do
	poolid=`echo $line | awk -F, '{print $1}'`	
	poolname=`echo $line | awk -F, '{print $2}'`
	packageid=`echo $line | awk -F, '{print $3}'`
	interval=`echo $line | awk -F, '{print $4}'`
	expirytime=`echo $line | awk -F, '{print $5}'`

	policyname=`echo "$poolname$policynamepostfix"`
	
	if [[ interval -eq -1 ]]; then
		renewaltype=1;
		hr=`echo $expirytime | awk -F: '{print $1}'`
		min=`echo $expirytime | awk -F: '{print $2}'`
		time=`expr $hr \* 60 + $min` 
	fi
	insquery="insert into tblselfregpolicy (policyId, policyType, policyName, usernametype, passwordType, renewalType, intervalDuration, intervalTime, renewalCount, zoneId, groupId, deviceCount) values (nextval('tblselfregpolicy_seq'), $policytype, '$policyname', $usernametype, $passwordtype, $renewaltype, $interval, $time, $renewalcount, $zoneid, '[$packageid]', $devicecount);"
	dbi -q "$insquery"
	policyid=`dbi -q "select policyid from tblselfregpolicy where policyname like '$policyname';"`
	updatequery="UPDATE tblippool SET macbasedpolicy = $policyid, selfregpolicy = 0 where poolid = $poolid;"
	dbi -q "$updatequery"
	echo $insquery
	echo $updatequery
done < package.tmp

##Self registration migration

pkgid=`dbi -q "SELECT servicevalue from tblclientservices where servicekey = 'packageforclientreg';"`
zoneid=`dbi -q "SELECT servicevalue from tblclientservices where servicekey = 'zoneforclientregistration';"`
if [ "$pkgid" != "-1" ]; then 
	IFS=', ' read -r -a array <<< `echo $pkgid | cut -d "[" -f2 | cut -d "]" -f1`
	
	policyname="selfpolicy_migration"
	policytype=1	#self
	renewaltype=2	#no renewal
	interval=-1
	time=-1
	renewalcount=-1
	packageid=$pkgid
	devicecount=-1
	usernametype=2	#custom
	passwordtype=3
	
	insquery="insert into tblselfregpolicy (policyId, policyType, policyName, usernametype, passwordType, renewalType, intervalDuration, intervalTime, renewalCount, zoneId, groupId, deviceCount) values (nextval('tblselfregpolicy_seq'), $policytype, '$policyname', $usernametype, $passwordtype, $renewaltype, $interval, $time, $renewalcount, $zoneid, '$packageid', $devicecount);"
	dbi -q "$insquery"
	policyid=`dbi -q "select policyid from tblselfregpolicy where policyname like '$policyname';"`
	updatequery="UPDATE tblippool SET selfregpolicy = $policyid"
	dbi -q "$updatequery"
	echo $insquery
	echo $updatequery
fi
