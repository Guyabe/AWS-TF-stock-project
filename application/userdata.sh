#!/bin/bash
# Update system packages
yum update -y

# Install Docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create necessary directories for volumes
mkdir -p /home/ec2-user/prometheus /home/ec2-user/prometheus/config /home/ec2-user/prometheus/data
mkdir -p /home/ec2-user/grafana /home/ec2-user/grafana/provisioning /home/ec2-user/grafana/provisioning/dashboards /home/ec2-user/grafana/provisioning/datasources

# Change ownership of directories to ec2-user
chown -R ec2-user:ec2-user /home/ec2-user/*
chown -R 65534:65534 /home/ec2-user/prometheus  # Ensure Prometheus has permission to write to the directory
sudo chown -R 472:472 /home/ec2-user/grafana
sudo chmod -R 755 /home/ec2-user/grafana

# Create the Prometheus configuration file
cat <<EOF > /home/ec2-user/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'flask_stock_app'
    metrics_path: /metrics
    static_configs:
      - targets: ['<STOCK-APP_IP_ADDRESS>:8000']
EOF

# Set Grafana datasource configuration file to pull from Prometheus and Loki
cat <<EOF > /home/ec2-user/grafana/provisioning/datasources/datasources.yml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    orgId: 1
    url: http://prometheus:9090
    isDefault: true
    version: 1
    editable: true

  - name: Loki
    type: loki
    access: proxy
    orgId: 1
    url: http://<STOCK-APP_IP_ADDRESS>:3100
    isDefault: false
    version: 1
    editable: true
EOF

# Provision Grafana dashboards
cat <<EOF > /home/ec2-user/grafana/provisioning/dashboards/dashboard.yml
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

# Create the Grafana Loki dashboard file
cat <<EOF > /home/ec2-user/grafana/provisioning/dashboards/loki_dashboard.json
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": {
          "type": "grafana",
          "uid": "-- Grafana --"
        },
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "links": [],
  "panels": [
    {
      "datasource": {
        "default": false,
        "type": "loki",
        "uid": "P8E80F9AEF21F6940"
      },
      "gridPos": {
        "h": 9,
        "w": 24,
        "x": 0,
        "y": 0
      },
      "id": 1,
      "options": {
        "dedupStrategy": "none",
        "enableLogDetails": true,
        "prettifyLogMessage": false,
        "showCommonLabels": false,
        "showLabels": false,
        "showTime": true,
        "sortOrder": "Descending",
        "wrapLogMessage": false
      },
      "targets": [
        {
          "datasource": {
            "type": "loki",
            "uid": "P8E80F9AEF21F6940"
          },
          "editorMode": "code",
          "expr": "{job=\"stock-app-logs\"}\n",
          "queryType": "range",
          "refId": "A"
        }
      ],
      "title": "Stock App Log Stream",
      "type": "logs"
    }
  ],
  "schemaVersion": 39,
  "tags": [],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-6h",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "",
  "title": "Stock App Logs",
  "uid": "stock-app-logs",
  "version": 1,
  "weekStart": ""
}
EOF

# Create the Grafana stock-app dashboard file
cat <<EOF > /home/ec2-user/grafana/provisioning/dashboards/stock-app_dashboard.json
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": {
          "type": "datasource",
          "uid": "grafana"
        },
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "description": "",
  "editable": true,
  "fiscalYearStartMonth": 0,
  "gnetId": 15956,
  "graphTooltip": 0,
  "links": [],
  "panels": [
    {
      "datasource": {
        "default": true,
        "type": "prometheus",
        "uid": "PBFA97CFB590B2093"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [
            {
              "options": {
                "0": {
                  "text": "DOWN"
                },
                "1": {
                  "text": "UP"
                }
              },
              "type": "value"
            },
            {
              "options": {
                "match": "null",
                "result": {
                  "text": "N/A"
                }
              },
              "type": "special"
            }
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "#d44a3a",
                "value": null
              },
              {
                "color": "rgba(237, 129, 40, 0.89)",
                "value": 0
              },
              {
                "color": "#299c46",
                "value": 1
              }
            ]
          },
          "unit": "none"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 16,
        "w": 4,
        "x": 0,
        "y": 0
      },
      "id": 2,
      "maxDataPoints": 100,
      "options": {
        "colorMode": "background",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "horizontal",
        "percentChangeColorMode": "standard",
        "reduceOptions": {
          "calcs": [
            "lastNotNull"
          ],
          "fields": "",
          "values": false
        },
        "showPercentChange": false,
        "text": {},
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "11.2.0",
      "repeatDirection": "v",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "PBFA97CFB590B2093"
          },
          "editorMode": "code",
          "exemplar": true,
          "expr": "current_stock_value",
          "format": "time_series",
          "interval": "$interval",
          "intervalFactor": 1,
          "legendFormat": "{{stock}}",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "Ticker",
      "type": "stat"
    },
    {
      "datasource": {
        "default": true,
        "type": "prometheus",
        "uid": "PBFA97CFB590B2093"
      },
      "description": "",
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "viz": false
            },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
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
          },
          "unit": "currencyUSD"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 16,
        "w": 20,
        "x": 4,
        "y": 0
      },
      "id": 138,
      "options": {
        "legend": {
          "calcs": [
            "mean"
          ],
          "displayMode": "table",
          "placement": "right",
          "showLegend": true
        },
        "tooltip": {
          "mode": "multi",
          "sort": "asc"
        }
      },
      "pluginVersion": "7.5.3",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "PBFA97CFB590B2093"
          },
          "editorMode": "code",
          "exemplar": true,
          "expr": "current_stock_value",
          "format": "time_series",
          "interval": "$interval",
          "intervalFactor": 1,
          "legendFormat": "{{stock}}",
          "range": true,
          "refId": "A"
        }
      ],
      "title": "All stock values",
      "type": "timeseries"
    },
    {
      "collapsed": false,
      "datasource": {
        "type": "prometheus",
        "uid": "PBFA97CFB590B2093"
      },
      "gridPos": {
        "h": 1,
        "w": 24,
        "x": 0,
        "y": 16
      },
      "id": 15,
      "panels": [],
      "repeat": "target",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "PBFA97CFB590B2093"
          },
          "refId": "A"
        }
      ],
      "title": "$target ",
      "type": "row"
    }
  ],
  "refresh": "",
  "schemaVersion": 39,
  "tags": [
    "blackbox",
    "prometheus"
  ],
  "templating": {
    "list": [
      {
        "auto": true,
        "auto_count": 10,
        "auto_min": "10s",
        "current": {
          "selected": false,
          "text": "10s",
          "value": "10s"
        },
        "hide": 0,
        "label": "Interval",
        "name": "interval",
        "options": [
          {
            "selected": false,
            "text": "auto",
            "value": "$__auto_interval_interval"
          },
          {
            "selected": false,
            "text": "5s",
            "value": "5s"
          },
          {
            "selected": true,
            "text": "10s",
            "value": "10s"
          },
          {
            "selected": false,
            "text": "30s",
            "value": "30s"
          },
          {
            "selected": false,
            "text": "1m",
            "value": "1m"
          },
          {
            "selected": false,
            "text": "10m",
            "value": "10m"
          },
          {
            "selected": false,
            "text": "30m",
            "value": "30m"
          },
          {
            "selected": false,
            "text": "1h",
            "value": "1h"
          },
          {
            "selected": false,
            "text": "6h",
            "value": "6h"
          },
          {
            "selected": false,
            "text": "12h",
            "value": "12h"
          },
          {
            "selected": false,
            "text": "1d",
            "value": "1d"
          },
          {
            "selected": false,
            "text": "7d",
            "value": "7d"
          },
          {
            "selected": false,
            "text": "14d",
            "value": "14d"
          },
          {
            "selected": false,
            "text": "30d",
            "value": "30d"
          }
        ],
        "query": "5s,10s,30s,1m,10m,30m,1h,6h,12h,1d,7d,14d,30d",
        "refresh": 2,
        "skipUrlSync": false,
        "type": "interval"
      },
      {
        "current": {
          "selected": false,
          "text": "All",
          "value": "$__all"
        },
        "datasource": {
          "type": "prometheus",
          "uid": "PBFA97CFB590B2093"
        },
        "definition": "label_values(stock_price, stock_symbol)",
        "hide": 0,
        "includeAll": true,
        "multi": true,
        "name": "target",
        "options": [],
        "query": {
          "query": "label_values(stock_price, stock_symbol)",
          "refId": "StandardVariableQuery"
        },
        "refresh": 1,
        "regex": "",
        "skipUrlSync": false,
        "sort": 0,
        "tagValuesQuery": "",
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
      "5s",
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
  "title": "Stock dashboard",
  "uid": "ferebtebh3",
  "version": 1,
  "weekStart": ""
}
EOF

# Create Docker Compose file
cat <<EOF > /home/ec2-user/docker-compose.yml
version: '3'
services:
  prometheus:
    image: gabecasis/prometheus:2
    ports:
      - "9090:9090"
    networks:
      - app-network
    restart: always
    volumes:
      - ./prometheus:/prometheus  # Persistent storage for Prometheus data
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml  # Custom Prometheus config

  grafana:
    image: gabecasis/grafana:2
    ports:
      - "3000:3000"
    networks:
      - app-network
    restart: always
    volumes:
      - ./grafana:/var/lib/grafana
      - ./grafana/provisioning/datasources:/etc/grafana/provisioning/datasources  # Correct datasource path
      - ./grafana/provisioning/dashboards:/etc/grafana/provisioning/dashboards  # Mount dashboards
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin

networks:
  app-network:
    driver: bridge
EOF

# Navigate to the directory and bring up the services
cd /home/ec2-user
docker-compose up -d
