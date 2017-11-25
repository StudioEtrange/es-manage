# Elastic Suite Management Tools

Shell tools to manage Elastic Suite.

Without polluting your system, nor using root/sudo. Everything in one single folder. No prerequired / external dependencies required. Everything needed will be downloaded. All you need is internet and git.

Works on Nix* & MacOS

## Features

* Elasticsearch / Kibana / Logstash / Heartbeat installation
* Set Elasticsearch / Kibana listen ip
* Connect Kibana / Heartbeat to an elasticsearch
* Copy management of index, meta-data and visualization.
* Elasticsearch / Kibana / Heartbeat run single instance daemonized or not

## Installation

```
git clone https://github.com/StudioEtrange/es-manage
cd es-manage
./do.sh env install
```


## Help

```
./do.sh -h
```

NOTE : at first use, `stella` shell framework will be downloaded.


## Credits

* elasticsearch-dump is used for copy management : https://github.com/taskrabbit/elasticsearch-dump
