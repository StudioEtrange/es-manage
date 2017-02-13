#!/bin/bash
_CURRENT_FILE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
_CURRENT_RUNNING_DIR="$( cd "$( dirname "." )" && pwd )"
source $_CURRENT_FILE_DIR/stella-link.sh include

# https://github.com/taskrabbit/elasticsearch-dump
# NOTE pick a elasticsearch-dump version dependening on ES version



# TODO : IDXSRC & IDXTGT could be list of index


function usage() {
    echo "USAGE :"
    echo "----------------"
    echo "List of commands"
    echo " o-- GENERIC management :"
    echo " L     env install : install this tool"
    echo " o-- ES management :"
    echo " L     es install [--version=<version>] : install elasticsearch on current host"
    echo " L     es home : print es install path"
    echo " L     es run [--daemon] [--heap] [--folder=<log_path>]: run single elasticsearch on current host"
    echo " L     es kill : stop all elasticsearch instances on current host"
    echo " L     es create --idx=<index> [--mapping=<json_file>]"
    echo " L     es delete --idx=<index> [--mapping=<json_file>]"
    echo " L     es listen --host=<ip|interface> : set es listening interface or ip with network.host var. If it is an interface use this format : _eth0_"
    echo " o-- KIBANA management :"
    echo " L     kibana install [--version=<version>] : install elasticsearch on current host"
    echo " L     kibana home : print kibana install path"
    echo " L     kibana run [--daemon] : run single elasticsearch on current host"
    echo " L     kibana kill : stop all elasticsearch instances on current host"
    echo " L     kibana connect --target=<host:port> : connect kibana on current host to a target elasticsearch instance"
    echo " o-- LOGSTASH management :"
    echo " L     logstash install [--version=<version>] : install logstash on current host"
    echo " L     logstash home : print logstash install path"
    echo " o-- COPY management :"
    echo " L     es copy --source=<host:port> --target=<host:port> --idxsrc=<index_list> --idxtgt=<index_list> : copy data of an index from source to target"
    echo " L     es copy-metadata --source=<host:port> --target=<host:port> --idxsrc=<index_list> --idxtgt=<index_list> : copy analyzer and mapping of an index from source to target"
    echo " L     kibana copy --source=<host:port> --target=<host:port> : copy all kibana resource from an elasticsearch source to an elasticsearch target"
}



# COMMAND LINE -----------------------------------------------------------------------------------
PARAMETERS="
DOMAIN=     '' 			a				'env es kibana logstash'
ACTION=     ''      a       'install home run kill create delete listen connect copy copy-metadata'
"
OPTIONS="
FORCE=''							  'f'		  ''					b			0		'1'					  Force.
HEAP=''                 ''      'es heap size'          s           0       ''  set elasticsearch heap size when launch (use ES_HEAP_SIZE)
DAEMON=''							  'd'		  ''					b			0		'1'					  run in background.
HOST='localhost'        ''     'host or interface'           s           0       ''              host or interface
SOURCE='localhost:9200'        's'     'host:port'           s           0       ''              host:port
TARGET='localhost:9200'        't'     'host:port'           s           0       ''              host:port
FOLDER=''                           ''         'path'                s           0       ''                      Root folder
IDX=''                             ''         'index'                s           0       ''                      Index name.
IDXSRC=''                          ''         'index'                s           0       ''                      Index name.
IDXTGT=''                          ''         'index'                s           0       ''                      Index name.
VERSION=''                          ''         'version'                s           0       ''                      Version number as X_Y_Z.
"

$STELLA_API argparse "$0" "$OPTIONS" "$PARAMETERS" "ES Manage" "$(usage)" "" "$@"


$STELLA_API feature_info elasticsearch ES
export ES_HOME=$ES_FEAT_INSTALL_ROOT
$STELLA_API feature_info kibana KIBANA
export KIBANA_HOME=$KIBANA_FEAT_INSTALL_ROOT

# ---------------------------  ENV --------------------------------------------------------
if [ "$DOMAIN" = "env" ]; then
  if [ "$ACTION" = "install" ]; then
    $STELLA_API feature_install "nodejs"
    if [ ! -f "$STELLA_APP_WORK_ROOT/elasticsearch-dump/bin/elasticdump" ]; then
      cd $STELLA_APP_WORK_ROOT
      git clone https://github.com/taskrabbit/elasticsearch-dump
      cd elasticsearch-dump
      npm install
    fi
  fi
fi

# ---------------------------  ES --------------------------------------------------------
if [ "$DOMAIN" = "es" ]; then
  if [ "$ACTION" = "install" ]; then
    if [ -z "$VERSION" ]; then
      $STELLA_API feature_install elasticsearch
    else
      $STELLA_API feature_install elasticsearch#$VERSION
    fi
  fi
fi


# ---------------------------  ES --------------------------------------------------------
if [ "$DOMAIN" = "es" ]; then
  if [ "$ACTION" = "install" ]; then
    if [ -z "$VERSION" ]; then
      $STELLA_API feature_install elasticsearch
    else
      $STELLA_API feature_install elasticsearch#$VERSION
    fi
  fi
  if [ "$ACTION" = "run" ]; then
    # https://www.elastic.co/guide/en/elasticsearch/guide/current/heap-sizing.html
    [ ! "$HEAP" = "" ] && export ES_HEAP_SIZE=$HEAP
    if [ "$DAEMON" = "1" ]; then
      if [ "$FOLDER" = "" ]; then
          nohup -- elasticsearch 1>/dev/null 2>&1 &
      else
          nohup -- elasticsearch 1>$FOLDER/log.es.log 2>&1 &
      fi
      sleep 1
      echo " ** elasticsearch started with PID $(ps aux | grep [o]rg.elasticsearch.bootstrap.Elasticsearch | tr -s " " | cut -d" " -f 2)"
      #echo " ** elasticsearch started with PID $(cat $STELLA_APP_WORK_ROOT/es.pid)"
    else
      if [ "$FOLDER" = "" ]; then
          elasticsearch
      else
          elasticsearch 1>$FOLDER/log.es.log 2>&1
      fi
    fi
  fi

  if [ "$ACTION" = "kill" ]; then
      echo " ** elasticsearch PID $(ps aux | grep [o]rg.elasticsearch.bootstrap.Elasticsearch | tr -s " " | cut -d" " -f 2) stopping"
      kill $(ps aux | grep [o]rg.elasticsearch.bootstrap.Elasticsearch | tr -s " " | cut -d" " -f 2)
  fi

  if [ "$ACTION" = "home" ]; then
    echo "$ES_HOME"
  fi

  if [ "$ACTION" = "listen" ]; then
    echo "** ES will listening on $HOST on next start"
    sed -i.bak 's/.*network.host.*//' $ES_HOME/config/elasticsearch.yml
    echo "network.host: $HOST" >> $ES_HOME/config/elasticsearch.yml

    echo "** If you use Kibana, dont forget to connect it to this IP"
  fi


  if [ "$ACTION" = "copy-data" ]; then
    TARGET_ES_HOST=$(echo "$TARGET" | sed "s/:.*$//")
    SOURCE_ES_HOST=$(echo "$SOURCE" | sed "s/:.*$//")
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

      echo "=== INDEX SOURCE : $i ==="
      echo "=== INDEX TARGET : $j ==="

      echo "** Data copy"
      ./elasticdump \
        --input=http://$SOURCE/$i \
        --output=http://$TARGET/$j \
        --limit=1000 \
        --type=data

      s=$(( $s + 1 ))
    done
  fi

  if [ "$ACTION" = "copy-metadata" ]; then
    TARGET_ES_HOST=$(echo "$TARGET" | sed "s/:.*$//")
    SOURCE_ES_HOST=$(echo "$SOURCE" | sed "s/:.*$//")
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
      echo "=== INDEX SOURCE : $i ==="
      echo "=== INDEX TARGET : $j ==="

      echo "** Analyser copy"
      ./elasticdump \
        --input=http://$SOURCE/$i \
        --output=http://$TARGET/$j \
        --type=analyzer

      echo "** Mapping copy"
      ./elasticdump \
        --input=http://$SOURCE/$i \
        --output=http://$TARGET/$j \
        --type=mapping
    done
  fi
fi

# --------------------------- KIBANA --------------------------------------------------------
if [ "$DOMAIN" = "kibana" ]; then
  if [ "$ACTION" = "home" ]; then
    echo "$KIBANA_HOME"
  fi

  if [ "$ACTION" = "install" ]; then
    if [ -z "$VERSION" ]; then
      $STELLA_API feature_install kibana
    else
      $STELLA_API feature_install kibana#$VERSION
    fi
  fi

  if [ "$ACTION" = "run" ]; then
    if [ "$DAEMON" = "1" ]; then
      if [ "$FOLDER" = "" ]; then
          nohup -- kibana 1>/dev/null 2>&1 &
      else
          nohup -- kibana 1>$FOLDER/log.kibana.log 2>&1 &
      fi
      echo " ** kibana started with PID $(ps aux | grep $KIBANA_HOME | grep node | tr -s " " | cut -d" " -f 2)"
    else
      if [ "$FOLDER" = "" ]; then
          kibana
      else
          kibana 1>/dev/null 2>&1
      fi
    fi
  fi

  if [ "$ACTION" = "kill" ]; then
    echo " ** kibana PID $(ps aux | grep $KIBANA_HOME | grep node | tr -s " " | cut -d" " -f 2) stopping"
    kill $(ps aux | grep $KIBANA_HOME | grep node | tr -s " " | cut -d" " -f 2)
  fi

  if [ "$ACTION" = "connect" ]; then
    echo "** Kibana will be connected to ES on $TARGET"
    sed -i.bak 's/.*elasticsearch.url.*//' $KIBANA_HOME/config/kibana.yml
    echo "elasticsearch.url: \"$TARGET\"" >> $KIBANA_HOME/config/kibana.yml
  fi

  if [ "$ACTION" = "copy" ]; then
    TARGET_ES_HOST=$(echo "$TARGET" | sed "s/:.*$//")
    SOURCE_ES_HOST=$(echo "$SOURCE" | sed "s/:.*$//")
    $STELLA_API no_proxy_for "$TARGET_ES_HOST"
    $STELLA_API no_proxy_for "$SOURCE_ES_HOST"

    cd $STELLA_APP_WORK_ROOT/elasticsearch-dump/bin

    echo "=== KIBANA ==="
    echo "** Index-Pattern copy"
    ./elasticdump \
      --input=http://$SOURCE/.kibana \
      --output=http://$TARGET/.kibana \
      --type=data \
      --searchBody='{"filter": {"type" : {"value":"index-pattern"} }}'

    echo "** Dashboard / Visualization copy"
    ./elasticdump \
      --input=http://$SOURCE/.kibana \
      --output=http://$TARGET/.kibana \
      --type=data \
      --searchBody='{"filter": { "or": [ {"type": {"value": "dashboard"}}, {"type" : {"value":"visualization"}}] }}'

    echo "** Search copy"
    ./elasticdump \
      --input=http://$SOURCE/.kibana \
      --output=http://$TARGET/.kibana \
      --type=data \
      --searchBody='{"filter": {"type" : {"value":"search"} }}'
  fi

fi
