import os
from time import perf_counter

from flask import Flask, jsonify
from prometheus_client import Counter, Gauge, Histogram, make_wsgi_app
from redis import Redis
from redis.exceptions import RedisError
from werkzeug.middleware.dispatcher import DispatcherMiddleware

REDIS_URL = os.getenv("REDIS_URL", "redis://redis-cart.default.svc.cluster.local:6379/0")
# TODO(production): Source Redis connection settings and credentials from Kubernetes Secrets, enable TLS where supported,
# and configure connection/read/write timeouts plus retry/backoff appropriate for the Redis provider's SLA.

app = Flask(__name__)
redis_client = Redis.from_url(REDIS_URL, decode_responses=True, socket_connect_timeout=2)

REQUEST_COUNT = Counter(
    "demo_cart_requests_total",
    "Total HTTP requests handled by the Redis cart demo.",
    ["method", "endpoint", "status"],
)
REQUEST_DURATION = Histogram(
    "demo_cart_request_duration_seconds",
    "Time spent handling Redis cart demo requests.",
    ["endpoint"],
)
REDIS_AVAILABLE = Gauge(
    "demo_cart_redis_available",
    "Whether the demo application can reach Redis (1 for available, 0 for unavailable).",
)
CART_ITEMS = Gauge(
    "demo_cart_items",
    "Number of items in a demo user's cart.",
    ["user"],
)
# TODO(production): Do not label metrics with individual user IDs in production; this creates unbounded Prometheus
# cardinality. Replace `user` with a bounded cohort/tenant label or publish an aggregate gauge instead.


def record_request(endpoint, status, start_time):
    REQUEST_COUNT.labels(method="GET", endpoint=endpoint, status=str(status)).inc()
    REQUEST_DURATION.labels(endpoint=endpoint).observe(perf_counter() - start_time)


def redis_ping():
    # TODO(resilience): Consider a short-lived health-cache or circuit breaker so every request does not add an
    # extra Redis PING under load. Preserve fast failure when Redis is a hard dependency.
    try:
        redis_client.ping()
        REDIS_AVAILABLE.set(1)
        return True
    except RedisError:
        REDIS_AVAILABLE.set(0)
        return False


@app.get("/")
def index():
    return jsonify(
        {
            "service": "redis-metrics-demo",
            "endpoints": ["/healthz", "/cart/<user>", "/metrics"],
            "redis_url": REDIS_URL,
        }
    )


@app.get("/healthz")
def healthz():
    # TODO(operations): Split this into `/livez` (process is alive) and `/readyz` (Redis dependency is ready).
    # Liveness should not restart a healthy process merely because an external dependency is temporarily unavailable.
    start_time = perf_counter()
    if not redis_ping():
        record_request("/healthz", 503, start_time)
        return jsonify({"status": "unhealthy", "redis": "unavailable"}), 503

    record_request("/healthz", 200, start_time)
    return jsonify({"status": "ok", "redis": "available"})


@app.get("/cart/<user>")
def cart(user):
    # TODO(validation): Validate and bound `user` and item values before using them in Redis keys; production APIs
    # should also authenticate callers and apply rate limits or an API gateway policy.
    start_time = perf_counter()
    if not redis_ping():
        record_request("/cart/<user>", 503, start_time)
        return jsonify({"error": "Redis is unavailable"}), 503

    cart_key = f"cart:{user}"
    try:
        items = redis_client.lrange(cart_key, 0, -1)
        CART_ITEMS.labels(user=user).set(len(items))
        record_request("/cart/<user>", 200, start_time)
        return jsonify({"user": user, "items": items, "count": len(items)})
    except RedisError:
        REDIS_AVAILABLE.set(0)
        record_request("/cart/<user>", 503, start_time)
        return jsonify({"error": "Unable to read cart"}), 503


@app.post("/cart/<user>/<item>")
def add_cart_item(user, item):
    start_time = perf_counter()
    if not redis_ping():
        REQUEST_COUNT.labels(method="POST", endpoint="/cart/<user>/<item>", status="503").inc()
        REQUEST_DURATION.labels(endpoint="/cart/<user>/<item>").observe(perf_counter() - start_time)
        return jsonify({"error": "Redis is unavailable"}), 503

    try:
        cart_key = f"cart:{user}"
        redis_client.rpush(cart_key, item)
        count = redis_client.llen(cart_key)
        CART_ITEMS.labels(user=user).set(count)
        REQUEST_COUNT.labels(method="POST", endpoint="/cart/<user>/<item>", status="201").inc()
        REQUEST_DURATION.labels(endpoint="/cart/<user>/<item>").observe(perf_counter() - start_time)
        return jsonify({"user": user, "item": item, "count": count}), 201
    except RedisError:
        REDIS_AVAILABLE.set(0)
        REQUEST_COUNT.labels(method="POST", endpoint="/cart/<user>/<item>", status="503").inc()
        REQUEST_DURATION.labels(endpoint="/cart/<user>/<item>").observe(perf_counter() - start_time)
        return jsonify({"error": "Unable to update cart"}), 503


application = DispatcherMiddleware(app, {"/metrics": make_wsgi_app()})


if __name__ == "__main__":
    # TODO(production): Use a production WSGI server such as Gunicorn with configured worker count, graceful
    # shutdown, request timeout, and access logging. Werkzeug's run_simple server is for development only.
    from werkzeug.serving import run_simple

    run_simple("0.0.0.0", 8080, application, use_reloader=False)
