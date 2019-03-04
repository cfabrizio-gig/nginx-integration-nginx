match igc_tomscasino_dev_statusok {
   status 200;
   body ~ "Login";
   }

upstream igc_tomscasino_dev_http {
 server AZR5DEVIGC01.stage.gig.local:80;
 zone igc_tomscasino_dev 64k;
 keepalive 64;
}

############## TOMSCASINO DEV IGC ################################

server {
status_zone igc_tomscasino_dev;
 include sites-includes/igc_stage_server.conf;
 server_name ~(.*?)tomscasinodev\.igamingcloud\.com$;
 access_log /nginx/log/igc-tomscasino-dev-access.log main;
 error_log /nginx/log/igc-tomscasino-error.log warn;

location /docs {
 include sites-includes/igc_stage_location.conf;
 proxy_pass http://igc_tomscasino_dev_http;
 auth_basic "Restricted content!";
 auth_basic_user_file "/etc/nginx/password/igc/.htpasswd-docs";
}

location /v2/Authentication/Login {
 limit_req zone=req-limit burst=5 nodelay;
 limit_conn req-limit-zone 200;
 limit_req_status 503;
 limit_req_log_level warn;
 include /nginx/acl/real-ip-list;
 error_log /nginx/log/igc-tomscasino-dev-req-limit.log;
 include sites-includes/igc_stage_location.conf;
 proxy_pass http://igc_tomscasino_dev_http;
}

location /resources/files/ {
 location ~* ^.+.(asp|aspx|php)$ { return 444; }
 include sites-includes/igc_stage_location.conf;
 proxy_pass http://igc_tomscasino_dev_http;
 }

location /dialog.aspx {
 if ($arg_currpath ~* (../|.../|%2e%2e|.asp) ) { return 444; }
 if ($arg_file ~* (../|.../|%2e%2e|.asp) ) { return 444; }
 include sites-includes/igc_stage_location.conf;
 proxy_pass http://igc_tomscasino_dev_http;
}

location / {
 include /nginx/acl/whitelist-igc;
 include sites-includes/igc_stage_location.conf;
 proxy_pass http://igc_tomscasino_dev_http;
 }

location @hc {
    health_check interval=10 passes=2 fails=3 port=80 match=igc_tomscasino_dev_statusok uri=/Login;
    proxy_pass http://igc_tomscasino_dev_http;
    proxy_set_header Host tomscasinodev.igamingcloud.com;
    proxy_set_header X-Forwarded-Host tomscasinodev.igamingcloud.com;
    proxy_set_header X-Forwarded-Server tomscasinodev.igamingcloud.com;
    error_log /var/log/nginx/hc.log info;
}

}
