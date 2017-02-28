#!/bin/bash
#
# DESCRIPTION:
#   A bash script that will check to see if you have the specified Minecraft
#   Server version, and take the actions you specify.
#   Default action: check for & install latest version
#   SCRIPT REQUIRES YOU TO CREATE YOUR OWN CUSTOM INSTALL PROCESS
#
# USAGE:
#  ./minecraft-updater.bash [arguments] [version|latest]
#
# DEPENDENCIES:
#   bash, jq, curl, egrep
#
# ASSUMPTIONS/PREREQUISITS:
#   This script depends on the version of the MC server .jar being in the
#   file name. EG: minecraft_server.1.11.2.jar
#
# ATTRIBUTIONS:
#   Script created by Perth: http://stackexchange.com/users/10345478/perth
#   WITH SPECIAL THANKS TO:
#     Richard Benson: http://gaming.stackexchange.com/questions/123194
#     Brian Campbell: http://stackoverflow.com/questions/1955505
#     Google: http://google.com :)
#
# LICENSE/LEGAL:
#   Copyright © 2017 by I'm not posting my name publicly on this site :)
#   This work is free. You can redistribute it and/or modify it under the
#   terms of the Do What The Fuck You Want To Public License, Version 2,
#   as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.

set -u # Quit if attempting to use an unset variable.
_progName="$(basename $0)"


################################################################################
# CONFIGURATION - PLEASE EDIT THIS SECTION TO MATCH YOUR ENVIRONMENT
mcUser='perth'				# The user your server runs as
mcGroup='perth'				# Dito, but group
serverDir='/home/perth/Minecraft'	# NO TRAILING SLASH!
worldDir="${serverDir}/world"		# NO TRAILING SLASH!
serverJarRegex='*.jar'			# Used by find to locate all server .jar
manifestFile="${serverDir}/version_manifest.json" # Where the file will be stored



################################################################################
# FUNCTION DECLARATIONS

########################################
# YOUR CUSTOM INSTALL PROCESS - EDIT THIS TO WORK WITH YOUR ENVIRONMENT
#   This function is intended to manipulate the downloaded jar, and take
#   any other required actions, such as warning users, stopping the old
#   Minecraft instance, and starting the new one.
#   Your server configuration, and how you want this process handled
#   will not be the same as the creator's. So set the series of commands you
#   want executed in the order you want inside of this function. This
#   will ensure the update process is as safe & holistic as you make it.
# VARIABLES AVAILABLE TO YOU
#   mcUser, mcGroup, serverDir, serverJarRegex (see CONFIGURATION)
#   targetServerJar = basename of the target version server jar
#
# DO NOT CHANGE THE NAME OF THIS FUNCTION, cause I call it later duh.
CustomInstallProcess() {
	_errExit ${LINENO} \
"You must build your own custom install process.
Please edit the CustomInstallProcess function in this script." 1

	
	###
	#### THIS WORKS FOR MY ENVIRONMENT.
	#### IF YOU USE IT W/OUT KNOWING WHAT YOU'RE DOING
	#### YOU VERY WELL MAY CORRUPT EVERYTHING!
	#### YOU HAVE BEEN WARNED!!!
	###
	
	# Require this section of the script to be run as root
	# as we will be using systemctl below, and don't want prompts.
	if [ $EUID -ne 0 ]; then
		_errExit ${LINENO} "Script must be run as root/sudo" 1
	fi

	# Set permissions on new server jar
	chmod +x "${targetServerJar}" \
	  && chown "${mcUser}:${mcGroup}" "${targetServerJar}" \
	  && _message "Set permissions on new server jar" \
	  || _errExit ${LINENO} "Failed to set permissions on jar" 1

	# Backup world directory
	backupName="${worldDir}_$(date -Iseconds).tar.gz"
	tar -czf "${backupName}" -C "$(dirname ${worldDir})" "./$(basename ${worldDir})" \
	  && _message "World backup successful: ${backupName}" \
	  || _errExit ${LINENO} "Failed to backup world." 1
	# Recover with:
	# cd /path/to/parent/directory/above/world-dir
	# mv world/ old_world
	# tar -xzf ./world...tar.gz

	# Set permissions on backup
	chmod 440 "${backupName}" \
	  && chown "${mcUser}:${mcGroup}" "${backupName}" \
	  && _message "Set permissions on world backup." \
	  || _errExit ${LINENO} "Failed to set permissions on world backup" 1

	# Kill running minecraft server
	systemctl stop minecraft.service \
	  && _message "Successfully initiated stop of minecraft server." \
	  || _errExit ${LINENO} "Failed to stop minecraft server." 1
	_message "Sleeping for 30 seconds to give server time to shut down"
	sleep 30 # Because shut up :)

	# Repoint symbolic link file named minecraft_server to new jar
	ln -s "${targetServerJar}" "${serverDir}/updated_link" \
	 && _message "Successfully created temp symbolic link" \
	 || _errExit ${LINENE} "Failed to create temporary symbolic link" 1
	chown "${mcUser}:${mcGroup}" "${serverDir}/updated_link" \
	 && _message "Successfully set permissions on temp link" \
	 || _errExit ${LINENO} "Failed to set permissions on temp link" 1
	mv "${serverDir}/updated_link" "${serverDir}/minecraft_server" \
	 && _message "Successfully replaced/updated minecraft_server link" \
	 || _errExit ${LINENO} "Failed to replace minecraft_server link." 1

	sleep 5 # Because SHUT    UP :)
	systemctl start minecraft.service \
	  && _message "Successfully started minecraft.service" \
	  || _errExit ${LINENO} "Failed to start minecraft.service" 1

	printf "\n"
	_message "SUCCESS!!!"
	_message "Your minecraft server has been successfully updated."
	_message "The new server is version: ${targetServerJar}"
	_message "Your world was backed up to: ${backupName}"
}

########################################
# Return (print) a space seperate string of version numbers for local server .jars
GetLocalVersions() {
	#Save and modify Internal Field Seperator, allows spaces in file names.
	local OLD_IFS="$IFS"; IFS=$'\n';

	#Create array of server .jar files
	local jars=($(find ${serverDir} -iname "${serverJarRegex}"))

	#Iterate through array, trim file name down to version string,
	# store all version strings seperated by spaces
	localVersions=""
	for ((i=0; i<${#jars[@]}; ++i)); do
		local temp="$(basename "${jars[$i]}" | egrep -o '[0-9]+\.[0-9]+\.[0-9]+')"
		if [[ "$temp" != "" ]]; then
			if [[ "$localVersions" != "" ]]; then
				localVersions+=" $temp"
			else
				localVersions+="$temp"
			fi
		fi
	done

	IFS="$OLD_IFS"
	printf "$localVersions"
}

# CHECK to see if targetV already exists locally.
# Returns 0 if it exists, 1 if it doesn't exist
CheckForTargetV() {
	# Validate targetV against version manifest
	if [[ "$targetV" == "latest" ]]; then
		# Replace latest with actual version number for latest release.
		targetV="$(jq -r '.latest.release' ${manifestFile})" \
		|| _errExit ${LINENO} "Failed parsing the version manifest" 1
	else
		# Validate provided version number is a valid MC version
		jq .versions[].id==\"${targetV}\" ${manifestFile} \
		  | grep true &> /dev/null \
		  || _errExit ${LINENO} "Invalid version supplied: ${targetV}" 1
	fi
	
	# Print a message indicating the target version.
	_message "TARGET: $targetV"
	
	# Geneerate and store an array of local server jar versions
	#  sorted newest to oldest.
	localVersions=($(printf '%s\n' $(GetLocalVersions)| sort -rV))

	# Check to see if targetV is in localVersions.
	for ((i=0; i<${#localVersions[@]}; ++i)); do
		if [[ "$targetV" == "${localVersions[$i]}" ]]; then
			_message "Version $targetV already exists locally"
			return 0
		fi
	done

	# If we get to here, then the function didn't return, so the target
	#  does not yet exist. Print a message, and return 1.
	_message "No local copy of $targetV exists."
	return 1
}

# DOWNLOAD, if necessary, the new server jar
# Returns 0 if successful download, or if file already exists
# SETS GLOBAL VARIABLE targetServerJar
#   - Contains full path to new/targt jar file.
DownloadTargetV() {
	# If checkReturn = 0/true; file exists; so otherwise
	if [ $checkRet -ne 0 ]; then
		# Build download URL of that version
		downloadURL="https://s3.amazonaws.com/Minecraft.Download/versions/${targetV}/minecraft_server.${targetV}.jar"
		_message "Download target: $downloadURL"
		
		# Download new jar (with no clobber just in case crazy)
		wget -nc -O "${serverDir}/minecraft_server.${targetV}.jar" "${downloadURL}" \
		  || _errExit ${LINENO} "Failed to download new server jar" 1
	else
		_message "Already have a local copy of $targetV, skipping download"
	fi

	# The name of the new/target version MC server jar available
	export targetServerJar="${serverDir}/minecraft_server.${targetV}.jar"
	return 0
}

#######################################
# Error functions
_errExit() {
	local parent_lineno="$1"
	local message="$2"
	local code="${3:-1}"
	if [[ -n "$message" ]]; then
		printf '%s[%d]: ERROR: %s\nExiting with status %d\n' \
		  "$_progName" "$parent_lineno" "$message" "$code"
	else
		printf '%s[$d]: ERROR, exiting with status %d\n' \
		  "$_progName" "$parent_lineno" "$code" >&2
	fi
	exit "$code"
}
_error() {
	local message="$@"
	if [[ -n "$message" ]]; then
		printf '%s: ERROR: %s\n' "$_progName" "$message" >&2
	else
		_errExit ${LINENO} "_error() called without a message" 1
	fi
}
_message() {
	local message="$@"
	if [[ -n "$message" ]]; then
		printf "%s: %s\n" "$_progName" "$message" >&1
	else
		_errExit ${LINENO} "_message() called without a message" 1
	fi
}

########################################
# Print usage details
_mcUpdaterUsage() {
	# Usage details
	printf '%s' "
Usage: ${_progName} [OPTION]... <VERSION|latest>
Checks for local VERSION (or latest version) of the minecraft server .jar
Checks for latest version by default.
Example: ${_progName} --install
 - Checks for latest version & installs it if not already installed

OPTIONS:
"
	printf '%s\t%s\n' " -c, --check" "Checks versions only"
	printf '%s\t%s\n' " -d, --download" "Check & Download only"
	printf '%s\t%s\n' " -i, --install" "Check, Download, Install"
	printf '\t%s\n' "REQUIRES YOU TO HAVE MODIFIED THE SCRIPT TO ENABLE INSTALL"
	printf '%s\t%s\n' " -h, --help" "Display this helpful message"
}



################################################################################
# MAIN

########################################
# Argument handling
#  Simply, set vars named for actions to true or false
#  Enables or disables the actions later on.
checkF="true"; downloadF="false"; installF="false"; targetV="latest"
for i in "$@"; do
	case "$i" in
		-c | --check)
			# Don't need to do anything, check by default
		;;
		-d | --download)
			downloadF="true"
		;;
		-i | --install)
			installF="true"
		;;
		-h | --help)
			_mcUpdaterUsage
			exit 0
		;;
		*)
			targetV="${i,,}"	# Force lower case

			# Exit if target isn't a version number or "latest"
			if [[ ! "$targetV" =~ [0-9]+\.[0-9]+\.[0-9]+ ]] \
			   && [[ ! "$targetV" =~ [0-9]+\.[0-9]+ ]] \
			   && [[ ! "$targetV" == "latest" ]]
			then
				_error "Invalid argument: $targetV"
				_mcUpdaterUsage
				exit 1
			fi
		;;
	esac
done

########################################
# Let's get to work then, shall we?

# Get Mojang's version manifest, will be used more than once.
wget -qO "${manifestFile}" \
  "https://launchermeta.mojang.com/mc/game/version_manifest.json" \
  || _errExit ${LINENO} "Failed to download version_manifest.json" 1


# CHECK if the target version is available locally
# Currently, check will always be true, but maybe not in future.
if $checkF; then
	CheckForTargetV
	checkRet=$?
fi

# DOWNLOAD a copy of the local file if Check didn't find it.
if $downloadF || $installF; then
	DownloadTargetV
	downloadRet=$? # If this ever manages to be non-zero, WTF?
	if [ $downloadRet -ne 0 ]; then
		_errExit ${LINENO} "Download jar function returned non-zero. WTF?" 255
	fi
fi

if $installF; then
	# Then it's time to call the custom install process function.
	# This is setup by each and every user of this script.
	# So don't ask me what it does, cause it does whatever YOU told it to.
	CustomInstallProcess
	installRet=$?
	if [ $installRet -ne 0 ]; then
		_errExit ${LINENO} "Your custom install process is borked." 2
	fi
fi
