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
    echo "CSV should have 5 columns with the following headers:
        1. username      (username of student)
        2. full-name     (full name of student)
        3. grad-year     (grad year of student)
        4. position      (student || teacher || staff)
        5. serial-number (device serial number)"
	exit 1
fi

# set jssURL to first parameter
jssURL=$1

# if jssURL is emply, warn user
if [[ -z "${jssURL}" ]]; then
	abort "Please specify a JSS server"
elif [[ `curl --connect-timeout 10 -k -s $jssURL/healthCheck.html -w \\nStatus:\ %{http_code} | grep Status: | awk '{print $2}'` != 200 ]]; then
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
testCredentials=$(curl --connect-timeout 10 -k -s -u "$apiUser":"$apiUserPass" "$jssURL/JSSResource/accounts" -w \\nStatus:\ %{http_code} | grep Status: | awk '{print $2}')
if [[ "$testCredentials" == "200" ]]; then
    echo "Credentials tested and confirmed functional"
    sleep 3
else
    abort "The user account or password was wrong, or doesn't have API Rights"
fi

findDeviceID() {
    # find ID of device
    deviceID=$(curl -k -s -u "$apiUser":"$apiUserPass" "$jssURL/JSSResource/mobiledevices/serialnumber/$serialNumber" | xpath '/mobile_device/general/id/text()' 2>/dev/null)
}

findUserID() {
    # find ID of user
    userID=$(curl -k -s -u "$apiUser":"$apiUserPass" "$jssURL/JSSResource/users/name/$userName" | xpath 'user/id/text()' 2>/dev/null)
}

updateDeviceName() {
    # this changes the name of the Device
	curl -k -s -u "$apiUser":"$apiUserPass" "$jssURL/JSSResource/mobiledevicecommands/command/DeviceName/$fullName /id/$deviceID" -X POST

    # this pushes a inventory for it
	curl -k -s -u "$apiUser":"$apiUserPass" "$jssURL/JSSResource/mobiledevicecommands/command/UpdateInventory/id/$deviceID" -X POST

    # this pushes a blankpush
    curl -k -s -u "$apiUser":"$apiUserPass" "$jssURL/JSSResource/mobiledevicecommands/command/BlankPush/id/$deviceID" -X POST
}

# create new user and apply position, grad year, and assigned device
createUser() {
    postXML="<user>
  <name>$userName</name>
  <full_name>$fullName</full_name>
  <email>$userName@olphbc.ca</email>
  <position>$position<position>
  <extension_attributes>
    <extension_attribute>
      <id>1</id>
      <name>Graduation Year</name>
      <type>Number</type>
      <value>$gradYear</value>
    </extension_attribute>
  </extension_attributes>
  <links>
    <mobile_devices>
      <mobile_device>
        <id>$deviceID</id>
        <name>$fullName</name>
      </mobile_device>
    </mobile_devices>
  </links>
</user>"
    curl -k -s -u "$apiUser":"$apiUserPass" "$jssURL/JSSResource/users/id/0" -H "Content-Type: text/xml" -X POST -d $postXML
}

# update position, grad year, and assigned device
updateUserInfo() {
    putXML="<user>
  <position>$position<position>
  <extension_attributes>
    <extension_attribute>
      <id>1</id>
      <name>Graduation Year</name>
      <type>Number</type>
      <value>$gradYear</value>
    </extension_attribute>
  </extension_attributes>
  <links>
    <mobile_devices>
      <mobile_device>
        <id>$deviceID</id>
        <name>$fullName</name>
      </mobile_device>
    </mobile_devices>
  </links>
</user>"
    curl -k -s -u "$apiUser":"$apiUserPass" "$jssURL/JSSResource/users/id/$userID" -H "Content-Type: text/xml" -X PUT -d $putXML
}

# remove first line of csvFile
csvFileWithoutHeader=/tmp/rename_iOS_from-tmp.csv
echo "Removing headers from CSV"
awk 'NR>1' "$csvFile" > $csvFileWithoutHeader

# all the things
while IFS=, read userName fullName gradYear position serialNumber
do
	if [[ -z $userName ]] || [[ -z $fullName ]] || [[ -z $gradYear ]] || [[ -z $position ]] || [[ -z $serialNumber ]]; then
		echo "Line missing required info, check CSV File"
	else
		echo "Processing $fullName"
    	findDeviceID
    	if [[ -z $deviceID ]]; then
        	echo "Serial Number $serialNumber not found, skipping"
    	else
        	findUserID
        	if [[ -z $userID ]]; then
            	updateDeviceName
            	echo "Username $userName not found, creating account now"
            	createUser
        	else
            	updateDeviceName
            	updateUserInfo
        	fi
    	fi
	fi
#    echo "The Username is $userName"
#    echo "The Full Name is $fullName"
#    echo "The Grad Year is $gradYear"
#    echo "The Position is $position"
#    echo "The Serial Number is $serialNumber"
done < $csvFileWithoutHeader

# cleanup
rm -f $csvFileWithoutHeader
exit 0
