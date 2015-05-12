#/bin/bash

prov="$1"
p12="$2"
password="$3"
blue_color="\033[0;36m"
green_color="\033[0;32m"
red_color="\033[0;31m"
end_color="\033[0m"

# Bail if missing required arguments
if [[ -z "$prov" || -z "$p12" || -z "$password" ]]; then
  echo "Usage: prov.mobileprovision pkcs.p12 password"
  exit 1
fi
echo

# Check for xmlstarlet
which xml > /dev/null
if [ $? -ne 0 ]; then
  echo "Error: Please install xmlstarlet using Homebrew: brew install xmlstarlet"
  exit 1
fi

# Validate prov path
if [ ! -f "$prov" ]; then
  echo "Error: $prov does not exist"
  exit 1
fi

# Validate p12 path
if [ ! -f "$p12" ]; then
  echo "Error: $p12 does not exist"
  exit 1
fi

# Grab the certificate from the p12, print the PKCS12 content, grab the content between the cert delimiters
p12_cert="`openssl pkcs12 -nokeys -in "$p12" -passin "pass:$password" 2>&1`"
if [ -z "$p12_cert" ]; then
  echo "Error: Could not find a certificate inside $p12. Wrong password?"
  exit 1
fi
p12_cert_sha1="`echo "$p12_cert" | openssl x509 -inform pem -fingerprint -sha1 -noout | sed 's/Fingerprint=//'`"
echo "P12 contains a certificate with fingerprint:"
echo -e "  ${blue_color}${p12_cert_sha1}${end_color}"

# Count the certs in the provisioning profile
prov_certs_xpath="/plist/dict/key[. = 'DeveloperCertificates']/following-sibling::array[1]/data"
prov_plist="`security cms -D -i "$prov"`"
prov_certs_count="`echo "$prov_plist" | xml sel -t -v "count($prov_certs_xpath)" 2>/dev/null`"
echo
echo "Provisioning profile contains $prov_certs_count developer certificates:"

# Loop over the certs in the prov and the compare the SHA-1 fingerprint of the current cert to that of the p12 cert, looking for a match
found_match=false
for (( prov_cert_index = 1; prov_cert_index <= $prov_certs_count; prov_cert_index++ )); do
  prov_cert="`echo "-----BEGIN CERTIFICATE-----" && echo "$prov_plist" | xml sel -t -v "$prov_certs_xpath[$prov_cert_index]" | awk '{print $1}' | tail -n +2 | sed '$d' && echo "-----END CERTIFICATE-----"`"
  prov_cert_sha1="`echo "$prov_cert" | openssl x509 -inform pem -fingerprint -sha1 -noout | sed 's/SHA1 Fingerprint=//'`"
  if [[ "$prov_cert_sha1" == "$p12_cert_sha1" ]]; then
    echo -e "  ${blue_color}${prov_cert_sha1}${end_color}"
    found_match=true
  else
    echo "  $prov_cert_sha1"
  fi
done

# What'd we discover about the match?
echo
if $found_match; then
  echo -e "${green_color}✓ Success: Provisioning profile contains a certificate matching the p12${end_color}"
  echo
  exit 0
fi
echo -e "${red_color}✗ Failure: Provisioning profile does not contain a certificate matching the p12${end_color}"
echo
exit 1
