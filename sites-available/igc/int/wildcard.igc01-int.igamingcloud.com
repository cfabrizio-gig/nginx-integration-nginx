upstream igc_igc01_int_http {
 server AZR5INTIGC01.stage.gig.local:80 max_fails=5;
 zone igc_igc01_int 64k;
 keepalive 128;
}
 
############## IGC01 INT IGC ################################
 
server {
status_zone igc_igc01_int;
 include sites-includes/igc_stage_server.conf;
 server_name ~(.*?)igc01-int\.igamingcloud\.com$;
 access_log /nginx/log/igc-igc01-int-access.log main;
 error_log /nginx/log/igc-igc01-int-error.log warn;

location /docs {
 include sites-includes/igc_stage_location.conf;
 proxy_pass http://igc_igc01_int_http;
 auth_basic "Restricted content!";
 auth_basic_user_file "/etc/nginx/password/igc/.httpasswd";
}

location /Authentication/Login {
 #limit_req zone=req-limit burst=5 nodelay;
 #limit_conn req-limit-zone 200;
 #limit_req_status 503;
 #limit_req_log_level warn;
 #include /nginx/acl/real-ip-list;
 error_log /nginx/log/igc-igc01-int-req-limit.log;
 include sites-includes/igc_stage_location.conf;
 proxy_pass http://igc_igc01_int_http;
}
 
location /resources/files/ {
 location ~* ^.+.(asp|aspx|php)$ { return 444; }
 include sites-includes/igc_stage_location.conf;
 proxy_pass http://igc_igc01_int_http;
 }

location /dialog.aspx {
 if ($arg_currpath ~* (../|.../|%2e%2e|.asp) ) { return 444; }
 if ($arg_file ~* (../|.../|%2e%2e|.asp) ) { return 444; }
 include sites-includes/igc_stage_location.conf;
 proxy_pass http://igc_igc01_int_http;
}

location / {
 #include /nginx/acl/whitelist-igc;
 include sites-includes/igc_stage_location.conf;
 proxy_pass http://igc_igc01_int_http;
 }

}
