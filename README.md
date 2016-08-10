# JSS API Scripts

This repo contains scripts used in conjunction with the JSS API.

## deployiOSAtSchool.sh
### Synopsis

Used within the k-7 schools we work with, this will utilize a CSV with the following headers:
```
1. username     	(username)
2. full-name		(full name)
3. email			(email address)
4. apple-id         (apple id)
5. grad-year    	(grad year of student)
6. stream           (for A/B schools)
7. position     	(student || teacher || staff)
8. serial-number	(device serial number)
```
### Functions of deployiOSAtSchool.sh
* Create User Extension Attributes:
    * Grad Year
    * Stream
    * Managed Apple ID
* Create Mobile Device Extension Attributes:
    * Grad Year
    * Stream
* Update existing users with:
    * Full Name
    * Email Address
    * Managed Apple ID (EA)
    * Grad Year (EA)
    * Stream (EA)
    * Position (Student, Teacher, Staff)
* Create new users with:
    * Username
    * Full Name
    * Email Address
    * Managed Apple ID (EA)
    * Stream (EA)
    * Grad Year (EA)
    * Position (Student, Teacher, Staff)
* Update Mobile Devices with:
    * Link User to Mobile Device Inventory
    * Rename to User's Full Name
    * Update Inventory
    * Send Blank Push

#### Change Log

v1.3 - Added logic for 'Stream' Mobile Device & User Extension Attributes  
v1.2 - Added logic for 'Grad Year' Mobile Device Extension Attributes  
v1.1 - Added logic for 'Grad Year' & 'Managed Apple ID' User Extension Attributes  
