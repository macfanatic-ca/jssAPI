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
    echo "CSV should have 7 columns with the following headers:
        1. username         (username)                    [required]
        2. full-name        (full name)                   [required]
        3. email            (email address)               [required]
        4. apple-id         (apple id)                    [can be left empty]
        5. grad-year        (grad year of student)        [can be left empty]
        6. stream           (for A/B schools)             [can be left empty]
        7. position         (student || teacher || staff) [required]"
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

# find ID of user
findUserID() {
    userID=$(curl -k -sS -u "$apiUser":"$apiUserPass" "$jssURL/JSSResource/users/name/$userName" -H "Accept: application/xml" | xpath 'user/id/text()' 2>/dev/null)
}

# find ID of 'Managed Apple ID' Extension Attribute
findManagedAppleIDEA() {
	managedAppleIDEAID=$(curl -k -sS -u "$apiUser":"$apiUserPass" "$jssURL/JSSResource/userextensionattributes/name/Managed%20Apple%20ID" -H "Accept: application/xml" | xpath 'user_extension_attribute/id/text()' 2>/dev/null)
}

# create 'Managed Apple ID' Extension Attribute
createManagedAppleIDEA() {
	postXML="<user_extension_attribute><name>Managed Apple ID</name><data_type>String</data_type><input_type><type>Text Field</type></input_type></user_extension_attribute>"
	curl -k -sS -u "$apiUser":"$apiUserPass" "$jssURL/JSSResource/userextensionattributes/id/0" -H "Content-Type: text/xml" -X POST -d "$postXML" /dev/null 2>&1
}

# find ID of 'Grad Year' Extension Attribute
findUserGradYearEA() {
	userGradYearEAID=$(curl -k -sS -u "$apiUser":"$apiUserPass" "$jssURL/JSSResource/userextensionattributes/name/Grad%20Year" -H "Accept: application/xml" | xpath 'user_extension_attribute/id/text()' 2>/dev/null)
}

# create 'Grad Year' Extension Attribute
createUserGradYearEA() {
	postXML="<user_extension_attribute><name>Stream</name><data_type>Integer</data_type><input_type><type>Text Field</type></input_type></user_extension_attribute>"
	curl -k -sS -u "$apiUser":"$apiUserPass" "$jssURL/JSSResource/userextensionattributes/id/0" -H "Content-Type: text/xml" -X POST -d "$postXML" > /dev/null 2>&1
}

# find ID of 'Stream' Extension Attribute
findUserStreamEA() {
	userStreamEAID=$(curl -k -sS -u "$apiUser":"$apiUserPass" "$jssURL/JSSResource/userextensionattributes/name/Stream" -H "Accept: application/xml" | xpath 'user_extension_attribute/id/text()' 2>/dev/null)
}

# create 'Stream' Extension Attribute
createUserStreamEA() {
	postXML="<user_extension_attribute><name>Stream</name><data_type>String</data_type><input_type><type>Pop-up Menu</type><popup_choices><choice>A</choice><choice>B</choice><choice>NA</choice></popup_choices></input_type></user_extension_attribute>"
	curl -k -sS -u "$apiUser":"$apiUserPass" "$jssURL/JSSResource/userextensionattributes/id/0" -H "Content-Type: text/xml" -X POST -d "$postXML" > /dev/null 2>&1
}

# create new user and apply position, grad year, and assigned device
createUser() {
    postXML="<user><name>$userName</name><full_name>$fullName</full_name><email>$email</email><position>$position</position><extension_attributes><extension_attribute><id>$userGradYearEAID</id><value>$gradYear</value></extension_attribute><extension_attribute><id>$userStreamEAID</id><value>$stream</value></extension_attribute><extension_attribute><id>$managedAppleIDEAID</id><value>$appleID</value></extension_attribute></extension_attributes></user>"
    curl -k -sS -u "$apiUser":"$apiUserPass" "$jssURL/JSSResource/users/id/0" -H "Content-Type: text/xml" -X POST -d "$postXML" > /dev/null 2>&1
}

# update position, grad year, and assigned device
updateUserInfo() {
    putXML="<user><full_name>$fullName</full_name><email>$email</email><position>$position</position><extension_attributes><extension_attribute><id>$userGradYearEAID</id><value>$gradYear</value></extension_attribute><extension_attribute><id>$userStreamEAID</id><value>$stream</value></extension_attribute><extension_attribute><id>$managedAppleIDEAID</id><value>$appleID</value></extension_attribute></extension_attributes></user>"
    curl -k -sS -u "$apiUser":"$apiUserPass" "$jssURL/JSSResource/users/id/$userID" -H "Content-Type: text/xml" -X PUT -d "$putXML" > /dev/null 2>&1
}

# find ID or create 'Managed Apple ID' Extension Attribute
findManagedAppleIDEA
if [[ -z $managedAppleIDEAID ]]; then
	createManagedAppleIDEA
	findManagedAppleIDEA
	echo "Created 'Managed Apple ID' User Extension Attribute with ID: $managedAppleIDEAID"
fi


# find ID or create 'Grad Year' User Extension Attribute
findUserGradYearEA
if [[ -z $userGradYearEAID ]]; then
	createUserGradYearEA
	findUserGradYearEA
	echo "Created 'Grad Year' User Extension Attribute with ID: $userGradYearEAID"
fi

# find ID or create 'Stream' User Extension Attribute
findUserStreamEA
if [[ -z $userStreamEAID ]]; then
	createUserStreamEA
	findUserStreamEA
	echo "Created 'Stream' User Extension Attribute with ID: $userStreamEAID"
fi

# remove first line of csvFile
csvFileWithoutHeader=/tmp/rename_iOS_from-tmp.csv
echo "Removing headers from CSV..."
tr -d $'\r' < "$csvFile" | awk 'NR>1' > $csvFileWithoutHeader

# all the things
while IFS=, read userName fullName email appleID gradYear stream position
do
	if [[ -z $userName ]] || [[ -z $fullName ]] || [[ -z $email ]] || [[ -z $position ]]; then
		echo "Required info missing.  Skipping... Username: $userName Fullname: $fullName Email: $email Stream: $gradYear Position: $position"
	else
		if [[ -z $appleID ]]; then
			appleID=$email
		fi
		if [[ -z $gradYear ]]; then
			gradYear=0000
		fi
		if [[ -z $stream ]]; then
			stream=NA
		elif [[ $stream == a ]]; then
			stream=A
		elif [[ $stream == b ]]; then
			stream=B
		fi
		echo "Processing $fullName..."
        findUserID
        	if [[ -z $userID ]]; then
            	echo "Username $userName not found, creating account now..."
            	createUser
        	else
            	updateUserInfo
        	fi
    	fi
done < $csvFileWithoutHeader
echo "Finished processing $csvFile"

# cleanup
rm -f $csvFileWithoutHeader
exit 0
