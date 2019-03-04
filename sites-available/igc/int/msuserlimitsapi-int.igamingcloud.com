upstream igc_msuserlimitsapi_int_https {
        server AZR5INTIGC01.stage.gig.local:80;
        zone igc_msuserlimitsapi_int 64k;
}

server {
status_zone igc_msuserlimitsapi_int;
                include sites-includes/igc_stage_server.conf;
                server_name  msuserlimitsapi-int.igamingcloud.com;
                access_log /nginx/log/igc-msuserlimitsapi-int-access.log main;

        location / {
                        include sites-includes/igc_stage_location.conf;
			include /nginx/acl/whitelist-igc;
                        proxy_pass http://igc_msuserlimitsapi_int_https;
        }
}
