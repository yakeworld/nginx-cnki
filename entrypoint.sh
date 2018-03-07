!/bin/bash

cat <<EOF
Modified from the marvambass/nginx-ssl-secure container
IMPORTANT:
  IF you use SSL inside your personal NGINX-config,
  you should add the Strict-Transport-Security header like:
    # only this domain
    add_header Strict-Transport-Security "max-age=31536000";
    # apply also on subdomains
    add_header Strict-Transport-Security "max-age=31536000; includeSubdomains";
  to your config.
  After this you should gain a A+ Grade on the Qualys SSL Test
EOF

if [ -z ${DH_SIZE+x} ]
then
  >&2 echo ">> no \$DH_SIZE specified using default" 
  DH_SIZE="2048"
fi


DH="/usr/local/nginx/external/dh.pem"

if [ ! -e "$DH" ]
then
  echo ">> seems like the first start of nginx"
  echo ">> doing some preparations..."
  echo ""

  echo ">> generating $DH with size: $DH_SIZE"
  openssl dhparam -out "$DH" $DH_SIZE
fi

if [ ! -e "/usr/local/nginx/external/cert.pem" ] || [ ! -e "/usr/local/nginx/external/key.pem" ]
then
  echo ">> generating self signed cert"
  openssl req -x509 -newkey rsa:4086 \
  -subj "/C=XX/ST=XXXX/L=XXXX/O=XXXX/CN=localhost" \
  -keyout "/usr/local/nginx/external/key.pem" \
  -out "/usr/local/nginx/external/cert.pem" \
  -days 3650 -nodes -sha256
fi

echo ">> copy /usr/local/nginx/external/*.conf files to /usr/local/nginx/conf.d/"
cp /usr/local/nginx/external/*.conf /usr/local/nginx/conf.d/ 2> /dev/null > /dev/null

# exec CMD
echo ">> exec docker CMD"
echo "$@"
exec "$@"
