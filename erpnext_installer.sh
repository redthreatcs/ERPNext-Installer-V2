#!/bin/bash
bold=$(tput bold)
normal=$(tput sgr0)

RED='\033[0;31m'
NC='\033[0m'

accept="Y"
multi_tenancy=false

is_arm=false

function validate_user() {
    egrep "^$1" /etc/passwd >/dev/null
    if [ $? -eq 0 ]; then
        echo "$1 exists! Please use a different user name"
        return 1
    else
        return 0
    fi
}

function deps_installation() {
    # First install python, pip and redis
    sudo apt install git python3-dev python3-pip redis-server -y

    # Install mariadb server and client
    sudo apt-get install mariadb-server -y
    sudo apt-get install mariadb-client -y

    # Install nvm and then node 14
    if [ "$is_arm" = true ]; then
        sudo -u $1 bash -c "cd /home/${1} && wget https://nodejs.org/download/release/v14.21.3/node-v14.21.3-linux-arm64.tar.xz && tar -xf node-v14.21.3-linux-arm64.tar.xz && sudo cp -r node-v14.21.3-linux-arm64/* /usr/local/"
    else
        sudo -u $1 bash -c "cd /home/${1} && wget https://nodejs.org/download/release/v14.21.3/node-v14.21.3-linux-x64.tar.xz && tar -xf node-v14.21.3-linux-x64.tar.xz && sudo cp -r node-v14.21.3-linux-x64/* /usr/local/"
    fi
    sudo -u $1 bash -c "sudo npm install -g yarn"

    # Install wkhtmltopdf
    sudo apt-get install xvfb libfontconfig wkhtmltopdf -y

    #Install python virtualenv
    sudo apt install python3.10-venv -y
}

function mariadb_config() {
    # Configure my.cnf
    echo -e "[mysqld]\ncharacter-set-client-handshake = FALSE\ncharacter-set-server = utf8mb4\ncollation-server = utf8mb4_unicode_ci\n\n[mysql]\ndefault-character-set = utf8mb4" | sudo tee -a /etc/mysql/my.cnf

    # Restart the mysql server
    sudo service mysql restart
}

function frappe_installation() {
    echo "Installing Bench"
    # Install Frappe bench
    sudo -u $1 bash -c "sudo pip3 install frappe-bench"
    
    python_version=$(python3 --version | cut -d " " -f 2)
    # Edit bench util file so it can start supervisor with sudo
    sudo sed -i 's/{sudo}supervisorctl restart {group}/sudo supervisorctl restart all/g' /usr/local/lib/python3.10/dist-packages/bench/utils/bench.py
    
    echo "Initializing bench"
    # Initialize a bench with a given erpnext version
    sudo -u $1 bash -c "cd /home/${1}; bench init --frappe-branch=${2} ${3}"
    
    # Check if bench is installed properly
    # common_site_file="/home/${1}/${3}/sites/common_site_config.json"
    # if [ -e "$common_site_file" ]; then
    # 	echo "Bench installation successful"
    # else
    # 	echo "Bench not installed properly"
    # 	exit 1
    # fi
}

function erpnext_install() {
    # create the site
    sudo -u $1 bash -c "cd /home/${1}/${6} && bench new-site ${2} --db-root-password ${3} --admin-password ${4}"
    
    # Check if the site is created properly
    # site_file="/home/${1}/${6}/sites/${2}/site_config.json"
    # if [ -e "$site_file" ]; then
    # 	echo "Site installation successful"
    # else
    # 	echo "Site not installed properly"
    # 	exit 1
    # fi
    
    if [ "$7" = false ]; then
        echo "Get the apps"
        # get bench payment app
        sudo -u $1 bash -c "cd /home/${1}/${6} && bench get-app payments; bench get-app --branch ${5} erpnext; bench --site ${2} install-app erpnext"
    else
        sudo -u $1 bash -c "cd /home/${1}/${6} && bench --site ${2} install-app erpnext"
    fi
    # get the erpnext app
    # bench get-app --branch $5 erpnext
    
    # echo "Installing the apps on Site"
    # Install erpnext
    # bench --site $2 install-app erpnext
}

cat << "EOF"
-------------------------------------------------------------------------
/    _____ ______ ______  _   _              _                          \
/   |  ___|| ___ \| ___ \| \ | |            | |                         \
/   | |__  | |_/ /| |_/ /|  \| |  ___ __  __| |_                        \
/   |  __| |    / |  __/ | . ` | / _ \\ \/ /| __|                       \
/   | |___ | |\ \ | |    | |\  ||  __/ >  < | |_                        \
/   \____/ \_| \_|\_|    \_| \_/ \___|/_/\_\ \__|                       \
/                                                                       \
/                                                                       \
/    _____             _          _  _         _    _                   \
/   |_   _|           | |        | || |       | |  (_)                  \
/     | |  _ __   ___ | |_  __ _ | || |  __ _ | |_  _   ___   _ __      \
/     | | | '_ \ / __|| __|/ _` || || | / _` || __|| | / _ \ | '_ \     \
/    _| |_| | | |\__ \| |_| (_| || || || (_| || |_ | || (_) || | | |    \
/    \___/|_| |_||___/ \__|\__,_||_||_| \__,_| \__||_| \___/ |_| |_|    \
/                                                                       \
/                                                                       \
-------------------------------------------------------------------------
EOF

cat << "EOF"
 _____        _                 
/  ___|      | |                
\ `--.   ___ | |_  _   _  _ __  
 `--. \ / _ \| __|| | | || '_ \ 
/\__/ /|  __/| |_ | |_| || |_) |
\____/  \___| \__| \__,_|| .__/ 
                         | |    
                         |_|    
EOF

while :
do
    read -p $'Enter username [default: erpnext]: \n' username
    if [ -z "$username" ]; then
        username="erpnext"
        validate_user $username
        [ $? -eq 0 ] && break || continue
    else
        validate_user $username
        [ $? -eq 0 ] && break || continue
    fi
done

while :
do
    read -s -p $'Enter password\n' password
    [ -z "$password" ] && continue || break
done

while :
do
    echo -e "${bold}${RED}Warning! Please use the same mysql root password given here when securing MariaDB${NC}"
    read -s -p $'Enter mysql root password: \n' mysql_root_password
    [ -z "$mysql_root_password" ] && continue || break
done

read -p $'Please enter the version [default: version-14]: \n' version
if [ -z "$version" ]; then
    version="version-14"
fi

read -p $'Please enter the bench name [default: frappe-bench]: \n' bench_name
if [ -z "$bench_name" ]; then
    bench_name="frappe-bench"
fi

while :
do
    read -p $'Please enter the site name: \n' sitename
    [ -z "$sitename" ] && continue || break
done

while :
do
    read -s -p $'Please enter the ERPNext admin password: \n' adminpassword
    [ -z "$adminpassword" ] && continue || break
done

while :
do
    read -p $'Please select x86 or ARM64. For x86 type "x86" ARM64 type "arm64": \n' arch
    if [[ "${arch,,}" == "x86" ]]; then
        is_arm=false
        break
    elif [[ "${arch,,}" == "arm64" ]]; then
        is_arm=true
        break
    else
        echo -e "${RED} Unknown Architecture${NC}"
    fi
done

echo
echo "Server Username: " $username
echo "Server Password: " $password
echo "MySQL Password: " $mysql_root_password
echo "Frappe Version: " $version
echo "Bench name: " $bench_name
echo "Site name: " $sitename
echo "ERPNext Admin Password: " $adminpassword
echo "Selected CPU Architecture: " $arch
echo
echo $'Please verify the inputs. You can change them if you wish\n'

while :
do
    echo "------------------------------------------"
    echo 'a: change server username'
    echo 'b: change server user password'
    echo 'c: change mysql root password'
    echo 'd: change Frappe version'
    echo 'e: change bench name'
    echo 'f: change the site name'
    echo 'g: change ERPNext admin password'
    echo 'h: change CPU Architecture'
    echo 'i: exit menu'
    echo "------------------------------------------"

    read -p $'Press a-i to change the input or press "i" exit changing: ' new_input

    invalid_option=true

    case $new_input in
        a)
            while :
            do
                read -p $'Enter username [default: erpnext]: \n' username
                if [ -z "$username" ]; then
                    username="erpnext"
                    validate_user $username
                    [ $? -eq 0 ] && break || continue
                else
                    validate_user $username
                    [ $? -eq 0 ] && break || continue
                fi
            done
            ;;
        b)
            while :
            do
                read -s -p $'Enter password\n' password
                [ -z "$password" ] && continue || break
            done
            ;;
        c)
            while :
            do
                echo -e "${bold}${RED}Warning! Please use the same mysql root password given here when securing MariaDB${NC}"
                read -s -p $'Enter mysql root password: \n' mysql_root_password
                [ -z "$mysql_root_password" ] && continue || break
            done
            ;;
        d)
            read -p $'Please enter the version [default: version-14]: \n' version
            if [ -z "$version" ]; then
                version="version-14"
            fi
            ;;
        e)
            read -p $'Please enter the bench name [default: frappe-bench]: \n' bench_name
            if [ -z "$bench_name" ]; then
                bench_name="frappe-bench"
            fi
            ;;
        f)
            while :
            do
                read -p $'Please enter the site name: \n' sitename
                [ -z "$sitename" ] && continue || break
            done
            ;;
        g)
            while :
            do
                read -s -p $'Please enter the ERPNext admin password: \n' adminpassword
                [ -z "$adminpassword" ] && continue || break
            done
            ;;
        h)
            while :
            do
                read -p $'Please select x86 or ARM64. For x86 type "x86" ARM64 type "arm64": \n' arch
                if [[ "${arch,,}" == "x86" ]]; then
                    is_arm=false
                    break
                elif [[ "${arch,,}" == "arm64" ]]; then
                    is_arm=true
                    break
                else
                    echo -e "${RED} Unknown Architecture${NC}"
                fi
            done
            ;;
        i)
            invalid_option=false
            ;;
        *)
            echo "Wrong input, please input a valid option"
            invalid_option=true
            ;;
    esac
    if [ "$invalid_option" = true ]; then
        continue
    else
        echo "Press ${bold}Y${normal} to confirm or press any key to change a value"
        read -p $'Please enter your choice: ' confirmation
        if [[ "${confirmation,,}" == "${accept,,}" ]]; then
            break
        fi
    fi
done

echo "New inputs are as follows, please validate your inputs"
echo
echo "Server Username: " $username
echo "Server Password: " $password
echo "MySQL Password: " $mysql_root_password
echo "Frappe Version: " $version
echo "Bench name: " $bench_name
echo "Site name: " $sitename
echo "ERPNext Admin Password: " $adminpassword
echo "Selected CPU Architecture: " $arch
echo
echo -e "${bold}Please verify the inputs. ${RED}You can not change the inputs at this stage${normal}${NC}"
echo

echo "Are you sure you want to proceed with the installation? Press ${bold}Y${normal} to proceed or press ${bold}any key${normal} to cancel the installation"
read -p "${normal}Please enter your choice: " confirmation
if [[ "${confirmation,,}" != "${accept,,}" ]]; then
    echo "Cancelling installation!!"
    exit 1
fi

cat << "EOF"
-------------------------------------------------------------------
/  _____             _          _  _         _    _                \
/ |_   _|           | |        | || |       | |  (_)               \
/   | |  _ __   ___ | |_  __ _ | || |  __ _ | |_  _   ___   _ __   \
/   | | | '_ \ / __|| __|/ _` || || | / _` || __|| | / _ \ | '_ \  \
/  _| |_| | | |\__ \| |_| (_| || || || (_| || |_ | || (_) || | | | \
/  \___/|_| |_||___/ \__|\__,_||_||_| \__,_| \__||_| \___/ |_| |_| \
/                                                                  \                                                               
-------------------------------------------------------------------
EOF

cat << "EOF"
-----------------------------------------------------------
|   _____                 __         __  __             
|  / ___/____ ___  ___ _ / /_ ___   / / / /___ ___  ____
| / /__ / __// -_)/ _ `// __// -_) / /_/ /(_-</ -_)/ __/
| \___//_/   \__/ \_,_/ \__/ \__/  \____//___/\__//_/   
|                                                       
-----------------------------------------------------------
EOF

sudo apt-get update && sudo apt-get upgrade -y
pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
sudo useradd -m -s /bin/bash -p "$pass" "$username"
[ $? -eq 0 ] && echo "User has been added to the system" || "Failed to add the user"
sudo usermod -aG sudo $username
echo "${username} ALL=(ALL) NOPASSWD:ALL" | sudo EDITOR="tee -a" visudo

cat << "EOF"
-----------------------------------------------------------------
|    ____           __         __ __                          
|   /  _/___   ___ / /_ ___ _ / // /                          
|  _/ / / _ \ (_-</ __// _ `// // /                           
| /___//_//_//___/\__/ \_,_//_//_/__                _         
|   / _ \ ___  ___  ___  ___  ___/ /___  ___  ____ (_)___  ___
|  / // // -_)/ _ \/ -_)/ _ \/ _  // -_)/ _ \/ __// // -_)(_-<
| /____/ \__// .__/\__//_//_/\_,_/ \__//_//_/\__//_/ \__//___/
|           /_/                                               
-----------------------------------------------------------------
EOF

deps_installation $username

cat << "EOF"
------------------------------------------------------------------------
|    __  ___            _        ___   ___                           
|   /  |/  /___ _ ____ (_)___ _ / _ \ / _ )                          
|  / /|_/ // _ `// __// // _ `// // // _  |                          
| /_/__/_/ \_,_//_/  /_/_\_,_//____//____/          __   _           
|  / ___/___   ___   / _/(_)___ _ __ __ ____ ___ _ / /_ (_)___   ___ 
| / /__ / _ \ / _ \ / _// // _ `// // // __// _ `// __// // _ \ / _ \
| \___/ \___//_//_//_/ /_/ \_, / \_,_//_/   \_,_/ \__//_/ \___//_//_/
|                         /___/                                      
------------------------------------------------------------------------
EOF

mariadb_config $username $mysql_root_password

# Secure MariaDB
#sudo mysql_secure_installation <<EOF
#
#y
#$mysql_root_password
#$mysql_root_password
#y
#y
#y
#y
#EOF

echo -e "${bold}${RED}Warning! Please use the same mysql root password entered at the beginning${NC}"
sudo mysql_secure_installation

cat << "EOF"
---------------------------------------------------------
|    ____           __         __ __ _           
|   /  _/___   ___ / /_ ___ _ / // /(_)___  ___ _
|  _/ / / _ \ (_-</ __// _ `// // // // _ \/ _ `/
| /___//_//_//___/\__/ \_,_//_//_//_//_//_/\_, / 
|   / __/____ ___ _ ___   ___  ___        /___/  
|  / _/ / __// _ `// _ \ / _ \/ -_)              
| /_/  /_/   \_,_// .__// .__/\__/               
|                /_/   /_/                       
---------------------------------------------------------
EOF

# https://discuss.frappe.io/t/please-make-sure-that-redis-queue-runs-redis-localhost-11000/105542/4
# Check for ARM64

if [ "${is_arm}" = true ]; then
    echo "port 11000" | sudo tee -a /etc/redis/redis.conf
    sudo systemctl restart redis-server
fi
frappe_installation $username $version $bench_name

cat << "EOF"
-----------------------------------------------------
|    ____           __         __ __ _           
|   /  _/___   ___ / /_ ___ _ / // /(_)___  ___ _
|  _/ / / _ \ (_-</ __// _ `// // // // _ \/ _ `/
| /___//_//_//___/\__/ \_,_//_//_//_//_//_/\_, / 
|    ____ ___   ___   _  __           __  /___/  
|   / __// _ \ / _ \ / |/ /___ __ __ / /_        
|  / _/ / , _// ___//    // -_)\ \ // __/        
| /___//_/|_|/_/   /_/|_/ \__//_\_\ \__/         
|                                                
-----------------------------------------------------
EOF

erpnext_install $username $sitename $mysql_root_password $adminpassword $version $bench_name $multi_tenancy

if [ "${is_arm}" = true ]; then
    sudo sed -i 's/port 11000//g' /etc/redis/redis.conf
    sudo systemctl restart redis-server
fi

#
# Set for production
cat << "EOF"
------------------------------------------------------------
|    ____      __   __   _              __  __         
|   / __/___  / /_ / /_ (_)___  ___ _  / / / /___      
|  _\ \ / -_)/ __// __// // _ \/ _ `/ / /_/ // _ \     
| /___/ \__/ \__/ \__//_//_//_/\_, /  \____// .__/     
|    ___                __    /___/   __   /_/         
|   / _ \ ____ ___  ___/ /__ __ ____ / /_ (_)___   ___ 
|  / ___// __// _ \/ _  // // // __// __// // _ \ / _ \
| /_/   /_/   \___/\_,_/ \_,_/ \__/ \__//_/ \___//_//_/
|                                                      
------------------------------------------------------------
EOF

sudo -u $username chmod 701 /home/$username
sudo -u $username bash -c "cd /home/${username}/${bench_name}; sudo bench setup production ${username}"

sudo -u $username bash -c "tmux new -d -s erpnext_session"
sudo -u $username bash -c "tmux send-keys -t erpnext_session.0 'cd /home/${username}/${bench_name}; bench start' ENTER"

sleep 20

sudo -u $username bash -c "cd /home/${username}/${bench_name}; sudo bench setup production ${username} <<EOF
y
y
EOF"

sudo -u $username bash -c "tmux send-keys -t erpnext_session C-c"
sudo -u $username bash -c "tmux kill-session -t erpnext_session"

cat << "EOF"
--------------------------------------------------
|    ____ ____ __     ____      __            
|   / __// __// /    / __/___  / /_ __ __ ___ 
|  _\ \ _\ \ / /__  _\ \ / -_)/ __// // // _ \
| /___//___//____/ /___/ \__/ \__/ \_,_// .__/
|                                      /_/    
--------------------------------------------------
EOF

# install snapd if not available
if ! command -v snapd > /dev/null 2>&1; then
    echo "snapd not found, installing..."
    sudo apt-get update && sudo apt-get install -y snapd
else
    echo "snapd found, no need to install."
fi

# Install certbot
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

# Generate certificate
sudo certbot --nginx #<<EOF
#$mail_address
#y
#y
#
#EOF

cat << "EOF"
------------------------------------------------------------------------
|    __  ___       __ __   _   ______                                  
|   /  |/  /__ __ / // /_ (_) /_  __/___  ___  ___ _ ___  ____ __ __   
|  / /|_/ // // // // __// /   / /  / -_)/ _ \/ _ `// _ \/ __// // /   
| /_/__/_/ \_,_//_/ \__//_/   /_/   \__//_//_/\_,_//_//_/\__/ \_, /    
|   / __/___  / /_ __ __ ___                                 /___/     
|  _\ \ / -_)/ __// // // _ \                                          
| /___/ \__/ \__/ \_,_// .__/                                          
|                     /_/                                              
------------------------------------------------------------------------
EOF

read -p "Do you want to setup Multi Tenancy? Press ${bold} Y ${normal} to continue or Press ${bold} any key ${normal}to finish installation: " choice
if [[ "${choice,,}" == "${accept,,}" ]]; then
    multi_tenancy=true

    while :
    do
        while :
        do
            read -p $'Please enter the site name: \n' new_sitename
            [ -z "$new_sitename" ] && continue || break
        done

        while :
        do
            read -s -p $'Please enter the ERPNext admin password: \n' new_adminpassword
            [ -z "$new_adminpassword" ] && continue || break
        done

        # if [ "${is_arm}" = true ]; then
        #     echo "port 11000" | sudo tee -a /etc/redis/redis.conf
        #     sudo systemctl restart redis-server
        # fi

        sudo -u $username bash -c "cd /home/${username}/${bench_name} && bench config dns_multitenant on"
        erpnext_install $username $new_sitename $mysql_root_password $new_adminpassword $version $bench_name $multi_tenancy

        # if [ "${is_arm}" = true ]; then
        #     sudo sed -i 's/port 11000//g' /etc/redis/redis.conf
        #     sudo systemctl restart redis-server
        # fi    

        echo "Do you want to add more sites?"
        read -p "Please enter ${bold}Y${normal} to add more site or ${bold}any key${normal} to continue: " is_more_sites

        if [[ "${is_more_sites,,}" == "${accept,,}" ]]; then
            continue
        else
            break
        fi
    done

    sudo -u $username bash -c "cd /home/${username}/${bench_name} && bench setup nginx"
    sudo systemctl reload nginx
    sudo certbot --nginx

    echo
    echo "${bold}Installation Finished! Enjoy...${normal}"
    echo

else
    echo
    echo "${bold}Installation Finished! Enjoy...${normal}"
    echo
fi

# Revert the privileges
sudo sed -i "s/${username} ALL=(ALL) NOPASSWD:ALL//g" /etc/sudoers
# echo "${username} ALL=(ALL:ALL) ALL" | sudo EDITOR="tee -a" visudo