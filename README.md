# ERPNext-Installer-V2
A bash script to install and setup ERPNext

This installer can set up ERPNext with SSL certificate and Multi tenancy. The installer is architecture specific and please select the architecture at the initial stage.

Attention: 
When you see Type “Y” in the documentation, you should type Y without “”.
When you see Press “ENTER” in the documentation, you should press ENTER on the keyboard.
If you are installing from a user other than the root user, the installer may ask for the sudo password for that user. So make sure the user has sudo privileges and give the password when asked.

Installation steps:
SSH into the server and copy the “erpnext_installer” binary file
Make sure the binary file is executable: Run “chmod +x erpnext_installer.sh” from the folder where you have placed the installer.
Run the binary file by typing “./erpnext_installer.sh”
Now this will prompt the initial setup interface. For some parameters, there are default values and “[default: xxxx]” will be shown if the parameter has a default value.
Enter username [default: erpnext]: type the username or leave empty to select default -> press “ENTER”
Enter password: Enter the password for the user -> press “ENTER”
Enter mysql root password: Enter the mysql root password you prefer -> press “ENTER”. YOU HAVE TO GIVE THE SAME MYSQL ROOT PASSWORD IN A LATER STAGE
Please enter the version [default: version-14]: Enter the ERPNext version according to the ERPNext branch name (version-14, version-13 etc) or leave blank to select version 14 ->  press “ENTER”
Please enter the bench name [default: frappe-bench]: Type the preferred frappe installation folder name or leave blank to select the default ->  press “ENTER”
Please enter the site name: Type the site name -> press “ENTER”
Please enter the ERPNext admin password: Type the Administrator password for the site -> press “ENTER”
Please select x86 or ARM64. For x86 type "x86" ARM64 type "arm64": Type x86 to choose x86 architecture or type arm64 to choose ARM64 architecture -> press “ENTER”
Now the inputs will be printed out for you to verify. NOTE! PASSWORDS ARE ALSO PRINTED OUT. If you wish to change anything, press “a” or “b” or “c” or “d” or “e” or “f” or “g” or “h” to make the changes. Once you are done with the changes press “i” to save and exit the changes
Please enter your choice: Type “Y” to continue the installation or type any key to return to changing values -> Press “ENTER”
Now validate the changes
Please enter your choice:  Type “Y” to continue the installation or type any key to exit the installer -> Press “ENTER”
Now the installation will start. At any point of the installation if you see popups, Simply press “ENTER” to continue the installation. It's nothing important. Please note these popups may appear multiple times during the installation.
Now you will be prompted to secure the MariaDB database. Here follow the following steps:
Enter current password for root (enter for none): -> Press “ENTER”
Switch to unix_socket authentication [Y/n]: Type “Y” -> Press “ENTER”
Change the root password? [Y/n]: Type “Y” -> Press “ENTER”
New password: Type the same mysql root password provided at the beginning -> Press “ENTER”
Re-enter new password: Type the same mysql root password provided at the beginning -> Press “ENTER”
Remove anonymous users? [Y/n]: Type “Y” -> Press “ENTER”
Disallow root login remotely? [Y/n]: Type “Y” -> Press “ENTER”
Remove test database and access to it? [Y/n]: Type “Y” -> Press “ENTER”
Reload privilege tables now? [Y/n]: Type “Y” -> Press “ENTER”
To setup the SSL certificates, follow the following steps:
Enter email address (used for urgent renewal and security notices): Type your email address -> Press “ENTER”
(Y)es/(N)o: Type “Y” -> Press “ENTER”
(Y)es/(N)o: Type “n” -> Press “ENTER”
Select the appropriate numbers separated by commas and/or spaces, or leave input: Type “1” -> Press “ENTER”
If you do not want to setup Multi tenancy:
Do you want to setup Multi Tenancy? Press  Y  to continue or Press  any key to finish installation: Press any key -> Press “ENTER”
Now if you want to setup multi tenancy:
Do you want to setup Multi Tenancy? Press  Y  to continue or Press  any key to finish installation: Type “Y” -> Press “ENTER”
Please enter the site name: Type the other site name you want -> Press “ENTER”
Please enter the ERPNext admin password: Type the Administrator password for the new site -> Press “ENTER”
If you are done with multi tenancy:
Please enter Y to add more site or any key to continue: Press any key to continue the installer -> Press “ENTER”
If you want to set up more sites in multi tenancy:
Please enter Y to add more site or any key to continue: Type “Y” -> Press “ENTER”
Do the same as in step 20. b and c sub steps
Once you exit the multi tenancy setup, it’s time to generate SSL certificates for the sites
nginx.conf already exists and this will overwrite it. Do you want to continue? [y/N]: Type “y” -> Press “ENTER”
Select the appropriate numbers separated by commas and/or spaces, or leave input blank to select all options shown (Enter 'c' to cancel): Press “ENTER”
(E)xpand/(C)ancel: Type “E” -> Press “ENTER”
Now the Installation is finished. You can visit the sites to verify.

