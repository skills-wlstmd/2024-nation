cat <<\EOF>> /etc/fluent-bit/fluent-bit.conf
[INPUT]
    Name tail
    Path /home/ec2-user/log/app.log
    Tag wsi.app.log
    
[FILTER]
    Name parser
    Match wsi.app.*
    Key_Name log
    Parser logParser
[FILTER]
    Name        grep
    Match       wsi.app.*
    Exclude      path /.*healthcheck.*/
    Exclude      path /.*healthcheck.*
    Exclude      path .*healthcheck.*
    
[OUTPUT]
    Name            es
    Match           wsi.app.*
    Host            ES_EP
    Port            443
    TLS             On
    AWS_Auth        On
    AWS_Region      ap-northeast-2
    Index           app-log
    Replace_Dots    On
    Suppress_Type_Name On
EOF

ES_EP=$(aws opensearch describe-domain --domain wsi-opensearch --query "DomainStatus.Endpoint" --output text)

sed -i "s|ES_EP|$ES_EP|g" /etc/fluent-bit/fluent-bit.conf

cat <<\SOS>> /etc/fluent-bit/parsers.conf
[PARSER]
    Name logParser
    Format regex
    Regex ^(?<clientip>[^ ]*) - \[(?<time>[^\]]*)\] "(?<method>[^ ]*) (?<path>[^ ]*) (?<protocol>[^ ]*)" (?<responsecode>[^ ]*) \S\S(?<useragent>[^"]*)\S
SOS

systemctl restart fluent-bit
systemctl status fluent-bit

nohup python3 /home/ec2-user/app.py > /dev/null 2>&1 &

nohup fluent-bit -c /etc/fluent-bit/fluent-bit.conf &