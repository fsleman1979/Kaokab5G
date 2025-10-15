#!/bin/bash
# CapX Core 2024 by Jeffrey Timmer | Forat Selman | Philip Prins
# Based on open-source core

# Define color codes for professional output
GREEN="\e[32m"
RED="\e[31m"
BLUE="\e[34m"
BOLD="\e[1m"
BLINK="\e[5m"
RESET="\e[0m"

# Install required packages (figlet and toilet) if not installed
if ! command -v figlet &> /dev/null || ! command -v toilet &> /dev/null; then
    echo -e "${BOLD}${RED}Installing required packages (figlet, toilet)...${RESET}"
    sudo apt-get install figlet toilet -y
fi

# Function to display a full-screen welcome message
display_fullscreen_message() {
    clear
    term_width=$(tput cols)

    # Define the message
    message1="WELCOME TO KAOKAB CORE"
    message2="SET UP YOUR PRIVATE LTE/5G NETWORK"
    message3="Press ENTER to proceed with the installation of CapX Core"

    # Center and display messages
    echo -e "${BOLD}${BLUE}"
    figlet -c -w "$term_width" "$message1"
    figlet -c -w "$term_width" "$message2"
    echo -e "${RESET}"

    # Print the blinking "Press ENTER" message in green
    echo -e "${BOLD}${GREEN}${BLINK}"
    printf "%*s\n" $(((${#message3} + term_width) / 2)) "$message3"
    echo -e "${RESET}"
}

# Show the full-screen welcome message
display_fullscreen_message

# Wait for user to press Enter
read -r

# Clear screen and continue installation
clear

# Continue with the rest of the script...

# Install dialog if not installed
if ! command -v dialog &> /dev/null; then
    echo -e "${BOLD}${RED}dialog is not installed. Installing...${RESET}"
    sudo apt-get install dialog -y
fi

# Function to create input boxes using dialog
input_box() {
    local prompt_message=$1
    local user_input

    # Use dialog to create an input box
    user_input=$(dialog --title "$prompt_message" --inputbox "$prompt_message" 10 60 2>&1 >/dev/tty)

    # Return the user input
    echo "$user_input"
}

# The script continues...


# Echo message before checking the OS
clear
term_width=$(tput cols)

# Centered function for large messages
centered_message() {
    local message=$1
    printf "%*s\n" $(((${#message} + term_width) / 2)) "$message"
}

# Show centered "Checking OS" message before clearing
echo -e "${BOLD}${BLUE}"
centered_message "========================================"
centered_message "Checking the OS version..."
centered_message "========================================"
echo -e "${RESET}"

# Get OS version
issue=$(head -n 1 /etc/issue 2>/dev/null)

# OS check
if [[ "$issue" == Ubuntu\ 22.04* ]]; then
    OS=ubuntu2204
    sleep 2
    echo -e "\n${GREEN}"
    centered_message "=================================================="
    centered_message "✅  YOUR SERVER MEETS THE STANDARD SPECIFICATIONS"
    centered_message "                OF UBUNTU 22.04                   "
    centered_message "=================================================="
    echo -e "${RESET}\n"

    # Blinking "Press ENTER" message
    echo -e "${BOLD}${GREEN}${BLINK}"
    centered_message "Press ENTER to proceed with the installation."
    echo -e "${RESET}"
    read -r
    clear
else
    clear
    echo -e "\n${RED}"
    centered_message "=================================================="
    centered_message "❌ ERROR: UNSUPPORTED OPERATING SYSTEM DETECTED!"
    centered_message "      INSTALLATION CAN ONLY RUN ON UBUNTU 22.04   "
    centered_message "=================================================="
    echo -e "${RESET}\n"

    # Instruction to verify and exit
    echo -e "${BOLD}${RED}"
    centered_message "Please verify your OS version and try again."
    centered_message "Press Ctrl+C to exit."
    echo -e "${RESET}"
    exit 1
fi

# Prompt the user for interface name and IP addresses using dialog
echo -e "\n${BOLD}${BLUE}Please enter the following details for your network setup:${RESET}"

# Ask for interface name and IPs with dialog input box
interface=$(input_box "Enter the network interface name (e.g., enp0s25 or eth0)")
s1ap_ip=$(input_box "Enter the IP address for the S1AP/N2 interface (Control Plane) - Example: 192.168.1.2")
gtpu_ip=$(input_box "Enter the IP address for the GTPU/N3 interface (User Plane) - Example: 192.168.1.6")
upf_ip=$(input_box "Enter the IP address for the UPF interface (User Plane Function) - Example: 192.168.1.7")
cidr=$(input_box "Enter the network CIDR (network mask) - Example: 24,22 or 16  ")
gateway=$(input_box "Enter the gateway IP address - Example: 192.168.1.254")
dns1=$(input_box "Enter DNS1 IP address - Example: 1.0.0.1")
dns2=$(input_box "Enter DNS2 IP address - Example: 1.1.1.1")
apnpool1=$(input_box "Enter the APN pool IP address (for subscriber configuration) - Example: 10.45.0.1/16")
apngateway1=$(input_box "Enter the APN gateway IP address - Example: 10.45.0.1")
# Ask for MCC (Mobile Country Code) and MNC (Mobile Network Code) for PLMN configuration
mcc=$(input_box "Enter the MCC (Mobile Country Code) for your network - Example: 204")
mnc=$(input_box "Enter the MNC (Mobile Network Code) for your network - Example: 25")
# Ask for S-NSSAI (Slice Service Type and Slice Differentiator)
sst=$(input_box "Enter the SST (Slice Service Type) - Example: 1")
sd=$(input_box "Enter the SD (Slice Differentiator) - Example: 010203")
# Ask for additional network configuration fields
tac=$(input_box "Enter the TAC (Tracking Area Code) - Example: 1")
region=$(input_box "Enter the Guami AMF region - Example: region 2")
set=$(input_box "Enter the Guami set - Example: set 1")

clear

# Function to display a blinking centered message
blinking_message() {
    local message=$1
    term_width=$(tput cols)

    for i in {1..5}; do  # Blink 5 times
        clear
        echo -e "${BOLD}${BLUE}"
        printf "%*s\n" $(((${#message} + term_width) / 2)) "$message"
        echo -e "${RESET}"
        sleep 0.7
    done
}

# Netplan configuration file creation with blinking effect
blinking_message "Generating the netplan configuration file..."


# Create the netplan configuration file
cat <<EOL | sudo tee /etc/netplan/00-installer-config.yaml > /dev/null
network:
  ethernets:
    $interface:
      dhcp4: no
      addresses:
       - $s1ap_ip/$cidr
       - $gtpu_ip/$cidr
       - $upf_ip/$cidr
      routes:
        - to: default
          via: $gateway
      nameservers:
       addresses: [$dns1, $dns2]
  version: 2
EOL

# Give user a moment to review
sleep 3

# Function to display centered messages
centered_message() {
    local message=$1
    term_width=$(tput cols)
    printf "%*s\n" $(((${#message} + term_width) / 2)) "$message"
}

# Ask if the user wants to back up the netplan configuration
clear
echo -e "\n${BOLD}${BLUE}"
centered_message "==============================================="
centered_message "Would you like to backup the current netplan"
centered_message "configuration before applying?"
centered_message "==============================================="
echo -e "${RESET}"

echo -e "${BOLD}${GREEN}"
centered_message "If yes, press Enter. If no, press Ctrl+C to exit."
echo -e "${RESET}"
read -r
clear

# Backup the current netplan configuration
sudo cp /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.bak
clear
echo -e "\n${BOLD}${GREEN}"
centered_message "==============================================="
centered_message "✅ Backup created at:"
centered_message "/etc/netplan/00-installer-config.yaml.bak"
centered_message "==============================================="
echo -e "${RESET}"
sleep 2
clear

# Apply the new netplan configuration
echo -e "\n${BOLD}${BLUE}"
centered_message "==============================================="
centered_message "Applying the new netplan configuration..."
centered_message "==============================================="
echo -e "${RESET}"
sudo netplan apply
sleep 3
clear

# Confirm netplan was applied successfully
echo -e "\n${BOLD}${GREEN}"
centered_message "==============================================="
centered_message "✅ Netplan configuration applied successfully!"
centered_message "==============================================="
echo -e "${RESET}"
sleep 2
clear


# Install required packages
echo -e "\n${BOLD}${BLUE}Step 1: Installing required system packages...${RESET}"
sudo apt update
sudo apt install -y vim net-tools ca-certificates curl gnupg nodejs iputils-ping git software-properties-common iptables
echo -e "${GREEN}✅ System packages installed.${RESET}"

# Enable and restart systemd-networkd
echo -e "\n${BOLD}${BLUE}Step 2: Configuring system networking...${RESET}"
sudo systemctl enable systemd-networkd
sudo systemctl restart systemd-networkd
echo -e "${GREEN}✅ System networking configured.${RESET}"

# Install MongoDB
echo -e "\n${BOLD}${BLUE}Step 3: Installing MongoDB...${RESET}"
sudo apt update
sudo apt install -y gnupg

# Import MongoDB public key
echo -e "${BOLD}${BLUE}Adding MongoDB public key...${RESET}"
curl -fsSL https://pgp.mongodb.com/server-6.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
echo -e "${GREEN}✅ MongoDB public key added.${RESET}"

# Add MongoDB repository
echo -e "\n${BOLD}${BLUE}Adding MongoDB repository to sources list...${RESET}"
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
echo -e "${GREEN}✅ MongoDB repository added.${RESET}"

# Install MongoDB
echo -e "\n${BOLD}${BLUE}Installing MongoDB packages...${RESET}"
sudo apt update
sudo apt install -y mongodb-org
echo -e "${GREEN}✅ MongoDB installation completed.${RESET}"

# Start and enable MongoDB service
echo -e "\n${BOLD}${BLUE}Starting and enabling MongoDB service...${RESET}"
sudo systemctl start mongod
sudo systemctl enable mongod
sleep 2
echo -e "${GREEN}✅ MongoDB is now running and enabled on system startup.${RESET}"

# Verify MongoDB is running
echo -e "\n${BOLD}${BLUE}Checking MongoDB status...${RESET}"
if systemctl is-active --quiet mongod; then
    echo -e "${GREEN}✅ MongoDB is active and running.${RESET}"
else
    echo -e "${RED}❌ ERROR: MongoDB is not running! Please check the logs.${RESET}"
    exit 1
fi
#!/bin/bash

# Clone the Kaokab5G repository
echo -e "\n${BOLD}${BLUE}Step 1: Cloning Kaokab5G repository...${RESET}"
git clone https://github.com/Kaokab1979/Kaokab5G.git
echo -e "${GREEN}✅ Kaokab5G repository cloned successfully.${RESET}"
sleep 2

# Install KAOKAB
echo -e "\n${BOLD}${BLUE}Step 2: Installing KAOKAB...${RESET}"
sudo add-apt-repository -y ppa:open5gs/latest
sudo apt update
sudo apt install -y open5gs
echo -e "${GREEN}✅ KAOKAB installed successfully.${RESET}"
sleep 2

# Install Node.js and KAOKAB WebUI
echo -e "\n${BOLD}${BLUE}Step 3: Installing Node.js and KAOKAB WebUI...${RESET}"
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sleep 2

# Add Node.js repository
echo -e "${BOLD}${BLUE}Adding Node.js repository...${RESET}"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=20
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt update
sudo apt install -y nodejs
echo -e "${GREEN}✅ Node.js installed successfully.${RESET}"
sleep 2

# Install KAOKAB WebUI
echo -e "\n${BOLD}${BLUE}Installing KAOKAB WebUI...${RESET}"
curl -fsSL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -
echo -e "${GREEN}✅ KAOKAB WebUI installed successfully.${RESET}"
sleep 2

# Apply Kaokab5G configurations
echo -e "\n${BOLD}${BLUE}Applying Kaokab5G configurations...${RESET}"
cp -fR /root/Kaokab5G/usr/lib/node_modules/open5gs/next/* /usr/lib/node_modules/open5gs/.next/
cp -fR /root/Kaokab5G/Open5GS/* /etc/open5gs/
echo -e "${GREEN}✅ Kaokab5G configurations applied successfully.${RESET}"
sleep 2

echo -e "\n${BOLD}${GREEN}🎉 Installation of KAOKAB and its components is complete!${RESET}"
# Configure IP forwarding permanently
    echo -e "${BOLD}${BLUE}Enabling IP forwarding...${RESET}"
    echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-open5gs.conf
    echo "net.ipv6.conf.all.forwarding=1" | sudo tee -a /etc/sysctl.d/99-open5gs.conf
    sudo sysctl --system

    # Display the result of IP forwarding status
    echo -e "${BOLD}${BLUE}IP forwarding status:${RESET}"
    sysctl net.ipv4.ip_forward

    # Configure NAT rules
    echo -e "${BOLD}${BLUE}Configuring NAT rules...${RESET}"
    sudo iptables -t nat -A POSTROUTING -s $apnpool1 ! -o ogstun -j MASQUERADE
    sudo ip6tables -t nat -A POSTROUTING -s 2001:db8:cafe::/48 ! -o ogstun -j MASQUERADE

    # Save iptables rules to be persistent
    echo -e "${BOLD}${BLUE}Saving iptables rules...${RESET}"
    sudo apt-get install -y iptables-persistent
    sudo netfilter-persistent save
    sudo netfilter-persistent reload

    # Display the result of NAT rules for ogstun
    echo -e "${BOLD}${BLUE}Current NAT rules for ogstun:${RESET}"
    sudo iptables -t nat -S | grep ogstun

    echo -e "${GREEN}✅ IP forwarding and NAT rules have been set up and made persistent.${RESET}"
#
# Function to display a large blinking message
echo -e "\e[1;5;32m========================================\e[0m"
echo -e "\e[1;5;32m   KAOKAB5G is configuring Network Functions   \e[0m"
echo -e "\e[1;5;32m========================================\e[0m"

# Wait for 3 seconds to show the message
sleep 3
# Configure Network Functions
#
## AMF configuratie
    cat <<EOL > /etc/open5gs/amf.yaml
logger:
  file:
    path: /var/log/open5gs/amf.log
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

amf:
  sbi:
    server:
      - address: 127.0.0.5
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
  ngap:
    server:
      - address: $s1ap_ip
  metrics:
    server:
      - address: 127.0.0.5
        port: 9090
  guami:
    - plmn_id:
        mcc: $mcc
        mnc: $mnc
      amf_id:
        region: $region
        set: $set
  tai:
    - plmn_id:
        mcc: $mcc
        mnc: $mnc
      tac: $tac
  plmn_support:
    - plmn_id:
        mcc: $mcc
        mnc: $mnc
      s_nssai:
          sst: $sst
          sd: $sd
  security:
    integrity_order : [ NIA2, NIA1, NIA0 ]
    ciphering_order : [ NEA0, NEA1, NEA2 ]
  network_name:
    full: Kaokab_5G
    short: Kaokab_5G
  amf_name: Kaokab-amf0
  time:
#    t3502:
#      value: 720   # 12 minutes * 60 = 720 seconds
    t3512:
      value: 540    # 9 minutes * 60 = 540 seconds
EOL
# AUSF configuratie
    cat <<EOL > /etc/open5gs/ausf.yaml
logger:
  file:
    path: /var/log/open5gs/ausf.log
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

ausf:
  sbi:
    server:
      - address: 127.0.0.11
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
EOL
# BSF configuratie
    cat <<EOL > /etc/open5gs/bsf.yaml
logger:
  file:
    path: /var/log/open5gs/bsf.log
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

bsf:
  sbi:
    server:
      - address: 127.0.0.15
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
EOL
# HSS configuratie
    cat <<EOL > /etc/open5gs/hss.yaml
db_uri: mongodb://localhost/open5gs
logger:
  file:
    path: /var/log/open5gs/hss.log
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

hss:
  freeDiameter: /etc/freeDiameter/hss.conf
#  sms_over_ims: "sip:smsc.mnc001.mcc001.3gppnetwork.org:7060;transport=tcp"
#  use_mongodb_change_stream: true
EOL
# MME configuratie
    cat <<EOL > /etc/open5gs/mme.yaml
logger:
  file:
    path: /var/log/open5gs/mme.log
    level: debug   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

mme:
  freeDiameter: /etc/freeDiameter/mme.conf
  s1ap:
    server:
      - address: $s1ap_ip
  gtpc:
    server:
      - address: 127.0.0.2
    client:
      sgwc:
        - address: 127.0.0.3
      smf:
        - address: 127.0.0.4
  metrics:
    server:
      - address: 127.0.0.2
        port: 9090
  gummei:
    - plmn_id:
        mcc: $mcc
        mnc: $mnc
      mme_gid: 2
      mme_code: 1
  tai:
    - plmn_id:
        mcc: $mcc
        mnc: $mnc
      tac: $tac
  security:
    integrity_order : [ EIA2, EIA1, EIA0 ]
    ciphering_order : [ EEA0, EEA1, EEA2 ]
  network_name:
    full: Kaokab_4G
    short: Kaokab_4G
  mme_name: open5gs-mme0
  time:
EOL
# NRF configuratie
    cat <<EOL > /etc/open5gs/nrf.yaml
logger:
  file:
    path: /var/log/open5gs/nrf.log
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

nrf:
  serving:  # 5G roaming requires PLMN in NRF
    - plmn_id:
        mcc: $mcc
        mnc: $mnc
  sbi:
    server:
      - address: 127.0.0.10
        port: 7777
EOL
# NSSF configuratie
    cat <<EOL > /etc/open5gs/nssf.yaml                   # Fixing directory name from /Open5GS/  to  /open5gs/
logger:
  file:
    path: /var/log/open5gs/nssf.log
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

nssf:
  sbi:
    server:
      - address: 127.0.0.14
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
      nsi:
        - uri: http://127.0.0.10:7777
          s_nssai:
            sst: $sst
            sd: $sd
EOL
# PCF configuratie
    cat <<EOL > /etc/open5gs/pcf.yaml                  # Fixing directory name from /Open5GS/  to  /open5gs/
db_uri: mongodb://localhost/open5gs
logger:
  file:
    path: /var/log/open5gs/pcf.log
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

pcf:
  sbi:
    server:
      - address: 127.0.0.13
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
  metrics:
    server:
      - address: 127.0.0.13
        port: 9090
EOL
# PCRF configuratie
    cat <<EOL > /etc/open5gs/pcrf.yaml                   # Fixing directory name from /Open5GS/  to  /open5gs/

db_uri: mongodb://localhost/open5gs
logger:
  file:
    path: /var/log/open5gs/pcrf.log
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64
pcrf:
  freeDiameter: /etc/freeDiameter/pcrf.conf
EOL
# SCP configuratie
    cat <<EOL > /etc/open5gs/scp.yaml                # Fixing directory name from /Open5GS/  to  /open5gs/
logger:
  file:
    path: /var/log/open5gs/scp.log
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

scp:
  sbi:
    server:
      - address: 127.0.0.200
        port: 7777
    client:
      nrf:
        - uri: http://127.0.0.10:7777
EOL
# SEPP1 configuratie
    cat <<EOL > /etc/open5gs/sepp1.yaml                 # Fixing directory name from /Open5GS/  to  /open5gs/
logger:
  file:
    path: /var/log/open5gs/sepp1.log
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

sepp:
  default:
    tls:
      server:
        private_key: /etc/open5gs/tls/sepp1.key
        cert: /etc/open5gs/tls/sepp1.crt
      client:
        cacert: /etc/open5gs/tls/ca.crt
  sbi:
    server:
      - address: 127.0.1.250
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
  n32:
    server:
      - sender: sepp1.localdomain
        scheme: https
        address: 127.0.1.251
        port: 7777
        n32f:
          scheme: https
          address: 127.0.1.252
          port: 7777
    client:
      sepp:
        - receiver: sepp2.localdomain
          uri: https://sepp2.localdomain:7777
          resolve: 127.0.2.251
          n32f:
            uri: https://sepp2.localdomain:7777
            resolve: 127.0.2.252
EOL
# SEPP2 configuratie
    cat <<EOL > /etc/open5gs/sepp2.yaml                      # Fixing directory name from /Open5GS/  to  /open5gs/
logger:
  file:
    path: /var/log/open5gs/sepp2.log
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

sepp:
  default:
    tls:
      server:
        private_key: /etc/open5gs/tls/sepp2.key
        cert: /etc/open5gs/tls/sepp2.crt
      client:
        cacert: /etc/open5gs/tls/ca.crt
  sbi:
    server:
      - address: 127.0.2.250
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
  n32:
    server:
      - sender: sepp2.localdomain
        scheme: https
        address: 127.0.2.251
        port: 7777
        n32f:
          scheme: https
          address: 127.0.2.252
          port: 7777
    client:
      sepp:
        - receiver: sepp1.localdomain
          uri: https://sepp1.localdomain:7777
          resolve: 127.0.1.251
          n32f:
            uri: https://sepp1.localdomain:7777
            resolve: 127.0.1.252
EOL
# SGWC configuratie
    cat <<EOL > /etc/open5gs/sgwc.yaml                       # Fixing directory name from /Open5GS/  to  /open5gs/
logger:
  file:
    path: /var/log/open5gs/sgwc.log
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

sgwc:
  gtpc:
    server:
      - address: 127.0.0.3
  pfcp:
    server:
      - address: 127.0.0.3
    client:
      sgwu:
        - address: 127.0.0.6
EOL
# SGWU configuratie
    cat <<EOL > /etc/open5gs/sgwu.yaml                              # Fixing directory name from /Open5GS/  to  /open5gs/
logger:
logger:
  file:
    path: /var/log/open5gs/sgwu.log
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

sgwu:
  pfcp:
    server:
      - address: 127.0.0.6
    client:
#      sgwc:    # SGW-U PFCP Client try to associate SGW-C PFCP Server
#        - address: 127.0.0.3
  gtpu:
    server:
      - address: $gtpu_ip
EOL
# SMF configuratie
    cat <<EOL > /etc/open5gs/smf.yaml                      # Fixing directory name from /Open5GS/  to  /open5gs/
logger:
  file:
    path: /var/log/open5gs/smf.log
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

smf:
  sbi:
    server:
      - address: 127.0.0.4
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
  pfcp:
    server:
      - address: 127.0.0.4
    client:
      upf:
        - address: 127.0.0.7
  gtpc:
    server:
      - address: 127.0.0.4
  gtpu:
    server:
      - address: 127.0.0.4
  metrics:
    server:
      - address: 127.0.0.4
        port: 9090
  session:
    - subnet: $apnpool1
      gateway: $apngateway1
      dnn: internet
  dns:
    - $dns1
    - $dns2
  mtu: 1500
#  p-cscf:
#    - 127.0.0.1
#    - ::1
#  ctf:
#    enabled: auto   # auto(default)|yes|no
  freeDiameter: /etc/freeDiameter/smf.conf
EOL
# UDM configuratie
    cat <<EOL > /etc/open5gs/udm.yaml                 # Fixing directory name from /Open5GS/  to  /open5gs/
logger:
  file:
    path: /var/log/open5gs/udm.log
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

udm:
  hnet:
    - id: 1
      scheme: 1
      key: /etc/open5gs/hnet/curve25519-1.key
    - id: 2
      scheme: 2
      key: /etc/open5gs/hnet/secp256r1-2.key
    - id: 3
      scheme: 1
      key: /etc/open5gs/hnet/curve25519-3.key
    - id: 4
      scheme: 2
      key: /etc/open5gs/hnet/secp256r1-4.key
    - id: 5
      scheme: 1
      key: /etc/open5gs/hnet/curve25519-5.key
    - id: 6
      scheme: 2
      key: /etc/open5gs/hnet/secp256r1-6.key
  sbi:
    server:
      - address: 127.0.0.12
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
EOL
# UDR configuratie
    cat <<EOL > /etc/open5gs/udr.yaml                    # Fixing directory name from /Open5GS/  to  /open5gs/
db_uri: mongodb://localhost/open5gs
logger:
  file:
    path: /var/log/open5gs/udr.log
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

udr:
  sbi:
    server:
      - address: 127.0.0.20
        port: 7777
    client:
#      nrf:
#        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
EOL
# UPF configuratie
    cat <<EOL > /etc/open5gs/upf.yaml               # Fixing directory name from /Open5GS/  to  /open5gs/
logger:
  file:
    path: /var/log/open5gs/upf.log
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

upf:
  pfcp:
    server:
      - address: 127.0.0.7
    client:
#      smf:     #  UPF PFCP Client try to associate SMF PFCP Server
#        - address: 127.0.0.4
  gtpu:
    server:
      - address: $upf_ip
  session:
    - subnet: $apnpool1
      gateway: $apngateway1
    - subnet: 2001:db8:cafe::/48
      gateway: 2001:db8:cafe::1
  metrics:
    server:
      - address: 127.0.0.7
        port: 9090
EOL
#
#
# Modify open5gs-webui.service to allow access from 0.0.0.0:9999
echo -e "${BOLD}${BLUE}Modifying open5gs-webui.service...${RESET}"
sudo tee /lib/systemd/system/open5gs-webui.service > /dev/null <<EOF
[Unit]
Description=Open5GS WebUI
Wants=mongodb.service mongod.service

[Service]
Type=simple
WorkingDirectory=/usr/lib/node_modules/open5gs
Environment=NODE_ENV=production
Environment=HOSTNAME=0.0.0.0
Environment=PORT=9999
ExecStart=/usr/bin/node server/index.js --address \${HOSTNAME} --port \${PORT}
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and restart the service
echo -e "${BOLD}${BLUE}Reloading systemd and restarting the Open5GS WebUI service...${RESET}"
sudo systemctl daemon-reload

# Sleep for a few seconds to allow systemd to reload and update the service
sleep 3

sudo systemctl restart open5gs-webui
sudo systemctl enable open5gs-webui
sleep 3
# Verify if the service is listening on 0.0.0.0:9999
echo -e "${BOLD}${BLUE}Checking if KAOKAB WebUI is listening on 0.0.0.0:9999...${RESET}"
if sudo ss -tuln | grep -q "0.0.0.0:9999"; then
    echo -e "${GREEN}✅ KAOKAB WebUI is successfully listening on 0.0.0.0:9999${RESET}"
else
    echo -e "${RED}❌ ERROR: KAOKAB WebUI is NOT listening on 0.0.0.0:9999. Check service status.${RESET}"
    sudo systemctl status open5gs-webui --no-pager
    exit 1
fi

    # Check the status of all Open5GS services
    echo -e "${BOLD}${BLUE}Checking KAOKAB Services Status...${RESET}"
    open5gs_status=$(sudo systemctl is-active open5gs-* )
    if echo "$open5gs_status" | grep -q "inactive\|failed"; then
        echo -e "${RED}❌ ERROR: Some KAOKAB services are not running!${RESET}"
        echo -e "${RED}Check the status below:${RESET}"
        sudo systemctl list-units --all --plain --no-pager | grep 'open5gs-'
        exit 1
    else
        echo -e "${GREEN}✅ All KAOKAB services are running successfully!${RESET}"
    fi

    # Display Open5GS service list
    echo -e "${BOLD}${BLUE}Current KAOKAB Services:${RESET}"
    sudo systemctl list-units --all --plain --no-pager | grep 'open5gs-'
#!/bin/bash

# Get server IP dynamically
SERVER_IP=$(hostname -I | awk '{print $1}')

# Connect to the KAOKAB WebUI
echo -e "\n${BOLD}${BLUE}🔗 Connect to the KAOKAB WebUI:${RESET}"
echo -e "${BOLD}${GREEN}👉 http://$SERVER_IP:9999${RESET}"
sleep 2

# Display login credentials
echo -e "\n${BOLD}${BLUE}Login Credentials:${RESET}"
echo -e "${BOLD}Username:${RESET} ${GREEN}admin${RESET}"
echo -e "${BOLD}Password:${RESET} ${GREEN}1423${RESET}"
sleep 2

# Tip to change the password
echo -e "\n${BOLD}${BLUE}Tip:${RESET} You can change the password in the Account Menu."
sleep 2

# Steps to Add a Subscriber
echo -e "\n${BOLD}${BLUE}📌 Steps to Add a Subscriber:${RESET}"
echo -e "${GREEN}1.${RESET} Go to the Subscriber Menu."
echo -e "${GREEN}2.${RESET} Click the ${BOLD}+${RESET} button to add a new subscriber."
echo -e "${GREEN}3.${RESET} Fill in the IMSI, security context (K, OPc, AMF), and APN of the subscriber."
echo -e "${GREEN}4.${RESET} Click the ${BOLD}SAVE${RESET} button."
sleep 2

# Final success message with large design and color
echo -e "\n"
echo -e "${BOLD}${GREEN}###############################${RESET}"
echo -e "${BOLD}${GREEN}# INSTALLATION COMPLETED      #${RESET}"
echo -e "${BOLD}${GREEN}# SUCCESSFULLY! 🚀           #${RESET}"
echo -e "${BOLD}${GREEN}###############################${RESET}"
sleep 2

# End of script
echo -e "\n${BOLD}${GREEN}Installation completed successfully!${RESET}"
