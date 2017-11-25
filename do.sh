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
    echo " L     es run [--daemon] [--heap=<size>] [--folder=<log_path>]: run single elasticsearch on current host"
    echo " L     es kill : stop all elasticsearch instances on current host"
    echo " L     es create --idx=<index> [--target=<schema://host:port>] [--mapping=<json_file>]"
    echo " L     es delete --idx=<index> [--target=<schema://host:port>]"
    echo " L     es listen --host=<ip|interface> : set es listening interface or ip. If it is an interface use this format : _eth0_"
    echo " o-- KIBANA management :"
    echo " L     kibana install [--version=<version>] : install elasticsearch on current host"
    echo " L     kibana home : print kibana install path"
    echo " L     kibana run [--daemon] : run single kibana on current host"
    echo " L     kibana kill : stop all kibana instances on current host"
    echo " L     kibana connect --target=<schema://host:port> : connect kibana on current host to a target elasticsearch instance"
    echo " L     kibana listen --host=<ip> : set es listening ip. For full access use 0.0.0.0"
    echo " o-- LOGSTASH management :"
    echo " L     logstash install [--version=<version>] : install logstash on current host"
    echo " L     logstash home : print logstash install path"
    echo " o-- HEARTBEAT management :"
    echo " L     heartbeat install [--version=<version>] : install heartbeat on current host"
    echo " L     heartbeat home : print heartbeat install path"
    echo " L     heartbeat run [--daemon] [--folder=<output_path>] [--config=<config_path>] [--host=<schema://host:port>] [--opt=<string>] : run single hearbeat on current host. Config path is a folder containing all conf files. Use target to specify es output (override config file)"
    echo " L     heartbeat kill : stop all heartbeat instances on current host"
    echo " o-- COPY management :"
    echo " L     es copy-data --idxsrc=<index_list> --idxtgt=<index_list> [--source=<schema://host:port>] [--target=<schema://host:port>] : copy data of an index from source to target"
    echo " L     es copy-metadata --idxsrc=<index_list> --idxtgt=<index_list> [--source=<schema://host:port>] [--target=<schema://host:port>] : copy analyzer and mapping of an index from source to target"
    echo " L     es export-data --idxsrc=<index_list> --file=<path> [--source=<schema://host:port>] : export data to a json file"
    echo " L     kibana copy --source=<schema://host:port> --target=<schema://host:port> : copy all kibana resource from an elasticsearch source to an elasticsearch target"
}



# COMMAND LINE -----------------------------------------------------------------------------------
PARAMETERS="
DOMAIN=     '' 			a				'env es kibana logstash heartbeat'
ACTION=     ''      a       'install home run kill create delete listen connect copy-data copy-metadata export-data'
"
OPTIONS="
FORCE=''							  'f'		  ''					b			0		'1'					  Force.
HEAP=''                 ''      'es heap size'          s           0       ''  set elasticsearch heap size when launch (use ES_HEAP_SIZE)
DAEMON=''							  'd'		  ''					b			0		'1'					  run in background.
HOST=''        ''     'host or interface'           s           0       ''              host or interface
SOURCE='http://localhost:9200'        's'     'host:port'           s           0       ''              schema://host:port
TARGET='http://localhost:9200'        't'     'host:port'           s           0       ''              schema://host:port
FOLDER=''                           ''         'path'                s           0       ''                      Path
CONFIG=''                           ''         'path'                s           0       ''                      Path
IDX=''                             ''         'index'                s           0       ''                      Index name.
IDXSRC=''                          ''         'index'                s           0       ''                      Index name.
IDXTGT=''                          ''         'index'                s           0       ''                      Index name.
VERSION=''                          ''         'version'                s           0       ''                      Version number as X.Y.Z
MAPPING=''                          'm'         'path'                s           0       ''                      mapping json file path.
FILE=''                          ''         'path'                s           0       ''                      File path.
OPT=''                             ''         'string'                s           0       ''                      Options.
"

$STELLA_API argparse "$0" "$OPTIONS" "$PARAMETERS" "ES Manage" "$(usage)" "" "$@"


$STELLA_API feature_info elasticsearch ES
export ES_HOME=$ES_FEAT_INSTALL_ROOT
$STELLA_API feature_info kibana KIBANA
export KIBANA_HOME=$KIBANA_FEAT_INSTALL_ROOT
$STELLA_API feature_info logstash LOGSTASH
export LOGSTASH_HOME=$LOGSTASH_FEAT_INSTALL_ROOT
$STELLA_API feature_info heartbeat HEARTBEAT
export HEARTBEAT_HOME=$HEARTBEAT_FEAT_INSTALL_ROOT

[ ! -z $VERSION ] && VERSION="$(echo "$VERSION" | sed -e 's/\./_/g')"

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

# ---------------------------  LOGSTASH --------------------------------------------------------
if [ "$DOMAIN" = "logstash" ]; then
  if [ "$ACTION" = "install" ]; then
    if [ -z "$VERSION" ]; then
      $STELLA_API feature_install logstash
    else
      $STELLA_API feature_install logstash#$VERSION
    fi
  fi

  if [ "$ACTION" = "home" ]; then
    echo "$LOGSTASH_HOME"
  fi
fi


# ---------------------------  HEARTBEAT --------------------------------------------------------
if [ "$DOMAIN" = "heartbeat" ]; then

  [ "$FOLDER" = "" ] && HEARTBEAT_LOG_PATH="$STELLA_APP_WORK_ROOT/heartbeat/logs" || HEARTBEAT_LOG_PATH="$FOLDER/logs"
  [ "$FOLDER" = "" ] && HEARTBEAT_DATA_PATH="$STELLA_APP_WORK_ROOT/heartbeat/data" || HEARTBEAT_DATA_PATH="$FOLDER/data"
  [ ! "$CONFIG" = "" ] && HEARTBEAT_CONFIG_OPTION="-path.config $CONFIG" || HEARTBEAT_CONFIG_OPTION="-path.config $HEARTBEAT_HOME"
  [ ! "$HOST" = "" ] && HEARTBEAT_OVERRIDE_ES_OUTPUT="-E output.elasticsearch.hosts=$HOST"

  # OPT examples :
  # -E output.elasticsearch.username=elastic -E output.elasticsearch.password=elastic

  HEARTBEAT_OPTIONS="$HEARTBEAT_CONFIG_OPTION $HEARTBEAT_OVERRIDE_ES_OUTPUT $OPT"

  if [ "$ACTION" = "install" ]; then
    if [ -z "$VERSION" ]; then
      $STELLA_API feature_install heartbeat
    else
      $STELLA_API feature_install heartbeat#$VERSION
    fi
  fi

  if [ "$ACTION" = "run" ]; then
    if [ "$DAEMON" = "1" ]; then
      nohup -- $HEARTBEAT_HOME/heartbeat $HEARTBEAT_OPTIONS -path.data "$HEARTBEAT_DATA_PATH" -path.logs "$HEARTBEAT_LOG_PATH" 1>/dev/null 2>&1 &
      sleep 1
      echo " ** heartbeat started with PID $(ps aux | grep $HEARTBEAT_HOME/heartbeat | grep -v "grep" | tr -s " " | cut -d" " -f 2)"
    else
      # log to console instead of log file if FOLDER not specified
      [ ! "$FOLDER" = "" ] && $HEARTBEAT_HOME/heartbeat $HEARTBEAT_OPTIONS -path.data "$HEARTBEAT_DATA_PATH" -path.logs "$HEARTBEAT_LOG_PATH" || \
      $HEARTBEAT_HOME/heartbeat $HEARTBEAT_OPTIONS -path.data "$HEARTBEAT_DATA_PATH" -e
    fi
  fi

  if [ "$ACTION" = "kill" ]; then
      echo " ** heartbeat PID $(ps aux | grep $HEARTBEAT_HOME/heartbeat | grep -v "grep" | tr -s " " | cut -d" " -f 2) stopping"
      kill $(ps aux | grep $HEARTBEAT_HOME/heartbeat | grep -v "grep" | tr -s " " | cut -d" " -f 2)
  fi

  if [ "$ACTION" = "home" ]; then
      echo "$HEARTBEAT_HOME"
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
    else
      if [ "$FOLDER" = "" ]; then
          # log to console instead of log file if FOLDER not specified
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


  if [ "$ACTION" = "create" ]; then
    $STELLA_API require "curl" "curl" "SYSTEM"
    [ -z "$IDX" ] && echo "** ERROR please specify an index with --idx" && exit 1

    if [ -z "$MAPPING" ]; then
      curl -XPUT $TARGET/$IDX
    else
      # TODO : do we need POST or PUT here ?
      curl -XPOST $TARGET/$IDX --data-binary @$MAPPING
    fi
  fi

  if [ "$ACTION" = "delete" ]; then
    $STELLA_API require "curl" "curl" "SYSTEM"
    [ -z "$IDX" ] && echo "** ERROR please specify an index with --idx" && exit 1
    curl -XDELETE $TARGET/$IDX
  fi


  if [ "$ACTION" = "listen" ]; then
    echo "** ES will listening on $HOST on next start"
    sed -i.bak 's/.*network.host.*//' $ES_HOME/config/elasticsearch.yml
    echo "network.host: $HOST" >> $ES_HOME/config/elasticsearch.yml

    echo "** If you use Kibana, dont forget to connect it to this IP"
  fi


  if [ "$ACTION" = "export-data" ]; then
    #SOURCE_ES_HOST=$(echo "$SOURCE" | sed "s/:.*$//")
    #$STELLA_API no_proxy_for "$SOURCE_ES_HOST"
    cd $STELLA_APP_WORK_ROOT/elasticsearch-dump/bin

    echo "=== INDEX SOURCE : $IDXSRC ==="
    echo "=== TARGET FILE : $FILE ==="
    if [ "$FILE" = "" ]; then
      echo "**ERROR use --file option to specify a file path"
      exit 1
    fi
    echo "** Data export"
    ./elasticdump \
      --input=$SOURCE/$IDXSRC \
      --output=$FILE \
      --limit=1000 \
      --type=data
  fi

  if [ "$ACTION" = "copy-data" ]; then
    #TARGET_ES_HOST=$(echo "$TARGET" | sed "s/:.*$//")
    #SOURCE_ES_HOST=$(echo "$SOURCE" | sed "s/:.*$//")
    #$STELLA_API no_proxy_for "$TARGET_ES_HOST"
    #$STELLA_API no_proxy_for "$SOURCE_ES_HOST"

    cd $STELLA_APP_WORK_ROOT/elasticsearch-dump/bin

    s=0
    for i in $IDXSRC; do
      t=0
      for j in $IDXTGT; do
        if [ "$s" = "$t" ]; then
          break
        fi
        t=$(( $t + 1 ))
      done

      echo "=== INDEX SOURCE : $i ==="
      echo "=== INDEX TARGET : $j ==="

      echo "** Data copy"
      ./elasticdump \
        --input=$SOURCE/$i \
        --output=$TARGET/$j \
        --limit=1000 \
        --type=data

      s=$(( $s + 1 ))
    done
  fi

  if [ "$ACTION" = "copy-metadata" ]; then
    #TARGET_ES_HOST=$(echo "$TARGET" | sed "s/:.*$//")
    #SOURCE_ES_HOST=$(echo "$SOURCE" | sed "s/:.*$//")
    #$STELLA_API no_proxy_for "$TARGET_ES_HOST"
    #$STELLA_API no_proxy_for "$SOURCE_ES_HOST"

    cd $STELLA_APP_WORK_ROOT/elasticsearch-dump/bin

    s=0
    for i in $IDXSRC; do
      t=0
      for j in $IDXTGT; do
        if [ "$s" = "$t" ]; then
          break
        fi
        t=$(( $t + 1 ))
      done
      echo "=== INDEX SOURCE : $i ==="
      echo "=== INDEX TARGET : $j ==="

      echo "** Analyser copy"
      ./elasticdump \
        --input=$SOURCE/$i \
        --output=$TARGET/$j \
        --type=analyzer

      echo "** Mapping copy"
      ./elasticdump \
        --input=$SOURCE/$i \
        --output=$TARGET/$j \
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
          # log to console instead of log file if FOLDER not specified
          kibana
      else
          kibana 1>$FOLDER/log.kibana.log 2>&1
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

  if [ "$ACTION" = "listen" ]; then
    echo "** KIBANA will listening on $HOST on next start"
    sed -i.bak 's/.*server.host.*//' $KIBANA_HOME/config/kibana.yml
    echo "server.host: $HOST" >> $KIBANA_HOME/config/kibana.yml
  fi


  if [ "$ACTION" = "copy" ]; then
    #TARGET_ES_HOST=$(echo "$TARGET" | sed "s/:.*$//")
    #SOURCE_ES_HOST=$(echo "$SOURCE" | sed "s/:.*$//")
    #$STELLA_API no_proxy_for "$TARGET_ES_HOST"
    #$STELLA_API no_proxy_for "$SOURCE_ES_HOST"

    cd $STELLA_APP_WORK_ROOT/elasticsearch-dump/bin

    echo "=== KIBANA ==="
    echo "** Index-Pattern copy"
    ./elasticdump \
      --input=$SOURCE/.kibana \
      --output=$TARGET/.kibana \
      --type=data \
      --searchBody='{"filter": {"type" : {"value":"index-pattern"} }}'

    echo "** Dashboard / Visualization copy"
    ./elasticdump \
      --input=$SOURCE/.kibana \
      --output=$TARGET/.kibana \
      --type=data \
      --searchBody='{"filter": { "or": [ {"type": {"value": "dashboard"}}, {"type" : {"value":"visualization"}}] }}'

    echo "** Search copy"
    ./elasticdump \
      --input=$SOURCE/.kibana \
      --output=$TARGET/.kibana \
      --type=data \
      --searchBody='{"filter": {"type" : {"value":"search"} }}'
  fi

fi
