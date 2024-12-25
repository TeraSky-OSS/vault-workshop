#!/bin/bash

########################
# include the magic
########################
. demo-magic.sh

# hide the evidence
clear

p "Vault Grafana Demo."
TYPE_SPEED=80

mkdir -p /tmp/learn-vault-monitoring/{vault-config,vault-data} \
    /tmp/learn-vault-monitoring/grafana-config \
    /tmp/learn-vault-monitoring/prometheus-config && \
    export LEARN_VAULT=/tmp/learn-vault-monitoring

p "make sure the telemetry stanza was added to the vault config file like this:"
echo 'telemetry {
  disable_hostname = true
  prometheus_retention_time = "12h"
}'

p "Define Prometheus ACL Policy"
vault policy write prometheus-metrics - << EOF
path "/sys/metrics" {
  capabilities = ["read"]
}
EOF

vault policy read prometheus-metrics

p "lets create a vault token for prometheus"
p "vault token create \
  -field=token \
  -policy prometheus-metrics \
  > $LEARN_VAULT/prometheus-config/prometheus-token"

vault token create \
  -field=token \
  -policy prometheus-metrics \
  > $LEARN_VAULT/prometheus-config/prometheus-token

cat > $LEARN_VAULT/prometheus-config/prometheus.yml << EOF
scrape_configs:
  - job_name: vault
    metrics_path: /v1/sys/metrics
    params:
      format: ['prometheus']
    scheme: http
    authorization:
      credentials_file: /etc/prometheus/prometheus-token
    static_configs:
    - targets: ['$VAULT_IP:8200']
EOF

docker pull prom/prometheus
sudo docker run \
    --detach \
    --name learn-prometheus \
    -p 9090:9090 \
    --rm \
    --volume $LEARN_VAULT/prometheus-config/prometheus.yml:/etc/prometheus/prometheus.yml \
    --volume $LEARN_VAULT/prometheus-config/prometheus-token:/etc/prometheus/prometheus-token \
    prom/prometheus

sudo  docker logs learn-prometheus 2>&1 | grep -i "server is ready"

cat > $LEARN_VAULT/grafana-config/datasource.yml << EOF
# config file version
apiVersion: 1

datasources:
- name: vault
  type: prometheus
  access: server
  orgId: 1
  url: http://PRIVAE_IP:9090
  password:
  user:
  database:
  basicAuth:
  basicAuthUser:
  basicAuthPassword:
  withCredentials:
  isDefault:
  jsonData:
     graphiteVersion: "1.1"
     tlsAuth: false
     tlsAuthWithCACert: false
  secureJsonData:
    tlsCACert: ""
    tlsClientCert: ""
    tlsClientKey: ""
  version: 1
  editable: true
EOF

sudo docker pull grafana/grafana:latest

cat > $LEARN_VAULT/grafana-config/dashboards.yml << EOF
- name: 'default'
  org_id: 1
  folder: ''
  type: 'file'
  options:
    folder: '/etc/grafana/provisioning/dashboards/vault.json'
EOF

cat > $LEARN_VAULT/grafana-config/vault.json << EOF
{
  "__inputs": [
    {
      "name": "DS_PROMXY",
      "label": "Promxy",
      "description": "",
      "type": "datasource",
      "pluginId": "prometheus",
      "pluginName": "Prometheus"
    }
  ],
  "__requires": [
    {
      "type": "grafana",
      "id": "grafana",
      "name": "Grafana",
      "version": "7.0.3"
    },
    {
      "type": "panel",
      "id": "grafana-piechart-panel",
      "name": "Pie Chart",
      "version": "1.5.0"
    },
    {
      "type": "panel",
      "id": "graph",
      "name": "Graph",
      "version": ""
    },
    {
      "type": "datasource",
      "id": "prometheus",
      "name": "Prometheus",
      "version": "1.0.0"
    },
    {
      "type": "panel",
      "id": "stat",
      "name": "Stat",
      "version": ""
    },
    {
      "type": "panel",
      "id": "table",
      "name": "Table",
      "version": ""
    }
  ],
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": "${DS_PROMXY}",
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "description": " Hashicorp Vault Metrics",
  "editable": true,
  "gnetId": 12904,
  "graphTooltip": 1,
  "id": null,
  "iteration": 1602255075192,
  "links": [],
  "panels": [
    {
      "datasource": "${DS_PROMXY}",
      "fieldConfig": {
        "defaults": {
          "custom": {
            "align": null
          },
          "mappings": [
            {
              "from": "",
              "id": 0,
              "operator": "",
              "text": "Standby",
              "to": "",
              "type": 1,
              "value": "0"
            },
            {
              "from": "",
              "id": 1,
              "operator": "",
              "text": "Active",
              "to": "",
              "type": 1,
              "value": "1"
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "red",
                "value": null
              },
              {
                "color": "green",
                "value": 1
              }
            ]
          },
          "unit": "Misc"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 9,
        "x": 0,
        "y": 0
      },
      "id": 39,
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "last"
          ],
          "fields": "",
          "values": false
        }
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "up{job=\"vault\"}",
          "format": "time_series",
          "interval": "",
          "legendFormat": "{{ instance }}",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "Healthy Status",
      "type": "stat"
    },
    {
      "datasource": "${DS_PROMXY}",
      "fieldConfig": {
        "defaults": {
          "custom": {
            "align": null,
            "displayMode": "auto"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          }
        },
        "overrides": [
          {
            "matcher": {
              "id": "byName",
              "options": "Mount Path"
            },
            "properties": [
              {
                "id": "custom.width",
                "value": 166
              }
            ]
          }
        ]
      },
      "gridPos": {
        "h": 8,
        "w": 5,
        "x": 9,
        "y": 0
      },
      "id": 59,
      "maxDataPoints": 100,
      "options": {
        "showHeader": true,
        "sortBy": [
          {
            "desc": true,
            "displayName": "Number of Entries"
          }
        ]
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "avg without(instance) (vault_secret_kv_count)",
          "format": "table",
          "interval": "",
          "legendFormat": "{{ mount_point }}",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "Secrets",
      "transformations": [
        {
          "id": "seriesToColumns",
          "options": {
            "byField": "mount_point"
          }
        },
        {
          "id": "organize",
          "options": {
            "excludeByName": {
              "Time": true,
              "__name__": true,
              "cluster": true,
              "env": true,
              "instance": true,
              "job": true,
              "namespace": true,
              "project": true
            },
            "indexByName": {},
            "renameByName": {
              "Value": "Number of Entries",
              "mount_point": "Mount Path"
            }
          }
        }
      ],
      "type": "table"
    },
    {
      "datasource": "${DS_PROMXY}",
      "fieldConfig": {
        "defaults": {
          "custom": {},
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 5,
        "x": 14,
        "y": 0
      },
      "id": 78,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        }
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "avg(vault_identity_num_entities)",
          "interval": "",
          "legendFormat": "",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "Number of Identity Entities",
      "type": "stat"
    },
    {
      "aliasColors": {},
      "breakPoint": "50%",
      "cacheTimeout": null,
      "combine": {
        "label": "Others",
        "threshold": 0
      },
      "datasource": "${DS_PROMXY}",
      "decimals": null,
      "fieldConfig": {
        "defaults": {
          "custom": {
            "align": null
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          }
        },
        "overrides": []
      },
      "fontSize": "80%",
      "format": "short",
      "gridPos": {
        "h": 8,
        "w": 5,
        "x": 19,
        "y": 0
      },
      "id": 49,
      "interval": null,
      "legend": {
        "header": "count",
        "percentage": false,
        "show": true,
        "sideWidth": null,
        "values": true
      },
      "legendType": "Right side",
      "links": [],
      "maxDataPoints": 1,
      "nullPointMode": "connected",
      "pieType": "pie",
      "pluginVersion": "7.0.3",
      "strokeWidth": "3",
      "targets": [
        {
          "expr": "avg without(instance) (vault_identity_entity_alias_count)",
          "format": "time_series",
          "interval": "",
          "legendFormat": "{{ auth_method }}",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "Identity Entities Aliases by Method",
      "type": "grafana-piechart-panel",
      "valueName": "current"
    },
    {
      "datasource": "${DS_PROMXY}",
      "fieldConfig": {
        "defaults": {
          "custom": {},
          "mappings": [
            {
              "from": "",
              "id": 0,
              "operator": "",
              "text": "UNSEALED",
              "to": "",
              "type": 1,
              "value": "2"
            },
            {
              "from": "",
              "id": 1,
              "operator": "",
              "text": "SEALED",
              "to": "",
              "type": 1,
              "value": "1"
            }
          ],
          "noValue": "N/A",
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "red",
                "value": null
              },
              {
                "color": "yellow",
                "value": 1
              },
              {
                "color": "green",
                "value": 2
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 9,
        "x": 0,
        "y": 4
      },
      "id": 47,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "last"
          ],
          "fields": "",
          "values": false
        }
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "max(1 + vault_core_unsealed{})",
          "format": "time_series",
          "interval": "",
          "legendFormat": "{{ instance }}",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "Sealed Status",
      "type": "stat"
    },
    {
      "datasource": "${DS_PROMXY}",
      "fieldConfig": {
        "defaults": {
          "custom": {},
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "#EAB839",
                "value": 100
              },
              {
                "color": "#EF843C",
                "value": 200
              },
              {
                "color": "red",
                "value": 400
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 5,
        "x": 14,
        "y": 4
      },
      "id": 95,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        }
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "avg(vault_expire_num_leases)",
          "interval": "",
          "legendFormat": "",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "Number of Leases",
      "type": "stat"
    },
    {
      "collapsed": true,
      "datasource": "${DS_PROMXY}",
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 8
      },
      "id": 74,
      "panels": [
        {
          "aliasColors": {},
          "bars": true,
          "dashLength": 10,
          "dashes": false,
          "datasource": "${DS_PROMXY}",
          "decimals": 0,
          "fieldConfig": {
            "defaults": {
              "custom": {}
            },
            "overrides": []
          },
          "fill": 1,
          "fillGradient": 0,
          "gridPos": {
            "h": 9,
            "w": 12,
            "x": 0,
            "y": 9
          },
          "hiddenSeries": false,
          "id": 24,
          "legend": {
            "alignAsTable": true,
            "avg": false,
            "current": false,
            "hideEmpty": false,
            "hideZero": false,
            "max": true,
            "min": false,
            "rightSide": false,
            "show": true,
            "sort": null,
            "sortDesc": null,
            "total": true,
            "values": true
          },
          "lines": false,
          "linewidth": 1,
          "links": [],
          "nullPointMode": "null as zero",
          "options": {
            "dataLinks": []
          },
          "percentage": false,
          "pointradius": 5,
          "points": false,
          "renderer": "flot",
          "scopedVars": {
            "mountpoint": {
              "selected": true,
              "text": "secret",
              "value": "secret"
            }
          },
          "seriesOverrides": [],
          "spaceLength": 10,
          "stack": true,
          "steppedLine": false,
          "targets": [
            {
              "expr": "avg(increase(vault_route_create_${mountpoint}__count[5m]))",
              "format": "time_series",
              "hide": false,
              "interval": "5m",
              "legendFormat": "Create",
              "refId": "A"
            },
            {
              "expr": "avg(increase(vault_route_delete_${mountpoint}__count[5m]))",
              "hide": false,
              "interval": "5m",
              "legendFormat": "Delete",
              "refId": "B"
            },
            {
              "expr": "avg(increase(vault_route_read_${mountpoint}__count[5m]))",
              "format": "time_series",
              "hide": false,
              "instant": false,
              "interval": "5m",
              "intervalFactor": 1,
              "legendFormat": "Read",
              "refId": "C"
            },
            {
              "expr": "avg(increase(vault_route_list_${mountpoint}__count[5m]))",
              "format": "time_series",
              "hide": false,
              "interval": "5m",
              "legendFormat": "List",
              "refId": "D"
            },
            {
              "expr": "avg(increase(vault_route_rollback_${mountpoint}__count[5m]))",
              "hide": true,
              "interval": "5m",
              "legendFormat": "Rollback",
              "refId": "E"
            }
          ],
          "thresholds": [],
          "timeFrom": null,
          "timeRegions": [],
          "timeShift": null,
          "title": "Number of Operations in \"$mountpoint\"",
          "tooltip": {
            "shared": true,
            "sort": 0,
            "value_type": "individual"
          },
          "type": "graph",
          "xaxis": {
            "buckets": null,
            "mode": "time",
            "name": null,
            "show": true,
            "values": []
          },
          "yaxes": [
            {
              "$$hashKey": "object:182",
              "decimals": 0,
              "format": "short",
              "label": "Operations in 5 minute",
              "logBase": 1,
              "max": null,
              "min": null,
              "show": true
            },
            {
              "$$hashKey": "object:183",
              "format": "short",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": false
            }
          ],
          "yaxis": {
            "align": false,
            "alignLevel": null
          }
        },
        {
          "aliasColors": {},
          "bars": false,
          "dashLength": 10,
          "dashes": false,
          "datasource": "${DS_PROMXY}",
          "decimals": 0,
          "fieldConfig": {
            "defaults": {
              "custom": {}
            },
            "overrides": []
          },
          "fill": 1,
          "fillGradient": 0,
          "gridPos": {
            "h": 9,
            "w": 12,
            "x": 12,
            "y": 9
          },
          "hiddenSeries": false,
          "id": 35,
          "legend": {
            "alignAsTable": true,
            "avg": true,
            "current": false,
            "hideEmpty": false,
            "hideZero": false,
            "max": true,
            "min": false,
            "rightSide": false,
            "show": true,
            "sort": null,
            "sortDesc": null,
            "total": false,
            "values": true
          },
          "lines": true,
          "linewidth": 1,
          "links": [],
          "nullPointMode": "null as zero",
          "options": {
            "dataLinks": []
          },
          "percentage": false,
          "pointradius": 5,
          "points": false,
          "renderer": "flot",
          "scopedVars": {
            "mountpoint": {
              "selected": true,
              "text": "secret",
              "value": "secret"
            }
          },
          "seriesOverrides": [],
          "spaceLength": 10,
          "stack": false,
          "steppedLine": false,
          "targets": [
            {
              "expr": "avg(rate(vault_route_create_${mountpoint}__sum[1m]) / rate(vault_route_create_${mountpoint}__count[1m]) * 1000)",
              "format": "time_series",
              "interval": "",
              "intervalFactor": 1,
              "legendFormat": "Create",
              "refId": "A"
            },
            {
              "expr": "avg(rate(vault_route_delete_${mountpoint}__sum[1m]) / rate(vault_route_delete_${mountpoint}__count[1m]) * 1000)",
              "interval": "",
              "legendFormat": "Delete",
              "refId": "B"
            },
            {
              "expr": "avg(rate(vault_route_read_${mountpoint}__sum[1m]) / rate(vault_route_read_${mountpoint}__count[1m]) * 1000)",
              "hide": false,
              "interval": "",
              "legendFormat": "Read",
              "refId": "C"
            },
            {
              "expr": "avg(rate(vault_route_list_${mountpoint}__sum[1m]) / rate(vault_route_list_${mountpoint}__count[1m]) * 1000)",
              "hide": false,
              "interval": "",
              "legendFormat": "List",
              "refId": "D"
            },
            {
              "expr": "avg(rate(vault_route_rollback_${mountpoint}__sum[1m]) / rate(vault_route_rollback_${mountpoint}__count[1m]) * 1000)",
              "hide": true,
              "interval": "",
              "legendFormat": "Rollback",
              "refId": "E"
            }
          ],
          "thresholds": [],
          "timeFrom": null,
          "timeRegions": [],
          "timeShift": null,
          "title": "Time of Operations in \"$mountpoint\"",
          "tooltip": {
            "shared": true,
            "sort": 0,
            "value_type": "individual"
          },
          "type": "graph",
          "xaxis": {
            "buckets": null,
            "mode": "time",
            "name": null,
            "show": true,
            "values": []
          },
          "yaxes": [
            {
              "$$hashKey": "object:82",
              "decimals": 0,
              "format": "µs",
              "label": "Time of one operation",
              "logBase": 1,
              "max": null,
              "min": "0",
              "show": true
            },
            {
              "$$hashKey": "object:83",
              "format": "short",
              "label": null,
              "logBase": 1,
              "max": null,
              "min": null,
              "show": false
            }
          ],
          "yaxis": {
            "align": false,
            "alignLevel": null
          }
        }
      ],
      "repeat": "mountpoint",
      "title": "Path Info: $mountpoint",
      "type": "row"
    },
    {
      "collapsed": false,
      "datasource": "${DS_PROMXY}",
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 9
      },
      "id": 45,
      "panels": [],
      "repeat": null,
      "title": "CPU/Mem Info: $node",
      "type": "row"
    },
    {
      "datasource": "${DS_PROMXY}",
      "description": "",
      "fieldConfig": {
        "defaults": {
          "custom": {},
          "mappings": [],
          "noValue": "N/A",
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 0.2
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 5,
        "w": 3,
        "x": 0,
        "y": 10
      },
      "id": 41,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "last"
          ],
          "fields": "",
          "values": false
        }
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "avg(vault_runtime_heap_objects{} / vault_runtime_malloc_count{})",
          "interval": "",
          "intervalFactor": 10,
          "legendFormat": "",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "Heap Objects Used",
      "type": "stat"
    },
    {
      "datasource": "${DS_PROMXY}",
      "fieldConfig": {
        "defaults": {
          "custom": {},
          "mappings": [],
          "noValue": "N/A",
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "#EAB839",
                "value": 70
              },
              {
                "color": "#EF843C",
                "value": 100
              },
              {
                "color": "#E24D42",
                "value": 150
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 5,
        "w": 3,
        "x": 3,
        "y": 10
      },
      "id": 76,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "last"
          ],
          "fields": "",
          "values": false
        }
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "avg(vault_runtime_num_goroutines{})",
          "interval": "",
          "legendFormat": "",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "Number of Goroutines",
      "type": "stat"
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "${DS_PROMXY}",
      "decimals": 3,
      "fieldConfig": {
        "defaults": {
          "custom": {},
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          }
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 5,
        "w": 18,
        "x": 6,
        "y": 10
      },
      "hiddenSeries": false,
      "id": 43,
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": true,
        "hideEmpty": false,
        "hideZero": false,
        "max": true,
        "min": true,
        "rightSide": false,
        "show": true,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 1,
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pluginVersion": "7.0.3",
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "avg(vault_runtime_alloc_bytes{})",
          "interval": "",
          "intervalFactor": 5,
          "legendFormat": "$node",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Allocated MB",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "$$hashKey": "object:373",
          "format": "decbytes",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "$$hashKey": "object:374",
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "collapsed": false,
      "datasource": "${DS_PROMXY}",
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 15
      },
      "id": 16,
      "panels": [],
      "title": "Token",
      "type": "row"
    },
    {
      "datasource": "${DS_PROMXY}",
      "fieldConfig": {
        "defaults": {
          "custom": {},
          "mappings": [],
          "noValue": "N/A",
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 3,
        "x": 0,
        "y": 16
      },
      "id": 53,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        }
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "avg(vault_token_count)",
          "interval": "",
          "legendFormat": "",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "Available Tokens",
      "type": "stat"
    },
    {
      "aliasColors": {},
      "bars": true,
      "dashLength": 10,
      "dashes": false,
      "datasource": "${DS_PROMXY}",
      "decimals": 0,
      "fieldConfig": {
        "defaults": {
          "custom": {}
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 8,
        "w": 21,
        "x": 3,
        "y": 16
      },
      "hiddenSeries": false,
      "id": 104,
      "legend": {
        "alignAsTable": true,
        "avg": false,
        "current": true,
        "max": true,
        "min": false,
        "rightSide": true,
        "show": true,
        "total": false,
        "values": true
      },
      "lines": false,
      "linewidth": 1,
      "nullPointMode": "connected",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "avg without(instance) (vault_token_count_by_policy)",
          "interval": "",
          "legendFormat": "{{ policy }}",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Tokens by Policy",
      "tooltip": {
        "shared": false,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "series",
        "name": null,
        "show": true,
        "values": [
          "current"
        ]
      },
      "yaxes": [
        {
          "$$hashKey": "object:575",
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "$$hashKey": "object:576",
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "cacheTimeout": null,
      "datasource": "${DS_PROMXY}",
      "fieldConfig": {
        "defaults": {
          "custom": {},
          "mappings": [],
          "noValue": "0",
          "nullValueMode": "connected",
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "orange",
                "value": 1
              },
              {
                "color": "red",
                "value": 3
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 4,
        "w": 3,
        "x": 0,
        "y": 20
      },
      "id": 8,
      "interval": null,
      "links": [],
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "fieldOptions": {
          "calcs": [
            "lastNotNull"
          ]
        },
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "reduceOptions": {
          "calcs": [
            "last"
          ],
          "fields": "",
          "values": false
        }
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "avg(vault_token_create_count - vault_token_store_count)",
          "format": "time_series",
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "Pending Tokens",
      "type": "stat"
    },
    {
      "aliasColors": {},
      "bars": true,
      "dashLength": 10,
      "dashes": false,
      "datasource": "${DS_PROMXY}",
      "decimals": 0,
      "fieldConfig": {
        "defaults": {
          "custom": {}
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 24
      },
      "hiddenSeries": false,
      "id": 102,
      "legend": {
        "alignAsTable": true,
        "avg": false,
        "current": true,
        "max": true,
        "min": false,
        "rightSide": true,
        "show": true,
        "total": false,
        "values": true
      },
      "lines": false,
      "linewidth": 1,
      "nullPointMode": "connected",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "avg without(instance) (vault_token_count_by_ttl)",
          "format": "time_series",
          "interval": "",
          "legendFormat": "{{ creation_ttl }}",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Tokens by TTL",
      "tooltip": {
        "shared": false,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "series",
        "name": null,
        "show": true,
        "values": [
          "current"
        ]
      },
      "yaxes": [
        {
          "$$hashKey": "object:390",
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "$$hashKey": "object:391",
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": true,
      "dashLength": 10,
      "dashes": false,
      "datasource": "${DS_PROMXY}",
      "decimals": 0,
      "fieldConfig": {
        "defaults": {
          "custom": {}
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 24
      },
      "hiddenSeries": false,
      "id": 100,
      "legend": {
        "alignAsTable": true,
        "avg": false,
        "current": true,
        "max": true,
        "min": false,
        "rightSide": true,
        "show": true,
        "total": false,
        "values": true
      },
      "lines": false,
      "linewidth": 1,
      "nullPointMode": "connected",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "avg without(instance) (vault_token_count_by_auth)",
          "interval": "",
          "legendFormat": "{{ auth_method }}",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Tokens by Auth Method",
      "tooltip": {
        "shared": false,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "series",
        "name": null,
        "show": true,
        "values": [
          "current"
        ]
      },
      "yaxes": [
        {
          "$$hashKey": "object:136",
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "$$hashKey": "object:137",
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": true,
      "dashLength": 10,
      "dashes": false,
      "datasource": "${DS_PROMXY}",
      "decimals": 0,
      "fieldConfig": {
        "defaults": {
          "custom": {
            "align": null
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          }
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 6,
        "w": 12,
        "x": 0,
        "y": 32
      },
      "hiddenSeries": false,
      "id": 65,
      "legend": {
        "alignAsTable": false,
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "rightSide": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": false,
      "linewidth": 1,
      "maxDataPoints": 100,
      "nullPointMode": "null as zero",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pluginVersion": "7.0.3",
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": true,
      "steppedLine": false,
      "targets": [
        {
          "expr": "avg by(auth_method, creation_ttl) (vault_token_creation)",
          "format": "time_series",
          "instant": false,
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "{{ auth_method }} - {{ creation_ttl }}",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Tokens Creation by Method & TTL",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "$$hashKey": "object:1956",
          "format": "short",
          "label": "",
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "$$hashKey": "object:1957",
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": false
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {
        "Create": "rgb(84, 183, 90)",
        "Store": "#0a437c"
      },
      "bars": true,
      "dashLength": 10,
      "dashes": false,
      "datasource": "${DS_PROMXY}",
      "decimals": 0,
      "fieldConfig": {
        "defaults": {
          "custom": {}
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 6,
        "w": 12,
        "x": 12,
        "y": 32
      },
      "hiddenSeries": false,
      "id": 6,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": false,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": true,
      "steppedLine": false,
      "targets": [
        {
          "expr": "avg without(instance) (vault_token_create_count)",
          "format": "time_series",
          "instant": false,
          "interval": "",
          "intervalFactor": 10,
          "legendFormat": "Create",
          "refId": "A"
        },
        {
          "expr": "avg without(instance) (vault_token_store_count)",
          "format": "time_series",
          "hide": false,
          "instant": false,
          "interval": "",
          "intervalFactor": 10,
          "legendFormat": "Store",
          "refId": "B"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Token Creation/Storage",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "$$hashKey": "object:877",
          "decimals": 0,
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "$$hashKey": "object:878",
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": false
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {
        "Lookup": "#0a50a1"
      },
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "${DS_PROMXY}",
      "decimals": 3,
      "fieldConfig": {
        "defaults": {
          "custom": {}
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 6,
        "w": 24,
        "x": 0,
        "y": 38
      },
      "hiddenSeries": false,
      "id": 14,
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": true,
        "hideEmpty": false,
        "hideZero": false,
        "max": true,
        "min": true,
        "show": true,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "avg(irate(vault_token_lookup_count[1m]))",
          "hide": false,
          "interval": "",
          "legendFormat": "Lookups",
          "refId": "B"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Token Lookups",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "$$hashKey": "object:330",
          "decimals": 0,
          "format": "short",
          "label": "Lookups per second",
          "logBase": 1,
          "max": null,
          "min": "0",
          "show": true
        },
        {
          "$$hashKey": "object:331",
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": false
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "collapsed": false,
      "datasource": "${DS_PROMXY}",
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 44
      },
      "id": 20,
      "panels": [],
      "title": "Audit",
      "type": "row"
    },
    {
      "datasource": "${DS_PROMXY}",
      "description": "",
      "fieldConfig": {
        "defaults": {
          "custom": {},
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 1
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 5,
        "w": 3,
        "x": 0,
        "y": 45
      },
      "id": 97,
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "max"
          ],
          "fields": "",
          "values": false
        }
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "max(idelta(vault_audit_log_request_failure[1m]))",
          "format": "time_series",
          "interval": "",
          "legendFormat": "Request",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "Log Request Failures",
      "type": "stat"
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "${DS_PROMXY}",
      "decimals": 3,
      "fieldConfig": {
        "defaults": {
          "custom": {}
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 10,
        "w": 11,
        "x": 3,
        "y": 45
      },
      "hiddenSeries": false,
      "id": 4,
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": true,
        "hideEmpty": false,
        "hideZero": false,
        "max": true,
        "min": true,
        "rightSide": false,
        "show": true,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "avg(irate(vault_audit_log_request_count[1m]))",
          "format": "time_series",
          "instant": false,
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "Request ",
          "refId": "A"
        },
        {
          "expr": "avg(irate(vault_audit_log_response_count[1m]))",
          "format": "time_series",
          "hide": false,
          "instant": false,
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "Response",
          "refId": "B"
        },
        {
          "expr": "avg(irate(vault_core_handle_request_count[1m]))",
          "format": "time_series",
          "hide": false,
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "Handled",
          "refId": "C"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Log Requests",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "$$hashKey": "object:109",
          "decimals": 0,
          "format": "short",
          "label": "Requests per second",
          "logBase": 1,
          "max": null,
          "min": "0",
          "show": true
        },
        {
          "$$hashKey": "object:110",
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": false
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {},
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "${DS_PROMXY}",
      "fieldConfig": {
        "defaults": {
          "custom": {}
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 10,
        "w": 10,
        "x": 14,
        "y": 45
      },
      "hiddenSeries": false,
      "id": 61,
      "legend": {
        "alignAsTable": true,
        "avg": true,
        "current": true,
        "max": true,
        "min": true,
        "show": true,
        "total": false,
        "values": true
      },
      "lines": true,
      "linewidth": 1,
      "nullPointMode": "null as zero",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 2,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "avg(irate(vault_consul_get_count[1m]))",
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "GET",
          "refId": "A"
        },
        {
          "expr": "avg(irate(vault_consul_put_count[1m]))",
          "interval": "",
          "legendFormat": "PUT",
          "refId": "B"
        },
        {
          "expr": "avg(irate(vault_consul_delete_count[1m]))",
          "interval": "",
          "legendFormat": "DELETE",
          "refId": "C"
        },
        {
          "expr": "irate(vault_consul_list_count{instance=\"$node:$port\"}[1m])",
          "interval": "",
          "legendFormat": "LIST",
          "refId": "D"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Consul Requests",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "$$hashKey": "object:949",
          "format": "short",
          "label": "Requests per second",
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        },
        {
          "$$hashKey": "object:950",
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": false
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "datasource": "${DS_PROMXY}",
      "description": "",
      "fieldConfig": {
        "defaults": {
          "custom": {},
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 1
              }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": {
        "h": 5,
        "w": 3,
        "x": 0,
        "y": 50
      },
      "id": 98,
      "maxDataPoints": 100,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": [
            "max"
          ],
          "fields": "",
          "values": false
        }
      },
      "pluginVersion": "7.0.3",
      "targets": [
        {
          "expr": "max(idelta(vault_audit_log_response_failure[1m]))",
          "format": "time_series",
          "interval": "",
          "legendFormat": "Request",
          "refId": "A"
        }
      ],
      "timeFrom": null,
      "timeShift": null,
      "title": "Log Response Failures",
      "type": "stat"
    },
    {
      "collapsed": false,
      "datasource": "${DS_PROMXY}",
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 55
      },
      "id": 18,
      "panels": [],
      "title": "Policy",
      "type": "row"
    },
    {
      "aliasColors": {
        "set": "#629e51"
      },
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "${DS_PROMXY}",
      "fieldConfig": {
        "defaults": {
          "custom": {}
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 6,
        "w": 12,
        "x": 0,
        "y": 56
      },
      "hiddenSeries": false,
      "id": 10,
      "legend": {
        "alignAsTable": false,
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "avg(irate(vault_policy_set_policy_count[1m]))",
          "format": "time_series",
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "SET",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Policy Set",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "$$hashKey": "object:1834",
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": "0",
          "show": true
        },
        {
          "$$hashKey": "object:1835",
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    },
    {
      "aliasColors": {
        "GET": "#1f78c1"
      },
      "bars": false,
      "dashLength": 10,
      "dashes": false,
      "datasource": "${DS_PROMXY}",
      "fieldConfig": {
        "defaults": {
          "custom": {}
        },
        "overrides": []
      },
      "fill": 1,
      "fillGradient": 0,
      "gridPos": {
        "h": 6,
        "w": 12,
        "x": 12,
        "y": 56
      },
      "hiddenSeries": false,
      "id": 12,
      "legend": {
        "avg": false,
        "current": false,
        "max": false,
        "min": false,
        "show": true,
        "total": false,
        "values": false
      },
      "lines": true,
      "linewidth": 1,
      "links": [],
      "nullPointMode": "null",
      "options": {
        "dataLinks": []
      },
      "percentage": false,
      "pointradius": 5,
      "points": false,
      "renderer": "flot",
      "seriesOverrides": [],
      "spaceLength": 10,
      "stack": false,
      "steppedLine": false,
      "targets": [
        {
          "expr": "avg(irate(vault_policy_get_policy_count[1m]))",
          "format": "time_series",
          "interval": "",
          "intervalFactor": 1,
          "legendFormat": "GET",
          "refId": "A"
        }
      ],
      "thresholds": [],
      "timeFrom": null,
      "timeRegions": [],
      "timeShift": null,
      "title": "Policy Get",
      "tooltip": {
        "shared": true,
        "sort": 0,
        "value_type": "individual"
      },
      "type": "graph",
      "xaxis": {
        "buckets": null,
        "mode": "time",
        "name": null,
        "show": true,
        "values": []
      },
      "yaxes": [
        {
          "$$hashKey": "object:2132",
          "decimals": 0,
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": "0",
          "show": true
        },
        {
          "$$hashKey": "object:2133",
          "format": "short",
          "label": null,
          "logBase": 1,
          "max": null,
          "min": null,
          "show": true
        }
      ],
      "yaxis": {
        "align": false,
        "alignLevel": null
      }
    }
  ],
  "refresh": false,
  "schemaVersion": 25,
  "style": "dark",
  "tags": [
    "vault"
  ],
  "templating": {
    "list": [
      {
        "allValue": null,
        "current": {},
        "datasource": "${DS_PROMXY}",
        "definition": "label_values(up{job=\"vault\"}, instance)",
        "hide": 2,
        "includeAll": false,
        "label": "Host:",
        "multi": false,
        "name": "node",
        "options": [],
        "query": "label_values(up{job=\"vault\"}, instance)",
        "refresh": 1,
        "regex": "/([^:]+):.*/",
        "skipUrlSync": false,
        "sort": 1,
        "tagValuesQuery": "",
        "tags": [],
        "tagsQuery": "",
        "type": "query",
        "useTags": false
      },
      {
        "allValue": null,
        "current": {},
        "datasource": "${DS_PROMXY}",
        "definition": "label_values(up{job=\"vault\",instance=~\"$node:(.*)\"}, instance)",
        "hide": 2,
        "includeAll": false,
        "label": null,
        "multi": false,
        "name": "port",
        "options": [],
        "query": "label_values(up{job=\"vault\",instance=~\"$node:(.*)\"}, instance)",
        "refresh": 1,
        "regex": "/[^:]+:(.*)/",
        "skipUrlSync": false,
        "sort": 0,
        "tagValuesQuery": "",
        "tags": [],
        "tagsQuery": "",
        "type": "query",
        "useTags": false
      },
      {
        "allValue": "",
        "current": {},
        "datasource": "${DS_PROMXY}",
        "definition": "label_values(vault_secret_kv_count, mount_point)",
        "hide": 0,
        "includeAll": true,
        "label": "Mount Point:",
        "multi": true,
        "name": "mountpoint",
        "options": [],
        "query": "label_values(vault_secret_kv_count, mount_point)",
        "refresh": 2,
        "regex": "/(.*)//",
        "skipUrlSync": false,
        "sort": 1,
        "tagValuesQuery": "",
        "tags": [],
        "tagsQuery": "",
        "type": "query",
        "useTags": false
      }
    ]
  },
  "time": {
    "from": "now-30m",
    "to": "now"
  },
  "timepicker": {
    "refresh_intervals": [
      "10s",
      "30s",
      "1m",
      "5m",
      "15m",
      "30m",
      "1h",
      "2h",
      "1d"
    ],
    "time_options": [
      "5m",
      "15m",
      "1h",
      "6h",
      "12h",
      "24h",
      "2d",
      "7d",
      "30d"
    ]
  },
  "timezone": "",
  "title": "Hashicorp Vault",
  "uid": "vaults",
  "version": 71
}
EOF

sudo docker run \
    --detach \
    --name learn-grafana \
    -p 3000:3000 \
    --rm \
    --volume $LEARN_VAULT/grafana-config/datasource.yml:/etc/grafana/provisioning/datasources/prometheus_datasource.yml \
    --volume $LEARN_VAULT/grafana-config/dashboards.yml:/etc/grafana/provisioning/dashboards/prometheus_dashboards.yml \
    --volume $LEARN_VAULT/grafana-config/vault.json:/etc/grafana/provisioning/dashboards/vault.json \
    grafana/grafana

sudo docker logs learn-grafana 2>&1 | grep "HTTP Server Listen"

prometheus_dashboards.yml

p "access grafana dashboard: http://"
p "Enter admin for both the Email or username and password fields."
p "follow steps in URL: https://developer.hashicorp.com/vault/tutorials/archive/monitor-telemetry-grafana-prometheus"

p "generate traffic:"
pe "for i in {1..100}; do vault token lookup; done"
p "telemetery metrics additional reference: https://developer.hashicorp.com/vault/tutorials/monitoring/telemetry-metrics-reference"



p "full info and features of vault prometheus and grafana can be found on the official vault documentations at:"
p "https://developer.hashicorp.com/vault/tutorials/archive/monitor-telemetry-grafana-prometheus"

p "Demo End."

sudo docker stop learn-grafana
sudo docker stop learn-prometheus
sudo docker rm learn-grafana
sudo docker rm learn-prometheus
rm -r /tmp/learn-vault-monitoring
vault policy delete prometheus-metrics