name: Deploy to DigitalOcean

on:
  push:
    branches:
      - main  # Change if needed

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Set up SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -H your-droplet-ip >> ~/.ssh/known_hosts

      - name: Copy script to Droplet
        run: |
          scp -i ~/.ssh/id_rsa shell.sh root@your-droplet-ip:/root/shell.sh
          ssh -i ~/.ssh/id_rsa root@your-droplet-ip "chmod +x /root/shell.sh"

      - name: Run script on Droplet with environment variables
        run: |
          ssh -i ~/.ssh/id_rsa root@your-droplet-ip "
            export DB_NAME='${{ secrets.DB_NAME }}' &&
            export DB_USER='${{ secrets.DB_USER }}' &&
            export DB_PASSWORD='${{ secrets.DB_PASSWORD }}' &&
            export DBMS='${{ secrets.DBMS }}' &&
            export APP_ZIP='${{ secrets.APP_ZIP }}' &&
            export APP_JAR='${{ secrets.APP_JAR }}' &&
            /root/shell.sh
          "

