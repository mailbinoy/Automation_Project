#!/bin/bash
#vars
myname="Binoy"
s3_bucket="upgrad-binoy"

timestamp=$(date '+%d%m%Y-%H%M%S')
log_type="httpd-logs"
file_type="tar"
html_tab="&emsp;"
inventory_file="/var/www/html/inventory.html"

task2() {
    #1. Perform an update of the package details and the package list at the start of the script.
    /usr/bin/apt update -y

    #2. Install the apache2 package if it is not already installed. (The dpkg and apt commands are used to check the installation of the packages.)
    if ! dpkg -s apache2 >/dev/null 2>&1; then
        echo "apache2 not installed...Installing apache2..."
        /usr/bin/apt -y install apache2 >/dev/null 2>&1
    else
        echo "apache2 already installed"
    fi

    #unmask service (repeated install and uninstall causes the service to mask)
    systemctl unmask apache2 > /dev/null 2>&1
    #3. Ensure that the apache2 service is running. 
    if [ $(systemctl is-active apache2 ) == "inactive" ]; then
        systemctl start apache2
    fi

    #4. Ensure that the apache2 service is enabled. 
    if [ $(systemctl is-enabled apache2 ) == "disabled" ]; then
        systemctl enable apache2
    fi
    #Generate some logs
    for i in {1..10}; do
        curl -s http://localhost/  > /dev/null
        curl -s http://localhost/notfound  > /dev/null
    done


    #5. Create a tar archive of apache2 access logs and error logs that are present in the /var/log/apache2/ directory and place the tar into the /tmp/ directory.
    tar cf /tmp/${myname}-httpd-logs-${timestamp}.tar /var/log/apache2/*.log

    #6. The script should run the AWS CLI command and copy the archive to the s3 bucket. 
        # install aws cli if not exists
    if ! dpkg -s awscli >/dev/null 2>&1; then
        /usr/bin/apt -y install awscli
    fi
    #upload
    /usr/bin/aws s3 cp /tmp/${myname}-httpd-logs-${timestamp}.tar s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar
    
}

task3_part1 () {
    if [ -f ${inventory_file} ]; then
        file_size=$(ls -lh /tmp/${myname}-httpd-logs-${timestamp}.tar | awk '{print $5}')
        echo "<h2>${log_type}${html_tab}${html_tab}${timestamp}${html_tab}${html_tab}${file_type}${html_tab}${html_tab}${file_size}</h2>" >> ${inventory_file}
    else
        echo "<h1>Log Type&emsp;Time Created&emsp;Type&emsp;Size</h1>" > ${inventory_file}
    fi
}

task3_part2 () {
    cron_path="/etc/cron.d/automation"
    if [ ! -f ${cron_path} ]; then
        echo "00 01 * * * root /root/Automation_Project/automation.sh" > ${cron_path}
    fi
    #ensure cron is running
    if [ $(systemctl is-active cron ) == "inactive" ]; then
        systemctl start cron
    fi
}


task2
task3_part1
task3_part2
exit 0
