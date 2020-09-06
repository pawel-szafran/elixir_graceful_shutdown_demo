import http from 'k6/http';
import { check } from 'k6';

export let options = {
  vus: 500,
  duration: '2m',
  noVUConnectionReuse: true,
  discardResponseBodies: true,
  noUsageReport: true,
};

export default function () {
  let res = http.post(
    `${__ENV.CALC_URL}/sum`,
    JSON.stringify({ numbers: [1, 2, 3, 4] }),
    { headers: { 'Content-Type': 'application/json' } }
  );
  if (res.status != 200) {
    console.error("Not 200 OK: " + JSON.stringify(res, ["status", "error"]))
  }

  check(res, {
    '200 OK': (r) => r.status === 200,
    "HTTP/2": (r) => r.proto === 'HTTP/2.0'
  });
}
