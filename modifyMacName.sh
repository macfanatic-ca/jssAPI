#!/bin/bash
######################### Variables #########################
apiUser=$3
apiUserPass=$4
####################### Do Not Modify #######################
# function for error reporting
abort() {
	errorString=${*}
	echo "ERROR: $errorString"
	exit 1
}

# explanation of script
if [[ ${#} -lt 2 ]] || [[ ${*} == *"-h"* ]] || [[ ${*} == *"--help"* ]]; then
	echo "Usage: $0 https://jss.example.com:8443 /path/to/example.csv [username] [password]"
	echo ""
    echo "CSV should have 2 columns with the following headers:
        1. device-name			(name of mac) [required]
        2. serial-number		(device serial number) [required]"
	exit 1
fi

# set jssURL to first parameter
jssURL=$1

# if jssURL is emply, warn user
if [[ -z "${jssURL}" ]]; then
	abort "Please specify a JSS server"
elif [[ `curl --connect-timeout 10 -k -sS $jssURL/healthCheck.html -w \\nStatus:\ %{http_code} | grep Status: | awk '{print $2}'` != 200 ]]; then
	abort "Could not connect to JSS server $jssURL"
fi

# set csvFile to second parameter
csvFile=$2

# if csvFile is empty, warn user
if [[ -z "${csvFile}" ]]; then
	abort "Please specify a CSV file"
fi

# if csvFile cannot be read, warn user
if [[ ! -r "${csvFile}" ]]; then
	abort "Cannot read the CSV file"
fi

# collect username if not specified
if [[ -z "${apiUser}" ]]; then
    echo "JSS Username: "
    read apiUser
fi

# collect username if not specified
if [[ -z "${apiUserPass}" ]]; then
    echo "JSS Password: "
    read -s apiUserPass
fi

# test supplied details
testCredentials=$(curl --connect-timeout 10 -k -sS -u "$apiUser":"$apiUserPass" "$jssURL/JSSResource/accounts" -w \\nStatus:\ %{http_code} | grep Status: | awk '{print $2}')
if [[ "$testCredentials" == "200" ]]; then
    echo "Credentials look good, moving forward..."
else
    abort "The user account or password was wrong, or doesn't have API Rights"
fi

# find ID of device
findDeviceID() {
    deviceID=$(curl -k -sS -u "$apiUser":"$apiUserPass" "$jssURL/JSSResource/computers/serialnumber/$serialNumber" -H "Accept: application/xml" | xpath '/computer/general/id/text()' 2>/dev/null)
}

# update device name within device inventory
updateDeviceInfo() {
	putXML="<computer><general><name>$deviceName</name></general></computer>"
	curl -k -sS -u "$apiUser":"$apiUserPass" "$jssURL/JSSResource/computers/id/$deviceID" -H "Content-Type: text/xml" -X PUT -d "$putXML" > /dev/null 2>&1
}

# remove first line of csvFile
csvFileWithoutHeader=/tmp/rename_iOS_from-tmp.csv
echo "Removing headers from CSV..."
tr -d $'\r' < "$csvFile" | awk 'NR>1' > $csvFileWithoutHeader

# all the things
while IFS=, read deviceName serialNumber
do
	if [[ -z $deviceName ]] || [[ -z $serialNumber ]]; then
		echo "Required info missing.  Skipping... Position: $position Serial Number: $serialNumber"
	else
		echo "Processing $serialNumber..."
    	findDeviceID
    	if [[ -z $deviceID ]]; then
        	echo "Serial Number $serialNumber not found, skipping..."
    	else
				updateDeviceInfo
        fi
    fi
done < $csvFileWithoutHeader
echo "Finished processing $csvFile"

# cleanup
rm -f $csvFileWithoutHeader
exit 0
