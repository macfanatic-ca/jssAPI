# JSS API

This repo contains scripts used in conjunction with the JSS API.

### name_iOS_from_CSV.sh

Used within the k-7 schools we work with, this will utilize a CSV containing Username, Full Name, Email Address, Apple ID, Grad Year, Position, and Serial Number to achieve the following:
* Update Mobile Device name to Full Name, Run Inventory, Send Blank Push
* Create User Extension Attributes 'Grad Year' and 'Managed Apple ID'
* Update existing usernames with Full Name, Email Address, Apple ID (EA), Grad Year (EA), Position (Student, Teacher, Staff), and associate Mobile Device with User
* Create new users with Username, Full Name, Email Address, Apple ID (EA), Grad Year (EA), Position (Student, Teacher, Staff), and associate Mobile Device with User
