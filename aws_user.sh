#!/bin/bash


# AWS CLI Script to create and assign users
# Version: 1.0.0
# Last Modified: February 3, 2026

# Requirements: 
#   - AWS CLI v2 (aws-cli/2.0 or higher)
#   - Configure AWS profile in ~/.aws/config
#   - Preconfigured IAM Groups within AWS


# Setup: 
#   1. Install AWS CLI v2: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
#   2. Configure AWS Profile:
#   	- run aws configure
#   3. Ensure script is executable: chmod +x aws_user.sh
# Usage:
#   ./aws_user.sh [-n] [-g] [-p]






    usage() {
  cat <<EOF
Usage: $0 -n <username> -g <group> [-p <password>]

Required:
  -n <username> IAM username to create
  -g <group>    IAM group to add the user to

Optional:
  -p <password> Temporary console password
                If omitted, you will be prompted

Allowed Groups:
  Admin
  Dev
  Student

Examples:
  $0 -n gbrown -g Admin
  $0 -n gbrown -g Dev -p TempPass123!
EOF
}

###### ------- Functions ---- #######


##### Verify that aws and cli is configured 

  getaws() { 
      command -v aws >/dev/null 2>&1 || return 127
       aws sts get-caller-identity >/dev/null 2>&1 || return 1
  }	  
	
#### Checking for IAM User
  
  user_exists() {
          local username="$1"
          aws iam get-user --user-name "$username" >/dev/null 2>&1
}



#### Create IAM User

    create_user() {
	local username="$1"
	aws iam create-user --user-name "$username" >/dev/null 2>&1
}


#### Check for IAM login Profile


	login_profile_exists() { 
	    local username="$1"
	    aws iam get-login-profile --user-name "$username" >/dev/null 2>&1
	 }



#### Set Console Password

    set_console_password() {
	    local username="$1"
	    local password="$2"
	    aws iam create-login-profile \
		    --user-name "$username" \
		    --password "$password" \
		    --password-reset-required  >/dev/null 2>&1
    }



##### Add user to group

      add_user_to_group() {
	   local username="$1"
	   local group="$2"
	   aws iam add-user-to-group \
	      --user-name "$username" \
	      --group-name "$group" \
	      >/dev/null 2>&1
	} 



##### Main logic


     main() {

	if ! getaws; then
	  echo "AWS CLI not configured"
	  exit 1
	fi 

     while getopts "n:g:p:h" opt; do
       case "$opt" in

	  n) username="$OPTARG" ;;
	  g) group="$OPTARG" ;;
	  p) password="$OPTARG" ;;
          h)
		  usage
		  exit 0
		  ;;
	esac
      done

   [ -z "$username" ] && echo "Error: Username required" && usage &&  exit 1
   [ -z "$group" ] && echo "Group required" && usage &&  exit 1
   
   case "$group" in
        Admin|Dev|Student)
          # valid
          ;;
         *)
           echo "Invalid group: $group"
           echo "Allowed groups: Admin, Dev, Student"
           exit 1
           ;;
      esac
   
   if [ -z "$password" ]; then 
      read -s -p "Temporary password: " password 

      echo
   fi
   
   [ -z "$password" ] && echo "Password required" && exit 1

   echo 

   echo "About to create IAM user: "
   echo " Username: $username"
   echo " Group: $group"

   read -r -p "Proceed? [y/N]: " confirm


   case "$confirm" in 

	 y|Y|yes|YES)
            ;;
	 *)
 	  echo "Aborted."
	  exit 0

	  ;;
    esac	  

   if user_exists "$username"; then

      echo "User already exists"
      exit 1
   fi
   
   create_user "$username" 

   if login_profile_exists "$username"; then
	
	aws iam update-login-profile \
		--user-name "$username" \
		--password "$password" \
		--password-restet-required >/dev/null 2>&1
	else
   
   	  set_console_password "$username" "$password"

    fi

   add_user_to_group "$username" "$group"

	echo "-----------------"

	echo "User creation complete"
	
	echo "Username: $username"

	echo "Group: $group"

	echo "-----------------"

}



main "$@"



	  
	       	
