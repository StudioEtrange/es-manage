# Elasticsearch Management Tools

Shell tools to manage Elasticsearch suite.

Without polluting your system, nor using root/sudo. Everything in one single folder. No prerequired / external dependencies required. Everything needed will be downloaded. All you need is internet and git.

Works on Nix* & MacOS

## Features

* Elasticsearch / Kibana / Logstash installation
* Set Elasticsearch / Kibana listen ip
* Connect Kibana to an elasticsearch
* Copy management of index, meta-data and visualization.
* Elasticsearch run single instance
* Kibana run single instance

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

NOTE : at first use, a shell tool `stella` will be downloaded.


## Credits

* elasticsearch-dump is used for copy management : https://github.com/taskrabbit/elasticsearch-dump
