# Tenderduty Automatic Configuration Updater
## Pre-requesites
 - A Linux system with Tenderduty, Docker, and Docker-Compose installed
 - A private repository for hosting the Tenderduty config
## Add Deploy Key to Private Repo
The first thing that needs to be done is to configure the private repository where the Tenderduty config will be hosted. If using a public repository, skip to the next section.

For this example, I'll be using GitHub. In order to be able to pull the config from the private repository, a Deploy key needs to be added to the repo. Go to the private repo -> Settings -> Deploy keys -> Add deploy key. Enter a title to identify the key based on personal preference.

On the Linux system that will be pulling the config, an SSH key will need to be generated to be used as the deploy key. Run the following command to generate the key:

`ssh-keygen -t ed25519`

When prompted, enter the path for the key. For ease of use, I've chosen to use the default keyname. When prompted for a password on the SSH key, this is an important choice for how this workflow will need to be set up. Because this SSH key will only have Read access of the repo, I have not password protected the SSH key. As such, this SSH key should ONLY be used to read the private repo. Given more time, I plan on adding a password to the SSH key, but it will require more work to get setup.

Now that the key is generated, copy the contents of the PUBLIC key to the GitHub Deploy key window. Because this key is not password protected, DO NOT allow write access. Once completed, hit "Add key" to add this deploy key to the repo.

## Configure Systemd Service/Timers and Updater Script
Now that the repo is configured, the Tenderduty server will need to be configured.

- Pull the public repo containing the scripts/services needed to update the config
	- `git clone https://github.com/Crypto-Chemistry/tenderduty-config-updater.git`
- Pull the private repo containing the Tenderduty config
	- `cd $HOME/.config && git clone $repo_url tenderduty_config`
	- If `$HOME/.config` does not exist, first create it with `mkdir $HOME/.config`
- Edit the `tenderduty_config_updater.sh` script to use the proper TENDERDUTY_DIR (`/home/user_name/tenderduty`) and CONFIG_DIR (`/home/user_name/.config/tenderduty_config`) for your system. 
- Edit the `tenderduty_config_updater.service` script:
	-  Set the User and Group for the service to run as
	- Set the path to the `tenderduty_config_updater.sh` script in `ExecStart` 
- Copy the service and timer to systemd's service directory
	- `sudo ln -s /home/user_name/tenderduty-config-updater/tenderduty_config_updater.service /etc/systemd/system/tenderduty_config_updater.service`
	- `sudo ln -s /home/user_name/tenderduty-config-updater/tenderduty_config_updater.timer /etc/systemd/system/tenderduty_config_updater.timer`
- If the private tenderduty configuration uses an environment variable for the pagerduty API key, add it as a service override by doing the following
	- `sudo systemctl edit tenderduty_config_updater.service`
	- Add the following line to the override file. replacing the variable name and value according to your config:
		```
		[Service]
		Environment="PAGERDUTY_API_KEY_VARIABLE_NAME=api_string"
- Enable the timer and service
	- `sudo systemctl enable tenderduty_config_updater.service`
	- `sudo systemctl enable tenderduty_config_updater.timer`
	- `sudo systemctl start tenderduty_config_updater.timer`

## Testing The Auto Updater
Test the implementation by commiting a change to the Tenderduty config repo. Check the output of the updater with the following command:
`sudo journalctl -f -u tenderduty_config_updater.service`

Changes are checked every 5 minutes, so you may need to wait up to 5 minutes. Once the changes are seen by the script, you should see output of the Tenderduty docker-compose being brought down and stood back up with the new config. Once this occurs, you can check the contents of the docker-compose.yml file that contains the Tenderduty config to ensure your change was ingested properly.

`cat $HOME/tenderduty/docker-compose.yml`
