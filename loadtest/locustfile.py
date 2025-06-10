import os

from locust import HttpUser, task, between


class KonnichiwaUser(HttpUser):
    """
    Simulates user behavior for the Konnichiwa service.
    """
    # Wait 100-500ms between each task. A small wait time is necessary
    # to generate a high number of requests per second per user.
    wait_time = between(0.1, 0.5)

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        # Get the API key from an environment variable once per user
        self.api_key = os.getenv("API_KEY")
        self.auth_headers = {"Authorization": f"Bearer {self.api_key}"}

    @task(3)
    def get_root(self):
        self.client.get("/")

    @task(3)
    def get_health(self):
        self.client.get("/health")

    @task(1)
    def get_inspect(self):
        """Task to hit the secured inspect endpoint."""
        if not self.api_key:
            # Do nothing if the key is missing
            # On the first run, Locust will show this as a failure.
            return

        self.client.get("/inspect", headers=self.auth_headers, name="/inspect")
