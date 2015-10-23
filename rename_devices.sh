#!/bin/bash
################################### Variables ###################################
# API Username
username="apiTestAccount"
# API Password
password="LfCKHUUgHzX4y4"
# JSS URL (without trailing /)
JSS_URL='https://newton.corp.olphbc.ca:8443'
# Path to Resource (without trailing /)
JSS_Resource='JSSResource/mobiledevices/id'
# ID to start at
id="124"
# Location for Temporary files
tempLocation=/tmp/
################################## Do Not Edit ##################################
if [ ! -d "$tempLocation/$JSS_Resource" ]; then
    mkdir -p "$tempLocation/$JSS_Resource"
fi

formattedList="$tempLocation/$JSS_Resource/formattedList.xml"
plainList="$tempLocation/$JSS_Resource/plainList"

createIDlist () {
curl $JSS_URL/$JSS_Resource -u $username:$password | xmllint --format - > "$formattedList"
cat "$formattedList" |awk -F'<id>|</id>' '/<id>/ {print $2}' > "$plainList"
echo -e "\n\n\n"
sleep 3
}

gatherInformation() {
    # Grab Device id
    getDeviceID=`curl $JSS_URL/$JSS_Resource/$id -u $username:$password | xpath '//general/id' 2>&1 | awk -F'<id>|</id>' '{print $2}'`
    # Grab Device display_name
    #getDeviceDisplayName=`curl $JSS_URL/$JSS_Resource/$id -u $username:$password | xpath '//general/display_name' 2>&1 | awk -F'<display_name>|</display_name>' '{print $2}'`
    # Grab Device device_name
    #getDeviceDeviceName=`curl $JSS_URL/$JSS_Resource/$id -u $username:$password | xpath '//general/device_name' 2>&1 | awk -F'<device_name>|</device_name>' '{print $2}'`
    # Grab Device name
    getDeviceName=`curl $JSS_URL/$JSS_Resource/$id -u $username:$password | xpath '//general/name' 2>&1 | awk -F'<name>|</name>' '{print $2}'`
    # Grab Device username
    getUserName=`curl $JSS_URL/$JSS_Resource/$id -u $username:$password | xpath '//location/username' 2>&1 | awk -F'<username>|</username>' '{print $2}'`
    sleep 3
}

createDeviceName () {
    newDeviceName="OLPH iPad $(echo $getDeviceName | awk '{print $3,$4}') $getUserName"
    sleep 3
}

putInformation() {
    curl $JSS_URL/$JSS_Resource/$id -u $username:$password -H "Content-Type: application/xml" -X PUT -d "<general><id>$getDeviceID</id><display_name>$newDeviceName</display_name><device_name>$newDeviceName</device_name><name>$newDeviceName</name></general>"
    sleep 3
}


## Look at this
fetchResourceID () {
    totalFetchedIDs=`cat "$plainList" | wc -l | sed -e 's/^[ \t]*//'`
        for apiID in $(cat $plainList)
           do
            echo "Downloading ID number $apiID ( $resultInt out of $totalFetchedIDs )"
            curl --silent -k --user "$sourceJSSuser:$sourceJSSpw" -H "Content-Type: application/xml" -X GET  "$sourceJSS"JSSResource/$jssResource/id/$apiID  | xmllint --format - >> $fetchedResult
            let "resultInt = $resultInt + 1"
            fetchedResult="$localOutputDirectory"/"$jssResource"/fetched_xml/result"$resultInt".xml
            done
}


# Get whole record
#getDeviceRecord=curl $JSS_URL/$JSS_Resource/$id -u $username:$password | xmllint --format -> $tempLocation
