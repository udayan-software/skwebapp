#!/bin/bash


#!/bin/bash

set -e
set -o pipefail

# Define variables using environment variables
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
DB_PASSWORD="${DB_PASSWORD}"
DBMS="${DBMS}"
APP_GROUP="appgroup"
APP_USER="appuser"
APP_DIR="/opt"
APP_ZIP="${APP_ZIP}"
APP_JAR="${APP_JAR}"
LOG_FILE="/var/log/deployment.log"

# Logging function
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Ensure environment variables are set
if [[ -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASSWORD" || -z "$DBMS" ]]; then
    log "Error: Database credentials are not set. Exiting."
    exit 1
fi

log "Starting setup on Droplet..."

# Update and upgrade the system
sudo apt-get update -y && sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
sudo apt-get install -y unzip openjdk-17-jre

# Install the selected RDBMS
echo "Installing $DBMS..."
if [ "$DBMS" == "mysql" ]; then
    sudo apt install -y mysql-server
    sudo systemctl enable --now mysql
    sudo mysql -e "CREATE DATABASE $DB_NAME;"
    sudo mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"
elif [ "$DBMS" == "postgresql" ]; then
    sudo apt install -y postgresql postgresql-contrib
    sudo systemctl enable --now postgresql
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
elif [ "$DBMS" == "mariadb" ]; then
    sudo apt install -y mariadb-server
    sudo systemctl enable --now mariadb
    sudo mysql -e "CREATE DATABASE $DB_NAME;"
    sudo mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"
else
    echo "Unsupported DBMS: $DBMS"
    exit 1
fi

echo "Database setup completed."

# Create a new Linux group and user
echo "Creating user group: $APP_GROUP"
sudo groupadd -f $APP_GROUP
echo "Creating application user: $APP_USER"
sudo useradd -m -g $APP_GROUP -s /bin/bash $APP_USER

# Unzip the application
echo "Setting up application directory..."
sudo mkdir -p $APP_DIR
sudo unzip -o $APP_ZIP -d $APP_DIR

# Update permissions
echo "Updating permissions..."
sudo chown -R $APP_USER:$APP_GROUP $APP_DIR
sudo chmod -R 750 $APP_DIR

echo "Application setup completed successfully."

# Set up application
log "Setting up application directory..."
sudo mkdir -p $APP_DIR

if [ -f "$APP_ZIP" ]; then
    log "Unzipping application..."
    sudo unzip -o "$APP_ZIP" -d "$APP_DIR"
else
    log "Application ZIP not found, skipping extraction."
fi

log "Updating permissions..."
sudo chown -R $APP_USER:$APP_GROUP $APP_DIR
sudo chmod -R 750 $APP_DIR

# Start Java application (if JAR exists)
if [ -f "$APP_JAR" ]; then
    log "Starting Java application..."
    sudo -u $APP_USER nohup java -jar "$APP_JAR" > "$APP_DIR/app.log" 2>&1 &
else
    log "Java application JAR not found, skipping start."
fi

log "Application setup completed successfully."

