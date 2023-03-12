#!/bin/bash


####################################################################################
#                      Creating Log file for better debugging			   #
####################################################################################
echo "Creating/Emptying log file for better debugging purposes"
touch script.log


####################################################################################
#                      Creating User from file					   #
####################################################################################

echo "Started processing script to create new users from file"
for line in `cat users.txt`
do
	username=`echo $line | cut -d"|" -f1`
	user_policy=`echo $line | cut -d"|" -f2`
	echo "Processing user $username with policy $user_policy"
	aws iam get-user --user-name $username >> script.log
	user_status=$?
	if [ $user_status != 0 ];
	then
# User Does not exist create new one
		echo "$username User does not exist hence creating new one"
		aws iam create-user --user-name $username >> script.log
		randompassword=$(aws secretsmanager get-random-password --include-space --password-length 20 --require-each-included-type --output text)
		echo $randompassword
		aws iam create-login-profile --user-name $username --password $randompassword --password-reset-required
		aws iam create-access-key --user-name $username > "${username}-access-key.txt"
	fi
# User exists just attach a new policy
	echo 'Getting policy ARN for policy ${user_policy}'
	full_policy_arn=$(aws iam list-policies --query "Policies[?PolicyName=='${user_policy}'].{ARN:Arn}" --output text)
	echo "Attaching policy to the user Policy Name:$full_policy_arn"
	aws iam attach-user-policy --user-name $username --policy-arn ${full_policy_arn}
	policy_attach_status=$?
	if [ $policy_attach_status != 0 ];
	then
		echo "Failed to attach policy to user. User:$username Policy: $user_policy"
	fi
#	aws iam get-login-profile --user-name $username >> $username.txt
#	aws iam get-login-password --user-name $username >> $username.txt
done

