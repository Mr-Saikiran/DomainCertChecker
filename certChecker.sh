#!/bin/bash
#
# Description   :Script to check SSL certificate expiration date of a list of sites. Recommended to use with a dark terminal theme to
#                see the colors correctly. The terminal also needs to support 256 colors.
# Dependencies  :openssl, mutt (if you use the mail option)
# License       :GPLv3
#

#
# VARIABLES
#

sites_list="$1"
site=""
html_file="certs_check.html"
img_file="certs_check.jpg"
current_date=$(date +%s)
end_date=""
days_left=""
certificate_last_day=""
warning_days="100"
alert_days="50"
# Terminal colors
ok_color="\e[38;5;40m"
warning_color="\e[38;5;220m"
alert_color="\e[38;5;208m"
expired_color="\e[38;5;196m"
decom_color="\e[38;5;104m"
end_of_color="\033[0m"

#
# FUNCTIONS
#

html_mode(){
	# Generate and reset file
	cat <<- EOF > $html_file
	<!DOCTYPE html>
	<html>
			<head>
			<title>Certificate expiration details</title>
			</head>
			<body style="background-color: white;">
					<h1 style="color: navy;text-align: center;font-family: 'Helvetica Neue', sans-serif;font-size: 20px;font-weight: bold;">SSL Certs expiration checker</h1>
					<table style="background-color: #C5E1E7;padding: 10px;box-shadow: 5px 10px 18px #888888;margin-left: auto ;margin-right: auto ;border: 1px solid black;">
					<tr style="padding: 8px;text-align: left;font-family: 'Helvetica Neue', sans-serif;">
					<th style="padding: 8px;text-align: left;font-family: 'Helvetica Neue', sans-serif;font-weight: bold;">Site</th>
					<th style="padding: 8px;text-align: left;font-family: 'Helvetica Neue', sans-serif;font-weight: bold;">Expiration date</th>
					<th style="padding: 8px;text-align: left;font-family: 'Helvetica Neue', sans-serif;font-weight: bold;">Days left</th>
					<th style="padding: 8px;text-align: left;font-family: 'Helvetica Neue', sans-serif;font-weight: bold;">Status</th>
					</tr>
	EOF

	while read site;do
		certificate_last_day=$(echo | openssl s_client -servername ${site} -connect ${site}:443 2>/dev/null | \
		openssl x509 -noout -enddate 2>/dev/null | cut -d "=" -f2)
		end_date=$(date +%s -d "$certificate_last_day")
		days_left=$(((end_date - current_date) / 86400))

		if [ "$days_left" -gt "$warning_days" ];then
			echo "<tr style=\"padding: 8px;text-align: left;font-family: 'Helvetica Neue', sans-serif;\">" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #33FF4F;\">${site}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #33FF4F;font-size: 12px\">${certificate_last_day}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #33FF4F;\">${days_left}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #33FF4F;\">Valid</td>" >> $html_file
			echo "</tr>" >> $html_file

		elif [ "$days_left" -le "$warning_days" ] && [ "$days_left" -gt "$alert_days" ];then
			echo "<tr style=\"padding: 8px;text-align: left;font-family: 'Helvetica Neue', sans-serif;\">" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #FFE032;\">${site}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #FFE032;font-size: 12px\">${certificate_last_day}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #FFE032;\">${days_left}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #FFE032;\">Warning</td>" >> $html_file
			echo "</tr>" >> $html_file

		elif [ "$days_left" -le "$alert_days" ] && [ "$days_left" -gt 0 ];then
			echo "<tr style=\"padding: 8px;text-align: left;font-family: 'Helvetica Neue', sans-serif;\">" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #FF8F32;\">${site}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #FF8F32;font-size: 12px\">${certificate_last_day}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #FF8F32;\">${days_left}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #FF8F32;\">Alert</td>" >> $html_file
			echo "</tr>" >> $html_file

		elif [ "$days_left" -lt 0 ];then
			echo "<tr style=\"padding: 8px;text-align: left;font-family: 'Helvetica Neue', sans-serif;\">" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #ff1a1a;\">${site}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #ff1a1a;font-size: 12px\">${certificate_last_day}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #ff1a1a;\">${days_left}</td>" >> $html_file
			echo "<td style=\"padding: 8px;background-color: #ff1a1a;\">Expired</td>" >> $html_file
			echo "</tr>" >> $html_file
                elif [ "$days_left" -eq 0 ];then
                        echo "<tr style=\"padding: 8px;text-align: left;font-family: 'Helvetica Neue', sans-serif;\">" >> $html_file
                        echo "<td style=\"padding: 8px;background-color: #00ffff;\">${site}</td>" >> $html_file
                        echo "<td style=\"padding: 8px;background-color: #00ffff;font-size: 12px\">${certificate_last_day}</td>" >> $html_file
                        echo "<td style=\"padding: 8px;background-color: #00ffff;\">${days_left}</td>" >> $html_file
                        echo "<td style=\"padding: 8px;background-color: #00ffff;\">Non-existent</td>" >> $html_file
                        echo "</tr>" >> $html_file

		fi
	done < ${sites_list}

	# Close main HTML tags
	cat <<- EOF >> $html_file
			</table>
<p><b>STATUS LEGEND</p></b>
 <p><span style="background-color: #ff1a1a;">Expired</span> - Certificate is already expired<br>
 <span style="background-color: #FF8F32;">Alert</span>   - The certificate will expire in less than 50 days<br>
 <span style="background-color: #FFE032;">Warning</span> - The certificate will expire in less than 100 days<br>
 <span style="background-color: #33FF4F;">Valid</span> - More than 100 days left until the certificate expires<br>
 <span style="background-color: #00ffff;">Non-existent</span> - Website is unreachable or Down/Decommissioned</p>
<b><p><span style="color: #02bd3d;">Saikiran M</span></b></br>
Middleware Services</p>
			</body>
	</html>
	EOF
}

terminal_mode(){
	printf "\n| %-30s | %-30s | %-10s | %-5s %s\n" "SITE" "EXPIRATION DAY" "DAYS LEFT" "STATUS"

	while read site;do
		certificate_last_day=$(echo | openssl s_client -servername ${site} -connect ${site}:443 2>/dev/null | \
		openssl x509 -noout -enddate 2>/dev/null | cut -d "=" -f2)
		end_date=$(date +%s -d "$certificate_last_day")
		days_left=$(((end_date - current_date) / 86400))

		if [ "$days_left" -gt "$warning_days" ];then
			printf "${ok_color}| %-30s | %-30s | %-10s | %-5s %s\n${end_of_color}" \
			"$site" "$certificate_last_day" "$days_left" "Ok"

		elif [ "$days_left" -le "$warning_days" ] && [ "$days_left" -gt "$alert_days" ];then
			printf "${warning_color}| %-30s | %-30s | %-10s | %-5s %s\n${end_of_color}" \
			"$site" "$certificate_last_day" "$days_left" "Warning"

		elif [ "$days_left" -le "$alert_days" ] && [ "$days_left" -gt 0 ];then
			printf "${alert_color}| %-30s | %-30s | %-10s | %-5s %s\n${end_of_color}" \
			"$site" "$certificate_last_day" "$days_left" "Alert"

		elif [ "$days_left" -lt 0 ];then
			printf "${expired_color}| %-30s | %-30s | %-10s | %-5s %s\n${end_of_color}" \
			"$site" "$certificate_last_day" "$days_left" "Expired"

                elif [ "$days_left" -eq 0 ];then
                        printf "${decom_color}| %-30s | %-30s | %-10s | %-5s %s\n${end_of_color}" \
                        "$site" "$certificate_last_day" "$days_left" "Non-existent"
		fi

	done < $sites_list

	printf "\n %-10s" "STATUS LEGEND"
	printf "\n ${ok_color}%-8s${end_of_color} %-30s" "Ok" "- More than ${warning_days} days left until the certificate expires"
	printf "\n ${warning_color}%-8s${end_of_color} %-30s" "Warning" "- The certificate will expire in less than ${warning_days} days"
	printf "\n ${alert_color}%-8s${end_of_color} %-30s" "Alert" "- The certificate will expire in less than ${alert_days} days"
	printf "\n ${expired_color}%-8s${end_of_color} %-30s" "Expired" "- Certificate is already expired"
        printf "\n ${decom_color}%-8s${end_of_color} %-30s\n\n" "Non-existent" "- Website/DNS is unreachable or Down"
}

howtouse(){
	cat <<-'EOF'

	You must always specify -f option with the name of the file that contains the list of sites to check
	Options:
		-f [ sitelist file ]          list of sites (domains) to check
		-o [ html | terminal ]        output (can be html or terminal)
		-m [ mail ]                   mail address to send the graphs to
		-h                            help
	
	Examples:

		# Launch the script in terminal mode:
		./certChecker.sh -f sitelist -o terminal

		# Using HTML mode:
		./certChecker.sh -f sitelist -o html

		# Using HTML mode and sending results via email
		./certChecker.sh -f sitelist -o html -m mail@example.com

	EOF
}

# 
# MAIN
# 

if [ "$#" -eq 0 ];then
	howtouse

elif [ "$#" -ne 0 ];then
	while getopts ":f:o:m:s:h" opt; do
		case $opt in
			"f")
				sites_list="$OPTARG"
				;;
			"o")
				output="$OPTARG"
				if [ "$output" == "terminal" ];then
					terminal_mode
				elif [ "$output" == "html" ];then
					html_mode
				else
					echo "Wrong output selected"
					howtouse
				fi
				;;
			"m")
				if [ "$output" == "html" ];then
					mail_to="$OPTARG"
				else
					echo "Mail option is only used with HTML mode"
				fi
				;;
			\?)
				echo "Invalid option: -$OPTARG" >&2
				howtouse
				exit 1
				;;
			:)
				echo "Option -$OPTARG requires an argument." >&2
				howtouse
				exit 1
				;;
			"h" | *)
				howtouse
				exit 1
				;;
		esac
	done

	# Send mail if specified
	if [[ $mail_to ]];then
		mutt -e 'set content_type="text/html"' $mail_to -s "SSL certs expiration check" < $html_file
	fi

fi
