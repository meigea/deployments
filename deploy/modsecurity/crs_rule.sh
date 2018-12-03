#!/usr/bin/env bash

### 仅供参考，
MODSECURITY_UTILS_PATH=/usr/local/share/

if [ ! -d $MODSECURITY_UTILS_PATH ]; then
    mkdir -p  $MODSECURITY_UTILS_PATH
fi
## 下载crs-3.0规则库
wget https://github.com/SpiderLabs/owasp-modsecurity-crs/archive/v3.0.2.zip && \
  unzip v3.0.2.zip && mv owasp-modsecurity-crs-3.0.2 owasp-modsecurity-crs && \
   mv owasp-modsecurity-crs $MODSECURITY_UTILS_PATH

cat >> $MODSECURITY_UTILS_PATH/modsecurity.conf << EOF
SecRuleEngine On
SecRequestBodyAccess On
SecRule REQUEST_HEADERS:Content-Type "(?:application(?:/soap\+|/)|text/)xml" "id:'200000',phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=XML"
SecRule REQUEST_HEADERS:Content-Type "application/json" "id:'200001',phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=JSON"
SecRequestBodyLimit 13107200
SecRequestBodyNoFilesLimit 131072
SecRequestBodyInMemoryLimit 131072
SecRequestBodyLimitAction Reject
SecRule REQBODY_ERROR "!@eq 0" "id:'200002', phase:2,t:none,log,deny,status:400,msg:'Failed to parse request body.',logdata:'%{reqbody_error_msg}',severity:2"
SecRule MULTIPART_STRICT_ERROR "!@eq 0" "id:'200003',phase:2,t:none,log,deny,status:400, msg:'Multipart request body failed strict validation: PE %{REQBODY_PROCESSOR_ERROR}, BQ %{MULTIPART_BOUNDARY_QUOTED}, BW %{MULTIPART_BOUNDARY_WHITESPACE}, DB %{MULTIPART_DATA_BEFORE}, DA %{MULTIPART_DATA_AFTER}, HF %{MULTIPART_HEADER_FOLDING}, LF %{MULTIPART_LF_LINE}, SM %{MULTIPART_MISSING_SEMICOLON}, IQ %{MULTIPART_INVALID_QUOTING}, IP %{MULTIPART_INVALID_PART}, IH %{MULTIPART_INVALID_HEADER_FOLDING}, FL %{MULTIPART_FILE_LIMIT_EXCEEDED}'"
SecRule MULTIPART_UNMATCHED_BOUNDARY "!@eq 0" "id:'200004',phase:2,t:none,log,deny,msg:'Multipart parser detected a possible unmatched boundary.'"
SecPcreMatchLimit 1000
SecPcreMatchLimitRecursion 1000
SecRule TX:/^MSC_/ "!@streq 0" "id:'200005',phase:2,t:none,deny,msg:'ModSecurity internal error flagged: %{MATCHED_VAR_NAME}'"
SecResponseBodyAccess On
SecResponseBodyMimeType text/plain text/html text/xml application/json
SecResponseBodyLimit 524288
SecResponseBodyLimitAction ProcessPartial
SecTmpDir /tmp/
SecDataDir /tmp/
SecAuditEngine RelevantOnly
SecAuditLogRelevantStatus "^(?:5|4(?!04))"
SecAuditLogParts ABIJDEFHZ
SecAuditLogType Serial
SecAuditLog /var/log/nginx/modsec_audit.log
SecArgumentSeparator &
SecCookieFormat 0
SecUnicodeMapFile unicode.mapping 20127
SecStatusEngine On

EOF

mv $MODSECURITY_UTILS_PATH"/owasp-modsecurity-crs/crs-setup.conf.example" $MODSECURITY_UTILS_PATH"/owasp-modsecurity-crs/crs-setup.conf"
echo -e "\ninclude $MODSECURITY_UTILS_PATH/owasp-modsecurity-crs/*.rules\n" >> $MODSECURITY_UTILS_PATH/modsecurity.conf