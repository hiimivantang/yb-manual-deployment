#!/bin/sh

NODE1_IP="$1"
shift 1
NODE2_IP="$1"
shift 1
NODE3_IP="$1"

if [ -z "$NODE1_IP" ] | [ -z "$NODE2_IP" ] | [ -z "$NODE3_IP" ]; then
  echo "Usage $0 <node 1 ip address> <node 2 ip address> <node 3 ip address>"
  exit 1
fi

wget https://github.com/prometheus/prometheus/releases/download/v2.42.0/prometheus-2.42.0.linux-amd64.tar.gz

tar xvfz prometheus-2.42.0.linux-amd64.tar.gz && cd prometheus-2.42.0.linux-amd64

PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

tee ./yugabytedb.yaml <<EOF
global:
  scrape_interval:     5s # Set the scrape interval to every 5 seconds. Default is every 1 minute.
  evaluation_interval: 5s # Evaluate rules every 5 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# YugabyteDB configuration to scrape Prometheus time-series metrics
scrape_configs:
  - job_name: "yugabytedb"
    metrics_path: /prometheus-metrics
    relabel_configs:
      - target_label: "node_prefix"
        replacement: "cluster-1"
    metric_relabel_configs:
      # Save the name of the metric so we can group_by since we cannot by __name__ directly...
      - source_labels: ["__name__"]
        regex: "(.*)"
        target_label: "saved_name"
        replacement: "$1"
      # The following basically retrofit the handler_latency_* metrics to label format.
      - source_labels: ["__name__"]
        regex: "handler_latency_(yb_[^_]*)_([^_]*)_([^_]*)(.*)"
        target_label: "server_type"
        replacement: "$1"
      - source_labels: ["__name__"]
        regex: "handler_latency_(yb_[^_]*)_([^_]*)_([^_]*)(.*)"
        target_label: "service_type"
        replacement: "$2"
      - source_labels: ["__name__"]
        regex: "handler_latency_(yb_[^_]*)_([^_]*)_([^_]*)(_sum|_count)?"
        target_label: "service_method"
        replacement: "$3"
      - source_labels: ["__name__"]
        regex: "handler_latency_(yb_[^_]*)_([^_]*)_([^_]*)(_sum|_count)?"
        target_label: "__name__"
        replacement: "rpc_latency$4"

    static_configs:
      - targets: ["$NODE1_IP:7000", "$NODE2_IP:7000", "$NODE3_IP:7000"]
        labels:
          export_type: "master_export"

      - targets: ["$NODE1_IP:9000", "$NODE2_IP:9000", "$NODE3_IP:9000"]
        labels:
          export_type: "tserver_export"

      - targets: ["$NODE1_IP:12000", "$NODE2_IP:12000", "$NODE3_IP:12000"]
        labels:
          export_type: "cql_export"

      - targets: ["$NODE1_IP:13000", "$NODE2_IP:13000", "$NODE3_IP:13000"]
        labels:
          export_type: "ysql_export"

      - targets: ["$NODE1_IP:11000", "$NODE2_IP:11000", "$NODE3_IP:11000"]
        labels:
          export_type: "redis_export"
EOF


./prometheus --config.file=yugabytedb.yaml &> prometheus.out
