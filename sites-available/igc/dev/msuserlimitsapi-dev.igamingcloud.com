upstream igc_msuserlimitsapi_dev_https {
        server AZR5DEVIGC01.stage.gig.local:80;
        zone igc_msuserlimitsapi_int 64k;
}

server {
status_zone igc_msuserlimitsapi_dev;
                include sites-includes/igc_stage_server.conf;
                server_name  msuserlimitsapi-dev.igamingcloud.com;
                access_log /nginx/log/igc-msuserlimitsapi-dev-access.log main;

        location / {
                        include sites-includes/igc_stage_location.conf;
			include /nginx/acl/whitelist-igc;
                        proxy_pass http://igc_msuserlimitsapi_dev_https;
        }
}
