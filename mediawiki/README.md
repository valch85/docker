# MediaWiki 
MediaWiki runs with docker-compose (SSL enabled)

to start project run `docker-compose up .` in the directory

- during the setup process using a server name `database` instead of `localhost`
- after initial setup, download `LocalSettings.php` to the same directory as this .yaml and uncomment the following line and use docker-compose to restart the MediaWiki service
- replace certs with your own