# Runbook: checkout-api is crash-looping after a deploy

> Sample runbook used by the `oncall-triage` agent in the talk's demo.

## Investigate (read-only — the agent may do this)
```bash
kubectl get pods -n prod -l app=checkout-api
kubectl logs deploy/checkout-api -n prod --previous --tail=100
kubectl rollout history deploy/checkout-api -n prod
kubectl get events -n prod --sort-by=.lastTimestamp | tail -20
```
Look for: a config value that changed in the last revision, failing health checks,
`FATAL` lines at startup.

## Decide (a human does this)
If errors started right after a deploy and the previous revision was healthy:
roll back. The agent proposes; the named on-call approves.

## Apply (a human, or the pipeline — prod-guard ASKs)
```bash
kubectl rollout undo deploy/checkout-api -n prod --to-revision=<last-good>
kubectl rollout status deploy/checkout-api -n prod
```

## Verify
- Pods `Running`, restarts stop increasing.
- Error rate / SLO back to normal for 10 minutes.
- Incident notes: evidence, decision, who approved.
