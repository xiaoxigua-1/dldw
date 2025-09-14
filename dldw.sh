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

  local TOKEN=$(awk '/XSRF-TOKEN/ {print $7}' dlsite-cookie.txt)
  local FORM_DATA="_token=$TOKEN&login_id=$USERNAME&password=$PASSWORD"
  local CONTENT=$(curl -s -b dlsite-cookie.txt -c dlsite-cookie.txt -d "$FORM_DATA" -H "Content-Type: application/x-www-form-urlencoded" -L https://login.dlsite.com/login)

  if [[ $CONTENT != *"ログインが完了しました。"* ]]; then
    echo "Login failed."
    exit 1
  else
    echo "Login success."
  fi
}

function product {
  local PRODUCT_SUBCOMMAND=${POSITIONAL_ARGS[0]}
  local POSITIONAL_ARGS=("${POSITIONAL_ARGS[@]:1}")

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
  local WORKNO_LIST=$(curl -s -b dlsite-cookie.txt https://play.dlsite.com/api/v3/content/sales?last=0 | jq '[.[].workno]')
  local PRODUCT_LIST=$(curl -X POST -s -b dlsite-cookie.txt -H "Content-Type: application/json" -d "$WORKNO_LIST" https://play.dlsite.com/api/v3/content/works | jq -c '.works')

  echo $PRODUCT_LIST | jq -c '.[]' | while read d; do
    WORKNO=$(echo $d | jq -r -c '.workno')
    NAME=$(echo $d | jq -r -c '.name | values | join(" ")')

    printf "%10s   %s\n" $WORKNO "$NAME"
  done
}

function product_files {
  local WORKNO=$1
  local FILES_COUNT=$(curl -s https://www.dlsite.com/maniax/api/=/product.json?workno=$WORKNO | jq '.[].contents | length')
  local OUTPUT_DIR=${OUTPUT_DIR:-./downloads}

  case $FILES_COUNT in
  0) ;;
  1)
    local HEADER=$(curl -s -b dlsite-cookie.txt -o /dev/null -D - "https://www.dlsite.com/home/download/=/product_id/$WORKNO.html")
    local DOWNLOAD_URL=$(echo "$HEADER" | grep -i "^Location" | awk '{print $2}' | tr -d '\r')
    local JWT=$(echo "$HEADER" | grep -i "^Set-Cookie: " | awk -F': ' '{print $2}' | tr -d '\r')

    aria2c -x 10 -s 10 --header="Cookie: $JWT" -d "$OUTPUT_DIR" $DOWNLOAD_URL
    ;;
  *)
    for i in $(seq 1 $FILES_COUNT); do
      local HEADER=$(curl -s -b dlsite-cookie.txt -o /dev/null -D - "https://www.dlsite.com/home/download/=/number/$i/product_id/$WORKNO.html")
      local DOWNLOAD_URL=$(echo "$HEADER" | grep -i "^Location" | awk '{print $2}' | tr -d '\r')
      local JWT=$(echo "$HEADER" | grep -i "^Set-Cookie: " | awk -F': ' '{print $2}' | tr -d '\r')

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
