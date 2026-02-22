---
title: QA for DevOps using k6
summary: 'Quick guide to using k6 for load-testing: constant-VUs and ramping-VUs (wave) pattern scenarios, with examples for local and Kubernetes runs.'
date: 2026-02-22
authors:
  - Mati: author.jpeg
---

## Preface

---

In this post I would like to present an easy yet powerful tool to run load-test simulations.
Usually I use a simple while-true loop to generate sample load, but this time I tried something more powerful that pushes the app to its limits.

The [K6](https://k6.io/about/) is simple yet very powerful and can create different [scenarios](https://grafana.com/docs/k6/latest/using-k6/scenarios/), but we will focus on two simple ones:

- the constant load, aka.: [constant-VUs](https://grafana.com/docs/k6/latest/using-k6/scenarios/executors/constant-vus/)
- the wave pattern, aka.: [ramping-VUs](https://grafana.com/docs/k6/latest/using-k6/scenarios/executors/ramping-vus/)

---

## Prepare the tool and run a simple constant load test

### Download from sources

```bash
wget https://github.com/grafana/k6/releases/download/v1.6.0/k6-v1.6.0-linux-arm64.tar.gz
tar -xzf k6-v1.6.0-linux-arm64.tar.gz -C ~/bin/ --strip-components=1
k6 version
```

### Oneliner run command | constant-VUs

```bash
VUS=1500
DUR='1h'
URL='https://YOUR_APP_URL/hello'

echo 'import http from "k6/http";import { sleep } from "k6"; export let options = { vus: "'${VUS}'", duration: "'${DUR}'" }; export default function () { http.get("'${URL}'"); sleep(1); }' | k6 run -
```

### Dump to file and run | constant-VUs

```bash
VUS=1500
DUR='1h'
URL='https://YOUR_APP_URL/hello'

cat > /tmp/test.js << EOF
import http from "k6/http";
import { sleep } from "k6";
export let options = { vus: ${VUS}, duration: "${DUR}" };
export default function () { http.get("${URL}"); sleep(1); }
EOF

k6 run /tmp/test.js
```

## Wave pattern | ramping-VUs

```bash
URL='https://YOUR_APP_URL/hello'


cat > /tmp/test.js << EOFF
import http from "k6/http";
import { sleep } from "k6";
import { Counter, Trend } from "k6/metrics";

const errors = new Counter("errors");
const duration = new Trend("request_duration");

export const options = {
  scenarios: {
    baseline: {
      executor: "constant-vus",
      vus: 50,
      duration: "30m",
      exec: "baseline",
    },
    waves: {
      executor: "ramping-vus",
      startVUs: 50,
      stages: [
        { duration: "1m", target: 50 },
        { duration: "5m", target: 500 },
        { duration: "1m", target: 1500 },
        { duration: "5m", target: 500 },
        { duration: "1m", target: 50 },
        { duration: "2m", target: 2500 },
        { duration: "5m", target: 200 },
      ],
      exec: "waves"
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<500", "p(99)<1000"],
    errors: ["count<100"],
  },
};

export function baseline() {
  const res = http.get("${URL}");
  duration.add(res.timings.duration);
  if (res.status !== 200) errors.add(1);
  sleep(1);
}

export function waves() {
  const res = http.get("${URL}");
  duration.add(res.timings.duration);
  if (res.status !== 200) errors.add(1);
  sleep(0.5);
}
EOFF

k6 run /tmp/test.js
```

## Bonus: Run k6 in a single Kubernetes Pod (not a Deployment)

If you are limited to use just base Ubuntu image, you can use below one.

The example below uses a ConfigMap to:

- First, install required tools at container startup
- Second, provide the k6 test script. You can combine and adapt these steps for automation.

To apply the manifest directly from your shell, run:

```bash
cat <<'EOFF' | kubectl apply -f -
<BELOW_YAML_MANIFEST_HERE>
EOFF
```

Don't forget to export the `URL` or `TARGET` environment variable before running k6.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-k6-tester
  labels:
    app: ubuntu-k6-tester
spec:
  nodeSelector:
    karpenter.sh/nodepool: spot-arm64
  tolerations:
    - effect: NoSchedule
      key: k8s.io/arch
      operator: Equal
      value: arm64
    - effect: NoSchedule
      key: k8s.io/dedicated
      operator: Equal
      value: spot-arm64
  containers:
    - name: ubuntu
      image: ubuntu:latest
      command: ['/bin/bash', '-c', '. /tmp/startup.sh; sleep infinity']
      stdin: true
      tty: true
      # env:
      # - name: URL
      #   value: "https://YOUR_APP_URL/hello"
      resources:
        requests:
          cpu: '10m'
          memory: '32Mi'
        limits:
          memory: '4Gi'
      volumeMounts:
        - name: config-json
          mountPath: /tmp/startup.sh
          subPath: startup.sh
        - name: config-json
          mountPath: /tmp/wavetest.js
          subPath: wavetest.js
  volumes:
    - name: config-json
      configMap:
        name: volume-from-cm
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: volume-from-cm
data:
  startup.sh: |
    #!/bin/bash
    apt update
    apt install -y gnupg2 curl ca-certificates lsb-release wget curl
    wget https://github.com/grafana/k6/releases/download/v1.6.0/k6-v1.6.0-linux-arm64.tar.gz
    tar -xzf k6-v1.6.0-linux-arm64.tar.gz -C /usr/bin/ --strip-components=1
    k6 version
  wavetest.js: |
    import http from "k6/http";
    import { sleep } from "k6";
    import { Counter, Trend } from "k6/metrics";

    const errors = new Counter("errors");
    const duration = new Trend("request_duration");

    // Read target from environment variables.
    // k6 provides environment variables via __ENV.
    // Accept either URL or TARGET for flexibility.
    let TARGET_URL = __ENV.URL || __ENV.TARGET;

    // Runtime validation: fail early with a clear message if no URL is provided.
    if (!TARGET_URL) {
      console.error(
        "Missing required target URL. Set environment variable 'URL' (or 'TARGET') when running k6.\n" +
        "Example: k6 run --env URL='https://example.com' /tmp/wavetest.js"
      );
      // Throwing here aborts the test run with a clear error.
      throw new Error("Missing required environment variable 'URL' (or 'TARGET'). Aborting k6 run.");
    }

    // Basic validation: ensure protocol is present; if not, prepend http:// and warn.
    if (!/^https?:\/\//i.test(TARGET_URL)) {
      console.warn(`Target URL "${TARGET_URL}" does not include a protocol (http/https). Prepending "http://".`);
      TARGET_URL = "http://" + TARGET_URL;
    }

    export const options = {
      scenarios: {
        baseline: {
          executor: "constant-vus",
          vus: 50,
          duration: "30m",
          exec: "baseline",
        },
        waves: {
          executor: "ramping-vus",
          startVUs: 50,
          stages: [
            { duration: "1m", target: 50 },
            { duration: "5m", target: 500 },
            { duration: "1m", target: 1500 },
            { duration: "5m", target: 500 },
            { duration: "1m", target: 50 },
            { duration: "2m", target: 2500 },
            { duration: "5m", target: 200 },
          ],
          exec: "waves"
        },
      },
      thresholds: {
        http_req_duration: ["p(95)<500", "p(99)<1000"],
        errors: ["count<100"],
      },
    };

    export function baseline() {
      const res = http.get(TARGET_URL);
      duration.add(res.timings.duration);
      if (res.status !== 200) errors.add(1);
      sleep(1);
    }

    export function waves() {
      const res = http.get(TARGET_URL);
      duration.add(res.timings.duration);
      if (res.status !== 200) errors.add(1);
      sleep(0.5);
    }
```
