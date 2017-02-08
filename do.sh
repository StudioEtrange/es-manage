#!/bin/bash
_CURRENT_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
_CURRENT_RUNNING_DIR="$( cd "$( dirname "." )" && pwd )"
source $_CURRENT_FILE_DIR/stella-link.sh include


# TODO NEED TO SET TARGET_ES_PORT and TARGET_ES_HOST MANUALLY
TARGET_ES_HOST=hcc05node.acc.edf.fr
TARGET_ES_PORT=9200
SOURCE_ES_HOST=hcc05node.acc.edf.fr
SOURCE_ES_PORT=9200


ACTION="$1"
INDEX_LIST_SOURCE="$2"
INDEX_LIST_TARGET="$3"
if [ "$INDEX_LIST_TARGET" = "" ]; then
  INDEX_LIST_TARGET="$INDEX_LIST_TARGET"
fi



# COPY DES INDEX ET TABLEAUX DE BORDS
# ./do.sh env
# ./do.sh copy-metadata "index1"
# ./do.sh copy-data "index1" "index2"
# ./do.sh copy-viz

if [ "$ACTION" == "env" ]; then
  $STELLA_API feature_install "nodejs"

  if [ ! -f "$STELLA_APP_WORK_ROOT/elasticsearch-dump/bin/elasticdump" ]; then
    cd $STELLA_APP_WORK_ROOT
    git clone https://github.com/taskrabbit/elasticsearch-dump
    cd elasticsearch-dump
    npm install
  fi
fi

if [ "$ACTION" == "copy-data" ]; then
  $STELLA_API no_proxy_for "$TARGET_ES_HOST"
  $STELLA_API no_proxy_for "$SOURCE_ES_HOST"

  cd $STELLA_APP_WORK_ROOT/elasticsearch-dump/bin

  s=0
  for i in $INDEX_LIST_SOURCE; do
    t=0
    for j in $INDEX_LIST_TARGET; do
      if [ "$s" = "$t" ]; then
        break
      fi
      t=$(( $t + 1 ))
    done

    echo "===== INDEX SOURCE : $i ====="
    echo "===== INDEX TARGET : $j ====="

    echo "** Data copy"
    ./elasticdump \
      --input=http://$SOURCE_ES_HOST:$SOURCE_ES_PORT/$i \
      --output=http://$TARGET_ES_HOST:$TARGET_ES_PORT/$j \
      --limit=1000 \
      --type=data

    s=$(( $s + 1 ))
  done
fi


if [ "$ACTION" == "copy-metadata" ]; then
  $STELLA_API no_proxy_for "$TARGET_ES_HOST"
  $STELLA_API no_proxy_for "$SOURCE_ES_HOST"

  cd $STELLA_APP_WORK_ROOT/elasticsearch-dump/bin


  s=0
  for i in $INDEX_LIST_SOURCE; do
    t=0
    for j in $INDEX_LIST_TARGET; do
      if [ "$s" = "$t" ]; then
        break
      fi
      t=$(( $t + 1 ))
    done
    echo "===== INDEX SOURCE : $i ====="
    echo "===== INDEX TARGET : $j ====="

    echo "** Analyser copy"
    ./elasticdump \
      --input=http://$SOURCE_ES_HOST:$SOURCE_ES_PORT/$i \
      --output=http://$TARGET_ES_HOST:$TARGET_ES_PORT/$j \
      --type=analyzer

    echo "** Mapping copy"
    ./elasticdump \
      --input=http://$SOURCE_ES_HOST:$SOURCE_ES_PORT/$i \
      --output=http://$TARGET_ES_HOST:$TARGET_ES_PORT/$j \
      --type=mapping
  done
fi


if [ "$ACTION" == "copy-viz" ]; then
  $STELLA_API no_proxy_for "$TARGET_ES_HOST"
  $STELLA_API no_proxy_for "$SOURCE_ES_HOST"

  cd $STELLA_APP_WORK_ROOT/elasticsearch-dump/bin

  echo "===== KIBANA ====="
  echo "** Index-Pattern copy"
  ./elasticdump \
    --input=http://$SOURCE_ES_HOST:$SOURCE_ES_PORT/.kibana \
    --output=http://$TARGET_ES_HOST:$TARGET_ES_PORT/.kibana \
    --type=data \
    --searchBody='{"filter": {"type" : {"value":"index-pattern"} }}'

  echo "** Dashboard / Visualization copy"
  ./elasticdump \
    --input=http://$SOURCE_ES_HOST:$SOURCE_ES_PORT/.kibana \
    --output=http://$TARGET_ES_HOST:$TARGET_ES_PORT/.kibana \
    --type=data \
    --searchBody='{"filter": { "or": [ {"type": {"value": "dashboard"}}, {"type" : {"value":"visualization"}}] }}'

  echo "** Search copy"
  ./elasticdump \
    --input=http://$SOURCE_ES_HOST:$SOURCE_ES_PORT/.kibana \
    --output=http://$TARGET_ES_HOST:$TARGET_ES_PORT/.kibana \
    --type=data \
    --searchBody='{"filter": {"type" : {"value":"search"} }}'
fi
