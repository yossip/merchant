#!/usr/bin/env bash
# =============================================================================
# DORA Metrics Emission Script
# =============================================================================
# Sends deployment lifecycle metrics to Datadog (custom metrics) and logs 
# deployment events to Coralogix (via structured JSON to Firehose).
#
# DORA Four Key Metrics:
#   1. Deployment Frequency   — How often code ships to production
#   2. Lead Time for Changes  — Time from first commit to production deploy
#   3. Change Failure Rate    — Ratio of failed deployments or rollbacks
#   4. Mean Time to Recovery  — Time to restore service after an incident
#
# Extended Metrics (custom):
#   5. Security Rejection Rate — SAST/SCA/DAST failures blocking promotion
#   6. Development Error Count — Unit test / lint failures in dev pipeline
# =============================================================================

set -euo pipefail

# ---- Required Environment Variables ----
# DORA_ENVIRONMENT        : development | integration | staging | production
# DORA_EVENT_TYPE         : deploy_started | deploy_succeeded | deploy_failed |
#                           test_failed | security_rejected | rollback
# DORA_COMMIT_SHA         : The git SHA being deployed
# DORA_PIPELINE_URL       : URL to the GitHub Actions run
# DD_API_KEY              : Datadog API Key (from Secrets Manager)
# CORALOGIX_FIREHOSE_STREAM : Kinesis Firehose stream name (optional)

TIMESTAMP=$(date +%s)
DORA_ENVIRONMENT="${DORA_ENVIRONMENT:-unknown}"
DORA_EVENT_TYPE="${DORA_EVENT_TYPE:-deploy_succeeded}"
DORA_COMMIT_SHA="${DORA_COMMIT_SHA:-$(git rev-parse HEAD 2>/dev/null || echo 'unknown')}"
DORA_PIPELINE_URL="${DORA_PIPELINE_URL:-}"
DORA_LEAD_TIME_SECONDS="${DORA_LEAD_TIME_SECONDS:-0}"
DORA_ERROR_COUNT="${DORA_ERROR_COUNT:-0}"
DORA_SECURITY_REJECTS="${DORA_SECURITY_REJECTS:-0}"

# =============================================================================
# 1. EMIT TO DATADOG (Custom Metrics via DogStatsD API)
# =============================================================================
emit_datadog_metrics() {
    echo "📊 Emitting DORA metrics to Datadog..."

    local tags="environment:${DORA_ENVIRONMENT},event_type:${DORA_EVENT_TYPE},service:merchant-core-api"

    # Deployment Frequency: Increment counter per deployment event
    if [[ "$DORA_EVENT_TYPE" == "deploy_succeeded" || "$DORA_EVENT_TYPE" == "deploy_started" ]]; then
        curl -s -X POST "https://api.datadoghq.com/api/v1/series" \
            -H "Content-Type: application/json" \
            -H "DD-API-KEY: ${DD_API_KEY}" \
            -d @- <<EOF
{
    "series": [
        {
            "metric": "dora.deployment.frequency",
            "type": "count",
            "points": [[$TIMESTAMP, 1]],
            "tags": ["$tags"]
        },
        {
            "metric": "dora.lead_time.seconds",
            "type": "gauge",
            "points": [[$TIMESTAMP, $DORA_LEAD_TIME_SECONDS]],
            "tags": ["$tags"]
        }
    ]
}
EOF
        echo "  ✅ Deployment frequency + lead time metrics sent."
    fi

    # Change Failure Rate: Increment on failures/rollbacks
    if [[ "$DORA_EVENT_TYPE" == "deploy_failed" || "$DORA_EVENT_TYPE" == "rollback" ]]; then
        curl -s -X POST "https://api.datadoghq.com/api/v1/series" \
            -H "Content-Type: application/json" \
            -H "DD-API-KEY: ${DD_API_KEY}" \
            -d @- <<EOF
{
    "series": [
        {
            "metric": "dora.change_failure.count",
            "type": "count",
            "points": [[$TIMESTAMP, 1]],
            "tags": ["$tags"]
        }
    ]
}
EOF
        echo "  ✅ Change failure metric sent."
    fi

    # Development Error Count
    if [[ "$DORA_ERROR_COUNT" -gt 0 ]]; then
        curl -s -X POST "https://api.datadoghq.com/api/v1/series" \
            -H "Content-Type: application/json" \
            -H "DD-API-KEY: ${DD_API_KEY}" \
            -d @- <<EOF
{
    "series": [
        {
            "metric": "dora.development.error_count",
            "type": "gauge",
            "points": [[$TIMESTAMP, $DORA_ERROR_COUNT]],
            "tags": ["$tags"]
        }
    ]
}
EOF
        echo "  ✅ Development error count metric sent."
    fi

    # Security Rejection Count
    if [[ "$DORA_SECURITY_REJECTS" -gt 0 ]]; then
        curl -s -X POST "https://api.datadoghq.com/api/v1/series" \
            -H "Content-Type: application/json" \
            -H "DD-API-KEY: ${DD_API_KEY}" \
            -d @- <<EOF
{
    "series": [
        {
            "metric": "dora.security.rejection_count",
            "type": "count",
            "points": [[$TIMESTAMP, $DORA_SECURITY_REJECTS]],
            "tags": ["$tags"]
        }
    ]
}
EOF
        echo "  ✅ Security rejection metric sent."
    fi

    # Datadog Event (for the Events Explorer timeline)
    curl -s -X POST "https://api.datadoghq.com/api/v1/events" \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: ${DD_API_KEY}" \
        -d @- <<EOF
{
    "title": "DORA: ${DORA_EVENT_TYPE} on ${DORA_ENVIRONMENT}",
    "text": "Commit: ${DORA_COMMIT_SHA}\nPipeline: ${DORA_PIPELINE_URL}\nLead Time: ${DORA_LEAD_TIME_SECONDS}s\nErrors: ${DORA_ERROR_COUNT}\nSecurity Rejects: ${DORA_SECURITY_REJECTS}",
    "tags": ["$tags", "commit:${DORA_COMMIT_SHA}"],
    "alert_type": "info",
    "source_type_name": "github_actions"
}
EOF
    echo "  ✅ Datadog deployment event recorded."
}

# =============================================================================
# 2. LOG TO CORALOGIX (Structured JSON via Kinesis Firehose)
# =============================================================================
emit_coralogix_log() {
    echo "📋 Logging DORA deployment event to Coralogix via Firehose..."

    local STREAM_NAME="${CORALOGIX_FIREHOSE_STREAM:-merchant-logs-to-coralogix-${DORA_ENVIRONMENT}}"

    local log_payload
    log_payload=$(cat <<EOF
{
    "timestamp": "$TIMESTAMP",
    "severity": "INFO",
    "log_type": "dora_deployment_event",
    "environment": "$DORA_ENVIRONMENT",
    "event_type": "$DORA_EVENT_TYPE",
    "commit_sha": "$DORA_COMMIT_SHA",
    "pipeline_url": "$DORA_PIPELINE_URL",
    "metrics": {
        "lead_time_seconds": $DORA_LEAD_TIME_SECONDS,
        "development_errors": $DORA_ERROR_COUNT,
        "security_rejections": $DORA_SECURITY_REJECTS
    },
    "service": "merchant-core-api",
    "team": "platform-engineering"
}
EOF
)

    # Encode and send to Kinesis Firehose (which delivers to Coralogix)
    local encoded_data
    encoded_data=$(echo "$log_payload" | base64)

    aws firehose put-record \
        --delivery-stream-name "$STREAM_NAME" \
        --record "{\"Data\": \"$encoded_data\"}" \
        --region "${AWS_REGION:-us-east-1}" 2>/dev/null || \
        echo "  ⚠️  Firehose delivery skipped (stream may not exist in this env)."

    echo "  ✅ Coralogix deployment log emitted."
}

# =============================================================================
# Main Execution
# =============================================================================
echo "=================================================="
echo "  DORA Metrics Reporter"
echo "  Environment : $DORA_ENVIRONMENT"
echo "  Event       : $DORA_EVENT_TYPE"
echo "  SHA         : $DORA_COMMIT_SHA"
echo "  Lead Time   : ${DORA_LEAD_TIME_SECONDS}s"
echo "  Errors      : $DORA_ERROR_COUNT"
echo "  Sec Rejects : $DORA_SECURITY_REJECTS"
echo "=================================================="

emit_datadog_metrics
emit_coralogix_log

echo "🎉 DORA metrics emission complete."
