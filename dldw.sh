#!/bin/bash

function login {
  curl -s -c dlsite-cookie.txt -L -o /dev/null https://www.dlsite.com/home/login/=/skip_register/1

  if [[ -z "$USERNAME" ]]; then
    echo "Missing --username"
    exit 1
  elif [[ -z "$PASSWORD" ]]; then
    echo "Missing --password"
    exit 1
  fi

  TOKEN=$(awk '/XSRF-TOKEN/ {print $7}' dlsite-cookie.txt)
  FORM_DATA="_token=$TOKEN&login_id=$USERNAME&password=$PASSWORD"

  curl -s -b dlsite-cookie.txt -c dlsite-cookie.txt -d "$FORM_DATA" -H "Content-Type: application/x-www-form-urlencoded" -L -o /dev/null https://login.dlsite.com/login
}

function product {
  PRODUCT_SUBCOMMAND=${POSITIONAL_ARGS[0]}
  POSITIONAL_ARGS=("${POSITIONAL_ARGS[@]:1}")

  case "$PRODUCT_SUBCOMMAND" in
  list)
    product_list
    ;;
  download)
    product_files ${POSITIONAL_ARGS[0]}
    ;;
  esac
}

function product_list {
  USER_PRODUCT_COUNT=$(curl -s -b dlsite-cookie.txt https://play.dlsite.com/api/product_count | jq '.user')
  COUNT=1
  PRODUCT_LIST=

  while ((USER_PRODUCT_COUNT > 0)); do
    PRODUCT_WORKS=$(curl -s -b dlsite-cookie.txt "https://play.dlsite.com/api/purchases?page=$COUNT" | jq '.works')
    PRODUCT_LIST="$PRODUCT_LIST$PRODUCT_WORKS"
    ((COUNT++))
    USER_PRODUCT_COUNT=$(($USER_PRODUCT_COUNT - 50))
  done

  PRODUCT_LIST=$(echo $PRODUCT_LIST | jq -s 'add')

  echo $PRODUCT_LIST | jq -c '.[]' | while read d; do
    WORKNO=$(echo $d | jq -r -c '.workno')
    NAME=$(echo $d | jq -r -c '.name | values | join(" ")')

    printf "%10s   %s\n" $WORKNO "$NAME"
  done
}

function product_files {
  WORKNO=$1
  FILES_COUNT=$(curl -s https://www.dlsite.com/maniax/api/=/product.json?workno=$WORKNO | jq '.[].contents | length')
  OUTPUT_DIR=${OUTPUT_DIR:-./downloads}

  case $FILES_COUNT in
  0) ;;
  1)
    HEADER=$(curl -s -b dlsite-cookie.txt -o /dev/null -D - "https://www.dlsite.com/home/download/=/product_id/$WORKNO.html")
    DOWNLOAD_URL=$(echo "$HEADER" | grep -i "^Location" | awk '{print $2}' | tr -d '\r')
    JWT=$(echo "$HEADER" | grep -i "^Set-Cookie: " | awk -F': ' '{print $2}' | tr -d '\r')

    aria2c -x 10 -s 10 --header="Cookie: $JWT" -d "$OUTPUT_DIR" $DOWNLOAD_URL
    ;;
  *)
    for i in $(seq 1 $FILES_COUNT); do
      HEADER=$(curl -s -b dlsite-cookie.txt -o /dev/null -D - "https://www.dlsite.com/home/download/=/number/$i/product_id/$WORKNO.html")
      DOWNLOAD_URL=$(echo "$HEADER" | grep -i "^Location" | awk '{print $2}' | tr -d '\r')
      JWT=$(echo "$HEADER" | grep -i "^Set-Cookie: " | awk -F': ' '{print $2}' | tr -d '\r')

      aria2c -x 10 -s 10 --header="Cookie: $JWT" -d "$OUTPUT_DIR" $DOWNLOAD_URL
    done
    ;;
  esac
}

if ! command -v curl &>/dev/null; then
  echo "Missing curl command."
  exit 1
elif ! command -v jq &>/dev/null; then
  echo "Missing jq command."
  exit 1
elif ! command -v aria2c &>/dev/null; then
  echo "Missing aria2c command."
  exit 1
fi

SUBCOMMAND=$1
shift

while [[ $# -gt 0 ]]; do
  case $1 in
  -p | --password)
    shift
    PASSWORD=$1
    ;;
  -u | --username)
    shift
    USERNAME=$1
    ;;
  -d | --dir)
    shift
    OUTPUT_DIR=$1
    ;;
  -* | --*)
    echo "Unknown option $1"
    exit 1
    ;;
  *)
    POSITIONAL_ARGS+=("$1")
    ;;
  esac
  shift
done

case $SUBCOMMAND in
login)
  login
  ;;
product)
  product
  ;;
esac
